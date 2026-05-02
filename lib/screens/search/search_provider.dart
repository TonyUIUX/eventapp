import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = StreamProvider<List<EventModel>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  
  if (query.isEmpty) return Stream.value([]);

  // Note: For production, consider Algolia or Meilisearch. 
  // Here we filter the active events stream for demonstration.
  return FirestoreService.instance.getEventsStream().map((events) {
    return events.where((e) {
      return e.title.toLowerCase().contains(query) || 
             e.description.toLowerCase().contains(query) ||
             e.location.toLowerCase().contains(query) ||
             e.category.toLowerCase().contains(query);
    }).toList();
  });
});
