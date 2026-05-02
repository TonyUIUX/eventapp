# ⚙️ Dynamic Pricing & App Configuration — KochiGo v3.1

> ⚠️ THIS DOC SUPERSEDES the tier system in `16_PLATFORM_VISION_V3.md` and `19_PAYMENT_INTEGRATION.md`
> The 3-tier (Basic/Boost/Premium) system is REPLACED by a single configurable flat fee.
> All pricing is now controlled 100% from the Admin Panel in real-time.

---

## The Pricing Philosophy

```
Phase 1 (NOW):     FREE      ← Launch offer. Zero friction. Grow user base fast.
Phase 2 (Month 2+): ₹200/month ← Once you have traction, flip the switch in admin.
Phase 3 (Scale):   ₹200–500  ← Admin raises price based on demand and city growth.
```

**One admin action** — changing a number in a Firestore document — changes the price for every new event posted. No app update. No redeployment. Zero developer involvement.

---

## Firestore Collection: `app_config`

Single document. Document ID: `pricing`

```
app_config/pricing

  ─── Core Pricing ────────────────────────────────────────────────
  postingFee            Number      Current posting fee in ₹
                                    0 = completely free (no payment step shown)
                                    200 = ₹200, etc.

  postingFeePaise       Number      Same amount in paise for Razorpay
                                    (admin-computed: postingFee × 100)
                                    0 when free

  postingFeeLabel       String      Display text shown to users
                                    e.g. "Free", "₹200/month", "₹350/month"

  eventDurationDays     Number      How many days the event listing stays active
                                    Default: 30
                                    Can be changed by admin anytime

  ─── Free Period Controls ────────────────────────────────────────
  isFreePeriod          Boolean     Master override. true = skip all payment logic.
                                    When true: postingFee is ignored entirely.

  freePeriodReason      String      Why it's free. Shown on "Post Event" CTA.
                                    e.g. "🎉 Free during launch — post your event!"
                                    e.g. "🎁 Free this week only"

  freePeriodEndsAt      Timestamp?  Optional hard deadline. Null = indefinitely free.
                                    When set, app shows countdown: "Free for 3 more days"

  ─── Payment Gateway ─────────────────────────────────────────────
  paymentEnabled        Boolean     Master payment switch.
                                    false = bypass Razorpay entirely even if postingFee > 0.
                                    Use when: Razorpay is down, testing, grace period.

  razorpayMode          String      'test' | 'live'
                                    Switches which key the app uses.

  ─── Promotional Banner ──────────────────────────────────────────
  showPromoBanner       Boolean     Show a banner on HomeScreen
  promoBannerText       String      e.g. "🎉 Post your event FREE this month!"
  promoBannerColor      String      Hex color e.g. "#FF5247"
  promoBannerCta        String      Button text e.g. "Post Now"

  ─── App Health ──────────────────────────────────────────────────
  maintenanceMode       Boolean     true = show maintenance screen to all users
  maintenanceMessage    String      e.g. "We're upgrading KochiGo. Back in 30 mins!"

  ─── Audit ───────────────────────────────────────────────────────
  updatedAt             Timestamp   Last change timestamp
  updatedBy             String      Admin email who made the change
  changeLog             String      Brief note: "Raised price for Q2" etc.
```

---

## Initial Document Values (Set This in Firebase Console Now)

```json
{
  "postingFee": 0,
  "postingFeePaise": 0,
  "postingFeeLabel": "Free",
  "eventDurationDays": 30,

  "isFreePeriod": true,
  "freePeriodReason": "🎉 Post your event for FREE during our launch!",
  "freePeriodEndsAt": null,

  "paymentEnabled": false,
  "razorpayMode": "test",

  "showPromoBanner": true,
  "promoBannerText": "🎉 Post your Kochi event for FREE this month!",
  "promoBannerColor": "#FF5247",
  "promoBannerCta": "Post Free Now",

  "maintenanceMode": false,
  "maintenanceMessage": "",

  "updatedAt": "<server timestamp>",
  "updatedBy": "admin@kochigo.app",
  "changeLog": "Initial launch config"
}
```

---

## How to Switch from Free → Paid

When you're ready to start charging (Month 2):

1. Open Admin Panel → Pricing Management
2. Set `postingFee` = 200
3. Set `postingFeePaise` = 20000
4. Set `postingFeeLabel` = "₹200 / 30 days"
5. Set `isFreePeriod` = false
6. Set `paymentEnabled` = true
7. Set `razorpayMode` = 'live' (after Razorpay KYC is done)
8. Update `freePeriodReason` = "" (or a farewell message)
9. Tap "Save & Broadcast" → admin sends push notification to all users:
   > "KochiGo is now ₹200 to list your event for 30 days. 
   >  Still cheaper than one Facebook ad! 🎯"
10. Done. Every new post from that moment costs ₹200.

**Zero code changes. Zero app update. Instant.**

---

## AppConfig Model (Dart)

