import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_quote.dart';
import '../../data/repositories/ai_repository.dart';

const _suggestedPrompts = [
  'How much should my emergency fund be?',
  'How do I start a monthly SIP?',
  'Tips to cut subscription spending',
  'Explain the 50/30/20 budgeting rule',
];

/// Direct port of the PaisaMitraChat component in src/routes/_app.insights.tsx.
class AiCoachChat extends StatefulWidget {
  const AiCoachChat({super.key});
  @override
  State<AiCoachChat> createState() => _AiCoachChatState();
}

class _AiCoachChatState extends State<AiCoachChat> {
  final _repo = const AiRepository();
  final _messages = <ChatMessage>[
    const ChatMessage('assistant',
        "Hi! I'm Paisa Mitra, your AI money coach. Ask me how to save more, cut wasted spending, start a SIP, plan EMIs or save tax — I'll give you simple, actionable steps."),
  ];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  String? _error;

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
    setState(() {
      _error = null;
      _messages.add(ChatMessage('user', content));
      _input.clear();
      _busy = true;
    });
    _scrollToBottom();
    try {
      final reply = await _repo.chatWithPaisaMitra(_messages);
      setState(() => _messages.add(ChatMessage('assistant', reply)));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
          child: ListView.separated(
            controller: _scroll,
            shrinkWrap: true,
            itemCount: _messages.length + (_busy ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i >= _messages.length) return const LoadingQuote(label: 'Paisa Mitra is thinking');
              final m = _messages[i];
              return _ChatBubble(role: m.role, content: m.content);
            },
          ),
        ),
        if (_messages.length <= 1) ...[
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
                child: Text(p, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
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
              child: Text(_error!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
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
                  : const Icon(Icons.send, size: 18),
            ),
          ),
        ]),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.role, required this.content});
  final String role;
  final String content;

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
            child: Text(content, style: TextStyle(fontSize: 13, height: 1.4, color: isUser ? scheme.onPrimary : null)),
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
      child: Icon(isUser ? Icons.person : Icons.smart_toy_outlined, size: 13, color: isUser ? scheme.onPrimary : scheme.primary),
    );
  }
}
