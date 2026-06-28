import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _idMapKey = 'reminder_notif_ids';

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> scheduleEventReminder(
      String eventId, String title, DateTime eventDate) async {
    await init();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) return false;
    }

    // Schedule 1 day before
    final scheduledDate = eventDate.subtract(const Duration(days: 1));
    if (scheduledDate.isBefore(DateTime.now())) {
      // Event is less than a day away — too late to schedule
      return true;
    }

    final notifId = await _getOrCreateNotifId(eventId);

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for upcoming saved events',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      id: notifId,
      title: 'Upcoming Event: $title',
      body: 'Your event is starting tomorrow!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    return true;
  }

  Future<void> cancelReminder(String eventId) async {
    final notifId = await _getStoredNotifId(eventId);
    if (notifId != null) {
      await _notifications.cancel(id: notifId);
      await _removeNotifId(eventId);
    }
  }

  // ── Stable ID helpers ───────────────────────────────────────────────────────
  // Store eventId → notificationId in SharedPreferences so the same ID is
  // used across app restarts. String.hashCode is NOT stable between restarts.

  Future<int> _getOrCreateNotifId(String eventId) async {
    final existing = await _getStoredNotifId(eventId);
    if (existing != null) return existing;

    final newId = Random().nextInt(2147483647); // max int32
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadIdMap(prefs);
    map[eventId] = newId.toString();
    await prefs.setString(_idMapKey, _encodeMap(map));
    return newId;
  }

  Future<int?> _getStoredNotifId(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadIdMap(prefs);
    final val = map[eventId];
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> _removeNotifId(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadIdMap(prefs);
    map.remove(eventId);
    await prefs.setString(_idMapKey, _encodeMap(map));
  }

  Future<Map<String, String>> _loadIdMap(SharedPreferences prefs) async {
    final raw = prefs.getString(_idMapKey) ?? '';
    if (raw.isEmpty) return {};
    // Simple key=value;key=value encoding to avoid json import
    final result = <String, String>{};
    for (final pair in raw.split(';')) {
      final idx = pair.indexOf('=');
      if (idx > 0) result[pair.substring(0, idx)] = pair.substring(idx + 1);
    }
    return result;
  }

  String _encodeMap(Map<String, String> map) =>
      map.entries.map((e) => '${e.key}=${e.value}').join(';');
}
