# 💳 Payment Integration — KochiGo v3.0 (Razorpay)

---

## Why Razorpay

| Factor | Razorpay | Other options |
|---|---|---|
| India-first | ✅ Built for India | Stripe has limited UPI support |
| UPI support | ✅ Native UPI, GPay, PhonePe | Most Western gateways lack this |
| Flutter SDK | ✅ Official `razorpay_flutter` | Stripe Flutter is complex |
| Activation | Fast — KYC via Aadhar/PAN | Stripe requires more documents |
| MDR (fee) | 2% per transaction | Similar across all Indian gateways |
| Minimum | No minimum threshold | Stripe has $20 minimum payout |
| Settlement | T+2 business days | Standard |

**For ₹49 payment: you receive ₹47.98 (Razorpay keeps ₹1.02)**

---

## Setup Steps

### Step 1: Create Razorpay Account
1. Go to https://dashboard.razorpay.com
2. Sign up → complete KYC (PAN + bank details)
3. You can use **Test mode** during development (no real payments)
4. Get your **Key ID** and **Key Secret** from Settings → API Keys

### Step 2: Add to Flutter

```yaml
# pubspec.yaml
razorpay_flutter: ^1.3.x
```

### Step 3: Android Setup

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- Add inside <application> tag -->
<activity
  android:name="com.razorpay.CheckoutActivity"
  android:configChanges="keyboard|keyboardHidden|phoneState|orientation|uiMode"
  android:exported="false"
  android:hardwareAccelerated="true"
  android:theme="@style/Checkout.Theme" />
```

### Step 4: Proguard rules (for release builds)

```
# android/app/proguard-rules.pro
-keepclassmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
```

---

## Payment Service

```dart
// lib/services/payment_service.dart

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  late Razorpay _razorpay;

  // Callbacks — set before opening checkout
  Function(String paymentId, String orderId, String signature)? onSuccess;
  Function(String description, int code)? onFailure;
  Function()? onExternalWallet;

  static const _keyId = 'rzp_test_XXXXXXXXXXXXXXX'; // Replace with your Key ID
  // ⚠️ NEVER hardcode Key Secret in Flutter code — only Key ID goes here

  static const _tierPrices = {
    'basic':   4900,  // Amount in paise (₹49 = 4900 paise)
    'boost':   14900, // ₹149
    'premium': 34900, // ₹349
  };

  static const _tierLabels = {
    'basic':   '₹49',
    'boost':   '₹149',
    'premium': '₹349',
  };

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required String tier,
    required String eventId,
    required String eventTitle,
    required UserModel user,
  }) {
    final amount = _tierPrices[tier]!;
    final options = {
      'key': _keyId,
      'amount': amount,
      'name': 'KochiGo',
      'description': 'Event: $eventTitle (${tier.toUpperCase()})',
      'prefill': {
        'contact': user.phone ?? '',
        'email': user.email ?? '',
        'name': user.displayName,
      },
      'notes': {
        'event_id': eventId,
        'tier': tier,
        'user_id': user.uid,
      },
      'theme': {
        'color': '#FF5247',  // KochiGo coral
      },
      // UPI is auto-shown — no extra config needed
    };

    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(
      response.paymentId ?? '',
      response.orderId ?? '',
      response.signature ?? '',
    );
  }

  void _handleError(PaymentFailureResponse response) {
    onFailure?.call(
      response.message ?? 'Payment failed',
      response.code ?? 0,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call();
  }
}
```

---

## Wiring Payment in PostEventScreen

```dart
// In PostEventScreen (ConsumerStatefulWidget) — Step 6

late PaymentService _paymentService;
String? _pendingEventId;

@override
void initState() {
  super.initState();
  _paymentService = PaymentService();
  _paymentService.init();
  
  _paymentService.onSuccess = _onPaymentSuccess;
  _paymentService.onFailure = _onPaymentFailure;
}

@override
void dispose() {
  _paymentService.dispose();
  super.dispose();
}

