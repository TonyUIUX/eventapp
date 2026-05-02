# 📝 Event Posting Flow — KochiGo v3.0

> This is the core UGC feature. The entire monetisation depends on this flow being smooth.
> Think of it as Instagram's "Create Post" — but for events, with a payment step.

---

## Flow Overview

```
Tab 2 tap (✚)
    ↓
[Not logged in?] → LoginSheet → return here after login
    ↓
Step 1: Event Basics      (title, category, date/time)
    ↓
Step 2: Details           (description, location, map link, price/ticket)
    ↓
Step 3: Media             (cover image — required, optional gallery images)
    ↓
Step 4: Contact & Tags    (organiser name, phone, instagram, tags)
    ↓
Step 5: Choose Tier       (Basic ₹49 / Boost ₹149 / Premium ₹349)
    ↓
Step 6: Payment           (Razorpay checkout)
    ↓
Step 7: Success Screen    ("Your event is under review! Goes live in ~24h")
```

---

## Navigation Architecture

Use a single `PostEventScreen` as a shell with `PageView` for steps.
Do NOT use named routes for each step — state would be lost on back navigation.

```dart
// lib/screens/post_event/post_event_screen.dart

class PostEventScreen extends ConsumerStatefulWidget {
  // Holds PostEventFormData (accumulated across steps)
  // PageController to move between steps
  // Progress indicator at top (step X of 5)
  // "Save Draft" option in AppBar (writes to SharedPreferences as JSON)
}

// Form data accumulator
class PostEventFormData {
  String? title;
  String? category;
  DateTime? eventDate;
  TimeOfDay? eventTime;
  DateTime? endDate;       // Optional
  String? description;
  String? location;
  String? mapLink;
  String? price;
  String? ticketLink;
  File? coverImage;
  List<File> galleryImages = [];
  String? organizerName;
  String? contactPhone;
  String? contactInstagram;
  List<String> tags = [];
  String selectedTier = 'basic'; // 'basic' | 'boost' | 'premium'
}
```

---

## Step 1: Event Basics

```
AppBar: "Create Event" | ✕ close button | Step 1 of 5

Fields:

1. Event Title *
   TextField
   Hint: "e.g. Open Mic Night at Kashi Café"
   maxLength: 80, counter shown
   Validation: required, min 5 chars

2. Category *
   Grid of category cards (NOT a dropdown — more visual)
   2 columns × N rows, each card has emoji + label
   Categories: Comedy 😂 | Music 🎵 | Tech 💻 | Fitness 🏃 | Art 🎨 | 
               Workshop 🛠️ | Food 🍽️ | Kids 🧒 | Business 💼 | Health 🧘
   Selected card: coral border + coral background tint

3. Date & Time *
   Date row: calendar icon + "Select date" → showDatePicker()
   Time row: clock icon + "Select start time" → showTimePicker()
   End time row (optional): toggle "Add end time"
   
   Validation: date must be FUTURE (today or later)
   Show formatted preview: "Saturday, 19 April 2026 · 7:00 PM – 10:00 PM"

NEXT button at bottom (full width, coral, 52px)
  Validates all Step 1 fields before advancing
```

---

## Step 2: Event Details

```
AppBar: ← back | "Event Details" | Step 2 of 5

Fields:

1. Description *
   Multiline TextField
   Hint: "Tell people what this event is about, what to expect, and why they should come..."
   minLines: 5, maxLines: unlimited (scrollable)
   maxLength: 1000, counter shown
   Validation: required, min 30 chars

2. Location *
   TextField
   Hint: "Kashi Art Café, Fort Kochi"
   maxLength: 100
   Validation: required

3. Google Maps Link (optional)
   TextField with map icon prefix
   Hint: "Paste Google Maps link"
   Helper text: "Open Google Maps → Search venue → Share → Copy link"
   Validation: if non-empty, must start with https://

4. Entry Price *
   Segmented selector:
   [FREE] [PAID]
   
   If FREE: price = "Free", no more fields
   If PAID: 
     TextField: "Enter price or range"
     Hint: "₹200" or "₹100–₹500"
     + optional TextField: "Ticket booking link"
     Hint: "BookMyShow / Insider / direct link"

NEXT button
```

---

## Step 3: Event Media

```
AppBar: ← back | "Add Photos" | Step 3 of 5

Cover Image (REQUIRED):
  - Large dashed-border box (16:9 area)
  - Icon: 📷 + "Add Cover Photo"
  - Subtext: "This is the main image users will see. 16:9 ratio recommended."
  - On tap: showModalBottomSheet with options:
      📷 Take Photo (camera)
      🖼️ Choose from Gallery
  - After selection: open ImageCropper at 16:9 ratio
  - After crop: shows preview in the box
  - Tap preview: shows "Change" / "Remove" options

Gallery Images (OPTIONAL, max 4):
  - Section: "More photos (optional)"
  - Row of + boxes (tap each to add)
  - Show thumbnails when added
  - Long press to remove
  - These go in event.imageUrls array (first = cover)

File constraints:
  - Max 5MB per image
  - Compress to 85% quality via image_picker
  - Crop to 16:9 for cover, free crop for gallery

NEXT button
  Validation: cover image is required
```

---

## Step 4: Contact & Tags

