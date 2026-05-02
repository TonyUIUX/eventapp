import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventPostService {
  static final EventPostService instance = EventPostService._();
  EventPostService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createPendingEvent({
    required Map<String, dynamic> eventData,
    required int eventDurationDays,
    required List<String> imageUrls,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: eventDurationDays));

    final data = {
      ...eventData,
      'postedBy': user?.uid,
      'status': 'pending_payment',
      'paymentStatus': 'pending',
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryDate),
      'isActive': false,
      'isFeatured': false,
      'totalViews': 0,
      'totalShares': 0,
    };

    final docRef = await _db.collection('events').add(data);
    return docRef.id;
  }

  Future<void> markPaymentComplete({
    required String eventId,
    required String paymentId,
    required int postingFee,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _db.batch();
    
    // Update Event
    final eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'status': 'under_review',
      'paymentStatus': 'paid',
      'paymentId': paymentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create Payment Record
    final paymentRef = _db.collection('payments').doc();
    batch.set(paymentRef, {
      'eventId': eventId,
      'userId': user.uid,
      'paymentId': paymentId,
      'amount': postingFee / 100, // stored in rupees
      'currency': 'INR',
      'status': 'captured',
      'paidAt': FieldValue.serverTimestamp(),
    });

    // Increment user stats
    final userRef = _db.collection('users').doc(user.uid);
    batch.update(userRef, {
      'totalEventsPosted': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> markPaymentFailed(String eventId) async {
    await _db.collection('events').doc(eventId).update({
      'status': 'payment_failed',
      'paymentStatus': 'failed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitFreeEvent({
    required Map<String, dynamic> eventData,
    required int eventDurationDays,
    required List<String> imageUrls,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: eventDurationDays));

    final batch = _db.batch();
    final eventRef = _db.collection('events').doc();

    final data = {
      ...eventData,
      'postedBy': user?.uid,
      'status': 'under_review',
      'paymentStatus': 'free_period',
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryDate),
      'isActive': false,
      'isFeatured': false,
      'totalViews': 0,
      'totalShares': 0,
    };
    batch.set(eventRef, data);

    if (user != null) {
      final userRef = _db.collection('users').doc(user.uid);
      batch.update(userRef, {
        'totalEventsPosted': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }
}
