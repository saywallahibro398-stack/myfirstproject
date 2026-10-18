import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class SupabaseStartupResult {
  const SupabaseStartupResult({this.client, this.error});

  final SupabaseClient? client;
  final String? error;
}

Future<SupabaseStartupResult> initializeSupabase(AppConfig config) async {
  final configurationError = config.configurationError;
  if (configurationError != null) {
    return SupabaseStartupResult(error: configurationError);
  }

  try {
    await Supabase.initialize(
      url: config.supabaseUrl.trim(),
      publishableKey: config.supabaseKey.trim(),
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    return SupabaseStartupResult(client: Supabase.instance.client);
  } catch (error) {
    return SupabaseStartupResult(
      error:
          'Supabase initialization failed (${error.runtimeType}). The build values are present; check Android storage setup and Supabase SDK configuration.',
    );
  }
}
