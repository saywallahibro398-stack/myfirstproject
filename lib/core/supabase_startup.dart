import 'package:flutter/services.dart';
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
      error: describeSupabaseStartupError(config, error),
    );
  }
}

String describeSupabaseStartupError(AppConfig config, Object error) {
  if (error is PlatformException) {
    final safeMessage = (error.message ?? '')
        .replaceAll(config.supabaseUrl, '[SUPABASE_URL]')
        .replaceAll(config.supabaseKey, '[SUPABASE_PUBLIC_KEY]')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final messageSuffix = safeMessage.isEmpty ? '' : ': $safeMessage';
    return 'Supabase startup failed (PlatformException code=${error.code})$messageSuffix';
  }

  return 'Supabase initialization failed (${error.runtimeType}). The build values are present; check Android storage setup and Supabase SDK configuration.';
}
