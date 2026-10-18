import 'package:flutter/material.dart';

import 'app/my_notes_app.dart';
import 'core/app_config.dart';
import 'core/supabase_startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startup = await initializeSupabase(AppConfig.fromBuildEnvironment);
  runApp(
    MyNotesApp(client: startup.client, initializationError: startup.error),
  );
}
