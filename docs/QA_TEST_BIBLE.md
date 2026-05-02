# 🧪 KochiGo — Complete QA Test Bible

> Version: 3.1 | Role: Senior QA Engineer + UX Reviewer
> Coverage: Functional · UX · Animations · Edge Cases · Performance · Security · Payments

---

## Test Device Matrix (Run ALL tests on these)

| Priority | Device Type | Why |
|---|---|---|
| P0 | Mid-range Android (₹8,000–15,000) | 80% of Indian users. Moto G, Redmi Note, Realme |
| P1 | Low-end Android (₹5,000–8,000) | Stress test animations and storage |
| P2 | Flagship Android (Samsung S, Pixel) | Verify premium UI looks perfect |
| P3 | Android Emulator (API 29 = Android 10) | Quick regression runs |

**Minimum: Test P0 + P3 before every release.**

---

## Test Accounts Setup (Do This First)

```
Create these before starting any testing:

Account A: testuser.kochigo@gmail.com
  - Role: Regular user
  - Has 2 saved events
  - Has posted 1 event (status: active)

Account B: organiser.kochigo@gmail.com  
  - Role: Event organiser
  - Has posted 3 events (active, pending, expired)
  - isVerifiedOrg: true (set in Firebase Console)

Account C: newuser.kochigo@gmail.com
  - Role: Fresh user (no history)
  - Never posted anything

Admin: Use Firebase Console directly for admin actions.

Razorpay: Use test mode. Test UPI = success@razorpay
```

---

## Critical Bug Checklist (Check Before Anything Else)

These are the most common Flutter + Firebase bugs. Fix these FIRST.

```
[ ] App crashes on cold start (no internet) — must show cached events or offline state
[ ] App crashes on hot reload during Firebase stream
[ ] Hero animation crashes when navigating rapidly (double tap)  
[ ] Keyboard overlaps input fields on older Android (check windowSoftInputMode)
[ ] Bottom nav tab 2 (Post) opens wrong screen or does nothing when not logged in
[ ] Images fail silently — must show DarkShimmer placeholder, not broken icon
[ ] Back button from PostEvent step 1 exits app instead of going back to home
[ ] Razorpay sheet doesn't open (ProGuard stripping issue in release build)
[ ] SharedPreferences not persisting between sessions (cold start)
[ ] Firestore stream not closing (memory leak — check dispose in ConsumerStatefulWidget)
```

---

## SECTION A — Core User Flows

### A1. Guest Browse Flow
```
Start: Fresh app install, no account

Step 1: Open app
  EXPECT: Splash screen shows (coral bg, logo) for 1–2 sec only
  EXPECT: Auto-dismisses when events load — NOT stuck on splash
  FAIL IF: Splash stays more than 3 seconds

Step 2: Home screen loads
  EXPECT: Dark background (NOT white/light)
  EXPECT: Shimmer skeletons show BEFORE events load
  EXPECT: Events appear with stagger animation (slide up + fade in)
  EXPECT: Story ring row visible at top
  EXPECT: Featured carousel visible if featured events exist
  FAIL IF: Plain white background, no animation, events flash in instantly

Step 3: Filter "Today" → switch to "Weekend" → switch to "This Week"
  EXPECT: List updates instantly (no loading indicator — client-side filter)
  EXPECT: Empty state shows correctly if no events in that range
  FAIL IF: Network call on every filter change (check with no internet)

Step 4: Tap a category chip (e.g. Music)
  EXPECT: Only music events shown
  EXPECT: Chip animates to gradient filled state
  EXPECT: Other chips become glass/outline
  FAIL IF: No visual change, wrong events shown

Step 5: Tap an event card
  EXPECT: Hero image transition (smooth shared element animation)
  EXPECT: TapScale press effect on card before navigation
  EXPECT: EventDetailScreen slides up
  FAIL IF: Jarring cut, no animation, card doesn't scale on press

Step 6: On EventDetailScreen:
  EXPECT: Dark glassmorphism design
  EXPECT: Booking CTA visible if ticketLink/registrationLink exists
  EXPECT: Back button is floating glass circle (NOT system back arrow in AppBar)
  EXPECT: Share button works — opens native share sheet
  EXPECT: Maps link opens Google Maps
  FAIL IF: White background on detail, booking CTA missing, share crashes

Step 7: Tap Save (🔖) without being logged in
  EXPECT: AuthGate shows — login prompt appears (bottom sheet or inline)
  EXPECT: Does NOT navigate away from EventDetailScreen
  EXPECT: After login — save completes automatically
  FAIL IF: App crashes, navigates to wrong screen, or silently fails

Step 8: Tap bottom nav tab 4 (Profile) without login
  EXPECT: AuthGate or login screen appears
  FAIL IF: Empty profile screen, crash, or nothing happens
```

