# ✨ New Features — KochiGo v2.0

> These are features being ADDED to the existing app.
> All existing code in v1.0 must be preserved. Only extend, don't rewrite.

---

## 1. Search Feature

### Where It Lives
- A `SearchScreen` accessible from a search icon in the HomeScreen AppBar
- OR a dedicated "Search" bottom nav tab (if 3-tab layout chosen)
- Search is FULL-TEXT, CLIENT-SIDE across event titles and descriptions

### Provider
```dart
// lib/providers/search_provider.dart

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final eventsAsync = ref.watch(eventsProvider);

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
```

### SearchScreen Layout
```
AppBar:
  - Back button
  - TextField (autofocus: true)
  - Clear (×) button when text is non-empty

Body:
  - While query is empty:
      Show recent searches (max 5, stored in SharedPreferences key: 'recent_searches')
      Show "Popular categories" chips
  
  - While typing (query non-empty):
      Show results list using same EventCard widget
      Show result count: "3 events found"
  
  - No results:
      Show empty state: 🔍 "No events for '{query}'"
```

### AppBar Search Icon
```dart
// home_screen.dart — add to AppBar actions:
actions: [
  IconButton(
    icon: const Icon(Icons.search, color: AppColors.textPrimary),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    ),
  ),
],
```

---

## 2. Featured Events Carousel

### Where It Lives
At the top of HomeScreen, ABOVE the category filter bar.
Only shows when `isFeatured == true` events exist for the selected date filter.

### Layout
```
Section header: "✨ Featured" (SemiBold 14px, textSecondary color)

Horizontal PageView or ListView.builder (horizontal scroll):
  - Card size: 280×160px (wider, landscape format)
  - Card spacing: 12px
  - Padding: 16px horizontal

FeaturedCard widget (different from EventCard):
  - Full bleed image with gradient overlay (bottom 50% dark gradient)
  - Title overlaid on image (bottom-left, white, bold)
  - Category chip top-left (overlay)
  - Date bottom-right (white, small)
  - Tap → EventDetailScreen

Auto-scroll:
  - Auto-advances every 4 seconds (Timer.periodic)
  - Dot indicator below carousel
  - Pauses on user touch
```

### Provider
```dart
// In events_provider.dart — add:

final featuredEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final dateFilter = ref.watch(selectedDateFilterProvider);
  
  return eventsAsync.whenData((events) {
    final now = DateTime.now();
    // Apply same date logic as filteredEventsProvider
    return events
      .where((e) => e.isFeatured && _matchesDateFilter(e, dateFilter, now))
      .take(5)  // Max 5 featured cards
      .toList();
  });
});
```

### Implementation Notes
```dart
// lib/screens/home/widgets/featured_carousel.dart

class FeaturedCarousel extends ConsumerStatefulWidget {
  // Uses PageController with viewportFraction: 0.85
  // Auto-scroll with Timer — cancel timer in dispose()
  // Smooth dot indicator synced to PageController
  // Only render if featuredEvents.isNotEmpty
}
```

---

## 3. Share Event Feature

### Why It Matters
#1 growth feature. Every share = free install potential.

### Where It Lives
- In `EventDetailScreen` AppBar (share icon, top-right)
- Long-press on EventCard (in addition to save)

### Package
```yaml
share_plus: ^10.x.x
```

### Share Content
```dart
// lib/core/utils/share_utils.dart

import 'package:share_plus/share_plus.dart';

Future<void> shareEvent(EventModel event) async {
  final dateStr = DateUtils.formatCardDate(event.date);
  final text = '''
🎉 ${event.title}

📅 $dateStr
📍 ${event.location}

Found on KochiGo — Kochi's event discovery app 🚀
Download: https://play.google.com/store/apps/details?id=com.kochigo.kochigo_app
''';

  await Share.share(
    text,
    subject: event.title,
  );
}
```

### UI Integration
```dart
// event_detail_screen.dart — AppBar
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.share_outlined),
      onPressed: () => shareEvent(event),
    ),
  ],
)
```

---

## 4. Price & Ticket Info

### Firestore Fields to Add
```
price       String    "Free" | "₹200" | "₹500–1000" | "Pay at door"
ticketLink  String?   URL to ticket purchase (optional)
```

### EventModel Update
```dart
// event_model.dart — add to class:
final String price;         // Default: "Free"
final String? ticketLink;   // Nullable

// In fromFirestore():
price: data['price'] ?? 'Free',
ticketLink: data['ticketLink'],

// In toMap():
'price': price,
'ticketLink': ticketLink,
```

