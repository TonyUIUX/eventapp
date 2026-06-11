// lib/screens/payment/payment_webview_screen.dart
// Instamojo WebView payment screen — Evorra v3.1
// Nothing in the existing Razorpay flow is touched.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/config/instamojo_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/instamojo_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final InstamojoPaymentRequest paymentRequest;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const PaymentWebViewScreen({
    required this.paymentRequest,
    required this.onSuccess,
    required this.onFailure,
    super.key,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundBase)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          if (request.url.startsWith(InstamojoConfig.redirectUrl)) {
            _handleRedirect(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentRequest.paymentUrl));
  }

  Future<void> _handleRedirect(String url) async {
    if (_paymentHandled) return;
    _paymentHandled = true;

    final uri = Uri.parse(url);
    final status = uri.queryParameters['payment_status'];
    final requestId =
        uri.queryParameters['payment_request_id'] ?? widget.paymentRequest.id;

    if (status == 'Credit') {
      final service = InstamojoService();
      final verified = await service.verifyPayment(requestId);
      if (mounted) {
        verified ? widget.onSuccess() : widget.onFailure();
      }
    } else {
      if (mounted) widget.onFailure();
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: const Text('Cancel payment?', style: AppTextStyles.heading3),
        content: const Text(
          'Your event will not be posted.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Keep paying',
              style: TextStyle(
                color: AppColors.brandCoral,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onFailure();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete Payment', style: AppTextStyles.heading2),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _confirmCancel,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.brandCoral),
            ),
        ],
      ),
    );
  }
}
