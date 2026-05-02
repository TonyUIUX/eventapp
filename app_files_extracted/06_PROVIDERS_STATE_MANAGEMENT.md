# ⚡ Providers & State Management (Riverpod)

## Provider Map

```
eventsProvider (FutureProvider)
    └── Fetches all events from FirestoreService
    └── Returns List<EventModel>

selectedCategoryProvider (StateProvider<String>)
    └── Currently selected category chip
    └── Default: 'all'

selectedDateFilterProvider (StateProvider<String>)
    └── 'today' or 'weekend'
    └── Default: 'today'

filteredEventsProvider (Provider — derived)
    └── Watches eventsProvider + category + date filters
    └── Returns filtered List<EventModel>
    └── All filtering is CLIENT-SIDE

savedEventIdsProvider (StateNotifierProvider)
    └── Set<String> of saved event IDs
    └── Persists to SharedPreferences
    └── Toggle save/unsave

savedEventsProvider (Provider — derived)
    └── Watches eventsProvider + savedEventIdsProvider
    └── Returns List<EventModel> for saved tab
```

---

## Provider Code

```dart
// lib/providers/events_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';

// Service provider
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// All events from Firebase
final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getEvents();
});

// Selected category filter
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Selected date filter
final selectedDateFilterProvider = StateProvider<String>((ref) => 'today');

// Derived: filtered events
final filteredEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final category = ref.watch(selectedCategoryProvider);
  final dateFilter = ref.watch(selectedDateFilterProvider);

  return eventsAsync.whenData((events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate weekend dates
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final saturday = today.add(Duration(days: daysUntilSaturday == 0 ? 0 : daysUntilSaturday));
    final sunday = saturday.add(const Duration(days: 1));

    return events.where((event) {
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);

      // Date filter
      bool dateMatch;
      if (dateFilter == 'today') {
        dateMatch = eventDate == today;
      } else {
        // weekend
        dateMatch = eventDate == saturday || eventDate == sunday;
      }

      // Category filter
      final categoryMatch = category == 'all' || event.category == category;

      return dateMatch && categoryMatch;
    }).toList();
  });
});
```

---

```dart
// lib/providers/saved_events_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedEventsNotifier extends StateNotifier<Set<String>> {
  SavedEventsNotifier() : super({}) {
    _loadSaved();
  }

  static const _key = 'saved_event_ids';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    state = Set<String>.from(saved);
  }

  Future<void> toggle(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final newState = Set<String>.from(state);
    if (newState.contains(eventId)) {
      newState.remove(eventId);
    } else {
      newState.add(eventId);
    }
    state = newState;
    await prefs.setStringList(_key, newState.toList());
  }

  bool isSaved(String eventId) => state.contains(eventId);
}

final savedEventIdsProvider =
    StateNotifierProvider<SavedEventsNotifier, Set<String>>(
  (ref) => SavedEventsNotifier(),
);

// Derived: saved events list (for Saved tab)
final savedEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final savedIds = ref.watch(savedEventIdsProvider);

  return eventsAsync.whenData((events) {
    return events.where((e) => savedIds.contains(e.id)).toList();
  });
});
```

> Note: The `savedEventsProvider` references `eventsProvider` — make sure all providers are in the same file or imported correctly.

---

## How to Use Providers in Screens

```dart
// In a ConsumerWidget (use this instead of StatelessWidget)
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredEventsProvider);

    return filteredAsync.when(
      data: (events) => events.isEmpty
          ? const EmptyStateWidget()
          : EventListView(events: events),
      loading: () => const ShimmerLoadingList(),
      error: (e, st) => ErrorStateWidget(
        onRetry: () => ref.invalidate(eventsProvider),
      ),
    );
  }
}
```

```dart
// Read (not watch) for one-time actions
// e.g. toggle save inside a button press:
ref.read(savedEventIdsProvider.notifier).toggle(event.id);

// Check if saved (in build):
final isSaved = ref.watch(savedEventIdsProvider).contains(event.id);

// Change filter:
ref.read(selectedCategoryProvider.notifier).state = 'comedy';
```

---

## Riverpod Setup in main.dart

```dart
// Wrap entire app with ProviderScope
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```
