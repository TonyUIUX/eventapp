# ✅ Production Readiness Checklist — KochiGo v2.0

> Work through this list TOP TO BOTTOM before Play Store submission.
> Every item must be ✅ before submitting.

---

## Part 1: Fix Existing Issues First (from v1.0 bug list)

- [ ] Enable Windows Developer Mode (Win+I → Privacy & Security → Developer Mode → ON → Restart)
- [ ] Run `flutter pub get` successfully on Android target
- [ ] Bundle Poppins font as asset (see `11_UI_AND_UX_UPGRADES.md` §3)
- [ ] Verify app runs on physical Android device (not just Chrome)
- [ ] Update seed data dates to current week (update `seed_firestore.js`)
- [ ] Replace all Unsplash CDN image URLs with Firebase Storage URLs

---

## Part 2: Tier 1 Must-Haves

- [ ] App icon generated (`dart run flutter_launcher_icons`)
- [ ] Adaptive icon tested on Android 8+ (round icon looks correct)
- [ ] Splash screen generated (`dart run flutter_native_splash:create`)
- [ ] Splash removed correctly after data loads (no permanent splash)
- [ ] Pull-to-refresh works on HomeScreen
- [ ] Pull-to-refresh works on SavedScreen
- [ ] Firebase Storage configured (rules deployed)
- [ ] Firestore offline persistence enabled in main.dart
- [ ] Offline banner shows when device has no internet
- [ ] App does NOT crash with no internet (shows cached data or error state)
- [ ] Price field shows on EventCard
- [ ] Price field shows on EventDetailScreen
- [ ] "Get Tickets" button shows only when ticketLink is non-null
- [ ] In-app review prompt implemented (triggers at 5 launches + 3 detail views)

---

## Part 3: UI Quality Check

- [ ] Poppins font renders correctly on Android (not fallback system font)
- [ ] All screens look correct on small screen (5-inch, 360px width)
- [ ] All screens look correct on large screen (6.5-inch)
- [ ] No text overflow / clipping on any screen
- [ ] All tap targets are minimum 48×48dp
- [ ] Category filter bar scrolls smoothly horizontally
- [ ] Hero transition from card to detail is smooth
- [ ] Back button on detail screen works
- [ ] Keyboard does not cover inputs in search screen
- [ ] Dark mode does NOT break the UI (or dark mode is fully supported)
- [ ] No hardcoded colors — everything uses AppColors
- [ ] No hardcoded text sizes — everything uses AppTextStyles
- [ ] Shimmer loading shows for correct duration (not flash)
- [ ] Empty state shows correctly with correct copy

---

## Part 4: Firebase & Data

- [ ] Firestore composite index created and active (check status in Firebase Console)
- [ ] Security rules deployed (read: true, write: false for public)
- [ ] All 5+ seed events have current/future dates
- [ ] All seed events have Firebase Storage imageUrls (not Unsplash)
- [ ] Events load correctly under "Today" filter
- [ ] Events load correctly under "This Weekend" filter  
- [ ] Category filter correctly shows/hides events
- [ ] Saved events persist after app restart
- [ ] Unsaved events are correctly removed from Saved tab
- [ ] Event with no phone → Call button hidden
- [ ] Event with no Instagram → Instagram button hidden
- [ ] Event with no ticket link → Get Tickets button hidden
- [ ] Maps link opens Google Maps correctly
- [ ] Phone link opens dialer correctly
- [ ] Instagram link opens Instagram app (or browser)

---

## Part 5: Android Build Quality

- [ ] `minSdk` is 21 (Android 5.0+)
- [ ] `google-services.json` is present in `android/app/`
- [ ] Internet permission declared in AndroidManifest.xml
- [ ] URL launcher queries declared in AndroidManifest.xml
- [ ] App label is "KochiGo" (not "kochigo_app")
- [ ] App version is `1.0.0+1` in pubspec.yaml
- [ ] Release build compiles without errors: `flutter build apk --release`
- [ ] Release APK size is under 30MB (target: under 20MB)
- [ ] APK signed with release keystore
- [ ] Keystore file backed up in 2+ locations (CRITICAL — losing it = can't update app)
- [ ] `key.properties` is in `.gitignore`

---

## Part 6: Play Store Requirements

- [ ] App icon: 512×512 PNG (no alpha channel)
- [ ] Feature graphic: 1024×500 PNG
- [ ] Minimum 4 screenshots (1080×1920px portrait preferred)
  - [ ] Home screen (with events)
  - [ ] Event detail screen
  - [ ] Saved screen
  - [ ] Search or featured carousel
- [ ] App title: "KochiGo — Events in Kochi" (max 50 chars)
- [ ] Short description written (max 80 chars)
- [ ] Full description written (max 4000 chars)
- [ ] Privacy policy URL hosted and accessible
- [ ] Content rating completed (Everyone)
- [ ] Target audience: 18+ OR all ages (choose based on content)
- [ ] App category: Events
- [ ] Contact email provided
- [ ] App Bundle (.aab) uploaded: `flutter build appbundle --release`

---

## Part 7: Performance Check

- [ ] Cold start time under 3 seconds on mid-range Android (test on a ₹8,000–12,000 device)
- [ ] Event list scrolls at 60fps (no jank)
- [ ] Images load without blocking the list scroll
- [ ] Memory usage is stable (no leaks after navigating between screens 10+ times)
- [ ] `flutter analyze` passes with 0 errors, 0 warnings
- [ ] All `const` opportunities used (run `flutter analyze --no-pub`)

---

## Part 8: Testing Scenarios (Manual QA)

Run these before every release:

### Happy Path
- [ ] Open app → events load → tap event → detail opens → tap back → back on home ✓
- [ ] Filter "Today" → correct events shown ✓
- [ ] Filter "Weekend" → correct events shown ✓
- [ ] Tap "Comedy" → only comedy events ✓
- [ ] Tap event → save → go to Saved tab → event is there ✓
- [ ] Kill app → reopen → saved event still in Saved tab ✓
- [ ] Tap "Open in Maps" → Google Maps opens ✓

### Edge Cases
- [ ] No events for selected filter → empty state shows ✓
- [ ] No saved events → empty state shows ✓
- [ ] Turn off WiFi → pull to refresh → shows offline banner or error ✓
- [ ] Turn WiFi back on → pull to refresh → events reload ✓
- [ ] Event with very long title → text truncates with ellipsis (not overflow) ✓
- [ ] Event with no contact info → contact section hidden (not empty row) ✓
- [ ] Search for non-existent text → "no results" empty state ✓

---

## Play Store Submission URLs (Bookmarks)

- Google Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com
- App signing guide: https://docs.flutter.dev/deployment/android
- Play Store listing checklist: https://support.google.com/googleplay/android-developer/answer/9859152
