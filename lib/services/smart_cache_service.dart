import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import 'firestore_service.dart';

/// SmartCacheService — Pre-fetches and caches the top 20 upcoming events
/// in SharedPreferences so they're available even with no internet.
class SmartCacheService {
  SmartCacheService._();
  static final SmartCacheService instance = SmartCacheService._();

  static const String _cacheKey = 'cached_events_v1';
  static const String _cacheTimestampKey = 'cached_events_timestamp_v1';
  static const int _cacheTtlMinutes = 30; // Refresh if cache is older than 30 min

  final FirestoreService _service = FirestoreService.instance;

  /// Call this at app startup. Refreshes cache in the background if stale.
  Future<void> warmUpCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_cacheTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMinutes = (now - lastFetch) / 1000 / 60;

      if (ageMinutes > _cacheTtlMinutes) {
        // Run in background — don't block UI
        _refreshCache(prefs);
      }
    } catch (e) {
      debugPrint('[SmartCache] warmUp error: $e');
    }
  }

  Future<void> _refreshCache(SharedPreferences prefs) async {
    try {
      final events = await _service.getEvents();
      final top20 = events.take(20).toList();
      final json = jsonEncode(top20.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, json);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('[SmartCache] Cache refreshed with ${top20.length} events.');
    } catch (e) {
      debugPrint('[SmartCache] refresh error: $e');
    }
  }

  /// Returns cached events if Firestore is unreachable.
  Future<List<EventModel>> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_cacheKey);
      if (data == null) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[SmartCache] getCachedEvents error: $e');
      return [];
    }
  }
}
