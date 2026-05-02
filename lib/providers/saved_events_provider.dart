import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/saved_events_service.dart';
import 'events_provider.dart';

// StateNotifier that manages the saved event IDs set
class SavedEventsNotifier extends StateNotifier<Set<String>> {
  SavedEventsNotifier() : super({}) {
    _loadSaved();
  }

  final _service = SavedEventsService();

  Future<void> _loadSaved() async {
    state = await _service.loadSaved();
  }

  Future<void> toggle(String eventId) async {
    final newState = Set<String>.from(state);
    if (newState.contains(eventId)) {
      newState.remove(eventId);
    } else {
      newState.add(eventId);
    }
    state = newState;
    await _service.persist(newState);
  }

  bool isSaved(String eventId) => state.contains(eventId);
}

// Provider for the saved event IDs notifier
final savedEventIdsProvider =
    StateNotifierProvider<SavedEventsNotifier, Set<String>>(
  (ref) => SavedEventsNotifier(),
);

// Derived provider: returns List<EventModel> for Saved tab
final savedEventsProvider =
    Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final savedIds = ref.watch(savedEventIdsProvider);

  return eventsAsync.whenData((events) {
    return events.where((e) => savedIds.contains(e.id)).toList();
  });
});
