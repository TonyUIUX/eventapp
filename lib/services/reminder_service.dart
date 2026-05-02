import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> scheduleEventReminder(String eventId, String title, DateTime eventDate) async {
    await init();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) return false;
    }

    // Schedule 1 day before
    final scheduledDate = eventDate.subtract(const Duration(days: 1));
    if (scheduledDate.isBefore(DateTime.now())) {
      // If the event is in less than a day, don't schedule
      return true; // Return true so it doesn't show error dialog, it's just too late
    }

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for upcoming saved events',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      id: eventId.hashCode,
      title: 'Upcoming Event: $title',
      body: 'Your event is starting tomorrow!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    return true;
  }

  Future<void> cancelReminder(String eventId) async {
    await _notifications.cancel(id: eventId.hashCode);
  }
}
