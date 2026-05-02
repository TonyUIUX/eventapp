# 🔥 Firebase & Backend Upgrades — KochiGo v2.0

---

## 1. Firebase Storage — Event Image Upload

### Why
Currently all images are Unsplash CDN URLs. For production, you need to own your images via Firebase Storage. This also enables the admin panel to upload event posters directly.

### Storage Structure
```
gs://kochigo-app.appspot.com/
└── events/
    ├── {eventId}/
    │   ├── cover.jpg          # Main cover image
    │   ├── gallery_1.jpg      # Optional extra images
    │   └── gallery_2.jpg
    └── temp/                  # Admin upload staging (optional)
```

### Storage Rules (paste in Firebase Console → Storage → Rules)
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Anyone can READ event images
    match /events/{allPaths=**} {
      allow read: if true;
      allow write: if false;  // Only via Firebase Console or Admin SDK
    }
  }
}
```

### Image Upload Service (for Admin Panel)
```dart
// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 675,    // Forces 16:9 via maxWidth/maxHeight
      imageQuality: 85,  // Compress to ~85% quality
    );
    return picked != null ? File(picked.path) : null;
  }

  // Upload to Firebase Storage, return download URL
  Future<String> uploadEventImage({
    required File imageFile,
    required String eventId,
    String imageName = 'cover',
  }) async {
    final ext = imageFile.path.split('.').last;
    final ref = _storage.ref('events/$eventId/$imageName.$ext');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  // Upload with progress (for showing upload %) 
  Stream<TaskSnapshot> uploadWithProgress({
    required File imageFile,
    required String eventId,
  }) {
    final ref = _storage.ref('events/$eventId/cover.jpg');
    return ref.putFile(imageFile).snapshotEvents;
  }

  // Delete image
  Future<void> deleteEventImage(String eventId) async {
    try {
      await _storage.ref('events/$eventId/cover.jpg').delete();
    } catch (e) {
      debugPrint('Image delete failed (may not exist): $e');
    }
  }
}
```

### pubspec.yaml additions
```yaml
firebase_storage: ^12.x.x
image_picker: ^1.x.x
```

### AndroidManifest.xml — Add Camera Permission (for future admin use)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

## 2. Firestore Offline Persistence

### Why
App currently crashes/shows error on no internet. With offline persistence, Firestore caches data locally. Users can browse previously loaded events even with no connection.

### Implementation
```dart
// main.dart — enable BEFORE first Firestore call

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Enable offline persistence
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### Connectivity-Aware UI
```dart
// lib/services/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
    .onConnectivityChanged
    .map((result) => result != ConnectivityResult.none);
});
```

```dart
// home_screen.dart — show offline banner when disconnected

final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

if (!isOnline)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8),
    color: AppColors.textSecondary,
    child: const Text(
      '📶 Offline — showing cached events',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white, fontSize: 12),
    ),
  ),
```

### pubspec.yaml
```yaml
connectivity_plus: ^6.x.x
```

---

## 3. Firebase Analytics

### Why
After launch, you're flying blind without analytics. Track which categories are popular, which events get most views, and where users drop off.

### Setup
```dart
// main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

// Already initialized with Firebase.initializeApp()
// No additional setup needed
```

### Analytics Service
```dart
// lib/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  // Track screen views
  static Future<void> logScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Track event detail views (most important metric)
  static Future<void> logEventView(EventModel event) async {
    await _analytics.logEvent(
      name: 'event_viewed',
      parameters: {
        'event_id': event.id,
        'event_title': event.title,
        'category': event.category,
        'is_featured': event.isFeatured,
      },
    );
  }

  // Track saves
  static Future<void> logEventSaved(String eventId, bool isSaving) async {
    await _analytics.logEvent(
      name: isSaving ? 'event_saved' : 'event_unsaved',
      parameters: {'event_id': eventId},
    );
  }

  // Track shares
  static Future<void> logEventShared(EventModel event) async {
    await _analytics.logShare(
      contentType: 'event',
      itemId: event.id,
      method: 'system_share',
    );
  }

  // Track category filter usage
  static Future<void> logCategoryFilter(String category) async {
    await _analytics.logEvent(
      name: 'category_filtered',
      parameters: {'category': category},
    );
  }
  
  // Track search queries
  static Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }
}
```

