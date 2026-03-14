import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../application/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _controller = AuthController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _controller.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      } else {
        await _controller.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = error.message ?? error.code;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Sign in',
      subtitle:
          'Use your email and password to access Ayeyo Delivery. New signups become customer accounts by default.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose your login',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = false;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.person_rounded),
                  label: const Text('Customer login'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.adminLogin),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Admin login'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            contentPadding: EdgeInsets.all(20),
            title: Text('Staff roles'),
            subtitle: Text(
              'Admin, counter, and rider access are assigned from Firestore under users/{uid}.',
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isRegisterMode) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (!_isRegisterMode) {
                          return null;
                        }
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email address.';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password.';
                      }
                      if (_isRegisterMode && value.length < 6) {
                        return 'Use at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting
                          ? 'Please wait...'
                          : _isRegisterMode
                          ? 'Create account'
                          : 'Sign in',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : _toggleMode,
                    child: Text(
                      _isRegisterMode
                          ? 'Already have an account? Sign in'
                          : 'Need an account? Create one',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
