import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/my_notes_app.dart';
import 'core/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromBuildEnvironment;
  SupabaseClient? client;
  String? initializationError = config.configurationError;

  if (initializationError == null) {
    try {
      await Supabase.initialize(
        url: config.supabaseUrl.trim(),
        publishableKey: config.supabaseKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      client = Supabase.instance.client;
    } catch (_) {
      initializationError = 'Supabase initialization failed. Check that the project URL and public key are valid and belong to the same project.';
    }
  }

  runApp(MyNotesApp(client: client, initializationError: initializationError));
}
