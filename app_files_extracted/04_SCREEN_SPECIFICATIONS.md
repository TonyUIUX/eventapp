# 📱 Screen Specifications

## Screen Map

```
App Launch
    └── HomeScreen (Tab 0)
            ├── [tap event card] → EventDetailScreen
            └── [tap saved tab] → SavedScreen (Tab 1)
```

No splash screen for MVP. Use Flutter's native splash.

---

## Screen 1: HomeScreen

**File:** `lib/screens/home/home_screen.dart`

### Layout (top to bottom)
1. **App Bar** — Title "KochiGo" + city chip "📍 Kochi"
2. **Date Toggle** — "Today" | "This Weekend" pill toggle
3. **Category Filter Bar** — Horizontal scrollable chips
4. **Events List** — `ListView.builder` of `EventCard` widgets
5. **Bottom Navigation** — Home | Saved

### App Bar Spec
```
- Title: "KochiGo" (or app name)  
- No back button (root screen)  
- No search icon (MVP — skip)  
- Background: white  
- Elevation: 0 (flat)  
- Bottom border: 1px light grey  
```

### Date Toggle Spec
```
- Two options: "Today" and "This Weekend"
- Pill/segmented control style
- Default selected: "Today"
- Switches active filter in provider
- "This Weekend" = Saturday + Sunday of current week
- "Today" = current calendar day
- Filtering is CLIENT-SIDE (already fetched from Firestore)
```

### Category Filter Bar Spec
```
- Horizontal ScrollView, no wrap
- First chip: "All" (default selected)
- Other chips: Comedy | Music | Tech | Fitness | Art | Workshop
- Each chip has an icon (emoji is fine):
    All: ✨
    Comedy: 😂
    Music: 🎵
    Tech: 💻
    Fitness: 🏃
    Art: 🎨
    Workshop: 🛠️
- Selected chip: filled color (primary brand color)
- Unselected chip: outlined, grey text
- Filtering is CLIENT-SIDE
```

### Event Card Spec
```
- Card with rounded corners (12px radius)
- Slight shadow (elevation 2)
- Image: top, 16:9 aspect ratio, cached + shimmer loading
- Category chip overlay on image (bottom-left)
- Below image:
    - Title (bold, max 2 lines, ellipsis)
    - 📅 Date (formatted: "Sat, 19 Apr · 7:00 PM")
    - 📍 Location (1 line, grey, ellipsis)
- Tap → navigate to EventDetailScreen
- No swipe actions
```

### Empty State Spec
```
- Show when filtered list is empty
- Illustration: simple SVG or emoji (🎭)  
- Text: "No events found"
- Subtext: "Try a different category or check back later"
- No retry button (data is already loaded)
```

### Loading State Spec
```
- Show shimmer placeholder cards (3 cards)
- Match exact layout of EventCard
- Use `shimmer` package
- Show while FutureProvider is loading
```

### Error State Spec
```
- Show when Firebase fetch fails
- Icon: ⚠️
- Text: "Couldn't load events"
- Subtext: "Check your internet and try again"
- Button: "Retry" → re-triggers the provider
```

---

## Screen 2: EventDetailScreen

**File:** `lib/screens/detail/event_detail_screen.dart`

### Layout (top to bottom)
1. **Hero Image** — Full width, 16:9, with back button overlay
2. **Category Chip** — Coloured pill  
3. **Title** — Large, bold
4. **Date & Time Row** — Icon + formatted date
5. **Location Row** — Icon + location text + "Open in Maps" button
6. **Divider**
7. **About Section** — "About this event" heading + full description
8. **Divider**
9. **Organizer Section** — Name + contact buttons (Phone / Instagram)
10. **Save Button** — Bottom sticky FAB-style button

### Back Button
```
- Overlaid on top of hero image (top-left)
- Circular white background with shadow
- Arrow icon
- Uses Navigator.pop()
```

### Hero Image
```
- Full width
- Aspect ratio: 16:9
- Use CachedNetworkImage
- Hero animation: tag = event.id (for smooth transition from card)
- No zoom/pinch
```

### Date & Time Row
```
Icon: 📅 calendar_today
Text: "Saturday, 19 April 2025 · 7:00 PM"
Format using intl package: "EEEE, d MMMM yyyy · h:mm a"
```

### Location Row
```
Icon: 📍 location_on
Text: event.location (e.g. "Kashi Art Café, Fort Kochi")
"Open in Maps" → url_launcher → event.mapLink
Style the link as a tappable text button, NOT a separate button
```

### Organizer Section
```
Heading: "Organizer"
Name: event.organizer
Buttons (show only if data exists):
  📞 "Call" → tel: link
  📸 "Instagram" → https://instagram.com/handle
Buttons: Outlined style, side by side
```

### Save Button (Sticky Bottom)
```
Position: Bottom of screen, full width, above system nav
Text: "Save Event" / "Saved ✓" (toggle)
Color: Primary brand color / Grey when saved
Uses SavedEventsProvider to toggle state
Persists via SharedPreferences
```

---

## Screen 3: SavedScreen

**File:** `lib/screens/saved/saved_screen.dart`

### Layout
1. **App Bar** — "Saved Events"
2. **Event List** — Same EventCard widget, reused
3. **Empty State** — if no saved events

### Empty State (Saved)
```
Icon: 🔖
Text: "Nothing saved yet"
Subtext: "Tap the save button on any event to bookmark it"
No CTA button
```

### Behaviour
```
- Reads saved event IDs from SharedPreferences
- Cross-references with events loaded in memory (from home provider)
- If an event was saved but no longer exists in Firestore → skip it silently
- Events shown in the order they were saved (most recent first)
```

---

## Bottom Navigation Bar

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
  ],
  selectedItemColor: AppColors.primary,
  unselectedItemColor: Colors.grey,
  showSelectedLabels: true,
  showUnselectedLabels: true,
  type: BottomNavigationBarType.fixed,
)
```

Use `IndexedStack` to preserve scroll position when switching tabs.
