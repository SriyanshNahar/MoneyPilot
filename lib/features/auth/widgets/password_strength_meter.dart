import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

class PasswordRules {
  static bool hasMinLength(String p) => p.length >= 8;
  static bool hasUpper(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasLower(String p) => RegExp(r'[a-z]').hasMatch(p);
  static bool hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p);
  static bool hasSpecial(String p) => RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]/\\;'~`]''').hasMatch(p);

  static bool isValid(String p) => hasMinLength(p) && hasUpper(p) && hasLower(p) && hasNumber(p) && hasSpecial(p);

  static PasswordStrength strengthOf(String p) {
    if (p.isEmpty) return PasswordStrength.empty;
    final score = [hasMinLength(p), hasUpper(p), hasLower(p), hasNumber(p), hasSpecial(p)].where((b) => b).length;
    if (score <= 2) return PasswordStrength.weak;
    if (score == 3) return PasswordStrength.fair;
    if (score == 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}

/// Visual strength bar + rule checklist for the new-password screen.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = PasswordRules.strengthOf(password);
    final (label, color, filled) = switch (strength) {
      PasswordStrength.empty => ('', Colors.grey, 0),
      PasswordStrength.weak => ('Weak', const Color(0xFFEF4444), 1),
      PasswordStrength.fair => ('Fair', const Color(0xFFF59E0B), 2),
      PasswordStrength.good => ('Good', const Color(0xFF0EA5A3), 3),
      PasswordStrength.strong => ('Strong', const Color(0xFF22C55E), 4),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                height: 5,
                decoration: BoxDecoration(
                  color: i < filled ? color : Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
        const SizedBox(height: 10),
        _rule('At least 8 characters', PasswordRules.hasMinLength(password)),
        _rule('One uppercase letter', PasswordRules.hasUpper(password)),
        _rule('One lowercase letter', PasswordRules.hasLower(password)),
        _rule('One number', PasswordRules.hasNumber(password)),
        _rule('One special character', PasswordRules.hasSpecial(password)),
      ],
    );
  }

  Widget _rule(String text, bool met) {
    final color = met ? const Color(0xFF22C55E) : Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.circle_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