### A2. Registration & Login Flow
```
Start: Account C (fresh user), not logged in

Test: Google Sign-In
  Tap "Continue with Google"
  EXPECT: Google account picker appears (native Android sheet)
  EXPECT: After selection: loading state on button (isLoading: true)
  EXPECT: Redirects to HomeScreen or Profile
  EXPECT: Users/{uid} document created in Firestore
  FAIL IF: Nothing happens after Google selection, crash, wrong screen

Test: Email Sign-Up
  Fill: Name = "Test User", Email = testuser3@test.com, Password = Test@1234
  EXPECT: Form validates (empty fields show error, weak password shows error)
  EXPECT: Confirm password mismatch shows error
  EXPECT: On success: account created, redirected to home
  FAIL IF: No validation, crash on submit, user created but not redirected

Test: Wrong Password Login
  Email: testuser.kochigo@gmail.com, Password: wrongpass
  EXPECT: Error message shown (NOT a crash, NOT a dialog box — inline error)
  EXPECT: Loading state shown and removed after failure
  FAIL IF: Crash, no feedback, app freezes

Test: Forgot Password
  EXPECT: Email sent confirmation shown
  EXPECT: Works on real email (verify in inbox)

Test: Sign Out
  Go to Profile → Sign Out
  EXPECT: Returns to home screen as guest
  EXPECT: Saved events cleared from UI (not persisting from previous user)
  FAIL IF: App freezes, crash, previous user data still showing
```

### A3. Event Posting Flow (FREE period)
```
Precondition: isFreePeriod = true in app_config (verify in Firebase Console)
Account: Account A or B (logged in)

Step 1: Tap ✚ (center bottom nav)
  EXPECT: PostEventScreen slides up
  EXPECT: Step 1 of 5 progress bar visible
  EXPECT: Dark background, glass card inputs

Step 2: Fill Step 1 (Basics)
  - Leave title empty → tap Next
    EXPECT: Validation error shown inline (red text below field)
    EXPECT: Does NOT advance
  - Enter title + select Comedy + pick today's date + pick 7:00 PM → Next
    EXPECT: Advances to Step 2 smoothly (page slide animation)

Step 3: Fill Step 2 (Details)
  - Enter description under 50 chars → tap Next
    EXPECT: Error "Description too short"
  - Fill all required fields
  - Toggle FREE → PAID → FREE
    EXPECT: Ticket link field appears on PAID, disappears on FREE
  - Paste invalid URL in map link
    EXPECT: Validation error "Must start with https://"
  → Next

Step 4: Fill Step 3 (Media)
  - Tap Next WITHOUT adding cover photo
    EXPECT: Error — "Cover photo is required"
    EXPECT: Does NOT advance
  - Add cover photo from gallery
    EXPECT: ImageCropper opens at 16:9 ratio
    EXPECT: After crop: preview shows in card
  → Next

Step 5: Fill Step 4 (Contact)
  - Organiser name pre-filled with user's displayName
    EXPECT: Editable
  - Select 2–3 tags
    EXPECT: Chips animate to gradient fill on selection
  → "Review & Submit"

Step 6: Review Screen (Step 5)
  EXPECT: Event preview card shows with correct info
  EXPECT: Fee section shows "FREE" (since isFreePeriod = true)
  EXPECT: freePeriodReason text visible
  EXPECT: Button says "Submit Event for Review" (NOT "Continue to Payment")
  
  Tap "Submit Event for Review"
  EXPECT: Loading state on button
  EXPECT: Event created in Firestore with:
    status: 'under_review'
    paymentStatus: 'free'
    isActive: false
  EXPECT: SuccessScreen appears

Step 7: Success Screen
  EXPECT: Animated checkmark (scale animation)
  EXPECT: Shows event title, status "Under Review"
  EXPECT: "View My Events" → ProfileScreen pending tab
  EXPECT: Event appears in ProfileScreen → Pending tab

CRITICAL CHECK: Open Firebase Console → events collection
  Verify the document has:
  - postedBy = correct UID
  - status = 'under_review'
  - paymentStatus = 'free'
  - isActive = false
  - expiresAt = approximately 30 days from now
```

