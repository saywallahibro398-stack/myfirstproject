class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseKey});

  static final fromBuildEnvironment = AppConfig(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseKey:
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty
        ? const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY')
        : const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseKey;

  bool get isConfigured =>
      Uri.tryParse(supabaseUrl)?.hasAuthority == true &&
      supabaseKey.trim().isNotEmpty;

  String get authRedirectUrl => 'my-notes://login-callback/';
}
