# 🎨 UI & UX Upgrades — KochiGo v2.0

> Reference: Existing design system in `05_UI_DESIGN_SYSTEM.md`
> Primary color: `#FF5A35` | Font: Poppins | Background: `#F8F5F2`

---

## 1. App Icon (MUST — Before Play Store)

### Setup
```yaml
# pubspec.yaml — dev_dependencies section
dev_dependencies:
  flutter_launcher_icons: ^0.13.x

# pubspec.yaml — root level config
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#FF5A35"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
  min_sdk_android: 21
```

### Icon Design Spec
```
Main icon (icon.png): 1024×1024px PNG
  - Background: #FF5A35 (coral)
  - Centered white icon: a map pin (📍) merged with a ticket/spark shape
  - OR: Bold white "K" lettermark with a location pin dot

Adaptive icon foreground (icon_foreground.png): 1024×1024px PNG  
  - White graphic only, transparent background
  - Design in the safe zone (centre 66% of canvas)
  - Use Canva or Figma — search "adaptive icon template"

Adaptive icon background: solid #FF5A35 (set in config above)
```

### Generate Command
```bash
dart run flutter_launcher_icons
```

---

## 2. Native Splash Screen (MUST — Before Play Store)

### Setup
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.x.x

flutter_native_splash:
  color: "#FF5A35"
  image: assets/splash/splash_logo.png
  color_dark: "#FF5A35"
  image_dark: assets/splash/splash_logo.png
  android_12:
    image: assets/splash/splash_logo.png
    icon_background_color: "#FF5A35"
    color: "#FF5A35"
  fullscreen: false
```

### Splash Logo Spec
```
splash_logo.png: 400×400px PNG
  - White KochiGo wordmark OR white icon
  - On coral background (#FF5A35)
  - Keep it simple — just the logo, no tagline
```

### Generate Command
```bash
dart run flutter_native_splash:create
```

### Preserve Splash Until App Loads
```dart
// main.dart — update runApp to preserve splash

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: KochiGoApp()));
}

// In HomeScreen — remove splash after first load
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    
    // Remove splash when data arrives (success OR error)
    ref.listen(eventsProvider, (_, next) {
      if (!next.isLoading) {
        FlutterNativeSplash.remove();
      }
    });
    
    // ... rest of build
  }
}
```

---

## 3. Poppins Font — Bundled as Asset (MUST for Android)

### Download Font Files
Download from Google Fonts: https://fonts.google.com/specimen/Poppins

Weights needed:
- `Poppins-Regular.ttf` (400)
- `Poppins-Medium.ttf` (500)
- `Poppins-SemiBold.ttf` (600)
- `Poppins-Bold.ttf` (700)

Place at: `assets/fonts/`

### pubspec.yaml
```yaml
flutter:
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
          weight: 400
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
  assets:
    - assets/fonts/
    - assets/icon/
    - assets/splash/
```

### Update app_text_styles.dart
All TextStyle objects already use `fontFamily: 'Poppins'` — no changes needed.
The font will automatically load from assets on Android instead of CDN.

---

## 4. Pull-to-Refresh on Home Screen (MUST)

### Implementation
```dart
// home_screen.dart — wrap the ListView with RefreshIndicator

RefreshIndicator(
  color: AppColors.primary,
  backgroundColor: AppColors.surface,
  onRefresh: () async {
    // Invalidate provider to force re-fetch
    ref.invalidate(eventsProvider);
    // Wait for the new fetch to complete
    await ref.read(eventsProvider.future);
  },
  child: ListView.builder(
    // existing list content
  ),
)
```

> Works with both the event list and the empty state.
> Empty state must be in a `ListView` (even with 0 items) for pull-to-refresh to work.

---

## 5. Onboarding Screen — First Launch Only

### When to Show
Show ONCE on first app launch. Never again after that.
Track with SharedPreferences key: `has_seen_onboarding` (bool).

### Screen Design
```
3 pages, horizontal swipe (PageView)

Page 1:
  Illustration: 🎭 large emoji or simple vector
  Heading: "Kochi's Events,\nAll in One Place"
  Body: "Comedy nights, live music, workshops, fitness — discover what's on."

Page 2:
  Illustration: 📅
  Heading: "Today & This Weekend"
  Body: "No clutter. Just what's happening now in your city."

Page 3:
  Illustration: 🔖
  Heading: "Save & Never Miss Out"
  Body: "Bookmark events you love. Find them anytime."
  CTA Button: "Explore Kochi →" (navigates to HomeScreen)

Navigation:
  - Dot indicators at bottom
  - "Skip" text button top-right (goes straight to Home)
  - "Next" text button bottom-right
  - On last page: "Explore Kochi →" filled button
```

### Implementation
```dart
// lib/screens/onboarding/onboarding_screen.dart

class OnboardingScreen extends ConsumerStatefulWidget {
  // Uses PageController
  // On "Explore" or "Skip" tap:
  //   1. SharedPreferences.setBool('has_seen_onboarding', true)
  //   2. Navigator.pushReplacement to MainShell (bottom nav)
}

// main.dart — decide which screen to show
void main() async {
  // ...Firebase init...
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  
  runApp(ProviderScope(
    child: KochiGoApp(showOnboarding: !hasSeenOnboarding),
  ));
}

// KochiGoApp home:
home: showOnboarding ? const OnboardingScreen() : const MainShell(),
```

### Style
```
Background: #FF5A35 (coral) for first page
Background: #F8F5F2 (app bg) for pages 2–3
Active dot: #FF5A35
Inactive dot: #E0E0E0
Skip button: textSecondary color
CTA button: filled coral, full width, 52px height, rounded 12px
```

---

## 6. Bottom Navigation — Add "Explore" Tab (Optional Upgrade)

Current: 2 tabs (Home, Saved)
Upgrade: 3 tabs (Home, Explore/Search, Saved)

```
Tab 0: Home   → Icon: home_outlined / home (selected)
Tab 1: Search → Icon: search_outlined / search (selected)  
Tab 2: Saved  → Icon: bookmark_outline / bookmark (selected)
```

Only add this if Search is implemented. If not, keep 2 tabs.

---

## 7. Micro-UX Improvements

### Empty State Illustrations
Replace plain icon + text with more characterful empty states:

```dart
// events_empty_state.dart

Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('🎭', style: TextStyle(fontSize: 56)),
    SizedBox(height: 16),
    Text(
      'Nothing happening today',
      style: AppTextStyles.heading2,
    ),
    SizedBox(height: 8),
    Text(
      'Try switching to "This Weekend"\nor check a different category',
      style: AppTextStyles.bodySecondary,
      textAlign: TextAlign.center,
    ),
  ],
)
```

### Category Chip Count Badge
Show event count inside each chip:
```
[🎵 Music (3)]  [💻 Tech (1)]  [🏃 Fitness (0)]
```

```dart
// category_filter_bar.dart
// After filtering, compute counts per category from filteredEvents
// Pass counts map into chip builder
// Show: "${category.label} (${count})"
// Grey out chips with 0 events (but keep them tappable)
```

### Smooth Page Transitions
```dart
// Replace Navigator.push with custom transition:

Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (_, __, ___) => EventDetailScreen(event: event),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  ),
);
```

### Card Long Press — Quick Save
```dart
// event_card.dart — add GestureDetector with onLongPress
GestureDetector(
  onTap: () => Navigator.push(...),
  onLongPress: () {
    ref.read(savedEventIdsProvider.notifier).toggle(event.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSaved ? 'Removed from saved' : 'Event saved ✓'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  },
  child: EventCard(event: event),
)
```
