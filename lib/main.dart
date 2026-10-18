import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/my_notes_app.dart';
import 'core/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromBuildEnvironment;
  SupabaseClient? client;
  String? initializationError;

  if (config.isConfigured) {
    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      client = Supabase.instance.client;
    } catch (_) {
      initializationError = 'Check the Supabase URL and public client key.';
    }
  }

  runApp(MyNotesApp(client: client, initializationError: initializationError));
}
