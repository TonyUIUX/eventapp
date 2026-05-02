# 🛠️ Admin Panel — KochiGo v2.0

> The admin panel is a SEPARATE Flutter web app — NOT part of the user-facing Android app.
> It's hosted for free on Firebase Hosting or GitHub Pages.
> Only you (the team) uses it. No public access.

---

## Why a Separate Web App

- Keeps the user app clean and small
- Admin features (image upload, form creation) add unnecessary APK weight
- Web app is faster to build and update
- Access from any device with a browser

---

## Tech Stack for Admin Panel

```
Framework:   Flutter Web (same codebase language)
Firebase:    Same Firebase project (kochigo-app)
Auth:        Firebase Email/Password Auth (admin-only)
Hosting:     Firebase Hosting (free tier) or run locally
```

---

## Admin Authentication

Use Firebase Auth with a hardcoded admin email. This is not a public login — only your team email.

```dart
// admin_app/lib/screens/login_screen.dart

// Simple email + password login
// On success → navigate to EventListScreen
// On failure → show error message
// NO "forgot password" or "sign up" UI needed

// Firebase Auth setup:
// Firebase Console → Authentication → Sign-in methods → Email/Password → Enable
// Then manually create ONE admin user from Firebase Console
// (No self-registration)
```

```dart
// Firestore security rules — update to allow admin writes:
match /events/{eventId} {
  allow read: if true;
  allow write: if request.auth != null && 
                  request.auth.token.email == "your-admin-email@gmail.com";
}
```

---

## Admin App Folder Structure

```
admin_app/           ← Separate Flutter project folder
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart  (same project, re-run flutterfire configure)
│   ├── models/
│   │   └── event_model.dart   (copy from main app)
│   ├── services/
│   │   ├── firestore_admin_service.dart  (read + WRITE)
│   │   └── storage_service.dart
│   └── screens/
│       ├── login_screen.dart
│       ├── event_list_screen.dart   (list + delete + toggle active)
│       └── event_form_screen.dart   (create + edit)
```

---

## Admin Screens

### Screen 1: Login Screen
```
Fields: Email, Password
Button: "Sign In"
On success: go to EventListScreen
Error: Show SnackBar with Firebase error message
No "sign up", no "forgot password"
```

### Screen 2: Event List Screen

```
AppBar: "KochiGo Admin" + "Add Event" FloatingActionButton

List of all events (including isActive: false ones):
  Each row shows:
    - Event title
    - Category chip
    - Date
    - "Active" toggle switch (isActive field)
    - Edit icon → EventFormScreen(event: event)
    - Delete icon → confirmation dialog → delete document

Filters: "All" | "Active" | "Draft" tabs at top

FAB: + Add Event → EventFormScreen(event: null)
```

### Screen 3: Event Form Screen (Create + Edit)

```
AppBar: "Add Event" or "Edit Event" + Save button (top right)

Form fields (all validated before save):

1. Image Picker
   - Large tap area showing current image or placeholder
   - "Tap to upload" text
   - On tap: image_picker → gallery or camera
   - Shows upload progress bar
   - After upload: shows thumbnail
   - Required for new events

2. Title
   TextField, required, maxLength: 80

3. Category
   DropdownButtonFormField with options:
   comedy | music | tech | fitness | art | workshop | food | kids

4. Date & Time
   Two rows: Date picker + Time picker
   Uses showDatePicker() + showTimePicker()
   Shows combined formatted date

5. Location
   TextField, required, maxLength: 100
   Hint: "Kashi Art Café, Fort Kochi"

6. Google Maps Link
   TextField, optional
   Hint: "https://maps.google.com/?q=..."
   Validator: must start with https:// if non-empty

7. Description
   TextField, multiline (minLines: 4, maxLines: 12)
   Required, maxLength: 1000

8. Price
   DropdownButtonFormField: "Free" | "₹100–500" | "₹500–1000" | "₹1000+" | "Custom"
   + If "Custom": show free-text field

9. Ticket Link
   TextField, optional
   Hint: "https://bookmyshow.com/..."

10. Organizer Name
    TextField, required

11. Contact Phone
    TextField, optional
    Hint: "+91 98765 43210"

12. Contact Instagram
    TextField, optional
    Hint: "@kochicomedy"

13. Tags (multi-select chips)
    free | popular | new | outdoor | family | limited
    Tappable chips — toggles on/off

14. Toggles:
    - "Featured Event" switch (isFeatured)
    - "Active / Visible" switch (isActive)

Save Button: Full-width at bottom
  - Validates all required fields
  - Uploads image if new/changed
  - Creates or updates Firestore document
  - Shows loading indicator during save
  - On success: Navigator.pop() + SnackBar "Event saved!"
  - On error: SnackBar with error message
```

---

## Firestore Admin Service

```dart
// admin_app/lib/services/firestore_admin_service.dart

class FirestoreAdminService {
  final _db = FirebaseFirestore.instance;

  // Create new event
  Future<String> createEvent(Map<String, dynamic> eventData) async {
    final docRef = await _db.collection('events').add({
      ...eventData,
      'createdAt': FieldValue.serverTimestamp(),
      'totalViews': 0,
    });
    return docRef.id;
  }

  // Update existing event
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Soft delete — set isActive: false
  Future<void> toggleActive(String id, bool isActive) async {
    await _db.collection('events').doc(id).update({'isActive': isActive});
  }

  // Hard delete
  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  // Get all events (admin sees everything — no isActive filter)
  Stream<List<EventModel>> getAllEventsStream() {
    return _db
      .collection('events')
      .orderBy('date', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(EventModel.fromFirestore).toList());
  }
}
```

---

## Deploying the Admin Panel

### Option A: Run Locally (Simplest)
```bash
cd admin_app
flutter run -d chrome
```
Access at `localhost:PORT`. No hosting needed — just use your laptop.

### Option B: Firebase Hosting (Free)
```bash
cd admin_app
flutter build web --release

# Install Firebase CLI if not installed
npm install -g firebase-tools
firebase login
firebase init hosting  # Select admin_app/build/web as public dir
firebase deploy
```
Access at `https://kochigo-app.web.app/admin`

> Protect the URL — don't share it publicly. The Firebase Auth login is enough security for MVP.

---

## Admin Image Upload Flow (Detailed)

```
User taps image picker
    ↓
image_picker opens gallery
    ↓
User selects image
    ↓
[Optional] image_cropper opens at 16:9 ratio
    ↓
File passed to StorageService.uploadWithProgress()
    ↓
UploadTask stream → LinearProgressIndicator in UI
    ↓
On complete → getDownloadURL() → stored as imageUrl in form state
    ↓
On form save → imageUrl included in Firestore document
```

```dart
// image_cropper usage for consistent 16:9 images
import 'package:image_cropper/image_cropper.dart';

Future<CroppedFile?> cropImage(String sourcePath) async {
  return await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
    compressQuality: 85,
    compressFormat: ImageCompressFormat.jpg,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Event Image',
        toolbarColor: const Color(0xFFFF5A35),
        toolbarWidgetColor: Colors.white,
      ),
    ],
  );
}
```
