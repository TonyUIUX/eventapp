import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_constants.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Optimized stream — equality-only filters require NO composite index
  Stream<List<EventModel>> getEventsStream() {
    return _db
        .collection(FirestoreCollections.events)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          // Sort ascending by date client-side (avoids composite index)
          events.sort((a, b) => a.date.compareTo(b.date));
          return events;
        });
  }

  // One-time fetch for initialization/refresh — no composite index needed
  Future<List<EventModel>> getEvents() async {
    final query = await _db
        .collection(FirestoreCollections.events)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .limit(50)
        .get();
    
    final events = query.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .toList();
    // Sort ascending by date client-side
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  Future<EventModel?> getEventById(String eventId) async {
    final doc = await _db.collection(FirestoreCollections.events).doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  // User Profiles
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> saveUserProfile(UserModel user) async {
    await _db.collection(FirestoreCollections.users).doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  // Reports
  Future<void> submitReport(String eventId, String reason) async {
    await _db.collection(FirestoreCollections.reports).add({
      'eventId': eventId,
      'reason': reason,
      'reportedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
