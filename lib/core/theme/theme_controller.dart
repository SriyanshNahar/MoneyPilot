import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Direct port of src/lib/theme.tsx. "auto" resolves to LIGHT per product
/// preference (auto == light), matching the React implementation exactly.
enum ThemePref { light, dark, auto }

const _storageKey = 'mp_theme';

ThemePref _parsePref(String? raw) {
  switch (raw) {
    case 'dark':
      return ThemePref.dark;
    case 'light':
      return ThemePref.light;
    default:
      return ThemePref.auto;
  }
}

String _prefToString(ThemePref p) => switch (p) {
      ThemePref.dark => 'dark',
      ThemePref.light => 'light',
      ThemePref.auto => 'auto',
    };

class ThemeState {
  const ThemeState(this.pref);
  final ThemePref pref;

  /// "auto" resolves to light per product preference.
  Brightness get resolved => pref == ThemePref.dark ? Brightness.dark : Brightness.light;
  ThemeMode get themeMode => pref == ThemePref.dark ? ThemeMode.dark : ThemeMode.light;
}

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController() : super(const ThemeState(ThemePref.auto)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ThemeState(_parsePref(prefs.getString(_storageKey)));
  }

  Future<void> setTheme(ThemePref pref) async {
    state = ThemeState(pref);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _prefToString(pref));
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeState>(
  (ref) => ThemeController(),
);
