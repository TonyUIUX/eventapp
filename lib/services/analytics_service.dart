import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  void logEventView(String eventId, String eventTitle) {
    debugPrint('[Analytics] event_view | id=$eventId | title=$eventTitle');
    _analytics.logEvent(
      name: 'event_view',
      parameters: {'id': eventId, 'title': eventTitle},
    );
  }

  void logCategoryFilter(String category) {
    debugPrint('[Analytics] category_filter | category=$category');
    _analytics.logEvent(
      name: 'category_filter',
      parameters: {'category': category},
    );
  }

  void logEventSaved(String eventId, {required bool saved}) {
    final action = saved ? 'event_saved' : 'event_unsaved';
    debugPrint('[Analytics] $action | id=$eventId');
    _analytics.logEvent(
      name: action,
      parameters: {'id': eventId},
    );
  }

  void logSearch(String query, int resultCount) {
    debugPrint('[Analytics] search | query=$query | results=$resultCount');
    _analytics.logEvent(
      name: 'search',
      parameters: {'query': query, 'results': resultCount},
    );
  }

  void logShare(String eventId, String eventTitle) {
    debugPrint('[Analytics] share | id=$eventId | title=$eventTitle');
    _analytics.logShare(
      contentType: 'event',
      itemId: eventId,
      method: 'native_share',
    );
  }

  void logTicketTap(String eventId) {
    debugPrint('[Analytics] ticket_tap | id=$eventId');
    _analytics.logEvent(
      name: 'ticket_tap',
      parameters: {'id': eventId},
    );
  }

  void logMapTap(String eventId) {
    debugPrint('[Analytics] map_tap | id=$eventId');
    _analytics.logEvent(
      name: 'map_tap',
      parameters: {'id': eventId},
    );
  }

  void logBookingTap(String eventId, String type) {
    debugPrint('[Analytics] booking_tap | id=$eventId | type=$type');
    _analytics.logEvent(
      name: 'booking_tap',
      parameters: {'id': eventId, 'type': type},
    );
  }
}
