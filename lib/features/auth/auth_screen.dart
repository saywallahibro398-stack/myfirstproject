
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
          emailRedirectTo:
              AppConfig.fromBuildEnvironment.authRedirectUrl,
        );

        if (response.session == null && mounted) {
          _message(
            'Check your inbox to confirm your email, then come back to log in.',
          );
        }
      } else {
        final response = await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.session == null || response.user == null) {
          _message(
            'Login did not create a session. Check your details and try again.',
          );
          return;
        }

        // Login succeeded. Return to the root screen.
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (error) {
      _message(error.message);
    } catch (error) {
      _message(
        'We could not connect right now. Check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
