import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/ai_repository.dart';
import '../auth/auth_controller.dart';

const _suggestedPrompts = [
  'How much should my emergency fund be?',
  'How do I start a monthly SIP?',
  'Tips to cut subscription spending',
  'Explain the 50/30/20 budgeting rule',
];

const _greeting = ChatMessage(
  'assistant',
  "Hi! I'm Paisa Mitra, your AI money coach — now powered by Claude. Ask me to analyze your spending, plan a budget, size an EMI prepayment, or set a savings goal.",
);

/// Direct port of the PaisaMitraChat component in src/routes/_app.insights.tsx,
/// upgraded for v2.1: Claude (streaming) instead of Gemini, persisted chat
/// history, and a typing-cursor animation while the reply streams in.
class AiCoachChat extends ConsumerStatefulWidget {
  const AiCoachChat({super.key});
  @override
  ConsumerState<AiCoachChat> createState() => _AiCoachChatState();
}

class _AiCoachChatState extends ConsumerState<AiCoachChat> {
  final _repo = const AiRepository();
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _loadingHistory = true;
  bool _busy = false;
  String _streamingText = '';
  String? _error;

  String? get _uid => ref.read(authControllerProvider).user?.id;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = _uid;
    if (uid == null) {
      setState(() {
        _messages.add(_greeting);
        _loadingHistory = false;
      });
      return;
    }
    try {
      final history = await _repo.loadHistory(uid);
      setState(() {
        _messages.addAll(history.isEmpty ? [_greeting] : history);
        _loadingHistory = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_greeting);
        _loadingHistory = false;
      });
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final content = text.trim();
    if (content.isEmpty || _busy) return;
    final uid = _uid;
    final userMessage = ChatMessage('user', content);
    setState(() {
      _error = null;
      _messages.add(userMessage);
      _input.clear();
      _busy = true;
      _streamingText = '';
    });
    _scrollToBottom();
    if (uid != null) unawaited(_repo.saveMessage(uid, userMessage));

    try {
      final buffer = StringBuffer();
      await for (final delta in _repo.streamChat(_messages)) {
        buffer.write(delta);
        setState(() => _streamingText = buffer.toString());
        _scrollToBottom();
      }
      final reply = ChatMessage('assistant', buffer.toString());
      setState(() {
        _messages.add(reply);
        _streamingText = '';
      });
      if (uid != null) unawaited(_repo.saveMessage(uid, reply));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final itemCount = _messages.length + (_busy ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 320),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
          child: _loadingHistory
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : ListView.separated(
                  controller: _scroll,
                  shrinkWrap: true,
                  itemCount: itemCount,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i >= _messages.length) {
                      return _ChatBubble(role: 'assistant', content: _streamingText, streaming: true);
                    }
                    final m = _messages[i];
                    return _ChatBubble(role: m.role, content: m.content);
                  },
                ),
        ),
        if (_messages.length <= 1 && !_loadingHistory) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedPrompts.map((p) {
              return OutlinedButton(
                onPressed: _busy ? null : () => _send(p),
                style: OutlinedButton.styleFrom(
                  backgroundColor: colors.primaryTint.withValues(alpha: 0.6),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(p, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
              );
            }).toList(),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: colors.destructiveTint, borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error)),
            ),
          ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_busy,
              decoration: const InputDecoration(hintText: 'Ask about saving, SIPs, EMIs, tax…'),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: _busy || _input.text.trim().isEmpty ? null : () => _send(_input.text),
              style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
              child: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 20),
            ),
          ),
        ]),
      ],
    );
  }
}

void unawaited(Future<void> future) {}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.role, required this.content, this.streaming = false});
  final String role;
  final String content;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) _avatar(colors, scheme, isUser),
        if (!isUser) const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? scheme.primary : colors.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: content.isEmpty && streaming
                ? const _TypingDots()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(content, style: TextStyle(fontSize: 15, height: 1.4, color: isUser ? scheme.onPrimary : null)),
                      ),
                      if (streaming) const _TypingCursor(),
                    ],
                  ),
          ),
        ),
        if (isUser) const SizedBox(width: 6),
        if (isUser) _avatar(colors, scheme, isUser),
      ],
    );
  }

  Widget _avatar(AppColors colors, ColorScheme scheme, bool isUser) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: isUser ? scheme.primary : colors.primaryTint,
      child: Icon(isUser ? Icons.person : Icons.smart_toy_outlined, size: 15, color: isUser ? scheme.onPrimary : scheme.primary),
    );
  }
}

/// Blinking cursor shown at the end of the streaming bubble — the "typing
/// animation" while Claude's reply is still arriving.
class _TypingCursor extends StatefulWidget {
  const _TypingCursor();
  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(left: 2, bottom: 2),
        width: 7,
        height: 15,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}

/// Three-dot "thinking" indicator shown before the first token arrives.
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 34,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value - i * 0.2) % 1.0;
              final scale = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
              return Opacity(
                opacity: 0.4 + 0.6 * scale,
                child: Container(width: 6, height: 6, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
              );
            }),
          );
        },
      ),
    );
  }
}