### A4. Event Posting Flow (PAID)
```
Precondition: In Firebase Console, set app_config/pricing:
  isFreePeriod: false
  paymentEnabled: true
  postingFee: 49
  postingFeePaise: 4900

Kill and reopen app (stream should auto-update within 5 seconds)

Repeat posting flow until Step 5 Review screen:
  EXPECT: Fee section shows "₹49" (NOT "FREE")
  EXPECT: Button says "Continue to Payment · ₹49"
  
  Tap "Continue to Payment"
  EXPECT: Razorpay sheet opens
  EXPECT: Amount shows ₹49 (not ₹0, not ₹4900)
  EXPECT: KochiGo name shown in Razorpay header
  EXPECT: Coral color theme in Razorpay
  
  Use test UPI: success@razorpay
  EXPECT: Payment succeeds
  EXPECT: Firestore event updated:
    status: 'under_review'
    paymentStatus: 'paid'
    razorpayPaymentId: [some ID]
  EXPECT: payments collection has new document
  EXPECT: SuccessScreen appears

Test payment FAILURE:
  Use test UPI: failure@razorpay
  EXPECT: Razorpay shows failure
  EXPECT: Returns to Review screen (NOT crash, NOT success screen)
  EXPECT: SnackBar shows error message
  EXPECT: Form data STILL intact (user can retry)
  EXPECT: Firestore event has status: 'payment_failed'
```

### A5. Save & Offline Flow
```
Test Save persistence:
  Login → Save 3 events → Kill app → Reopen
  EXPECT: All 3 events still saved
  EXPECT: Saved tab shows correct events
  
  Unsave 1 event → Kill app → Reopen
  EXPECT: Only 2 events saved

Test Offline mode:
  Load app fully (events visible) → Turn on Airplane Mode → Pull to refresh
  EXPECT: Offline banner appears ("Offline — showing cached events")
  EXPECT: Events STILL visible (from cache)
  EXPECT: No crash
  EXPECT: Pull-to-refresh shows error state or just the offline banner
  
  Turn off Airplane Mode → Pull to refresh
  EXPECT: Offline banner disappears
  EXPECT: Events refresh successfully
```

---

## SECTION B — UX & Animation Quality Audit

Run this section on a P0 (mid-range) device. Use screen recording.

```
B1. Animation Smoothness (60fps check)
  [ ] Home screen stagger: first 6 event cards slide up with 60ms delay each
      PASS: Smooth, no jank
      FAIL: Cards pop in, delay uneven, jank visible

  [ ] TapScale on event cards
      PASS: Card shrinks to ~94% on press, bounces back on release
      FAIL: No animation, or scale is too extreme, or laggy

  [ ] Hero transition card → detail
      PASS: Image morphs smoothly from card to full-width
      FAIL: Image disappears and reappears, white flash, broken animation

  [ ] Page slide transition (SlideUpFadeRoute)
      PASS: Screens slide up with 350ms ease-out
      FAIL: Instant cut, slide wrong direction, too slow

  [ ] Featured carousel auto-scroll
      PASS: Smooth auto-advance every 4 seconds, stops on touch
      FAIL: Jank, doesn't stop on touch, dot indicator out of sync

  [ ] Category chip selection
      PASS: Gradient fill animates in on selection
      FAIL: Instant color change with no transition

  [ ] PostEvent progress bar
      PASS: Fills smoothly (animated) as steps advance
      FAIL: Jumps to new value instantly

B2. Dark UI Consistency Audit
  [ ] HomeScreen background: pure dark (#0D0E1A) — NO white/grey areas
  [ ] EventDetailScreen background: dark — NO white sections
  [ ] AuthScreen background: dark with gradient blob decoration
  [ ] PostEvent all steps: dark background
  [ ] Notifications screen: dark
  [ ] Profile screen: dark
  [ ] BottomNav: floating glass pill, NOT a flat white bar
  [ ] All inputs: glass surface style, NOT white TextField boxes
  [ ] All cards: dark glass surface with subtle border — NOT white cards
  FAIL IF: ANY screen has white background (#FFFFFF or default light theme)

B3. Typography Consistency
  [ ] All titles use AppTextStyles.heading (NOT hardcoded fontSize)
  [ ] All body text is AppColors.textPrimary (#F1F1F5) on dark bg
  [ ] All secondary text is AppColors.textSecondary (#8E8EA0)
  [ ] App name in HomeScreen AppBar has gradient shader text
  [ ] No text is unreadable (low contrast on dark bg)
  FAIL IF: Text appears in default black on dark background

B4. Empty States Quality
  Open app with no events for "Today" filter:
  [ ] Large emoji (not tiny icon)
  [ ] White bold heading (not grey)
  [ ] Helpful subtext suggesting action ("Try This Weekend")
  [ ] NOT just a blank white/dark screen with no content

B5. Loading States Quality
  [ ] Shimmer skeleton matches exact shape of EventCard
  [ ] Shimmer uses dark colors (not white flash shimmer)
  [ ] Loading never shows more than 3 seconds on normal connection
  [ ] No spinner-only loading (must be skeleton shimmer on lists)

B6. Error States Quality
  Trigger error: turn off internet, clear Firestore rules temporarily
  [ ] Error state shows in card style (GlassCard)
  [ ] Error has retry button (GradientButton)
  [ ] Error message is human-readable (NOT "PlatformException...")
  [ ] Retry actually re-triggers the data fetch

B7. Micro-interactions
  [ ] Long press on event card → save/unsave with SnackBar confirmation
  [ ] SnackBar is dark floating (NOT light default)
  [ ] SnackBar auto-dismisses after 2 seconds
  [ ] Pull-to-refresh indicator is coral colored (NOT blue default)
  [ ] Save button on detail: gradient fill when not saved, glass outline when saved
  [ ] Keyboard: closes on tap outside inputs (GestureDetector + FocusScope)
```

