# 🤖 ANTIGRAVITY MASTER CONTEXT — KochiGo App

> ⚠️ LOAD THIS FILE FIRST before any coding session.
> This is the single source of truth. All other .md files expand on this.

---

## What You're Building
A Flutter + Firebase event discovery app for Kochi, India called **KochiGo**.
Android only. No login. Minimal UI. Launch-ready MVP.

## Document Index (Read in this order)
1. `01_PROJECT_OVERVIEW.md` — Vision, scope, what NOT to build
2. `02_TECH_STACK_AND_ARCHITECTURE.md` — Stack, folder structure, rules
3. `03_DATA_MODELS_AND_FIREBASE.md` — Firestore schema, Dart models, queries
4. `04_SCREEN_SPECIFICATIONS.md` — Every screen, pixel by pixel
5. `05_UI_DESIGN_SYSTEM.md` — Colors, fonts, spacing, components
6. `06_PROVIDERS_STATE_MANAGEMENT.md` — All Riverpod providers, logic
7. `07_FIREBASE_SETUP_AND_SAMPLE_DATA.md` — Setup steps + test data
8. `08_BUILD_AND_RELEASE.md` — APK build + Play Store guide

---

## Coding Rules (ALWAYS FOLLOW)

### Architecture
- NEVER call Firebase from a screen directly. Use services → providers → screens
- NEVER use `setState` in screens — use Riverpod only
- NEVER use `StatefulWidget` unless absolutely necessary (animation controllers only)
- ALWAYS use `ConsumerWidget` instead of `StatelessWidget`

### Flutter Code Quality
- Use `const` constructors wherever possible
- Use `ListView.builder`, never `ListView(children: [...])`
- Extract widgets if they exceed 60 lines
- Name all widget parameters clearly
- Add a brief comment above each provider explaining its purpose

### Firebase
- NEVER write to Firestore from the app (read-only for MVP)
- ALWAYS handle null safely when parsing Firestore data
- ALWAYS use `.limit(50)` on queries

### UI
- Follow the color palette in `05_UI_DESIGN_SYSTEM.md` EXACTLY
- No hardcoded colors anywhere — always use `AppColors.xxx`
- No hardcoded text styles — always use `AppTextStyles.xxx`
- No hardcoded spacing values — use `AppSpacing.xxx`

---

## Prompting Strategy for Best Results

Work in this sequence — do NOT try to build everything at once:

### Session 1: Foundation
```
Load: 00_MASTER_CONTEXT.md + 02_TECH_STACK_AND_ARCHITECTURE.md
Task: "Set up the Flutter project structure. Create pubspec.yaml with all packages,
the folder structure, main.dart with Firebase init and ProviderScope,
and all files under lib/core/ (colors, text styles, constants)."
```

### Session 2: Data Layer
```
Load: 00_MASTER_CONTEXT.md + 03_DATA_MODELS_AND_FIREBASE.md
Task: "Create EventModel with fromFirestore factory.
Create FirestoreService with getEvents() method.
Add proper null safety and error handling."
```

### Session 3: State Management
```
Load: 00_MASTER_CONTEXT.md + 06_PROVIDERS_STATE_MANAGEMENT.md
Task: "Create all Riverpod providers as specified:
eventsProvider, selectedCategoryProvider, selectedDateFilterProvider,
filteredEventsProvider, savedEventIdsProvider, savedEventsProvider."
```

### Session 4: Home Screen
```
Load: 00_MASTER_CONTEXT.md + 04_SCREEN_SPECIFICATIONS.md + 05_UI_DESIGN_SYSTEM.md
Task: "Build the HomeScreen with app bar, date toggle, category filter bar,
and events list. Include EventCard widget, shimmer loading state,
empty state, and error state."
```

### Session 5: Detail Screen
```
Load: 00_MASTER_CONTEXT.md + 04_SCREEN_SPECIFICATIONS.md + 05_UI_DESIGN_SYSTEM.md
Task: "Build the EventDetailScreen with hero image, all info rows,
organizer section, and the sticky save button."
```

### Session 6: Saved Screen + Navigation
```
Load: 00_MASTER_CONTEXT.md + 04_SCREEN_SPECIFICATIONS.md
Task: "Build the SavedScreen. Wire up BottomNavigationBar with IndexedStack
for Home and Saved tabs. Ensure scroll state is preserved."
```

### Session 7: Polish
```
Load: 00_MASTER_CONTEXT.md
Task: "Review all screens for:
- Consistent use of AppColors, AppTextStyles, AppSpacing
- All loading/error/empty states present
- No hardcoded values
- const constructors used
- All tap targets 48dp minimum"
```

---

## Quick Reference: Key Decisions

| Decision | Choice | Reason |
|---|---|---|
| State management | Riverpod | Simple, scalable, no boilerplate |
| Local storage | SharedPreferences | Simple key-value for saved IDs |
| Image caching | cached_network_image | Industry standard |
| Loading state | Shimmer | Better UX than spinner |
| Navigation | Navigator.push | Simple, no over-engineering |
| Font | Poppins via google_fonts | Modern, readable, Indian app standard |
| Filtering | Client-side | Avoids complex Firestore queries |
| Category chips | String matching | Simple and fast |
