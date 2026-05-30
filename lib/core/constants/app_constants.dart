import 'package:flutter/material.dart';

class AppSpacing {
  static const double zero = 0.0;
  static const double quat = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

class AppCategories {
  static const List<Map<String, dynamic>> all = [
    {'label': 'All', 'value': 'all', 'icon': Icons.apps_rounded},
    {'label': 'Comedy', 'value': 'comedy', 'icon': Icons.sentiment_very_satisfied_rounded},
    {'label': 'Music', 'value': 'music', 'icon': Icons.music_note_rounded},
    {'label': 'Tech', 'value': 'tech', 'icon': Icons.computer_rounded},
    {'label': 'Fitness', 'value': 'fitness', 'icon': Icons.directions_run_rounded},
    {'label': 'Art', 'value': 'art', 'icon': Icons.palette_rounded},
    {'label': 'Workshop', 'value': 'workshop', 'icon': Icons.handyman_rounded},
  ];
}

/// Convenience aliases used across the app.
class AppConstants {
  /// Flat list of category value strings (for PostEventScreen FilterChips).
  static const List<String> categories = [
    'comedy',
    'music',
    'tech',
    'fitness',
    'art',
    'workshop',
  ];
}
