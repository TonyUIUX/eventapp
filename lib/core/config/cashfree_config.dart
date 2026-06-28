// lib/core/config/cashfree_config.dart
// Cashfree Payment Gateway configuration — Evorra
//
// ─── HOW TO USE ──────────────────────────────────────────────────────────────
// Keys are injected at build time via --dart-define. Never hard-code real keys.
//
// Local dev:
//   flutter run \
//     --dart-define=CASHFREE_APP_ID=your_app_id \
//     --dart-define=CASHFREE_SECRET_KEY=your_secret_key \
//     --dart-define=CASHFREE_SANDBOX=true
//
// CI/CD (GitHub Actions / Codemagic):
//   Store values as repo secrets and pass via --dart-define in the build step.
//
// ⚠️  PAYMENT IS DISABLED during the free period (paymentEnabled = false in
//     Firestore). These keys are NOT called until you enable paid posting.
// ─────────────────────────────────────────────────────────────────────────────

class CashfreeConfig {
  /// Cashfree App ID — injected via --dart-define=CASHFREE_APP_ID=...
  static const String appId = String.fromEnvironment(
    'CASHFREE_APP_ID',
    defaultValue: '', // ← intentionally empty; never hard-code here
  );

  /// Vercel API Base URL — injected via --dart-define=API_BASE_URL=...
  static const String orderApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Default to localhost for Android emulator
  );

  /// true = sandbox (testing), false = production
  /// Defaults to true so a misconfigured build never hits production.
  static const bool useSandbox = bool.fromEnvironment(
    'CASHFREE_SANDBOX',
    defaultValue: true, // safe default: sandbox
  );

  /// Returns false when appId is missing
  static bool get isConfigured => appId.isNotEmpty;

  /// Cashfree SDK API version header
  static const String apiVersion = '2023-08-01';
}
