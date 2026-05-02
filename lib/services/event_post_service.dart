import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventPostService {
  static final EventPostService instance = EventPostService._();
  EventPostService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit an event to Firestore.
  ///
  /// [requiresPayment]   — whether the platform is in paid-posting mode.
  /// [postingFee]   — fee in paise (from appConfigProvider), only stored
  ///                       in the payment record when [requiresPayment] is true.
  /// [eventDurationDays] — how many days until the event auto-expires.
  /// [paymentId]         — Razorpay payment ID; null for free-period submissions.
  Future<String> submitEvent({
    required Map<String, dynamic> eventData,
    required bool requiresPayment,
    required int eventDurationDays,
    required int postingFee,
    String? paymentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: eventDurationDays));

    final data = {
      ...eventData,
      'postedBy': user?.uid,
      'status': 'under_review', // Always goes to review first
      'paymentStatus': requiresPayment ? 'paid' : 'free_period',
      'paymentId': paymentId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryDate),
      'isActive': false, // Admin must approve to activate
      'isFeatured': false, // Admin must promote manually
      'totalViews': 0,
      'totalShares': 0,
    };

    final docRef = await _db.collection('events').add(data);

    // Only record a payment entry when money actually changed hands.
    if (requiresPayment && paymentId != null) {
      await _db.collection('payments').add({
        'eventId': docRef.id,
        'postedBy': user?.uid,
        'paymentId': paymentId,
        'amount': postingFee, // stored in paise; UI divides by 100
        'currency': 'INR',
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return docRef.id;
  }
}
