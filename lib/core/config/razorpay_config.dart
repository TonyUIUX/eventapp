class RazorpayConfig {
  // ↓↓↓ Paste your Razorpay Test Key here ↓↓↓
  static const String testKey = 'rzp_test_YOUR_KEY_HERE';
  
  // ↓↓↓ Paste your Razorpay Live Key here (for production) ↓↓↓
  static const String prodKey = 'rzp_live_YOUR_KEY_HERE';
  
  // Change to true when releasing to production
  static const bool useLiveKey = false;
  
  static String get activeKey => useLiveKey ? prodKey : testKey;
}
