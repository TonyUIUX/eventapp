import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../services/personalization_service.dart';

// ─── Core data provider ───────────────────────────────────────────────────
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService.instance,
);

// Fetches all active events from Firebase (server already filters past events)
// Uses keepAlive to cache the list across tab switches (Phase 4 Perf)
final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  ref.keepAlive();
  final service = ref.read(firestoreServiceProvider);
  return service.getEvents();
});

// ─── Filter state ─────────────────────────────────────────────────────────
// Currently selected category chip — default 'all'
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Currently selected date filter — 'today' or 'weekend'
final selectedDateFilterProvider = StateProvider<String>((ref) => 'today');

// ─── AI Personalization ───────────────────────────────────────────────────
final categoryAffinitiesProvider = FutureProvider<Map<String, int>>((ref) async {
  return PersonalizationService.instance.getAffinities();
});

// ─── Derived: filtered list for HomeScreen ────────────────────────────────
final filteredEventsProvider =
    Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final category = ref.watch(selectedCategoryProvider);
  final dateFilter = ref.watch(selectedDateFilterProvider);

  return eventsAsync.whenData((events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate coming Saturday and Sunday
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final saturday = today.add(
      Duration(days: daysUntilSaturday == 0 ? 0 : daysUntilSaturday),
    );
    final sunday = saturday.add(const Duration(days: 1));

    final filtered = events.where((event) {
      // Client-side guard: skip stale cache entries that slipped through
      if (!event.isActive || event.status != 'active') return false;

      final eventDate =
          DateTime(event.date.year, event.date.month, event.date.day);

      final bool dateMatch;
      if (dateFilter == 'today') {
        dateMatch = eventDate == today;
      } else if (dateFilter == 'weekend') {
        dateMatch = eventDate == saturday || eventDate == sunday;
      } else {
        // week
        final weekEnd = today.add(const Duration(days: 7));
        dateMatch = !eventDate.isBefore(today) && !eventDate.isAfter(weekEnd);
      }

      final categoryMatch =
          category == 'all' || event.category == category;

      return dateMatch && categoryMatch;
    }).toList();
    
    // AI Personalization Sort (only sort if 'all' categories is selected)
    if (category == 'all') {
      final affinities = ref.watch(categoryAffinitiesProvider).value ?? {};
      
      filtered.sort((a, b) {
        // Priority 1: Featured events go first
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        
        // Priority 2: Personalization (highest affinity score)
        final scoreA = affinities[a.category] ?? 0;
        final scoreB = affinities[b.category] ?? 0;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // descending
        }
        
        // Priority 3: Date
        return a.date.compareTo(b.date);
      });
    }

    return filtered;
  });
});

// ─── NEW v1.1: Featured carousel events ──────────────────────────────────
// Featured events that are today or in the future (no stale carousels)
final featuredEventsProvider =
    Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(eventsProvider).whenData((events) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return events
        .where((e) =>
            e.isFeatured &&
            !DateTime(e.date.year, e.date.month, e.date.day)
                .isBefore(todayDate))
        .toList();
  });
});

// ─── NEW v1.1: Search ─────────────────────────────────────────────────────
// Current search query — updated on every keystroke
final searchQueryProvider = StateProvider<String>((ref) => '');

// Client-side search across title, description, location, category, tags
final searchResultsProvider =
    Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return const AsyncValue.data([]);

  return eventsAsync.whenData((events) {
    return events.where((event) {
      return event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.category.toLowerCase().contains(query) ||
          event.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  });
});

// ─── NEW v2.0: Trending events ───────────────────────────────────────────
// Sorts all upcoming events by simulated popularity (FOMO watching count)
final trendingEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(eventsProvider).whenData((events) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final upcoming = events.where((e) => 
      !DateTime(e.date.year, e.date.month, e.date.day).isBefore(todayDate)
    ).toList();

    // Sort by simulated trending count (eventId hashcode % 40 + 12)
    upcoming.sort((a, b) {
      final countA = (a.id.hashCode.abs() % 40) + 12;
      final countB = (b.id.hashCode.abs() % 40) + 12;
      return countB.compareTo(countA); // Highest first
    });

    return upcoming.take(10).toList();
  });
});

// ─── NEW v2.0: Related events ───────────────────────────────────────────
// Provides 3 events from the same category, excluding the current one
final relatedEventsProvider = Provider.family<AsyncValue<List<EventModel>>, String>((ref, eventId) {
  final eventsAsync = ref.watch(eventsProvider);
  final allEvents = eventsAsync.valueOrNull ?? [];
  
  if (allEvents.isEmpty) return const AsyncValue.loading();

  // P0 fix: use firstWhereOrNull to avoid StateError if event was deleted
  final currentEvent = allEvents.where((e) => e.id == eventId).firstOrNull;
  if (currentEvent == null) return const AsyncValue.data([]);

  final related = allEvents.where((e) => 
    e.category == currentEvent.category && e.id != eventId
  ).toList();
  
  return AsyncValue.data(related.take(3).toList());
});
