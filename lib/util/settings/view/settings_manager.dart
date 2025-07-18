// lib/util/settings/settings_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsManager extends ChangeNotifier {
  SettingsManager._();
  static final instance = SettingsManager._();

  // Keys for SharedPreferences
  static const _themeKey = 'theme_mode';
  static const _rememberMeKey = 'remember_me';

  // Legacy (email) + new (username) remember-me payload keys
  static const _savedEmailKey = 'saved_email';         // legacy
  static const _savedUsernameKey = 'saved_username';   // new

  /// The current theme mode (light / dark / system). Defaults to system.
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Whether the user chose “Remember me” at login.
  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  /// Last saved username (new). If null, may fall back to legacy email.
  String? _savedUsername;
  String? get savedUsername => _savedUsername;

  /// Legacy: saved email. Retained for migration / password reset prompts.
  String? _savedEmail;
  String? get savedEmail => _savedEmail;

  // ------------------------------------------------------------
  // Initialization: load persisted settings from SharedPreferences
  // ------------------------------------------------------------

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final storedTheme = prefs.getString(_themeKey);
    instance._themeMode = switch (storedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // Load “remember me” flag
    instance._rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    // Load username (new) and email (legacy)
    instance._savedUsername = prefs.getString(_savedUsernameKey);
    instance._savedEmail = prefs.getString(_savedEmailKey);
  }

  // ------------------------------------------------------------
  // Theme: update and persist
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // “Remember me” support (username-first, email-fallback)
  // ------------------------------------------------------------

  /// Persist the remember-me flag and either username or email.
  ///
  /// Pass **usernameToSave** whenever possible. **emailToSave** is accepted
  /// for backward compatibility.
  Future<void> setRememberMe({
    required bool enabled,
    String? usernameToSave,
    String? emailToSave, // legacy
  }) async {
    _rememberMe = enabled;
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      await prefs.setBool(_rememberMeKey, true);
      if (usernameToSave != null) {
        _savedUsername = usernameToSave;
        await prefs.setString(_savedUsernameKey, usernameToSave);
      }
      if (emailToSave != null) {
        _savedEmail = emailToSave;
        await prefs.setString(_savedEmailKey, emailToSave);
      }
    } else {
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_savedUsernameKey);
      await prefs.remove(_savedEmailKey);
      _savedUsername = null;
      _savedEmail = null;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------
  // Account actions (delegate to FirebaseAuth) – unchanged
  // ------------------------------------------------------------

  Future<void> sendPasswordResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'No email available for the current user.',
      );
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final email = user.email;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Cannot change password: no email on record.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
    await user.delete();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}