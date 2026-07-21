import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Display font stack — mirrors the "Manrope" headings in the React app.
const _displayFontFamilyFallback = ['Manrope', 'Inter'];

class AppTheme {
  AppTheme._();

  static const double radius = 18; // matches --radius: 1.125rem

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: const Color(0xFFFFFFFF),
        foreground: const Color(0xFF111827),
        primary: const Color(0xFF0F766E),
        onPrimary: const Color(0xFFFFFFFF),
        secondary: const Color(0xFF0EA5A3),
        onSecondary: const Color(0xFFFFFFFF),
        accent: const Color(0xFFF59E0B),
        onAccent: const Color(0xFF111827),
        destructive: const Color(0xFFDC2626),
        onDestructive: const Color(0xFFFFFFFF),
        muted: const Color(0xFFF8FAFC),
        colors: AppColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: const Color(0xFF0B1220),
        foreground: const Color(0xFFF8FAFC),
        primary: const Color(0xFF14B8A6),
        onPrimary: const Color(0xFF04211E),
        secondary: const Color(0xFF2DD4BF),
        onSecondary: const Color(0xFF04211E),
        accent: const Color(0xFFFBBF24),
        onAccent: const Color(0xFF111827),
        destructive: const Color(0xFFEF4444),
        onDestructive: const Color(0xFFFFFFFF),
        muted: const Color(0xFF1F2937),
        colors: AppColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color onSecondary,
    required Color accent,
    required Color onAccent,
    required Color destructive,
    required Color onDestructive,
    required Color muted,
    required AppColors colors,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: destructive,
      onError: onDestructive,
      surface: colors.card,
      onSurface: foreground,
      surfaceContainerHighest: muted,
      outline: colors.border,
      tertiary: accent,
      onTertiary: onAccent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Inter', 'Roboto', 'Segoe UI'],
      splashFactory: InkRipple.splashFactory,
      extensions: [colors],
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: foreground,
            displayColor: foreground,
            fontFamily: 'Inter',
          )
          .copyWith(
            headlineLarge: base.textTheme.headlineLarge?.copyWith(
              fontFamily: 'Manrope',
              fontFamilyFallback: _displayFontFamilyFallback,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Manrope',
              fontFamilyFallback: _displayFontFamilyFallback,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontFamily: 'Manrope',
              fontFamilyFallback: _displayFontFamilyFallback,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontFamilyFallback: _displayFontFamilyFallback,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        hintStyle: TextStyle(color: colors.mutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide(color: destructive),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius - 4),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: colors.border),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius - 4),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dividerTheme: DividerThemeData(color: colors.border, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 6)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: TextStyle(color: background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
    );
  }
}