---

## SECTION C — Edge Cases & Stress Tests

```
C1. Data Edge Cases

  Event with missing optional fields:
  - No contactPhone: Call button must NOT show (not empty row)
  - No contactInstagram: Instagram button must NOT show
  - No ticketLink AND no registrationLink: Booking CTA must NOT show
  - No tags: tags row must NOT show (not empty Wrap)
  - No mapLink: Location row is non-tappable text only
  - Very long title (80 chars): Must truncate with ellipsis (not overflow)
  - Very long description (1000 chars): Detail screen scrolls properly
  - Event image URL broken/404: DarkShimmer placeholder shows (not broken image icon)

  C2. Search Edge Cases
  - Search with only spaces: treat as empty (show recent searches, not results)
  - Search with special chars: !@#$%: no crash, no results, empty state
  - Search while offline: searches cached events only, no crash
  - Very fast typing: debounce works, doesn't fire 20 queries

  C3. Form Edge Cases
  - PostEvent: paste emoji in title field → no crash
  - PostEvent: phone field accepts only digits (not letters)
  - PostEvent: select past date → validation blocks Next with error
  - PostEvent: exit mid-flow → "Save draft?" dialog appears
  - PostEvent: restore draft → all fields pre-filled correctly
  - PostEvent: clear draft → form is empty on next open

  C4. Auth Edge Cases
  - Sign in with email that doesn't exist: shows "No account found" (not crash)
  - Sign up with already-used email: shows "Email already in use"
  - Very weak password "123": shows password strength error
  - Google sign-in cancelled (user taps back): no crash, stays on auth screen
  - Network drops mid-sign-in: shows error, doesn't freeze on loading state

  C5. Payment Edge Cases
  - Close Razorpay sheet mid-payment (tap outside): 
    Returns to Review screen, form intact, no duplicate event doc
  - Razorpay opens but user kills app: 
    Event in 'pending_payment' status — acceptable, cleaned up later
  - Pay successfully but internet drops before Firestore update:
    Must retry Firestore update — check if markPaymentComplete has retry logic
  - Admin changes price during payment flow:
    User pays old price (cached config) — acceptable edge case
```

---

## SECTION D — Admin Panel Tests

```
D1. Pricing Control (Most Critical)

  Test 1: Switch Free → Paid instantly
  In Admin Pricing screen:
    Toggle "Free Period Active" OFF
    Set posting fee: 200
    Set paise: 20000
    Set label: "₹200 / 30 days"
    Enable payments: ON
    Save
  
  Open user app (kill + reopen OR wait 5 seconds):
  EXPECT: PostEvent review screen now shows "₹200"
  EXPECT: Button says "Continue to Payment · ₹200 / 30 days"
  FAIL IF: Still shows FREE, or shows wrong amount

  Test 2: Maintenance Mode
  Toggle maintenance ON → set message "Upgrading KochiGo. Back in 5 mins!"
  Open/refresh user app:
  EXPECT: MaintenanceScreen fills entire app
  EXPECT: Message shows correctly
  EXPECT: No way to bypass (back button, etc.)
  Toggle maintenance OFF in admin:
  EXPECT: App auto-returns to home (stream listener fires)

  Test 3: Promo Banner
  Enable promo banner, set text, color, CTA
  Open user app:
  EXPECT: Banner appears at top of HomeScreen
  EXPECT: Correct color, text, CTA
  Tap ✕ dismiss: banner hides
  Kill app + reopen: banner stays hidden (SharedPreferences)
  Change banner text in admin → open app:
  EXPECT: New banner appears (old dismissal cleared when text changes)

D2. Event Review Queue
  Post an event from user app (it goes to under_review)
  Open Admin review queue:
  EXPECT: Event appears with image, title, poster name
  EXPECT: Payment status shown (Free or Paid + amount)
  
  Tap Approve:
  EXPECT: Event disappears from queue
  EXPECT: Event in Firestore: status='active', isActive=true
  EXPECT: Notification appears in user app notifications tab
  
  Post another event → Reject with reason "Fake event":
  EXPECT: Event in Firestore: status='rejected', adminNote='Fake event'
  EXPECT: User gets rejection notification with reason

D3. Revenue Dashboard
  EXPECT: Total revenue reflects paid payments
  EXPECT: Recent payments list shows real data
  EXPECT: Date filter works (This Week / Month / All Time)
```