Future<void> _initiatePayment() async {
  setState(() => _isProcessing = true);
  
  try {
    // 1. Upload image + create Firestore doc with status: pending_payment
    final eventPostService = ref.read(eventPostServiceProvider);
    final eventId = await eventPostService.createEventDraft(
      _formData,
      ref.read(authServiceProvider).uid!,
    );
    _pendingEventId = eventId;

    // 2. Open Razorpay checkout
    _paymentService.openCheckout(
      tier: _formData.selectedTier,
      eventId: eventId,
      eventTitle: _formData.title!,
      user: ref.read(currentUserProfileProvider).value!,
    );
  } catch (e) {
    setState(() => _isProcessing = false);
    _showError('Failed to create event: $e');
  }
}

Future<void> _onPaymentSuccess(
  String paymentId, String orderId, String signature) async {
  
  // Update Firestore — status: under_review, paymentStatus: paid
  await ref.read(eventPostServiceProvider).markPaymentSuccess(
    eventId: _pendingEventId!,
    tier: _formData.selectedTier,
    razorpayPaymentId: paymentId,
  );

  // Update user's totalEventsPosted counter
  await FirebaseFirestore.instance
      .collection('users')
      .doc(ref.read(authServiceProvider).uid)
      .update({'totalEventsPosted': FieldValue.increment(1)});

  // Navigate to Success screen
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PostEventSuccessScreen(
          eventTitle: _formData.title!,
          tier: _formData.selectedTier,
          amount: PaymentService._tierLabels[_formData.selectedTier]!,
        ),
      ),
    );
  }
}

void _onPaymentFailure(String description, int code) {
  setState(() => _isProcessing = false);
  
  // Mark the Firestore doc as payment_failed so admin can see abandoned attempts
  if (_pendingEventId != null) {
    FirebaseFirestore.instance
        .collection('events')
        .doc(_pendingEventId)
        .update({'status': 'payment_failed'});
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Payment failed: $description'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## Firestore: `payments` Collection

```
payments/{paymentId}  (auto-generated ID)
  eventId           String    Reference to events/{id}
  userId            String    Firebase UID
  tier              String    'basic' | 'boost' | 'premium'
  amount            Number    In rupees (49 | 149 | 349)
  razorpayPaymentId String    From Razorpay response
  razorpayOrderId   String?   If using Orders API
  status            String    'captured' | 'failed' | 'refunded'
  paidAt            Timestamp
  refundedAt        Timestamp?
  refundReason      String?   e.g. "event rejected by admin"
```

---

## Admin: View Revenue

```dart
// admin_app — Revenue screen query
Stream<List<Payment>> getRevenueStream() {
  return _db
    .collection('payments')
    .where('status', isEqualTo: 'captured')
    .orderBy('paidAt', descending: true)
    .snapshots()
    .map((snap) => snap.docs.map(Payment.fromFirestore).toList());
}

// Aggregate stats (compute client-side for MVP):
// totalRevenue = payments.fold(0, (sum, p) => sum + p.amount)
// tierBreakdown = group by tier, count each
```

---

## Going Live with Razorpay

### Test Mode → Production Switch
1. Complete KYC on Razorpay Dashboard (PAN card + bank account + business details)
2. Once approved (usually 2–5 business days), you get Live Key ID + Live Key Secret
3. Replace `rzp_test_XXX` with `rzp_live_XXX` in PaymentService
4. Test with a real ₹1 payment to verify end-to-end

### Important: Key Secret Security
- Key ID: safe to put in app code
- Key Secret: NEVER in Flutter code
- For KochiGo MVP: you don't need Key Secret in the app (no server-side order verification)
- When you scale: add Firebase Functions to verify Razorpay signatures server-side

### Refund Policy (Implement in Admin Dashboard)
```
Event rejected by admin → Admin taps "Refund" → 
  Calls Razorpay Refunds API (from Firebase Functions or manual dashboard)
  Updates payments/{id}.status = 'refunded'
  Updates payments/{id}.refundedAt
  Sends notification to user
```

---

## GST Consideration
If your annual revenue exceeds ₹20 lakhs (~₹1.67L/month), you need GST registration.
For MVP phase: not required. Keep it simple.

---

## Test Cards (Razorpay Test Mode)

| Method | Details |
|---|---|
| Card (success) | `4111 1111 1111 1111`, any CVV, any future date |
| Card (failure) | `4000 0000 0000 0002` |
| UPI (success) | `success@razorpay` |
| UPI (failure) | `failure@razorpay` |
| Net Banking | Select any bank in test mode → success auto |
