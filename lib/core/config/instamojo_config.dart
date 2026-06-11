// lib/core/config/instamojo_config.dart
// Instamojo gateway configuration — Evorra v3.1
// Keys injected at build time via --dart-define.
// razorpay_config.dart is NOT touched.

class InstamojoConfig {
  /// Instamojo API key (from developer dashboard)
  static const String apiKey = String.fromEnvironment(
    'INSTAMOJO_API_KEY',
    defaultValue: '',
  );

  /// Instamojo auth token (from developer dashboard)
  static const String authToken = String.fromEnvironment(
    'INSTAMOJO_AUTH_TOKEN',
    defaultValue: '',
  );

  /// Set to false in production via --dart-define=INSTAMOJO_SANDBOX=false
  static const bool useSandbox = bool.fromEnvironment(
    'INSTAMOJO_SANDBOX',
    defaultValue: true,
  );

  static String get baseUrl => useSandbox
      ? 'https://test.instamojo.com/api/1.1'
      : 'https://www.instamojo.com/api/1.1';

  /// Redirect URL Instamojo calls after payment.
  /// Must be whitelisted in Instamojo developer settings.
  static const String redirectUrl = 'https://evorra.app/payment/success';
}