```
AppBar: ← back | "Organiser & Tags" | Step 4 of 5

1. Organiser Name *
   Pre-filled with user's displayName (editable)
   maxLength: 60

2. Contact Phone (optional)
   TextField with +91 prefix
   Hint: "98765 43210"
   Note: "Visible to event seekers"

3. Contact Instagram (optional)  
   TextField with @ prefix
   Hint: "kochicomedy"

4. Event Tags (select all that apply)
   Multi-select chips in a Wrap layout:
   🆓 Free Entry | 🔥 Popular | ✨ New | 🌿 Outdoor | 
   👨‍👩‍👧 Family Friendly | ⚡ Limited Seats | 🎟️ Registration Required |
   🍺 21+ Only | 🌧️ Indoor | 🚗 Parking Available

   User can select 0 to any number of tags.
   Selected: filled coral chip
   Unselected: outlined chip

5. Website / Event Page (optional)
   TextField
   Hint: "https://your-event-page.com"

NEXT → "Choose Plan" button
  Validation: organiser name required
```

---

## Step 5: Choose Tier

```
AppBar: ← back | "Choose Plan" (no step counter — this is the CTA page)
  
Heading: "How far do you want to reach?"
Subheading: "Your event gets reviewed and goes live within 24 hours."

3 Tier Cards (full width, stacked vertically):

┌──────────────────────────────────────┐
│ BASIC                    ₹49         │
│ ─────────────────────────────────    │
│ ✓ Listed in main feed                │
│ ✓ Visible in category filter         │
│ ✓ Shareable event page               │
│ ✗ Not in Trending or Featured        │
│                          7 DAYS      │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐  ← MOST POPULAR badge
│ 🔥 BOOST                 ₹149        │
│ ─────────────────────────────────    │
│ ✓ Everything in Basic                │
│ ✓ Trending section placement         │
│ ✓ Top of category filter             │
│ ✓ "Trending" badge on card           │
│                          7 DAYS      │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ ⭐ PREMIUM                ₹349        │
│ ─────────────────────────────────    │
│ ✓ Everything in Boost                │
│ ✓ Featured carousel slot             │
│ ✓ "PROMOTED" gold badge              │
│ ✓ Priority in All events             │
│ ✓ 30-day visibility (4× longer)      │
│                         30 DAYS      │
└──────────────────────────────────────┘

Selected tier: coral border + checkmark

"Proceed to Payment →" button (full width, 56px, coral)
Shows: "₹49 via UPI, Cards, Net Banking" (dynamic based on selection)

Fine print: "Payment is non-refundable unless your event is rejected by our team."
```

---

## Step 6: Payment (Razorpay)

```
This step triggers Razorpay checkout (NOT a custom screen).
The Razorpay SDK shows its own native payment sheet.

On "Proceed to Payment" tap:
  1. Create Firestore event document with status: 'pending_payment'
  2. Open Razorpay with the event doc ID as order ID
  3. Razorpay sheet appears (UPI, cards, net banking, wallets)
  4. On payment success → update Firestore status to 'under_review'
  5. Close Razorpay → navigate to SuccessScreen
  6. On payment failure → show error SnackBar, stay on tier screen (keep form data)
```

---

## Step 7: Success Screen

```
Full screen, coral gradient background

Large checkmark animation (AnimatedContainer or Lottie if available)

"Your event is submitted! 🎉"
"Under Review"

Body text:
  "Our team will review your event within 24 hours.
   You'll get a notification once it goes live.
   
   Event: {eventTitle}
   Tier: Boost · 7 Days
   Amount paid: ₹149"

Two buttons:
  "View My Events" → ProfileScreen (My Events tab)
  "Go to Home" → HomeScreen (pop to root)
```

---

## Draft Save Feature

If user exits mid-flow (taps back or ✕), show dialog:
```
"Save as draft?"
"Your event details will be saved. You can continue later."
[Save Draft] [Discard]
```

On "Save Draft": serialise PostEventFormData to JSON → save in SharedPreferences key `post_event_draft`

On next time user taps ✚ Post Event: check for draft → show banner:
```
"You have an unfinished event draft. [Continue] [Discard]"
```

---

## Firestore Write: Creating the Event Document

```dart
// lib/services/event_post_service.dart

class EventPostService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> createEventDraft(
    PostEventFormData formData,
    String userId,
  ) async {
    // Step 1: Upload cover image FIRST, get URL
    final imageUrl = await _uploadCoverImage(
      formData.coverImage!,
      'temp_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Step 2: Create Firestore document
    final docRef = await _db.collection('events').add({
      'title': formData.title,
      'category': formData.category,
      'date': Timestamp.fromDate(formData.eventDate!),
      'description': formData.description,
      'location': formData.location,
      'mapLink': formData.mapLink ?? '',
      'imageUrl': imageUrl,
      'price': formData.price ?? 'Free',
      'ticketLink': formData.ticketLink,
      'organizer': formData.organizerName,
      'contactPhone': formData.contactPhone,
      'contactInstagram': formData.contactInstagram,
      'tags': formData.tags,
      'isFeatured': formData.selectedTier == 'premium',
      'tier': formData.selectedTier,
      'isActive': false,           // NOT active until paid + approved
      'status': 'pending_payment', // Lifecycle status
      'postedBy': userId,
      'postedByName': formData.organizerName,
      'paymentStatus': 'pending',
      'expiresAt': null,           // Set after payment success
      'totalViews': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> markPaymentSuccess({
    required String eventId,
    required String tier,
    required String razorpayPaymentId,
  }) async {
    final durationDays = tier == 'premium' ? 30 : 7;
    final expiresAt = DateTime.now().add(Duration(days: durationDays));

    await _db.collection('events').doc(eventId).update({
      'status': 'under_review',
      'paymentStatus': 'paid',
      'expiresAt': Timestamp.fromDate(expiresAt),
      'razorpayPaymentId': razorpayPaymentId,
    });

    // Also log in payments collection
    await _db.collection('payments').add({
      'eventId': eventId,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'tier': tier,
      'amount': {'basic': 49, 'boost': 149, 'premium': 349}[tier],
      'razorpayPaymentId': razorpayPaymentId,
      'status': 'captured',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }
}
```