### Wire Analytics in Screens
```dart
// event_detail_screen.dart — in initState or build
AnalyticsService.logEventView(widget.event);

// home_screen.dart — when category changes
AnalyticsService.logCategoryFilter(category);

// search_screen.dart — on search submit
AnalyticsService.logSearch(query);

// event_detail_screen.dart — on save button tap
AnalyticsService.logEventSaved(event.id, !isSaved);
```

### pubspec.yaml
```yaml
firebase_analytics: ^11.x.x
```

---

## 4. Firebase Cloud Messaging (Push Notifications)

### When to Implement
Tier 3 — implement after reaching 500+ installs. Don't rush this.

### Use Cases for KochiGo
1. "New events added for this weekend" (Friday 6 PM broadcast)
2. "🎭 Comedy show tonight in Fort Kochi — 3 hours left!"
3. "Your saved event starts tomorrow 📅" (if reminder set)

### Setup Steps
1. Firebase Console → Cloud Messaging → Enable
2. Add `firebase_messaging` package
3. Request permission on first launch
4. Handle foreground + background messages

### Basic Setup
```dart
// pubspec.yaml
firebase_messaging: ^15.x.x
flutter_local_notifications: ^17.x.x

// lib/services/fcm_service.dart

class FCMService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS + Android 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token (save to Firestore later for targeted notifications)
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages — show as local notification
    FirebaseMessaging.onMessage.listen((message) {
      // Show using flutter_local_notifications
    });

    // Handle tap on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Navigate to relevant event if eventId is in message data
    });
  }
}

// main.dart
await FCMService.initialize();
```

### AndroidManifest.xml for FCM
```xml
<meta-data
  android:name="com.google.firebase.messaging.default_notification_channel_id"
  android:value="event_notifications" />
<meta-data
  android:name="com.google.firebase.messaging.default_notification_icon"
  android:resource="@mipmap/ic_launcher" />
<meta-data
  android:name="com.google.firebase.messaging.default_notification_color"
  android:resource="@color/primary_color" />
```

---

## 5. Deep Linking (Share Event URL)

### Why
When a user shares an event link, tapping it should open the app directly on that event's detail screen.

### Link Format
```
https://kochigo.app/event/{eventId}
OR
kochigo://event/{eventId}  (app scheme)
```

### Package
```yaml
app_links: ^6.x.x
```

### AndroidManifest.xml
```xml
<!-- android/app/src/main/AndroidManifest.xml — inside <activity> -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="kochigo.app" />
</intent-filter>
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="kochigo" />
</intent-filter>
```

### Handle Deep Link in App
```dart
// main.dart — listen for incoming links
final appLinks = AppLinks();

appLinks.uriLinkStream.listen((uri) {
  if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'event') {
    final eventId = uri.pathSegments[1];
    // Navigate to EventDetailScreen for this eventId
    // Fetch event from eventsProvider by ID
  }
});
```

---

## 6. Firestore Security Rules — Updated for v2.0

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /events/{eventId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Future: FCM tokens (if you store them)
    match /fcm_tokens/{tokenId} {
      allow write: if true;  // App can write its own token
      allow read: if false;  // Only admin reads
    }
    
    // Future: Analytics events (if server-side)
    match /analytics/{docId} {
      allow write: if true;
      allow read: if false;
    }
  }
}
```

---

## 7. Firestore Composite Indexes — v2.0 Additions

Add these in Firebase Console → Firestore → Indexes:

| Collection | Field 1 | Field 2 | Field 3 | Use |
|---|---|---|---|---|
| `events` | `isActive` ASC | `date` ASC | — | Existing — keep |
| `events` | `isActive` ASC | `isFeatured` ASC | `date` ASC | Featured carousel |
| `events` | `isActive` ASC | `category` ASC | `date` ASC | Category+date filter |
