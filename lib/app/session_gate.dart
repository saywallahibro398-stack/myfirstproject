import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/password_recovery_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/shell/app_shell.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({
    required this.client,
    required this.onThemeChanged,
    super.key,
  });

  final SupabaseClient client;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return PasswordRecoveryScreen(client: client);
        }
        final user = client.auth.currentUser;
        if (user == null) return WelcomeScreen(client: client);
        return AppShell(
          key: ValueKey(user.id),
          client: client,
          onThemeChanged: onThemeChanged,
        );
      },
    );
  }
}
