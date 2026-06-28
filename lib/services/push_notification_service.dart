import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Monotonic counter for unique local notification IDs — avoids hashCode collisions
  int _notifIdCounter = 0;

  Future<void> init() async {
    if (_initialized) return;

    // Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for push notifications');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        // Use a monotonic counter — avoids the hashCode collision issue
        // where two notifications arriving close together get the same ID.
        _localNotifications.show(
          id: _nextNotifId(),
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Fetch and store FCM token in Firestore so targeted push works
    await _fetchAndStoreToken();

    // Re-store token whenever it is refreshed (e.g. app reinstall)
    _fcm.onTokenRefresh.listen((newToken) => _saveTokenToFirestore(newToken));

    _initialized = true;
  }

  int _nextNotifId() {
    _notifIdCounter = (_notifIdCounter + 1) % 100000;
    return _notifIdCounter;
  }

  Future<void> _fetchAndStoreToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('[PushNotification] Failed to fetch FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return; // Not signed in yet — will retry after auth
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()});
      debugPrint('[PushNotification] FCM token stored for user $uid');
    } catch (e) {
      debugPrint('[PushNotification] Failed to store FCM token: $e');
    }
  }

  /// Call this after the user signs in so the FCM token is associated
  /// with their account immediately.
  Future<void> onUserSignedIn() async {
    await _fetchAndStoreToken();
  }
}
