import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/supabase/supabase_config.dart';

class ChatMessage {
  const ChatMessage(this.role, this.content, {this.id, this.createdAt});
  final String role; // "user" | "assistant"
  final String content;
  final String? id;
  final DateTime? createdAt;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Streams a chat reply from the `ai-chat` edge function (Anthropic Claude,
/// see supabase/functions/ai-chat), and persists chat history to
/// `ai_chat_messages` so the AI Coach reloads prior context on reopen.
///
/// Streaming is implemented as a direct HTTP call (rather than
/// `supabase.functions.invoke`, which buffers the whole response) so the UI
/// can render Claude's reply incrementally, matching Anthropic's native SSE
/// event format (`content_block_delta` with `delta.text`).
class AiRepository {
  const AiRepository();

  /// Yields incremental text chunks as Claude generates them. The caller
  /// accumulates these into the growing assistant bubble.
  Stream<String> streamChat(List<ChatMessage> messages) async* {
    final session = supabase.auth.currentSession;
    if (session == null) throw Exception('Not signed in');

    final uri = Uri.parse('$supabaseUrl/functions/v1/ai-chat');
    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': supabaseAnonKey,
      })
      ..body = jsonEncode({'messages': messages.map((m) => m.toJson()).toList()});

    final streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      String message = 'AI request failed (${streamedResponse.statusCode})';
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['error'] is String) message = decoded['error'] as String;
      } catch (_) {
        // keep default message
      }
      throw Exception(message);
    }

    var buffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (true) {
        final sep = buffer.indexOf('\n\n');
        if (sep == -1) break;
        final rawEvent = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);

        for (final line in rawEvent.split('\n')) {
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data.isEmpty) continue;
          Map<String, dynamic> event;
          try {
            event = jsonDecode(data) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }
          final type = event['type'] as String?;
          if (type == 'content_block_delta') {
            final delta = event['delta'] as Map<String, dynamic>?;
            if (delta?['type'] == 'text_delta') {
              final text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) yield text;
            }
          } else if (type == 'error') {
            final err = event['error'] as Map<String, dynamic>?;
            throw Exception(err?['message'] as String? ?? 'AI stream error');
          }
        }
      }
    }
  }

  Future<List<ChatMessage>> loadHistory(String uid, {int limit = 40}) async {
    final rows = await supabase
        .from('ai_chat_messages')
        .select('id, role, content, created_at')
        .eq('user_id', uid)
        .order('created_at')
        .limit(limit);
    return (rows as List)
        .map((r) => ChatMessage(
              r['role'] as String,
              r['content'] as String,
              id: r['id'] as String,
              createdAt: DateTime.tryParse(r['created_at'] as String? ?? ''),
            ))
        .toList();
  }

  Future<void> saveMessage(String uid, ChatMessage message) async {
    await supabase.from('ai_chat_messages').insert({
      'user_id': uid,
      'role': message.role,
      'content': message.content,
    });
  }

  Future<void> clearHistory(String uid) async {
    await supabase.from('ai_chat_messages').delete().eq('user_id', uid);
  }
}
