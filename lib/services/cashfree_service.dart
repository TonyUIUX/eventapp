// lib/services/cashfree_service.dart
// Cashfree Payment Gateway integration — Evorra
// Follows the same singleton + callback pattern as payment_service.dart.
// razorpay, instamojo code is NOT touched.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:http/http.dart' as http;
import '../core/config/cashfree_config.dart';

/// Holds the data returned after creating a Cashfree order.
class CashfreeOrder {
  final String orderId;
  final String paymentSessionId;
  final int amount;
  final String eventId;

  const CashfreeOrder({
    required this.orderId,
    required this.paymentSessionId,
    required this.amount,
    required this.eventId,
  });
}

/// Cashfree Payment Gateway service.
/// Provides order creation (via the REST API) and SDK checkout.
///
/// ⚠️  PRODUCTION NOTE: The [createOrder] method calls the Cashfree API
/// directly from the app for development/testing convenience. Before you
/// publish, move order creation to a Firebase Cloud Function so that the
/// Secret Key is never shipped in the APK/IPA.
class CashfreeService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final CashfreeService instance = CashfreeService._init();

  final CFPaymentGatewayService _gatewayService = CFPaymentGatewayService();

  Function(String orderId)? _onSuccess;
  Function(String errorMessage, String orderId)? _onError;

  CashfreeService._init();

  // ── Callback setup — call once from initState ──────────────────────────────
  void setCallback({
    required Function(String orderId) onSuccess,
    required Function(String errorMessage, String orderId) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _gatewayService.setCallback(_handleSuccess, _handleError);
  }

  /// Nullifies stored callbacks — call from the screen's dispose() to prevent
  /// stale closures from a previous payment session triggering on a new screen.
  void clearCallbacks() {
    _onSuccess = null;
    _onError = null;
  }

  // ── Internal callbacks forwarded by the SDK ────────────────────────────────
  void _handleSuccess(String orderId) {
    debugPrint('[Cashfree] Payment success: $orderId');
    if (_onSuccess != null) _onSuccess!(orderId);
  }

  void _handleError(CFErrorResponse errorResponse, String orderId) {
    final msg = errorResponse.getMessage() ?? 'Unknown Cashfree error';
    debugPrint('[Cashfree] Payment error ($orderId): $msg');
    if (_onError != null) _onError!(msg, orderId);
  }

  // ── Step 1: Create an order via Cashfree REST API ─────────────────────────
  /// Creates a Cashfree order and returns [CashfreeOrder] with the
  /// [paymentSessionId] needed for SDK checkout.
  ///
  /// [amountRupees]  — Smallest rupee unit (e.g. 50 for ₹50).
  /// [customerPhone] — 10-digit Indian mobile number.
  /// [customerId]    — Unique customer identifier (Firebase UID works).
  /// [customerEmail] — Customer email.
  /// [customerName]  — Customer display name.
  /// [eventId]       — Your Firestore event doc ID (stored as order note).
  Future<CashfreeOrder> createOrder({
    required int amountRupees,
    required String customerId,
    required String customerEmail,
    required String customerPhone,
    required String customerName,
    required String eventId,
  }) async {
    // Cashfree order_id max length = 50 chars
    final rawId = 'ev_${eventId}_${DateTime.now().millisecondsSinceEpoch}';
    final orderId = rawId.length > 50 ? rawId.substring(rawId.length - 50) : rawId;

    final response = await http.post(
      Uri.parse('${CashfreeConfig.orderApiBaseUrl}/orders'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-version': CashfreeConfig.apiVersion,
        'x-client-id': CashfreeConfig.appId,
        'x-client-secret': CashfreeConfig.secretKey,
      },
      body: jsonEncode({
        'order_id': orderId,
        'order_amount': amountRupees.toStringAsFixed(2),
        'order_currency': 'INR',
        'customer_details': {
          'customer_id': customerId,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': _sanitizePhone(customerPhone),
        },
        'order_meta': {
          'notify_url': '',
        },
        'order_note': 'Evorra event posting fee — eventId: $eventId',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Cashfree order creation failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return CashfreeOrder(
      orderId: data['order_id'] as String,
      paymentSessionId: data['payment_session_id'] as String,
      amount: amountRupees,
      eventId: eventId,
    );
  }

  // ── Step 2: Initiate SDK Web Checkout ─────────────────────────────────────
  /// Opens the Cashfree web checkout using [order] created in [createOrder].
  /// Make sure [setCallback] was called first (in initState of your widget).
  void doPayment(CashfreeOrder order) {
    try {
      const environment =
          CashfreeConfig.useSandbox ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION;

      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(order.orderId)
          .setPaymentSessionId(order.paymentSessionId)
          .build();

      final cfWebCheckout =
          CFWebCheckoutPaymentBuilder().setSession(session).build();

      _gatewayService.doPayment(cfWebCheckout);
    } on CFException catch (e) {
      debugPrint('[Cashfree] SDK error: ${e.message}');
      if (_onError != null) _onError!(e.message, order.orderId);
    }
  }

  // ── Step 3: Verify order status (call from verifyPayment callback) ────────
  /// Fetches the order status from Cashfree.
  /// Returns true only when [order_status] == 'PAID'.
  Future<bool> verifyOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${CashfreeConfig.orderApiBaseUrl}/orders/$orderId'),
        headers: {
          'x-api-version': CashfreeConfig.apiVersion,
          'x-client-id': CashfreeConfig.appId,
          'x-client-secret': CashfreeConfig.secretKey,
        },
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['order_status'] as String? ?? '';
      debugPrint('[Cashfree] Order $orderId status: $status');
      return status == 'PAID';
    } catch (e) {
      debugPrint('[Cashfree] Verify error: $e');
      return false;
    }
  }

  /// Strips non-digits and ensures exactly 10-digit phone for Cashfree.
  String _sanitizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits.padLeft(10, '0'); // fallback — should not happen in prod
  }
}
