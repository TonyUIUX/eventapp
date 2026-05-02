# 🚀 KochiGo v3.0 — Platform Vision & Business Model

> READ THIS FIRST. Every implementation decision flows from this document.
> Version 3.0 is NOT an incremental update — it is a fundamental platform shift.

---

## The Transformation

| | v1.0 MVP | v2.0 Production | v3.0 Platform |
|---|---|---|---|
| Who posts events? | Admin only | Admin only | **Any registered user** |
| Who discovers events? | Anyone | Anyone | Anyone (guests included) |
| Revenue model | None | B2B sponsorships (manual) | **Pay-to-post (automated)** |
| Auth required? | No | No | For posting only |
| Data flow | Admin → App | Admin → App | **Users → Payment → App** |
| Analogy | Zomato (curated) | Zomato + ads | **Instagram for events** |

---

## The Core Idea

> "Anyone in Kochi running an event — comedy show, yoga class, tech meetup, birthday party, product launch — opens KochiGo, taps ✚ Post Event, fills in details, picks a visibility tier, pays ₹49–₹349 via UPI, and their event goes live after a quick review."

This is the **entire business model**. No dependency on advertisers. No cold outreach for listings. Revenue scales automatically with user growth.

---

## Monetisation: The Tier System

This is how KochiGo makes money from day 1.

| Tier | Price | What You Get | Duration | Badge |
|---|---|---|---|---|
| **Basic** | ₹49 | Listed in the regular feed | 7 days | None |
| **Boost** | ₹149 | Trending section + category top placement | 7 days | 🔥 Trending |
| **Premium** | ₹349 | Featured carousel + PROMOTED badge + priority in All | 30 days | ⭐ PROMOTED |

### Why This Pricing Works for Kochi
- ₹49 = price of a chai + snack. Zero friction.
- Comedy show organizer making ₹5,000/night will happily pay ₹149 to fill seats.
- Gym promoting a new batch pays ₹349 monthly = cheaper than one Instagram ad.
- YOU keep 100% of the revenue. Zero platform cut until you scale to ad-server.

### Revenue Projection
If 10 Basic + 5 Boost + 2 Premium posts/week:
`(10 × ₹49) + (5 × ₹149) + (2 × ₹349) = ₹490 + ₹745 + ₹698 = ₹1,933/week = ~₹8,000/month`

At 2x growth (Month 3): **₹16,000/month from the app alone.**

---

## User Roles

| Role | Can Do |
|---|---|
| **Guest (not logged in)** | Browse events, search, filter. Cannot save or post. |
| **Registered User** | Everything a guest can do + save events, post events (paid), manage own events, view profile. |
| **Admin** | Everything + approve/reject events, moderate content, broadcast notifications. (Web app only) |

---

## Event Lifecycle

Every event goes through this exact pipeline:

```
[User fills form + pays]
        ↓
   PENDING_PAYMENT
        ↓  (Razorpay payment success webhook)
   UNDER_REVIEW  ← Admin gets notified
        ↓  (Admin approves)
     ACTIVE  ← Shows in app feed
        ↓  (expiresAt timestamp reached)
     EXPIRED  ← Auto-hidden from feed
        ↓  (User can re-boost — pays again)
     ACTIVE (extended)

Parallel path:
   UNDER_REVIEW → REJECTED (Admin rejects with reason)
                      ↓
              User gets notification + refund option
```

---

## What Stays the Same (Do NOT touch)

- All existing discovery features (search, filter, carousel, trending, FOMO)
- All v2.0 services (PersonalizationService, SmartCacheService, AnalyticsService)
- Design system (Slate theme, #FF5247 primary, Poppins font)
- Event detail screen structure
- Admin web app (extend, don't replace)
- Offline mode / connectivity handling

---

## Navigation Architecture v3.0

```
App Launch
    ├── [Not logged in] → AuthGate → Show full app but prompt on restricted actions
    └── [Logged in] → Full app

Bottom Navigation (5 tabs):
  Tab 0: 🏠 Home          → Existing HomeScreen (unchanged)
  Tab 1: 🔍 Explore       → Existing SearchScreen (unchanged)
  Tab 2: ✚  Post Event    → PostEventFlow (NEW — payment-gated)
  Tab 3: 🔔 Notifications → NotificationsScreen (NEW)
  Tab 4: 👤 Profile       → ProfileScreen (NEW)

Tab 2 (Post Event):
  - If not logged in → Navigate to LoginScreen first
  - If logged in → Navigate to PostEventStep1

Detail Screen:
  - "More from this organizer" section (links to poster's profile)
```

---

## AuthGate Strategy

Do NOT force login to browse. Let users explore freely.
Only require login when they try to:
1. Tap ✚ Post Event
2. Tap 🔖 Save event
3. Tap 👤 Profile tab

```dart
// lib/core/auth_gate.dart
// Wraps restricted actions — if not logged in, shows LoginBottomSheet
// On successful login, resumes the original action
```

---

## New Packages Required (add to existing pubspec.yaml)

```yaml
  # Authentication
  firebase_auth: ^5.x.x
  google_sign_in: ^6.x.x

  # Payment
  razorpay_flutter: ^1.3.x

  # Image handling (already have image_picker)
  image_cropper: ^7.x.x

  # Deep linking & dynamic links
  app_links: ^6.x.x

  # Local notifications (for event status updates)
  flutter_local_notifications: ^17.x.x

  # Form validation
  reactive_forms: ^17.x.x        # OR use Flutter's built-in Form widget (simpler)
```

---

## New Firestore Collections Overview

```
users/          ← User profiles (NEW)
events/         ← Extended with new fields (MODIFIED)
payments/       ← Transaction records (NEW)
notifications/  ← Per-user notification feed (NEW)
reports/        ← Content moderation flags (NEW)
```

Full schema in `20_FULL_SCHEMA_V3.md`.
