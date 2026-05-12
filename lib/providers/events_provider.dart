import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../services/personalization_service.dart';

// ─── Core data provider ───────────────────────────────────────────────────
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService.instance,
);

// Real-time stream from Firestore — auto-updates when admin changes events
final eventsProvider = StreamProvider<List<EventModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.getEventsStream();
});

// ─── Filter state ─────────────────────────────────────────────────────────
// Currently selected category chip — default 'all'
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Currently selected date filter — 'today', 'weekend', or 'week'
final selectedDateFilterProvider = StateProvider<String>((ref) => 'week');

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
    // Use local time to avoid IST/UTC mismatch
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    DateTime saturday;
    DateTime sunday;
    if (now.weekday == DateTime.saturday) {
      saturday = today;
      sunday = today.add(const Duration(days: 1));
    } else if (now.weekday == DateTime.sunday) {
      saturday = today.subtract(const Duration(days: 1));
      sunday = today;
    } else {
      final daysUntilSaturday = DateTime.saturday - now.weekday;
      saturday = today.add(Duration(days: daysUntilSaturday));
      sunday = saturday.add(const Duration(days: 1));
    }

    final filtered = events.where((event) {
      // Client-side guard: skip if not active/published
      if (!event.isActive || event.status != 'active') return false;

      // Convert event date to local and strip time component
      final localEventDate = event.date.toLocal();
      final eventDate = DateTime(
          localEventDate.year, localEventDate.month, localEventDate.day);

      final bool dateMatch;
      if (dateFilter == 'today') {
        dateMatch = eventDate == today;
      } else if (dateFilter == 'weekend') {
        dateMatch = eventDate == saturday || eventDate == sunday;
      } else {
        // 'week' — show next 7 days including today
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

// ─── Featured carousel events ──────────────────────────────────────────────
final featuredEventsProvider =
    Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(eventsProvider).whenData((events) {
    final today = DateTime.now().toLocal();
    final todayDate = DateTime(today.year, today.month, today.day);
    return events
        .where((e) {
          final local = e.date.toLocal();
          final eDate = DateTime(local.year, local.month, local.day);
          return e.isFeatured && !eDate.isBefore(todayDate);
        })
        .toList();
  });
});

// ─── Search ───────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

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

// ─── Trending events ──────────────────────────────────────────────────────
final trendingEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(eventsProvider).whenData((events) {
    final today = DateTime.now().toLocal();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final upcoming = events.where((e) {
      final local = e.date.toLocal();
      final eDate = DateTime(local.year, local.month, local.day);
      return !eDate.isBefore(todayDate);
    }).toList();

    upcoming.sort((a, b) {
      final countA = (a.id.hashCode.abs() % 40) + 12;
      final countB = (b.id.hashCode.abs() % 40) + 12;
      return countB.compareTo(countA);
    });

    return upcoming.take(10).toList();
  });
});

// ─── Related events ──────────────────────────────────────────────────────
final relatedEventsProvider =
    Provider.family<AsyncValue<List<EventModel>>, String>((ref, eventId) {
  final eventsAsync = ref.watch(eventsProvider);
  final allEvents = eventsAsync.valueOrNull ?? [];
  
  if (allEvents.isEmpty) return const AsyncValue.loading();

  final currentEvent = allEvents.where((e) => e.id == eventId).firstOrNull;
  if (currentEvent == null) return const AsyncValue.data([]);

  final related = allEvents.where((e) =>
    e.category == currentEvent.category && e.id != eventId
  ).toList();
  
  return AsyncValue.data(related.take(3).toList());
});
