// lib/login/login_screen.dart
//
// Polished login UI with:
//  • Username + password login (unchanged core logic).
//  • Remember-me support (secure storage + SettingsManager sync).
//  • Forgot username / password bottom sheet flows.
//  • Centered constrained layout for better web presentation.
//  • Consistent spacing + branded header.
//  • Keyboard actions & improved validation messaging.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../util/settings/view/settings_manager.dart'; // adjust path if needed
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---------------------------------------------------------------------------
  // Form & Controllers
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final _storage = const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Remember Me Load
  // ---------------------------------------------------------------------------
  Future<void> _loadRememberMe() async {
    final remember = await _storage.read(key: 'remember_me') ?? 'false';
    final savedUsername = await _storage.read(key: 'saved_username');
    if (!mounted) return;
    setState(() {
      _rememberMe = remember == 'true';
      if (_rememberMe) _usernameController.text = savedUsername ?? '';
    });
  }

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // Look up user by username
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Username not found',
        );
      }
      final data = query.docs.first.data();
      final email = (data['email'] ?? '') as String;
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'No email linked to username',
        );
      }

      // Sign in with email/password
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Remember-me sync
      if (_rememberMe) {
        await _storage.write(key: 'remember_me', value: 'true');
        await _storage.write(key: 'saved_username', value: username);
        await SettingsManager.instance.setRememberMe(
          enabled: true,
          usernameToSave: username,
          emailToSave: email,
        );
      } else {
        await _storage.delete(key: 'remember_me');
        await _storage.delete(key: 'saved_username');
        await SettingsManager.instance.setRememberMe(enabled: false);
      }

      // AuthGate will navigate on auth change.
    } on FirebaseAuthException catch (e) {
      _showErrorSnack(_authErrorToMessage(e));
    } catch (e) {
      _showErrorSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Forgot Password (bottom sheet action)
  // ---------------------------------------------------------------------------
  Future<void> _handleForgotPassword() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showErrorSnack('Enter your username first.');
      return;
    }

    try {
      // Look up email by username
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        _showErrorSnack('No account found for that username.');
        return;
      }
      final data = query.docs.first.data();
      final email = data['email'] as String?;
      if (email == null || email.isEmpty) {
        _showErrorSnack('Account missing email. Contact support.');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccessSnack('Password reset email sent to $email.');
    } on FirebaseAuthException catch (e) {
      _showErrorSnack(_authErrorToMessage(e));
    } catch (e) {
      _showErrorSnack('Error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Forgot Username (enter email, we look up username)
  // ---------------------------------------------------------------------------
  Future<void> _handleForgotUsername() async {
    final email = await _promptForEmail(context);
    if (email == null) return; // user cancelled

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        _showErrorSnack('No account found for that email.');
        return;
      }
      final data = query.docs.first.data();
      final username = data['username'] as String? ?? '(unknown)';
      await _showUsernameDialog(username);
    } catch (e) {
      _showErrorSnack('Error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UI Helpers: Snackbars & Dialogs
  // ---------------------------------------------------------------------------
  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  String _authErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that username.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid credentials.';
      case 'too-many-requests':
        return 'Too many attempts. Try later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  Future<String?> _promptForEmail(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Recover Username'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Lookup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUsernameDialog(String username) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Your Username'),
          content: SelectableText(
            username,
            style: Theme.of(ctx).textTheme.headlineSmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: username));
                Navigator.of(ctx).pop();
                _showSuccessSnack('Username copied to clipboard.');
              },
              child: const Text('Copy & Close'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Forgot bottom sheet
  // ---------------------------------------------------------------------------
  void _showForgotSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 8,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Reset Password'),
                subtitle: const Text('Send reset email to your account email'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleForgotPassword();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_search),
                title: const Text('Recover Username'),
                subtitle: const Text('Look up username using your email'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleForgotUsername();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Constrain width on large screens (web/tablet)
    final maxWidth = kIsWeb ? 420.0 : 480.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Brand / Logo
                      const _LoginHeader(),
                      const SizedBox(height: 32),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _passwordFocus.requestFocus();
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Remember me
                      CheckboxListTile(
                        title: const Text('Remember me'),
                        value: _rememberMe,
                        onChanged: (value) {
                          if (value != null) setState(() => _rememberMe = value);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Log In button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Log In'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Forgot username/password
                      TextButton(
                        onPressed: _showForgotSheet,
                        child: const Text('Forgot username or password?'),
                      ),
                      const SizedBox(height: 8),

                      // Register
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Create account'),
                          ),
                        ],
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
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        // TODO: replace with Image.asset(appIconPath) once asset path provided.
        Icon(Icons.receipt_long, size: 72, color: color),
        const SizedBox(height: 8),
        Text(
          'Welcome to BEPBuddy',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          // Updated subtitle text per user request:
          'Track invoices and submit Monthly Stand Report for Blind Vendors across the Business Enterprise Program.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}