import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationService {
  PersonalizationService._();
  static final PersonalizationService instance = PersonalizationService._();

  static const String _prefsKey = 'category_affinities';
  
  // Track which category a user viewed
  Future<void> logCategoryView(String category) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load existing map
    final String? data = prefs.getString(_prefsKey);
    Map<String, int> affinities = {};
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      affinities = decoded.map((key, value) => MapEntry(key, value as int));
    }
    
    // Increment the specific category
    affinities[category] = (affinities[category] ?? 0) + 1;
    
    // Save back
    await prefs.setString(_prefsKey, jsonEncode(affinities));
  }
  
  // Get all affinities to sort the event list
  Future<Map<String, int>> getAffinities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_prefsKey);
    if (data == null) return {};
    
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }
}
