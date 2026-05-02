import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime _toIST(DateTime date) {
    // Convert to UTC, then add 5 hours 30 mins to get exact IST time
    return date.toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  /// e.g. "Sat, 19 Apr · 7:00 PM"
  static String formatCardDate(DateTime date) {
    return DateFormat("EEE, d MMM · h:mm a").format(_toIST(date));
  }

  /// e.g. "Saturday, 19 April 2025 · 7:00 PM"
  static String formatDetailDate(DateTime date) {
    return DateFormat("EEEE, d MMMM yyyy · h:mm a").format(_toIST(date));
  }
}

