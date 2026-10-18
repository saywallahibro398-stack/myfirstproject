import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myfirstproject/core/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reports a missing URL separately from a missing client key', () {
    expect(
      const AppConfig(supabaseUrl: '', supabaseKey: '').configurationError,
      'The build is missing SUPABASE_URL.',
    );
    expect(
      const AppConfig(
        supabaseUrl: 'https://project.invalid',
        supabaseKey: '',
      ).configurationError,
      'The build is missing SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY).',
    );
  });

  test('rejects malformed project URLs without exposing their value', () {
    final config = const AppConfig(
      supabaseUrl: 'not-a-url',
      supabaseKey: 'not-empty',
    );

    expect(
      config.configurationError,
      'SUPABASE_URL must be a valid HTTP or HTTPS project URL.',
    );
  });

  final buildConfig = AppConfig.fromBuildEnvironment;
  test(
    'Flutter compiled the Supabase URL and public key into this build',
    () => expect(buildConfig.configurationError, isNull),
    skip: buildConfig.isConfigured ? false : 'Run this check with the Supabase build defines (the CI workflow does).',
  );

  test(
    'Supabase Flutter SDK initializes with the compiled project configuration',
    () async {
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(
        url: buildConfig.supabaseUrl.trim(),
        publishableKey: buildConfig.supabaseKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      expect(Supabase.instance.isInitialized, isTrue);
    },
    skip: buildConfig.isConfigured ? false : 'Run this check with the Supabase build defines (the CI workflow does).',
  );
}
