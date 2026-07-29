/// Runtime configuration for VIVRΛNT Mobile.
///
/// Pass overrides with `--dart-define`:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
/// flutter run --dart-define=API_BASE_URL=http://192.168.254.107:3000
/// flutter run --dart-define=API_BASE_URL=https://your-app.vercel.app
/// ```
///
/// Android emulator → host machine: `http://10.0.2.2:3000`
/// iOS simulator → host machine: `http://127.0.0.1:3000`
/// Physical device on LAN: `http://<your-pc-lan-ip>:3000`
class Env {
  Env._();

  /// Next.js / VIVRΛNT Web host that exposes the mobile REST API.
  /// Defaults to Android emulator loopback to the host's viva-server.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Same Supabase project as viva-server (`NEXT_PUBLIC_SUPABASE_URL`).
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gcqbuccazplfpmuhperg.supabase.co',
  );

  /// Browser-safe publishable key (`NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`).
  /// Default matches this project's Supabase publishable key so OAuth works
  /// even when the IDE run config omits `--dart-define-from-file`.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_LZIrdY7BOosvGebRjMPMeA_rgP_uKzJ',
  );

  /// Deep-link redirect after OAuth. Must be allowlisted in Supabase
  /// Authentication → URL Configuration → Redirect URLs.
  static const oauthRedirect = 'io.supabase.vivrant://login-callback/';

  static const appName = 'VIVRΛNT';
  static const tagline = 'Long live life';
  static const slogan = 'Every Choice Shapes Your Health.';
}
