import 'package:cloud_firestore/cloud_firestore.dart';

// ignore_for_file: constant_identifier_names

enum NotificationType {
  event_approved,
  event_rejected,
  event_reminder,
  system_broadcast,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId; // eventId or broadcastId
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.system_broadcast,
      ),
      relatedId: data['relatedId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
