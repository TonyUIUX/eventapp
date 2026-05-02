# 🛠️ Admin Panel v2 — Full Pricing & Platform Control

> ⚠️ THIS DOC SUPERSEDES and EXTENDS `14_ADMIN_PANEL.md`
> Major addition: Pricing Management screen with full real-time control.
> Admin now has a master control panel for the entire platform.

---

## Admin Panel Navigation (Updated)

```
admin_app/ — bottom nav or sidebar:

  🏠 Dashboard        → Stats overview (events, users, revenue)
  📋 Review Queue     → Pending events (with unread badge count)
  📅 Events           → All events management (existing)
  👤 Users            → User management
  💰 Pricing          → Platform pricing & config  ← NEW
  📊 Revenue          → Payment history & analytics ← NEW
  📣 Broadcast        → Push notifications (existing)
```

---

## Screen 1: Dashboard (Updated)

```
Wide-screen cards row:

  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐
  │ Pending   │ │ Active    │ │ Total     │ │ Revenue   │ │ Users     │
  │ Review    │ │ Events    │ │ Events    │ │ This Month│ │ Total     │
  │  [count]  │ │  [count]  │ │  [count]  │ │  ₹[sum]   │ │  [count]  │
  │ 🔴 badge  │ │           │ │           │ │           │ │           │
  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘

Platform Status Section:
  Current Mode:  🟢 LIVE  or  🟡 FREE PERIOD  or  🔴 MAINTENANCE
  Posting Fee:   ₹0 (Free)  /  ₹200  /  etc.
  Payment:       Enabled / Disabled
  [Quick toggle: Enable Payments] button → goes to Pricing screen

Recent Activity feed:
  - New event submitted: "Open Mic Night by @kochicomedy — Boost"
  - Payment received: "₹200 from user123"
  - Event approved: "Yoga at Cherai Beach"
  Real-time Firestore stream.
```

---

## Screen 2: Pricing Management (NEW — The Power Screen)

```
admin_app/lib/screens/pricing_screen.dart

This is THE most important admin screen.
Changing one field here affects every user's experience instantly.

AppBar: "Pricing Management"
        + "Last updated: 2 hours ago by admin@kochigo.app"

─── SECTION A: Current Mode Banner ─────────────────────────────────

  Large status card at top showing current live state:
  
  If isFreePeriod = true:
  ┌─────────────────────────────────────────────────────┐
  │  🎉  FREE PERIOD ACTIVE                             │
  │  All new events post for free.                      │
  │  Payment is bypassed entirely.                      │
  │  Reason: "Launch offer — post your event for free!" │
  └─────────────────────────────────────────────────────┘

  If isFreePeriod = false, paymentEnabled = true:
  ┌─────────────────────────────────────────────────────┐
  │  💰  PAID MODE ACTIVE                               │
  │  Posting fee: ₹200 per event (30 days)              │
  │  Revenue earned this week: ₹1,400                   │
  └─────────────────────────────────────────────────────┘

─── SECTION B: Posting Fee Settings ────────────────────────────────

  Card: "Posting Fee"

  Row 1: [Free Period Active] — Toggle Switch
    ON = isFreePeriod: true (payment completely bypassed)
    OFF = payment logic runs based on fields below

  Row 2: [Posting Fee]
    TextField with ₹ prefix
    Current value: 0 or 200
    Helper: "Set to 0 to make posting free. Set any amount for paid posting."
    Disabled when isFreePeriod = ON

  Row 3: [Fee Display Label]
    TextField
    Placeholder: "₹200 / 30 days"
    This is EXACTLY what users see in the app

  Row 4: [Event Duration (days)]
    TextField with "days" suffix
    Current: 30
    Helper: "How long each posted event stays active after approval"

  Row 5: [Free Period Message]
    TextField (multiline)
    Shown to users on the Post Event screen
    e.g. "🎉 Post your event for FREE during our launch!"

─── SECTION C: Free Period Deadline ────────────────────────────────

  Card: "Free Period End Date (Optional)"
  
  [Set deadline] toggle
  If ON: shows DateTimePicker
  When set: app shows countdown to users
  "Ends on: Saturday, 30 April 2026 at 11:59 PM"
  [Clear deadline] button

─── SECTION D: Payment Gateway ─────────────────────────────────────

  Card: "Payment Settings"

  Row 1: [Enable Payment Processing] — Toggle Switch
    ON = Razorpay checkout appears in app
    OFF = No payments collected (use for grace period, testing)
    
    ⚠️ Warning dialog when toggling ON:
    "Are you sure? Users will be charged ₹{fee} per event post."
    [Cancel] [Yes, Enable Payments]

  Row 2: [Razorpay Mode]
    Segmented: [Test Mode] [Live Mode]
    
    ⚠️ Warning dialog when switching to Live:
    "Live mode uses real money. Make sure your KYC is approved."

  Row 3: Razorpay Key ID (display-only, masked: rzp_live_XXX...)
    [Change key] opens a secure dialog

─── SECTION E: Promo Banner ─────────────────────────────────────────

  Card: "Home Screen Banner"

  [Show Banner] toggle
  
  If ON:
  TextField: Banner text
    "🎉 Post your Kochi event for FREE this month!"
  
  Color picker: Banner background color
    Presets: Coral #FF5247 | Green #22C55E | Amber #F59E0B | Blue #3B82F6
    Custom hex input
  
  TextField: CTA button text
    "Post Free Now"
  
  Live preview of banner (rendered in the form)

─── SECTION F: Maintenance Mode ─────────────────────────────────────

  Card: "Maintenance Mode"  ← Red border when active

  [Enable Maintenance Mode] toggle
  ⚠️ "This takes the app offline for ALL users immediately"
  
  If ON: TextField for maintenance message
  "We're upgrading KochiGo. Back in 30 minutes! 🔧"

─── SAVE BUTTON ─────────────────────────────────────────────────────

  [Save Changes]  full width, coral, 56px
  
  On tap: 
    1. Validates all fields
    2. Shows confirmation dialog: 
       "These changes affect all users immediately. Continue?"
       Lists what changed: "• Posting fee: ₹0 → ₹200  • Free period: ON → OFF"
    3. On confirm:
       → Updates app_config/pricing in Firestore
       → Sets updatedAt, updatedBy, changeLog
       → Shows SnackBar: "Config updated! Changes are now live."
    
  [Save & Notify Users] button (secondary)
    → Same as Save + opens NotificationCompose with pre-filled message:
      "📢 KochiGo pricing update: {postingFeeLabel} per event. 
       Post your events and reach thousands of Kochiites!"
```

