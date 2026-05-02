# 🗄️ Data Models & Firebase Schema

## Firestore Collection: `events`

### Document Fields

| Field        | Type        | Required | Notes                                      |
|--------------|-------------|----------|--------------------------------------------|
| `id`         | String      | Auto     | Firestore document ID                      |
| `title`      | String      | ✅        | Max 80 chars. e.g. "Open Mic Night Kochi"  |
| `category`   | String      | ✅        | One of the 6 valid categories (see below)  |
| `description`| String      | ✅        | Full event description. Max 1000 chars     |
| `date`       | Timestamp   | ✅        | Firebase Timestamp (not string)            |
| `location`   | String      | ✅        | Human-readable. e.g. "Kashi Art Café, Fort Kochi" |
| `mapLink`    | String      | ✅        | Google Maps URL                            |
| `imageUrl`   | String      | ✅        | Firebase Storage URL or external CDN URL   |
| `organizer`  | String      | ✅        | Organizer name                             |
| `contactPhone`| String     | ⬜        | Phone with country code: "+919876543210"   |
| `contactInstagram`| String | ⬜        | Instagram handle: "@kochicomedy"           |
| `isFeatured` | Boolean     | ✅        | true = show in featured section (future)   |
| `isActive`   | Boolean     | ✅        | false = hide from app without deleting     |
| `createdAt`  | Timestamp   | ✅        | Auto-set when document created             |

---

## Valid Categories (EXACT STRINGS — case sensitive)
```
comedy
music
tech
fitness
art
workshop
```
> ⚠️ These strings are used in Firestore queries. Never change them without updating the app.

---

## Dart Model

```dart
// lib/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime date;
  final String location;
  final String mapLink;
  final String imageUrl;
  final String organizer;
  final String? contactPhone;
  final String? contactInstagram;
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    required this.location,
    required this.mapLink,
    required this.imageUrl,
    required this.organizer,
    this.contactPhone,
    this.contactInstagram,
    required this.isFeatured,
    required this.isActive,
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      mapLink: data['mapLink'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      organizer: data['organizer'] ?? '',
      contactPhone: data['contactPhone'],
      contactInstagram: data['contactInstagram'],
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'mapLink': mapLink,
      'imageUrl': imageUrl,
      'organizer': organizer,
      'contactPhone': contactPhone,
      'contactInstagram': contactInstagram,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

---

## Firestore Service

```dart
// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Fetch all active events, sorted by date ascending
  Future<List<EventModel>> getEvents() async {
    final snapshot = await _db
        .collection('events')
        .where('isActive', isEqualTo: true)
        .orderBy('date', descending: false)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }
}
```

---

## Firestore Security Rules (Paste in Firebase Console)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Anyone can READ events, no one can WRITE from app
    match /events/{eventId} {
      allow read: if true;
      allow write: if false; // Admin-only via Firebase Console
    }
  }
}
```

---

## Firestore Indexes Required

Create a **Composite Index** in Firebase Console:

| Collection | Field 1   | Field 2 | Order     |
|------------|-----------|---------|-----------|
| `events`   | `isActive`| `date`  | Ascending |

> Without this index, the query will fail in production. Firebase will show an error with a direct link to create it — click it.

---

## Firebase Storage Structure

```
gs://your-app.appspot.com/
└── events/
    ├── event-id-1.jpg
    ├── event-id-2.jpg
    └── ...
```

**Image rules:**
- Format: JPEG or WebP
- Max size: 500KB per image
- Recommended dimensions: 800×450px (16:9 ratio)
- Storage rules: Public read, no write from app
