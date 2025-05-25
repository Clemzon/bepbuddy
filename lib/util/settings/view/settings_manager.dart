// File: lib/util/settings/settings_manager.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SettingsManager extends ChangeNotifier {
  SettingsManager._();
  static final instance = SettingsManager._();

  static const _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Call this once at startup to load the saved theme.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    instance._themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Call to update the theme (e.g. from your SettingsView).
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }
}