### EventCard — Price Badge
```dart
// Show price badge alongside category chip in bottom of image
Positioned(
  bottom: 8,
  right: 8,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: event.price == 'Free' 
        ? AppColors.success.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      event.price,
      style: const TextStyle(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
      ),
    ),
  ),
)
```

### EventDetailScreen — Ticket Button
```dart
// Below organizer section — show only if ticketLink is non-null
if (event.ticketLink != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.confirmation_number_outlined),
        label: const Text('Get Tickets'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: () => openUrl(event.ticketLink!),
      ),
    ),
  ),
```

---

## 5. Event Tags

### What Tags Are
Small visual pills on each event for quick scanning.

Valid tags (lowercase strings in Firestore array):
```
free        → 🆓 "Free Entry"
popular     → 🔥 "Popular"
new         → ✨ "New"
outdoor     → 🌿 "Outdoor"
family      → 👨‍👩‍👧 "Family Friendly"
limited     → ⚡ "Limited Seats"
```

### Firestore Field
```
tags    String[]    e.g. ["free", "popular", "outdoor"]
```

### EventModel Update
```dart
final List<String> tags;

// fromFirestore():
tags: List<String>.from(data['tags'] ?? []),

// toMap():
'tags': tags,
```

### EventCard — Tags Row
```dart
// Below location row — only show max 2 tags to keep card clean
if (event.tags.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(
      spacing: 6,
      children: event.tags.take(2).map((tag) => _TagChip(tag: tag)).toList(),
    ),
  ),
```

### Tag Chip Widget
```dart
class _TagChip extends StatelessWidget {
  final String tag;
  
  static const _labels = {
    'free':     ('🆓', 'Free Entry'),
    'popular':  ('🔥', 'Popular'),
    'new':      ('✨', 'New'),
    'outdoor':  ('🌿', 'Outdoor'),
    'family':   ('👨‍👩‍👧', 'Family'),
    'limited':  ('⚡', 'Limited'),
  };

  @override
  Widget build(BuildContext context) {
    final info = _labels[tag] ?? ('•', tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '${info.$1} ${info.$2}',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
```

---

## 6. "This Week" Filter (Extend Date Toggle)

Current: Today | This Weekend
Upgrade: Today | This Weekend | This Week

```dart
// date_toggle.dart — add third option
const filters = ['today', 'weekend', 'week'];
const labels  = ['Today', 'Weekend', 'This Week'];

// events_provider.dart — filteredEventsProvider
// Add case for 'week':
case 'week':
  final weekEnd = today.add(const Duration(days: 7));
  dateMatch = !eventDate.isBefore(today) && !eventDate.isAfter(weekEnd);
```

---

## 7. In-App Rating Prompt

### When to Trigger
Show the native in-app rating dialog after:
- User has opened the app 5+ times AND
- User has viewed 3+ event details AND
- User has NOT rated before (track with SharedPreferences)

### Package
```yaml
in_app_review: ^2.x.x
```

### Implementation
```dart
// lib/services/rating_service.dart

class RatingService {
  static const _launchCountKey = 'launch_count';
  static const _detailViewsKey = 'detail_views';
  static const _ratingRequestedKey = 'rating_requested';

  static Future<void> trackLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, count);
  }

  static Future<void> trackDetailView() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_detailViewsKey) ?? 0) + 1;
    await prefs.setInt(_detailViewsKey, count);
    await _maybeRequestReview(prefs);
  }

  static Future<void> _maybeRequestReview(SharedPreferences prefs) async {
    final launches = prefs.getInt(_launchCountKey) ?? 0;
    final views = prefs.getInt(_detailViewsKey) ?? 0;
    final alreadyRequested = prefs.getBool(_ratingRequestedKey) ?? false;

    if (!alreadyRequested && launches >= 5 && views >= 3) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool(_ratingRequestedKey, true);
      }
    }
  }
}
```

---

## 8. Local Event Reminders (Tier 3)

Let users set a reminder for an event: "Remind me 1 hour before".

### Package
```yaml
flutter_local_notifications: ^17.x.x
```

### Reminder Button
```dart
// event_detail_screen.dart — add below Save button
OutlinedButton.icon(
  icon: const Icon(Icons.alarm_add_outlined),
  label: const Text('Set Reminder'),
  onPressed: () => _showReminderOptions(context, event),
)

// Show BottomSheet with options:
// - "1 hour before"
// - "1 day before"  
// - "On the day (9 AM)"
// On selection: schedule local notification
```

### Notification Setup (Android)
```dart
// lib/services/notification_service.dart
// Initialize in main.dart
// Schedule notifications using event.date - reminder offset
// NotificationDetails with Android-specific config
// Channel: 'event_reminders', importance: Importance.high
```
