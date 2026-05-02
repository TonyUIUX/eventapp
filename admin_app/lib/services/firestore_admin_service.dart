import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';

class FirestoreAdminService {
  final _db = FirebaseFirestore.instance;

  // Create new event
  Future<String> createEvent(Map<String, dynamic> eventData) async {
    final docRef = await _db.collection('events').add({
      ...eventData,
      'createdAt': FieldValue.serverTimestamp(),
      'totalViews': 0,
    });
    return docRef.id;
  }

  // Update existing event
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update event status (e.g., 'active', 'pending', 'rejected')
  Future<void> updateStatus(String id, String status, {String? reason}) async {
    final doc = await _db.collection('events').doc(id).get();
    if (!doc.exists) return;
    final eventData = doc.data()!;
    final userId = eventData['postedBy'] ?? eventData['userId'];
    final eventTitle = eventData['title'] ?? 'Your event';

    await _db.collection('events').doc(id).update({
      'status': status,
      'isActive': status == 'active',
      if (reason?.isNotEmpty ?? false) 'adminNote': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null) {
      String title = '';
      String body = '';
      String type = '';

      if (status == 'active') {
        title = 'Event Approved! 🎉';
        body = 'Your event "$eventTitle" is now live on KochiGo.';
        type = 'event_approved';
      } else if (status == 'rejected') {
        title = 'Event Update Required ⚠️';
        body = 'Your event "$eventTitle" was not approved. ${reason ?? "Please check the guidelines."}';
        type = 'event_rejected';
      }

      if (title.isNotEmpty) {
        await _db.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'relatedId': id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  // Hard delete
  Future<void> deleteEvent(String id) async {
    final doc = await _db.collection('events').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final List<dynamic> urls = data['imageUrls'] ?? [];
      final String singleUrl = data['imageUrl'] ?? '';
      
      final storage = FirebaseStorage.instance;
      for (final url in urls) {
        try { await storage.refFromURL(url).delete(); } catch (_) {}
      }
      if (singleUrl.isNotEmpty) {
        try { await storage.refFromURL(singleUrl).delete(); } catch (_) {}
      }
    }
    await _db.collection('events').doc(id).delete();
  }

  // Get all events (admin sees everything — no isActive filter)
  Stream<List<EventModel>> getAllEventsStream() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(EventModel.fromFirestore).toList());
  }

  // Update global app configuration (pricing, maintenance, etc.)
  // Uses set+merge so the document is created automatically if missing.
  Future<void> updateAppConfig(
    Map<String, dynamic> configData,
    String adminId,
    String? changeLog,
  ) async {
    await _db.collection('app_config').doc('pricing').set(
      {
        ...configData,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
        if (changeLog != null && changeLog.isNotEmpty) 'changeLog': changeLog,
      },
      SetOptions(merge: true),
    );
  }
}
