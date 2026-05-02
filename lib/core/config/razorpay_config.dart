class RazorpayConfig {
  // Use --dart-define=RAZORPAY_TEST_KEY=... and --dart-define=RAZORPAY_PROD_KEY=...
  static const String testKey = String.fromEnvironment('RAZORPAY_TEST_KEY', defaultValue: 'rzp_test_YOUR_KEY_HERE');
  static const String prodKey = String.fromEnvironment('RAZORPAY_PROD_KEY', defaultValue: 'rzp_live_YOUR_KEY_HERE');
  
  // Use --dart-define=USE_LIVE_RAZORPAY=true for production
  static const bool useLiveKey = bool.fromEnvironment('USE_LIVE_RAZORPAY', defaultValue: false);
  
  static String get activeKey => useLiveKey ? prodKey : testKey;
}
