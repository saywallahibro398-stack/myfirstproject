import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfirstproject/core/app_config.dart';
import 'package:myfirstproject/core/supabase_startup.dart';

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
      final startup = await initializeSupabase(buildConfig);
      expect(startup.client, isNotNull, reason: startup.error);
    },
    skip: buildConfig.isConfigured ? false : 'Run this check with the Supabase build defines (the CI workflow does).',
  );
}
