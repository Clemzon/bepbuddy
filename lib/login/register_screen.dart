// lib/login/register_screen.dart
//
// Registration UI for BEPBuddy
//  • Username (unique across all users; case-insensitive)
//  • Email
//  • Password + Confirm
//  • Account creation via FirebaseAuth
//  • User profile document created in Firestore at /users/{uid}
//  • Consistent styling w/ LoginScreen
//
// NOTE: Adjust the import path for SettingsManager if you want to auto-set remember-me,
// but currently registration does not alter remember-me state.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../util/settings/view/settings_manager.dart'; // <- if not needed, remove
// If the above path is wrong in your project structure, update accordingly.

/// A registration screen for Firebase Auth + Firestore user profile.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ---------------------------------------------------------------------------
  // Form & Controllers
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController(); // new
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController  = TextEditingController();

  final _usernameFocus = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation Helpers
  // ---------------------------------------------------------------------------
  final _usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Choose a username';
    if (!_usernameRegExp.hasMatch(v)) {
      return '3–30 letters, numbers, _ only';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Snackbar Helpers
  // ---------------------------------------------------------------------------
  void _showSnack({
    required String msg,
    Color? bg,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg ?? Theme.of(context).colorScheme.primary,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) =>
      _showSnack(msg: msg, bg: Colors.red.shade700, icon: Icons.error_outline);

  void _showSuccess(String msg) =>
      _showSnack(msg: msg, bg: Colors.green.shade600, icon: Icons.check_circle_outline);

  // ---------------------------------------------------------------------------
  // Username Uniqueness Check
  // ---------------------------------------------------------------------------
  Future<bool> _isUsernameAvailable(String username) async {
    final lc = username.toLowerCase();
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('username_lc', isEqualTo: lc)
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    // Extra guard: Confirm match (validator already does this)
    if (password != _confirmController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) Check username availability BEFORE creating Auth user
      final available = await _isUsernameAvailable(username);
      if (!available) {
        _showError('That username is already taken.');
        return;
      }

      // 2) Create Auth user
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = cred.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'no-uid',
          message: 'Could not determine user ID after registration.',
        );
      }

      // 3) Create Firestore user profile
      final now = Timestamp.now();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'username_lc': username.toLowerCase(),
        'email': email,
        'createdAt': now,
        'updatedAt': now,
      });

      // Optional: sync remember-me preference; here we default disabled
      await SettingsManager.instance.setRememberMe(
        enabled: false,
        usernameToSave: null,
        emailToSave: null,
      );

      // 4) Success
      _showSuccess('Account created! You are now signed in.');
      if (!mounted) return;
      Navigator.of(context).pop(); // back to LoginScreen; AuthGate will show Home
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'email-already-in-use') {
        message = 'That email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      _showError(message);
    } catch (e) {
      _showError('An unknown error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final maxWidth = kIsWeb ? 420.0 : 480.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const _RegisterHeader(),
                      const SizedBox(height: 32),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          helperText: '3–30 letters, numbers, underscore',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: _validateUsername,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        validator: _validateConfirm,
                      ),
                      const SizedBox(height: 24),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Already have an account? Log in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header Widget (logo placeholder + tagline)
// -----------------------------------------------------------------------------
class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        // TODO: replace with Image.asset(appIconPath) once available.
        Icon(Icons.person_add_alt_1, size: 72, color: color),
        const SizedBox(height: 8),
        Text(
          'Create Your BEPBuddy Account',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Register to track invoices and submit monthly stand reports.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}