---

## SECTION E — Performance Tests

```
Run on P0 device (mid-range, ₹10,000 Android)

E1. Cold Start Time
  From icon tap → events visible on screen
  PASS: Under 3 seconds on WiFi
  PASS: Under 5 seconds on 4G
  FAIL: Over 5 seconds (check: too many providers initializing, heavy main.dart)

E2. Scroll Performance
  Scroll event list up and down rapidly for 30 seconds
  PASS: Smooth 60fps, no jank
  FAIL: Frame drops, stutters, images reloading on scroll
  FIX: Ensure CachedNetworkImage is used (not Image.network)

E3. Memory (Navigate 20 times)
  Tap event card → back → tap different card → back (repeat 20 times)
  PASS: App still responsive, no crashes
  FAIL: App slows down or crashes (memory leak — check stream subscriptions)

E4. Image Loading
  All 10 events visible → scroll past all → scroll back
  PASS: Images load from cache (no network flash on scroll back)
  FAIL: Images reload every time (CachedNetworkImage not configured)

E5. APK Size
  Run: flutter build apk --release
  PASS: APK under 25MB
  WARNING: 25–40MB (consider asset compression)
  FAIL: Over 40MB (something wrong — check assets, ProGuard)
```

---

## SECTION F — Security Spot Checks

```
F1. Firestore rules actually enforced:
  Using Postman or curl with no auth token:
  POST to Firestore events/ with isActive: true
  EXPECT: 403 Permission Denied
  FAIL IF: Event created successfully (rules not enforced)

F2. No secrets in APK:
  Unzip release APK → search for "rzp_live" in all files
  EXPECT: Not found in plain text
  PASS: Only found as --dart-define compiled value (obfuscated)
  FAIL IF: Key found in plaintext (ProGuard not working)

F3. User can't elevate own permissions:
  From Flutter app, try to update own isVerifiedOrg field:
  EXPECT: Firestore security rule blocks this
  FAIL IF: Successfully updated

F4. User can't read another user's payments:
  With Account A credentials, try to read Account B's payments
  EXPECT: Permission denied
```

---

## SECTION G — Play Store Pre-Launch Checklist

```
G1. APK Quality
  [ ] flutter build apk --release completes without errors
  [ ] Release APK signed with keystore (NOT debug key)
  [ ] App icon is custom (NOT Flutter default blue icon)
  [ ] Splash screen is coral with app logo (NOT white Flutter splash)
  [ ] App name in Android launcher is correct (NOT "kochigo_app")
  [ ] Version: 1.0.0+1 in pubspec.yaml

G2. Device Compatibility
  [ ] Runs on Android 8.0 (Oreo, API 26) — minimum supported
  [ ] Runs on Android 14 (latest)
  [ ] Works in portrait mode (landscape not required for MVP)
  [ ] Status bar text is white (for dark bg) — check via SystemChrome

G3. Permissions (only request what you need)
  [ ] INTERNET: yes (required)
  [ ] Camera: only asked when user taps "Take Photo"
  [ ] READ_MEDIA_IMAGES: only asked when user taps "Choose from Gallery"
  [ ] NOT requested: contacts, location, microphone (red flags for Play Store)

G4. Play Store Assets
  [ ] App icon 512×512 PNG (no transparency)
  [ ] Feature graphic 1024×500 PNG (dark themed)
  [ ] 4+ screenshots on dark phone mockup
  [ ] Privacy policy URL live and accessible
  [ ] Short description written (80 chars)
  [ ] Full description written (4000 chars max)
```

---

## Bug Severity Classification

When you find a bug, classify it:

```
P0 — App Crash:       Fix before ANY testing continues
P1 — Feature Broken:  Fix before release
P2 — UX Degraded:     Fix before Play Store
P3 — Minor Visual:    Fix in next patch
P4 — Enhancement:     Log for future sprint
```
