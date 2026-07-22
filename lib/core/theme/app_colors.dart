import 'package:flutter/material.dart';

/// Extra brand colors that don't map onto Flutter's [ColorScheme] —
/// mirrors the `--*-tint` custom properties in the React app's styles.css.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primaryTint,
    required this.secondaryTint,
    required this.accentTint,
    required this.destructiveTint,
    required this.card,
    required this.border,
    required this.mutedForeground,
    required this.gradientStart,
    required this.gradientEnd,
    required this.success,
    required this.successTint,
    required this.successForeground,
  });

  final Color primaryTint;
  final Color secondaryTint;
  final Color accentTint;
  final Color destructiveTint;
  final Color card;
  final Color border;
  final Color mutedForeground;
  final Color gradientStart;
  final Color gradientEnd;
  final Color success;
  final Color successTint;
  /// Darker than [success] — use for text/icons drawn on [successTint], since
  /// #22C55E itself falls below WCAG AA contrast (~2.1:1) on its own tint.
  final Color successForeground;

  static const light = AppColors(
    primaryTint: Color(0xFFE6F4F1),
    secondaryTint: Color(0xFFE0F7F5),
    accentTint: Color(0xFFFEF3C7),
    destructiveTint: Color(0xFFFEE2E2),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    mutedForeground: Color(0xFF6B7280),
    gradientStart: Color(0xFF0F766E),
    gradientEnd: Color(0xFF14B8A6),
    success: Color(0xFF22C55E),
    successTint: Color(0xFFDCFCE7),
    successForeground: Color(0xFF166534),
  );

  static const dark = AppColors(
    primaryTint: Color(0xFF062E2B),
    secondaryTint: Color(0xFF0A3A36),
    accentTint: Color(0xFF3A2A08),
    destructiveTint: Color(0xFF431414),
    card: Color(0xFF111827),
    border: Color(0xFF1F2937),
    mutedForeground: Color(0xFF94A3B8),
    gradientStart: Color(0xFF14B8A6),
    gradientEnd: Color(0xFF2DD4BF),
    success: Color(0xFF22C55E),
    successTint: Color(0xFF0F2E1B),
    successForeground: Color(0xFF22C55E), // already ~6.5:1 on the dark tint
  );

  @override
  AppColors copyWith({
    Color? primaryTint,
    Color? secondaryTint,
    Color? accentTint,
    Color? destructiveTint,
    Color? card,
    Color? border,
    Color? mutedForeground,
    Color? gradientStart,
    Color? gradientEnd,
    Color? success,
    Color? successTint,
    Color? successForeground,
  }) {
    return AppColors(
      primaryTint: primaryTint ?? this.primaryTint,
      secondaryTint: secondaryTint ?? this.secondaryTint,
      accentTint: accentTint ?? this.accentTint,
      destructiveTint: destructiveTint ?? this.destructiveTint,
      card: card ?? this.card,
      border: border ?? this.border,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      success: success ?? this.success,
      successTint: successTint ?? this.successTint,
      successForeground: successForeground ?? this.successForeground,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
      secondaryTint: Color.lerp(secondaryTint, other.secondaryTint, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      destructiveTint: Color.lerp(destructiveTint, other.destructiveTint, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      success: Color.lerp(success, other.success, t)!,
      successTint: Color.lerp(successTint, other.successTint, t)!,
      successForeground: Color.lerp(successForeground, other.successForeground, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
