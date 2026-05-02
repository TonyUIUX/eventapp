import 'package:shared_preferences/shared_preferences.dart';

class SavedEventsService {
  static const _key = 'saved_event_ids';

  Future<Set<String>> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    return Set<String>.from(saved);
  }

  Future<void> persist(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
