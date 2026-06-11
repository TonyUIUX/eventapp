// lib/services/instamojo_service.dart
// Instamojo REST API integration — Evorra v3.1
// payment_service.dart (Razorpay) is NOT touched.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/config/instamojo_config.dart';

/// Holds the data returned after creating an Instamojo payment request.
class InstamojoPaymentRequest {
  final String id;
  final String paymentUrl;
  final int amount;
  final String eventId;

  const InstamojoPaymentRequest({
    required this.id,
    required this.paymentUrl,
    required this.amount,
    required this.eventId,
  });
}

/// Service that talks to the Instamojo REST API.
/// Instantiated through [instamojoServiceProvider] — never use directly.
class InstamojoService {
  Map<String, String> get _headers => {
        'X-Api-Key': InstamojoConfig.apiKey,
        'X-Auth-Token': InstamojoConfig.authToken,
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  /// Creates a payment request on Instamojo and returns the pay URL.
  Future<InstamojoPaymentRequest> createPaymentRequest({
    required String purpose,
    required int amountRupees,
    required String buyerName,
    required String buyerEmail,
    required String buyerPhone,
    required String eventId,
  }) async {
    final response = await http.post(
      Uri.parse('${InstamojoConfig.baseUrl}/payment-requests/'),
      headers: _headers,
      body: {
        'purpose': purpose,
        'amount': amountRupees.toString(),
        'buyer_name': buyerName,
        'email': buyerEmail,
        'phone': buyerPhone,
        'redirect_url': InstamojoConfig.redirectUrl,
        'allow_repeated_payments': 'false',
        'send_email': 'false',
        'send_sms': 'false',
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Instamojo request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final request = data['payment_request'] as Map<String, dynamic>;

    return InstamojoPaymentRequest(
      id: request['id'] as String,
      paymentUrl: request['longurl'] as String,
      amount: amountRupees,
      eventId: eventId,
    );
  }

  /// Verifies payment status with Instamojo after redirect.
  /// Returns true only when the latest payment has status == 'Credit'.
  Future<bool> verifyPayment(String paymentRequestId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${InstamojoConfig.baseUrl}/payment-requests/$paymentRequestId/',
        ),
        headers: _headers,
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final req = data['payment_request'] as Map<String, dynamic>;
      final payments = req['payments'] as List<dynamic>;

      if (payments.isEmpty) return false;
      final latest = payments.first as Map<String, dynamic>;
      return latest['status'] == 'Credit';
    } catch (e) {
      debugPrint('Instamojo verify error: $e');
      return false;
    }
  }
}