---

## Screen 3: Revenue Dashboard (NEW)

```
admin_app/lib/screens/revenue_screen.dart

AppBar: "Revenue"  +  Date range picker (This Week / This Month / All Time)

─── Summary Row ──────────────────────────────────────
  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ Total    │  │ This     │  │ Today    │  │ Pending  │
  │ Revenue  │  │ Month    │  │          │  │ Review   │
  │ ₹8,200   │  │ ₹3,400   │  │ ₹400     │  │ 5 events │
  └──────────┘  └──────────┘  └──────────┘  └──────────┘

─── Recent Payments List ─────────────────────────────
  Each item:
    - Event title
    - User name
    - Amount (₹200)
    - Date + time
    - Razorpay payment ID
    - Status badge: Captured / Refunded / Failed

─── Stats ────────────────────────────────────────────
  Total payments this month: 17
  Avg per day: 0.6 payments
  Projected monthly (at current rate): ₹3,600

  (All computed client-side from payments stream)
```

---

## Screen 4: Users (NEW)

```
admin_app/lib/screens/users_screen.dart

Search bar at top (filter by name/email)
List of all users from `users` collection

Each row:
  - Profile photo + name
  - Email or phone
  - Events posted count
  - Join date
  - [Verified Org] badge if isVerifiedOrg=true

Tap user → UserDetailSheet:
  - Full profile info
  - List of their events (with status)
  - [Mark as Verified Org] toggle — sets isVerifiedOrg=true in Firestore
    (This gives them a ✓ badge on all their events)
  - [View Events] → filters Events screen by this user
  - [Refund All] button (for edge cases, opens confirmation)
```

---

## AdminConfigService (Dart — admin_app)

```dart
// admin_app/lib/services/admin_config_service.dart

class AdminConfigService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Real-time stream (same as user app)
  Stream<AppConfigModel> watchConfig() {
    return _db
        .collection('app_config')
        .doc('pricing')
        .snapshots()
        .map((doc) => AppConfigModel.fromFirestore(doc));
  }

  // Save updated config
  Future<void> updateConfig({
    required AppConfigModel updatedConfig,
    required String changeNote,
  }) async {
    final adminEmail = _auth.currentUser?.email ?? 'unknown';

    await _db.collection('app_config').doc('pricing').update({
      ...updatedConfig.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminEmail,
      'changeLog': changeNote,
    });
  }

  // Quick toggles (one-field updates for safety)
  Future<void> setFreePeriod(bool isFree) async {
    await _db.collection('app_config').doc('pricing').update({
      'isFreePeriod': isFree,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setMaintenanceMode(bool isDown, String message) async {
    await _db.collection('app_config').doc('pricing').update({
      'maintenanceMode': isDown,
      'maintenanceMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Revenue aggregation
  Future<Map<String, dynamic>> getRevenueStats(DateRange range) async {
    final payments = await _db
        .collection('payments')
        .where('status', isEqualTo: 'captured')
        .where('paidAt', isGreaterThan: range.start)
        .get();

    final total = payments.docs.fold<int>(
      0, (sum, doc) => sum + (doc['amount'] as int));

    return {
      'total': total,
      'count': payments.docs.length,
      'payments': payments.docs,
    };
  }
}
```

---

## Firestore Security Rules — app_config (Admin Write)

```javascript
match /app_config/{docId} {
  // Everyone reads (real-time in app)
  allow read: if true;
  
  // Only authenticated admin user can write
  allow write: if request.auth != null
               && request.auth.token.email == "your-admin@gmail.com";
}
```

---

## UX Design Notes for Pricing Screen

**Why the design is opinionated this way:**

1. **Large status banner at top** — admin always knows current live state at a glance. No confusion.

2. **Free Period as a Master Toggle** — disabling payment should be a single tap, not multiple field changes. When toggling ON, payment fields become disabled/greyed — less cognitive load.

3. **Confirmation dialog with diff** — "You're changing: Fee ₹0 → ₹200, Free Period OFF". Forces the admin to consciously review changes. Prevents accidental price changes.

4. **Save & Notify Users** — pricing changes need communication. Bundling notification with config save reduces the chance of users being surprised by a price change.

5. **Maintenance mode has a red border** — critical distinction. Admin should never accidentally leave maintenance mode on.

6. **All changes are instant** — no "publish" delay. Firestore real-time listeners in the app pick up changes in under 2 seconds. This is power in the admin's hands.
