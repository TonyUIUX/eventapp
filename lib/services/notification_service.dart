import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _db = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
