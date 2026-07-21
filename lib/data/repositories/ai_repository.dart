import '../../core/supabase/supabase_config.dart';

class ChatMessage {
  const ChatMessage(this.role, this.content);
  final String role; // "user" | "assistant"
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Calls the `ai-chat` edge function (see supabase/functions/ai-chat),
/// mirroring src/lib/ai.functions.ts's chatWithPaisaMitra server function.
class AiRepository {
  const AiRepository();

  Future<String> chatWithPaisaMitra(List<ChatMessage> messages) async {
    final res = await supabase.functions.invoke('ai-chat', body: {
      'messages': messages.map((m) => m.toJson()).toList(),
    });
    if (res.status != 200) {
      final err = (res.data is Map ? res.data['error'] : null) as String?;
      throw Exception(err ?? 'AI request failed');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['reply'] as String;
  }
}
