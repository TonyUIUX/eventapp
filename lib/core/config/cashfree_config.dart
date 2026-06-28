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
//     Before enabling payments, move order creation to a Vercel server so this
//     secret key is never needed in the APK at all.
//     See: held_payment_server_tasks.md
// ─────────────────────────────────────────────────────────────────────────────

class CashfreeConfig {
  /// Cashfree App ID — injected via --dart-define=CASHFREE_APP_ID=...
  static const String appId = String.fromEnvironment(
    'CASHFREE_APP_ID',
    defaultValue: '', // ← intentionally empty; never hard-code here
  );

  /// Cashfree Secret Key — injected via --dart-define=CASHFREE_SECRET_KEY=...
  /// ⚠️  NEVER set a defaultValue here. This must come from dart-define only.
  static const String secretKey = String.fromEnvironment(
    'CASHFREE_SECRET_KEY',
    defaultValue: '', // ← intentionally empty; never hard-code here
  );

  /// true = sandbox (testing), false = production
  /// Defaults to true so a misconfigured build never hits production.
  static const bool useSandbox = bool.fromEnvironment(
    'CASHFREE_SANDBOX',
    defaultValue: true, // safe default: sandbox
  );

  /// Returns false when credentials are not injected — prevents accidental
  /// calls to Cashfree API with empty credentials.
  static bool get isConfigured => appId.isNotEmpty && secretKey.isNotEmpty;

  /// Base URL for Cashfree Order Creation API
  static String get orderApiBaseUrl => useSandbox
      ? 'https://sandbox.cashfree.com/pg'
      : 'https://api.cashfree.com/pg';

  /// Cashfree SDK API version header
  static const String apiVersion = '2023-08-01';
}
