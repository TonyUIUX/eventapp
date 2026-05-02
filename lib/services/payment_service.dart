import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/config/razorpay_config.dart';

class PaymentService {
  static final PaymentService instance = PaymentService._init();
  late Razorpay _razorpay;
  
  Function(String paymentId)? _onSuccess;
  Function(String errorMessage)? _onError;

  PaymentService._init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void startPayment({
    required int amountPaise,
    required String contactPhone,
    required Function(String paymentId) onSuccess,
    required Function(String errorMessage) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    var options = {
      'key': RazorpayConfig.activeKey,
      'amount': amountPaise,
      'name': 'KochiGo',
      'description': 'Event Posting Fee',
      'prefill': {'contact': contactPhone, 'email': ''},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (_onError != null) _onError!(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onSuccess != null && response.paymentId != null) {
      _onSuccess!(response.paymentId!);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onError != null) {
      _onError!(response.message ?? 'Unknown error occurred.');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallets are not fully integrated right now.
  }
}
