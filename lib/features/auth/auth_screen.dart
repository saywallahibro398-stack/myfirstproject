import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../core/app_config.dart';
import '../../widgets/pastel_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.client,
    required this.startWithSignUp,
    this.setupError,
    super.key,
  });

  final SupabaseClient? client;
  final bool startWithSignUp;
  final String? setupError;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isSignUp = widget.startWithSignUp;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final client = widget.client;
    if (client == null) {
      _message(_setupErrorMessage);
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'display_name': _nameController.text.trim()},
          emailRedirectTo: AppConfig.fromBuildEnvironment.authRedirectUrl,
        );
        if (response.session == null && mounted) {
          _message(
            'Check your inbox to confirm your email, then come back to log in.',
          );
        }
      } else {
        await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message(
        'We could not connect right now. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    final client = widget.client;
    if (client == null) {
      _message(_setupErrorMessage);
      return;
    }
    setState(() => _loading = true);
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.fromBuildEnvironment.authRedirectUrl,
      );
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message(
        'Google sign-in is unavailable. Check the Supabase OAuth setup.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset your password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;
    if (widget.client == null) {
      _message('Connect Supabase before requesting a reset link.');
      return;
    }
    try {
      await widget.client!.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.fromBuildEnvironment.authRedirectUrl,
      );
      _message('If an account exists, a password reset link is on its way.');
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('We could not send a reset link right now. Try again shortly.');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Make room for your thoughts' : 'Welcome back';
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  size: 42,
                  color: AppPalette.lavenderDeep,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Your own little corner for ideas, plans and everyday moments.'
                      : 'Your notes are waiting right where you left them.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppPalette.mutedInk,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                PastelCard(
                  color: AppPalette.lavender,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Your name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Add your name to get started.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(email)
                                ? null
                                : 'Enter a valid email address.';
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: _isSignUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (_isSignUp && value.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            return null;
                          },
                        ),
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isSignUp ? 'Create account' : 'Log in'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'OR',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _continueWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 25),
                            label: const Text('Continue with Google'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : 'New here? Create an account',
                  ),
                ),
                if (widget.client == null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      _setupErrorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppPalette.mutedInk),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _setupErrorMessage =>
      widget.setupError ??
      AppConfig.fromBuildEnvironment.configurationError ??
      'Supabase could not initialize. Check the project URL and public key.';
}
