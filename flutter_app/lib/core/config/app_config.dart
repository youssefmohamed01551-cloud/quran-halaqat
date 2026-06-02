class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'replace-with-local-anon-key',
  );

  static const appNameAr = 'منصة الحلقات';
  static const appNameEn = 'Halaqat Platform';
}
