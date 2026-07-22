import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// 6-digit OTP entry: autofocus, auto-advance to the next box on input,
/// backspace moves back, and pasting a full 6-digit code fills every box.
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.length, required this.onChanged, required this.onCompleted});
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers = List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(
    widget.length,
    (i) => FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          return _handleBackspaceKey(i);
        }
        return KeyEventResult.ignored;
      },
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  KeyEventResult _handleBackspaceKey(int i) {
    if (_controllers[i].text.isEmpty && i > 0) {
      _controllers[i - 1].clear();
      _nodes[i - 1].requestFocus();
      widget.onChanged(_code);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onChanged(int i, String value) {
    if (value.length > 1) {
      // Pasted a full code into one box — distribute it across all boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < widget.length; j++) {
        _controllers[j].text = j < digits.length ? digits[j] : '';
      }
      final lastFilled = digits.length.clamp(0, widget.length) - 1;
      if (lastFilled >= 0) _nodes[lastFilled].requestFocus();
      widget.onChanged(_code);
      if (_code.length == widget.length) widget.onCompleted(_code);
      return;
    }
    if (value.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    }
    widget.onChanged(_code);
    if (_code.length == widget.length) widget.onCompleted(_code);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: Semantics(
            label: 'Digit ${i + 1} of ${widget.length}',
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: widget.length, // allow paste-into-one-box to work
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _onChanged(i, v),
            ),
          ),
        );
      }),
    );
  }
}
