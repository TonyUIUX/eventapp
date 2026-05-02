# 🔥 Firebase Setup & Sample Data

## Step-by-Step Firebase Setup

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project" → Name: `kochigo-app`
3. Disable Google Analytics (not needed for MVP)
4. Click "Create project"

### Step 2: Add Android App
1. In Firebase Console → Project Overview → Add app → Android
2. Android package name: `com.kochigo.app` (match your Flutter app ID)
3. App nickname: `KochiGo Android`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

### Step 3: Enable Firestore
1. Firebase Console → Build → Firestore Database
2. Click "Create database"
3. Select "Start in production mode" (we'll set rules manually)
4. Select region: `asia-south1` (Mumbai — closest to Kochi)
5. Click "Enable"

### Step 4: Enable Firebase Storage
1. Firebase Console → Build → Storage
2. Click "Get started"
3. Production mode → same region `asia-south1`

### Step 5: Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=kochigo-app
```
This auto-generates `lib/firebase_options.dart`

### Step 6: Update android/build.gradle
```gradle
// android/build.gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.0'  // Add this
  }
}
```

### Step 7: Update android/app/build.gradle
```gradle
// android/app/build.gradle
apply plugin: 'com.google.gms.google-services'  // Add at bottom

android {
  defaultConfig {
    minSdkVersion 21  // Minimum for Firebase
  }
}
```

### Step 8: Add Firestore Security Rules
In Firebase Console → Firestore → Rules tab, paste:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /events/{eventId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```
Click "Publish"

### Step 9: Create Composite Index
Firebase Console → Firestore → Indexes → Add Index:
- Collection ID: `events`
- Fields: `isActive` (Ascending), `date` (Ascending)
- Click "Create"
(Takes 2-3 minutes to build)

---

## Sample Dummy Data

Add these documents to the `events` collection in Firestore Console.
Use "Add document" → "Auto ID" for each.

---

### Document 1
```json
{
  "title": "Kochi Open Mic Night",
  "category": "comedy",
  "description": "Kochi's biggest open mic night returns! Join us for an evening of stand-up comedy, spoken word, and raw talent from local comedians. Whether you're a first-timer or a seasoned performer, this is your stage. Free entry, first come first served.",
  "date": "2025-04-19T19:00:00+05:30",
  "location": "Kashi Art Café, Fort Kochi",
  "mapLink": "https://maps.google.com/?q=Kashi+Art+Cafe+Fort+Kochi",
  "imageUrl": "https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800",
  "organizer": "Kochi Comedy Collective",
  "contactPhone": "+919876543210",
  "contactInstagram": "@kochicomedy",
  "isFeatured": true,
  "isActive": true,
  "createdAt": "2025-04-15T10:00:00+05:30"
}
```
> Note: In Firestore Console, use Timestamp type for `date` and `createdAt`. Set the date to **today** or **this weekend** when testing.

---

### Document 2
```json
{
  "title": "Flutter & Firebase Workshop",
  "category": "tech",
  "description": "Hands-on workshop for developers who want to build production apps with Flutter and Firebase. We'll cover Firestore integration, authentication patterns, and deployment. Bring your laptop. Limited seats — register on Meetup.",
  "date": "2025-04-20T10:00:00+05:30",
  "location": "Startup Village, Kalamassery",
  "mapLink": "https://maps.google.com/?q=Startup+Village+Kalamassery",
  "imageUrl": "https://images.unsplash.com/photo-1591115765373-5207764f72e7?w=800",
  "organizer": "GDG Kochi",
  "contactPhone": null,
  "contactInstagram": "@gdgkochi",
  "isFeatured": false,
  "isActive": true,
  "createdAt": "2025-04-15T11:00:00+05:30"
}
```

---

### Document 3
```json
{
  "title": "Yoga at the Beach",
  "category": "fitness",
  "description": "Start your Saturday right with a sunrise yoga session at Cherai Beach. Suitable for all levels — beginners welcome. Bring your own mat. Session runs for 1 hour followed by fresh coconut water. Pure Kerala vibes.",
  "date": "2025-04-19T06:30:00+05:30",
  "location": "Cherai Beach, North Paravur",
  "mapLink": "https://maps.google.com/?q=Cherai+Beach+Kerala",
  "imageUrl": "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
  "organizer": "Kerala Wellness Co.",
  "contactPhone": "+919765432100",
  "contactInstagram": "@keralawellness",
  "isFeatured": false,
  "isActive": true,
  "createdAt": "2025-04-15T12:00:00+05:30"
}
```

---

### Document 4
```json
{
  "title": "Indie Music Night: Local Bands",
  "category": "music",
  "description": "Four of Kochi's best indie bands perform live in an intimate venue setting. Featuring experimental rock, folk fusion, and jazz. Doors open at 6 PM. Tickets at the door. Food and drinks available.",
  "date": "2025-04-20T18:00:00+05:30",
  "location": "The Barge, Marine Drive",
  "mapLink": "https://maps.google.com/?q=The+Barge+Marine+Drive+Kochi",
  "imageUrl": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800",
  "organizer": "Kochi Live Music",
  "contactPhone": null,
  "contactInstagram": "@kochilivemusic",
  "isFeatured": true,
  "isActive": true,
  "createdAt": "2025-04-15T13:00:00+05:30"
}
```

---

### Document 5
```json
{
  "title": "Mural Art Walk — Fort Kochi",
  "category": "art",
  "description": "Join our guided walk through Fort Kochi's iconic street murals. A local artist will explain the stories behind Bose Krishnamachari's works and the annual Kochi-Muziris Biennale legacy. 2 hours. Meeting point at David Hall.",
  "date": "2025-04-19T09:00:00+05:30",
  "location": "David Hall, Fort Kochi",
  "mapLink": "https://maps.google.com/?q=David+Hall+Fort+Kochi",
  "imageUrl": "https://images.unsplash.com/photo-1561839561-b13bcfe4b50a?w=800",
  "organizer": "Kochi Arts Foundation",
  "contactPhone": "+918888877777",
  "contactInstagram": "@kochiartswalk",
  "isFeatured": false,
  "isActive": true,
  "createdAt": "2025-04-15T14:00:00+05:30"
}
```

---

## Important Notes on Dates

When adding test data to Firestore:
- Set `date` values to **today** and **this coming weekend** so they show up in the app
- Firestore Timestamp format in console: Select "Timestamp" type and pick the date

---

## Firebase Storage — Upload Test Image
1. Firebase Console → Storage → Files
2. Create folder: `events/`
3. Upload a test image (JPEG, 800×450px)
4. Click the uploaded file → Copy download URL
5. Use that URL in `imageUrl` field above

Or use the Unsplash URLs provided above (they work for testing but use Storage for production).