```dart
// lib/models/app_config_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigModel {
  final int postingFee;
  final int postingFeePaise;
  final String postingFeeLabel;
  final int eventDurationDays;

  final bool isFreePeriod;
  final String freePeriodReason;
  final DateTime? freePeriodEndsAt;

  final bool paymentEnabled;
  final String razorpayMode;

  final bool showPromoBanner;
  final String promoBannerText;
  final String promoBannerColor;
  final String promoBannerCta;

  final bool maintenanceMode;
  final String maintenanceMessage;

  const AppConfigModel({
    required this.postingFee,
    required this.postingFeePaise,
    required this.postingFeeLabel,
    required this.eventDurationDays,
    required this.isFreePeriod,
    required this.freePeriodReason,
    this.freePeriodEndsAt,
    required this.paymentEnabled,
    required this.razorpayMode,
    required this.showPromoBanner,
    required this.promoBannerText,
    required this.promoBannerColor,
    required this.promoBannerCta,
    required this.maintenanceMode,
    required this.maintenanceMessage,
  });

  // Computed helper — the single truth: should we show payment?
  bool get requiresPayment =>
      !isFreePeriod && paymentEnabled && postingFee > 0;

  // Is the free period about to end? (within 3 days)
  bool get freePeriodEndingSoon {
    if (freePeriodEndsAt == null) return false;
    return freePeriodEndsAt!.difference(DateTime.now()).inDays <= 3;
  }

  factory AppConfigModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppConfigModel(
      postingFee: d['postingFee'] ?? 0,
      postingFeePaise: d['postingFeePaise'] ?? 0,
      postingFeeLabel: d['postingFeeLabel'] ?? 'Free',
      eventDurationDays: d['eventDurationDays'] ?? 30,
      isFreePeriod: d['isFreePeriod'] ?? true,
      freePeriodReason: d['freePeriodReason'] ?? '',
      freePeriodEndsAt: (d['freePeriodEndsAt'] as Timestamp?)?.toDate(),
      paymentEnabled: d['paymentEnabled'] ?? false,
      razorpayMode: d['razorpayMode'] ?? 'test',
      showPromoBanner: d['showPromoBanner'] ?? false,
      promoBannerText: d['promoBannerText'] ?? '',
      promoBannerColor: d['promoBannerColor'] ?? '#FF5247',
      promoBannerCta: d['promoBannerCta'] ?? '',
      maintenanceMode: d['maintenanceMode'] ?? false,
      maintenanceMessage: d['maintenanceMessage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'postingFee': postingFee,
    'postingFeePaise': postingFeePaise,
    'postingFeeLabel': postingFeeLabel,
    'eventDurationDays': eventDurationDays,
    'isFreePeriod': isFreePeriod,
    'freePeriodReason': freePeriodReason,
    'freePeriodEndsAt': freePeriodEndsAt != null
        ? Timestamp.fromDate(freePeriodEndsAt!) : null,
    'paymentEnabled': paymentEnabled,
    'razorpayMode': razorpayMode,
    'showPromoBanner': showPromoBanner,
    'promoBannerText': promoBannerText,
    'promoBannerColor': promoBannerColor,
    'promoBannerCta': promoBannerCta,
    'maintenanceMode': maintenanceMode,
    'maintenanceMessage': maintenanceMessage,
  };
}
```

---

## AppConfig Provider (Riverpod)

```dart
// lib/providers/app_config_provider.dart

// Real-time stream — config changes reflect instantly in app
final appConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('pricing')
      .snapshots()
      .map((doc) => AppConfigModel.fromFirestore(doc));
});

// Convenience — just the maintenance state
final maintenanceModeProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).valueOrNull?.maintenanceMode ?? false;
});
```

---

## Maintenance Mode Screen

```dart
// lib/screens/maintenance/maintenance_screen.dart
// Shown from main.dart when maintenanceMode == true
// Replaces entire app content

// Layout:
//   🔧 large emoji or animation
//   "KochiGo is getting better!"
//   maintenanceMessage text
//   "We'll be back soon" subtext
//   Auto-refreshes every 60 seconds (listens to appConfigProvider)
//   When maintenanceMode flips to false: auto-navigates back to HomeScreen

// In main.dart / MaterialApp builder:
ref.listen(maintenanceModeProvider, (_, isDown) {
  if (isDown) Navigator.pushAndRemoveUntil(... MaintenanceScreen ...);
});
```

---

## Promo Banner (HomeScreen)

```dart
// lib/screens/home/widgets/promo_banner.dart
// Shown at TOP of HomeScreen when showPromoBanner == true
// Appears ABOVE the date toggle, below AppBar

// Layout:
//   Background: promoBannerColor (coral or any admin-set color)
//   Text: promoBannerText (white, semibold)
//   CTA button: promoBannerCta (white outlined)
//   ✕ dismiss button (top-right, stores 'banner_dismissed' in SharedPreferences)
//   Dismissed banners stay hidden until text changes

// Wire in HomeScreen:
final config = ref.watch(appConfigProvider).valueOrNull;
if (config?.showPromoBanner == true && !_bannerDismissed)
  PromoBanner(config: config!)
```

---

## Firestore Security Rules for app_config

```javascript
// In Firestore security rules
match /app_config/{docId} {
  allow read: if true;      // App reads this openly and in real-time
  allow write: if false;    // ONLY editable via Admin Panel (Firebase Auth admin user)
}
```

---

## Free Period Countdown Widget

Show this on the "Post Event" step (TierScreen or confirmation):

```dart
// If freePeriodEndsAt is set and isFreePeriod is true:

Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color(0xFFFFF3CD),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color(0xFFFFD700)),
  ),
  child: Row(
    children: [
      const Text('⏳', style: TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Free Period Ending Soon!',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              'Post now before the fee kicks in on ${DateUtils.format(config.freePeriodEndsAt!)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

---

## Pricing Change History (Future v4)

For now, admin just uses `changeLog` string field.
In v4: create `app_config/pricing_history` subcollection with full audit trail.
