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

  String? get configurationError {
    if (supabaseUrl.trim().isEmpty) {
      return 'The build is missing SUPABASE_URL.';
    }
    if (supabaseKey.trim().isEmpty) {
      return 'The build is missing SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY).';
    }
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        !{'https', 'http'}.contains(uri.scheme)) {
      return 'SUPABASE_URL must be a valid HTTP or HTTPS project URL.';
    }
    return null;
  }

  bool get isConfigured => configurationError == null;

  String get authRedirectUrl => 'my-notes://login-callback';
}
