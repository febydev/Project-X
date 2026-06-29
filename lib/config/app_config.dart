/// App-wide configuration.
///
/// Mira talks to an AI model (Gemini) through a small Cloudflare Worker proxy
/// so the API key NEVER ships inside the app. After you deploy the worker
/// (see /server/README.md), put its URL here — or set it in-app under
/// Settings → AI connection, which overrides this value.
class AppConfig {
  AppConfig._();

  /// Default proxy endpoint. Leave empty to force setup via Settings.
  /// Example: https://mira-proxy.yourname.workers.dev
  static const String defaultProxyUrl = String.fromEnvironment(
    'MIRA_PROXY_URL',
    defaultValue: '',
  );

  /// Daily message cap for free users (premium is unlimited-ish, still capped
  /// server-side to stay inside free AI limits).
  static const int freeDailyMessageLimit = 5;
}
