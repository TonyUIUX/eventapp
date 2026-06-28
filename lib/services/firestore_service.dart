import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_constants.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time stream — equality-only filters require NO composite index
  Stream<List<EventModel>> getEventsStream() {
    return _db
        .collection(FirestoreCollections.events)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) {
                try {
                  return EventModel.fromFirestore(doc);
                } catch (e) {
                  // Log parse failures so schema issues don't silently hide events
                  assert(() {
                    // ignore: avoid_print
                    print('[FirestoreService] Failed to parse event ${doc.id}: $e');
                    return true;
                  }());
                  return null;
                }
              })
              .whereType<EventModel>()
              .toList();
          events.sort((a, b) => a.date.compareTo(b.date));
          return events;
        });
  }

  // Stream of all events posted by a specific user (no status filter) — used for profile tabs
  Stream<List<EventModel>> getUserEventsStream(String uid) {
    return _db
        .collection(FirestoreCollections.events)
        .where('postedBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) {
                try {
                  return EventModel.fromFirestore(doc);
                } catch (e) {
                  assert(() {
                    // ignore: avoid_print
                    print('[FirestoreService] Failed to parse user event ${doc.id}: $e');
                    return true;
                  }());
                  return null;
                }
              })
              .whereType<EventModel>()
              .toList();
          events.sort((a, b) => b.date.compareTo(a.date)); // newest first
          return events;
        });
  }

  // One-time fetch — server first, falls back to cache automatically
  Future<List<EventModel>> getEvents() async {
    try {
      final query = await _db
          .collection(FirestoreCollections.events)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      
      final events = query.docs
          .map((doc) {
            try { return EventModel.fromFirestore(doc); }
            catch (_) { return null; }
          })
          .whereType<EventModel>()
          .toList();
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (e) {
      // Fallback to local cache on network error
      final query = await _db
          .collection(FirestoreCollections.events)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .limit(50)
          .get(const GetOptions(source: Source.cache));
      final events = query.docs
          .map((doc) {
            try { return EventModel.fromFirestore(doc); }
            catch (_) { return null; }
          })
          .whereType<EventModel>()
          .toList();
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    }
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

  // Block User
  Future<void> blockUser(String uidToBlock) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    await _db.collection(FirestoreCollections.users).doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([uidToBlock]),
    });
  }
}
