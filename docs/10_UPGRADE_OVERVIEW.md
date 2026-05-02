# 🔼 KochiGo v2.0 — Upgrade Master Overview

> Read this file first before any other upgrade doc.
> This is the upgrade context layered on top of the existing v1.0 MVP.

---

## Current State (v1.0 — April 2026)

The MVP is functionally complete on Chrome:
- All 3 screens built (Home, Detail, Saved)
- Firebase Firestore connected and reading
- Riverpod state management wired
- Date/category filters working client-side
- Shimmer loading, empty states, error states
- Hero transitions, bookmark persistence

**What it lacks for Play Store and real users:**
- No app icon (default Flutter icon)
- No splash screen
- Poppins font NOT loaded on Android (only CDN for web)
- No search — users can't find a specific event
- No featured events carousel — homepage feels flat
- No pull-to-refresh — stale data with no way to reload
- No share button — biggest growth lever missing
- No price/ticket info on events — users don't know if it's free
- Firebase Storage unused — images are Unsplash CDN (not production)
- No offline support — crashes with no internet
- No admin panel — you're manually entering data in Firebase Console
- No analytics — flying blind after launch
- No push notifications — no re-engagement
- No onboarding — first-time users get no context

---

## Upgrade Tiers

### 🔴 Tier 1 — MUST HAVE (Before Play Store)
These are non-negotiable. App CANNOT launch without these.

| # | Feature | Doc Reference |
|---|---|---|
| 1 | App icon + adaptive icon | `11_UI_AND_UX_UPGRADES.md` |
| 2 | Splash screen (native) | `11_UI_AND_UX_UPGRADES.md` |
| 3 | Poppins font bundled as asset | `11_UI_AND_UX_UPGRADES.md` |
| 4 | Pull-to-refresh on Home | `11_UI_AND_UX_UPGRADES.md` |
| 5 | Firebase Storage for images | `13_FIREBASE_AND_BACKEND_UPGRADES.md` |
| 6 | Firestore offline persistence | `13_FIREBASE_AND_BACKEND_UPGRADES.md` |
| 7 | Price / ticket info on events | `12_NEW_FEATURES.md` |
| 8 | In-app rating prompt | `12_NEW_FEATURES.md` |

### 🟡 Tier 2 — HIGH IMPACT (First Week After Launch)
Major UX improvements that drive installs and retention.

| # | Feature | Doc Reference |
|---|---|---|
| 9  | Search bar | `12_NEW_FEATURES.md` |
| 10 | Featured events carousel | `12_NEW_FEATURES.md` |
| 11 | Share event (native share sheet) | `12_NEW_FEATURES.md` |
| 12 | Event tags (Free, Popular, New) | `12_NEW_FEATURES.md` |
| 13 | "This Week" date filter (add to existing toggle) | `12_NEW_FEATURES.md` |
| 14 | Onboarding screen (first launch only) | `11_UI_AND_UX_UPGRADES.md` |
| 15 | Admin web panel for event management | `14_ADMIN_PANEL.md` |

### 🟢 Tier 3 — GROWTH (Month 2+)
Features that drive long-term engagement and monetisation.

| # | Feature | Doc Reference |
|---|---|---|
| 16 | Firebase Analytics | `13_FIREBASE_AND_BACKEND_UPGRADES.md` |
| 17 | Push notifications (FCM) | `13_FIREBASE_AND_BACKEND_UPGRADES.md` |
| 18 | Local event reminders | `12_NEW_FEATURES.md` |
| 19 | Multi-image gallery on detail | `12_NEW_FEATURES.md` |
| 20 | Deep linking (share event URL) | `13_FIREBASE_AND_BACKEND_UPGRADES.md` |

---

## What NOT to Add (Stay Focused)

These will bloat the app and delay launch. Add only post-traction:

- ❌ User login / Firebase Auth
- ❌ User-generated content (reviews, comments)
- ❌ Ticket booking / payment integration
- ❌ Maps SDK (Google Maps Widget) — a URL link is enough
- ❌ Social feed / following organisers
- ❌ Event creation by public users

---

## Firestore Schema Changes (v2.0)

The v1 schema needs these additions. Add to existing documents:

```
events collection — new fields:

price         String    "Free" | "₹200" | "₹500–1000"
ticketLink    String?   URL to BookMyShow / Meesho / organiser site
tags          String[]  ["free", "popular", "new", "outdoor", "family"]
imageUrls     String[]  Array of image URLs (supports multi-image gallery)
endDate       Timestamp?  End time (for multi-day events)
totalViews    Number    Incremented on detail screen open (analytics)
```

Add these to `EventModel.fromFirestore()` with safe null defaults.

---

## New Packages to Add (pubspec.yaml)

```yaml
  # Image upload
  firebase_storage: ^12.x.x
  image_picker: ^1.x.x
  image_cropper: ^7.x.x

  # Sharing
  share_plus: ^10.x.x

  # Notifications (local)
  flutter_local_notifications: ^17.x.x

  # Analytics
  firebase_analytics: ^11.x.x

  # In-app review
  in_app_review: ^2.x.x

  # Splash screen
  flutter_native_splash: ^2.x.x

  # App icon
  flutter_launcher_icons: ^0.13.x  # dev dependency

  # Connectivity
  connectivity_plus: ^6.x.x

  # Deep linking
  app_links: ^6.x.x
```

---

## Implementation Order (Recommended)

Work in this exact sequence for least merge conflicts:

```
Session A → Tier 1 fixes (icon, splash, font, pull-to-refresh)
Session B → Schema updates (price, tags, imageUrls fields)
Session C → New features: search + featured carousel
Session D → Share + tags + price display
Session E → Firebase Storage + Admin panel
Session F → Analytics + FCM
Session G → Onboarding + in-app review
Session H → Deep linking + local notifications
Session I → Full QA pass + Play Store build
```
