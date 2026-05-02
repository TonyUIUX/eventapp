# KochiGo App Documentation

## 📱 About KochiGo
KochiGo is a hyper-local event discovery and community platform built for Kochi, Kerala. It connects users with local events, workshops, music gigs, and tech meetups while providing event organizers with a seamless platform to list, promote, and manage their events.

## 🏗️ Technology Stack
*   **Frontend Framework:** Flutter (Dart)
*   **State Management:** Riverpod (`flutter_riverpod`)
*   **Backend & Database:** Firebase (Firestore, Authentication, Storage, Analytics, Cloud Messaging)
*   **Payments Integration:** Razorpay (with Test/Live mode toggling)
*   **Offline Support:** SharedPreferences & Smart Caching Mechanism
*   **Local Notifications:** `flutter_local_notifications` & `firebase_messaging`
*   **Deep Linking:** `app_links`

---

## 📂 Project Structure
The codebase follows a feature-first, clean architecture approach using Riverpod for dependency injection and state management.

```text
lib/
├── core/                  # Core configurations, design system, utilities
│   ├── config/            # Environment configs (Razorpay)
│   ├── constants/         # AppColors, AppTextStyles, Firestore Constants
│   ├── theme/             # Global ThemeData
│   └── utils/             # Helper functions (DateUtils, UrlUtils)
├── models/                # Strongly-typed data models (EventModel, UserModel, AppConfigModel)
├── providers/             # Riverpod global state providers (Events, Auth, Config)
├── screens/               # UI screens, organized by feature
│   ├── auth/              # Login, Registration workflows
│   ├── detail/            # Event detail view
│   ├── home/              # Main feed, Carousels, Trending sections
│   ├── post_event/        # Multi-step event creation wizard
│   ├── profile/           # User profiles and settings
│   └── saved/             # Bookmarked events
├── services/              # External integrations (Firestore, Storage, Payments, Notifications)
└── main.dart              # Entry point & App Shell (Bottom Navigation)

admin_app/                 # Dedicated Flutter Web project for Admin Dashboard
```

---

## ✨ Key Features & Workflows

### 1. Smart Offline Caching (`SmartCacheService`)
To ensure a fast, resilient UX even on poor mobile networks, the app pre-fetches and caches the top 20 upcoming events in `SharedPreferences`. If the user opens the app without internet access, these cached events are immediately served to the UI.

### 2. Event Posting & Monetization
Users can post their own events via a 5-step wizard.
*   **Free vs Paid Posting:** Controlled dynamically via the Admin Panel's `AppConfigModel`.
*   **Razorpay Integration:** If a posting fee is required, the `PaymentService` securely handles the Razorpay checkout flow. Keys are injected securely at build time.

### 3. Deep Linking (`DeepLinkService`)
Events can be shared via URLs (e.g., `https://kochigo.com/event/<event_id>`). The app intercepts these links and directly routes the user to the specific `EventDetailScreen`.

### 4. Admin Management (Web App)
A companion web dashboard allows platform owners to:
*   Toggle **Maintenance Mode** (instantly blocking app access with a custom message).
*   Toggle **Free Posting Periods** and modify base posting fees.
*   Review, approve, or reject pending events.
*   Dispatch global **Push Notifications** to all users.

---

## 🔐 Security & Best Practices

*   **Secrets Management:** No API keys or keystores are committed to version control. `google-services.json` and `key.properties` are strictly `.gitignore`'d.
*   **Secure Key Injection:** Razorpay keys are passed securely during the build step using `--dart-define` to prevent decompilation leakage.
*   **ProGuard/R8:** Minification and resource shrinking are enabled for release builds. Custom ProGuard rules (`proguard-rules.pro`) ensure Razorpay and Flutter embedding classes are not stripped.
*   **Firestore Rules:** Strict security rules govern database access, ensuring users can only modify their own profiles and event posts.

---

## 🚀 Build & Deployment Guide

### Prerequisites
*   Flutter SDK: `3.24.0` or higher
*   Java: `11` or higher
*   Android Gradle Plugin (AGP): `8.9.1`
*   Kotlin: `2.1.0`

### 1. Local Development (Debug)
For local testing using Razorpay test mode:
```bash
flutter run
```

### 2. Production Release Build (Android)
To build a production APK with live Razorpay keys and code obfuscation enabled, use the provided PowerShell script or run the following command directly:

```bash
flutter build apk --release \
  "--dart-define=RAZORPAY_TEST_KEY=rzp_test_your_key_here" \
  "--dart-define=RAZORPAY_PROD_KEY=rzp_live_your_key_here" \
  "--dart-define=USE_LIVE_RAZORPAY=true"
```
*(For Play Store submission, replace `apk` with `appbundle`)*

### 3. Signing Configuration
Ensure your `android/key.properties` file is configured correctly before building:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=kochigo-upload.jks
```

---

## 🎨 Design System (`AppColors` & `AppTextStyles`)
KochiGo uses a strict, centralized design system to maintain visual consistency.
*   **Primary Brand:** Vibrant Coral (`#FFFF5247`)
*   **Neutrals:** Deep Slates (`#111827`, `#4B5563`) for high contrast readability.
*   **Typography:** Google's `Poppins` font is bundled locally to eliminate network dependency on startup. All font sizes and weights are strictly referenced through `AppTextStyles` (e.g., `AppTextStyles.heading1`).
*   **No Hardcoded Values:** The codebase enforces the use of these semantic tokens.

---

## 🔔 Push Notifications
Powered by Firebase Cloud Messaging (FCM).
*   **Foreground:** Handled via `flutter_local_notifications` to show heads-up banners.
*   **Background/Terminated:** Handled natively by Android/iOS system trays.
*   **Admin Dispatch:** Admins can trigger broadcast messages from the Admin Web App, which syncs to Firestore and uses Firebase Extensions or Cloud Functions to distribute FCM payloads.
