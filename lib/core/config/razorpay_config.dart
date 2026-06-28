// lib/core/config/razorpay_config.dart
//
// ─── HOW TO USE ──────────────────────────────────────────────────────────────
// Keys are injected via --dart-define. Never hard-code real keys here.
//
// Local dev:
//   flutter run \
//     --dart-define=RAZORPAY_KEY=rzp_test_YOUR_TEST_KEY \
//     --dart-define=RAZORPAY_LIVE=false
//
// ⚠️  PAYMENT IS DISABLED during the free period (paymentEnabled = false in
//     Firestore). These keys are NOT called until you enable paid posting.
// ─────────────────────────────────────────────────────────────────────────────

class RazorpayConfig {
  /// Razorpay key — injected via --dart-define=RAZORPAY_KEY=...
  /// For test builds pass rzp_test_... ; for prod pass rzp_live_...
  static const String activeKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: '', // ← intentionally empty; never hard-code here
  );

  /// true = live key is being used (validated at runtime via prefix check)
  static bool get isLiveKey => activeKey.startsWith('rzp_live_');

  /// Returns false when no key is injected — prevents accidental empty calls.
  static bool get isConfigured => activeKey.isNotEmpty;
}
