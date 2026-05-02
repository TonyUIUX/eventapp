# 📝 Event Posting Flow v2 — KochiGo v3.1

> ⚠️ THIS DOC SUPERSEDES `18_EVENT_POSTING_FLOW.md`
> The 3-tier (Basic/Boost/Premium) system is REMOVED.
> Replaced with a single flat fee controlled by `app_config/pricing`.
> Payment step is CONDITIONAL — skipped entirely when isFreePeriod = true.

---

## Simplified Flow Overview

```
                    ┌─────────────────────────────┐
                    │  User taps ✚ (Post Event)   │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  Logged in?                 │
                    │  NO → LoginSheet → return   │
                    └─────────────┬───────────────┘
                                  │ YES
                    ┌─────────────▼───────────────┐
                    │  STEP 1: Event Basics        │
                    │  Title, Category, Date/Time  │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  STEP 2: Event Details       │
                    │  Description, Location,      │
                    │  Price, Booking Link         │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  STEP 3: Media               │
                    │  Cover photo (required)      │
                    │  Gallery photos (optional)   │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  STEP 4: Contact & Tags      │
                    │  Organiser info, event tags  │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  STEP 5: Review & Submit     │  ← NEW (replaces tier selection)
                    │  Summary + fee display       │
                    └─────────────┬───────────────┘
                                  │
                   ┌──────────────┴──────────────┐
     isFreePeriod=true              isFreePeriod=false
     paymentEnabled=false           paymentEnabled=true
                   │                             │
      ┌────────────▼──────────┐   ┌─────────────▼────────────┐
      │ Submit directly       │   │ STEP 6: Payment          │
      │ (no payment)          │   │ Razorpay (dynamic price) │
      └────────────┬──────────┘   └─────────────┬────────────┘
                   │                             │
                   └──────────────┬──────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  SUCCESS SCREEN              │
                    │  "Under review — live in 24h"│
                    └─────────────────────────────┘
```

**Key difference from v1:** 4 content steps + 1 review step + conditional payment. Simpler, faster, less intimidating for first-time posters.

---

## Progress Indicator

```dart
// Top of PostEventScreen — step counter
// When free:  ●●●●○  (4 filled, 1 empty — no payment dot)
// When paid:  ●●●●●  (5 dots including payment)

// Steps:
const freeStepLabels  = ['Basics', 'Details', 'Media', 'Contact', 'Review'];
const paidStepLabels  = ['Basics', 'Details', 'Media', 'Contact', 'Payment'];

// Show step number: "Step 2 of 5"
// Below: step label ("Event Details")
```

---

## Step 1: Event Basics

```
AppBar: "Create Event"  |  ✕ close  |  "Step 1 of 5"

1. Event Title *
   TextField
   Hint: "e.g. Open Mic Night at Kashi Café"
   maxLength: 80 chars, live counter
   Validation: required, min 5 chars

2. Category *  
   Visual grid (2 columns) — tap to select ONE:
   😂 Comedy    🎵 Music     💻 Tech      🏃 Fitness
   🎨 Art       🛠️ Workshop  🍽️ Food      🧒 Kids
   💼 Business  🧘 Health
   
   Selected: coral border + coral tint + ✓ overlay
   Validation: required — must select one

3. Event Date *
   Row: 📅 icon + "Select date" placeholder → showDatePicker()
   Minimum date: today (cannot post past events)
   
4. Start Time *
   Row: 🕐 icon + "Select start time" → showTimePicker()
   
5. End Time (optional)
   Toggle: "Add end time" switch
   If ON: shows time picker
   
   Live preview chip (appears below when date+time set):
   "Saturday, 19 Apr · 7:00 PM – 10:00 PM"  (green chip)

NEXT → "Event Details" button
```

---

## Step 2: Event Details

```
AppBar: ← back  |  "Event Details"  |  Step 2 of 5

1. Description *
   Multiline TextField
   Hint: "Tell people what to expect, who it's for, and why they should come..."
   minLines: 5, scrollable
   maxLength: 1000 chars, live counter
   Validation: required, min 50 chars

2. Venue Name *
   TextField
   Hint: "Kashi Art Café, Fort Kochi"

3. Google Maps Link  (optional but strongly encouraged)
   TextField with 📍 prefix
   Hint: "Paste Google Maps share link"
   Helper text below: "Open Google Maps → find your venue → tap Share → Copy link"
   Validation: if non-empty → must start with https://

4. Event Entry ─────────────────────────────────────
   Label: "Is this event free or paid?"
   Toggle: [FREE] [PAID]  (segmented control)

   If FREE selected:
     → price field = "Free", no more fields in this section

   If PAID selected:
     → TextField: "Ticket price or range"
       Hint: "₹200" or "₹150–₹400" or "Pay at door"
     → TextField: "Booking / Ticket Link"  ← IMPORTANT UX PRIORITY
       Hint: "BookMyShow, Insider, Paytm, or direct link"
       Label: "Where can people buy tickets?"
       Subtext: "Users tap this to book. Supports any URL."
       Validation: if entered → valid URL

   Even for FREE events — show optional field:
     "Event registration link (optional)"
     Hint: "Eventbrite, Google Form, or any link"
     Subtext: "Add if users need to register in advance"

NEXT button
```

---

## Step 3: Event Media

```
AppBar: ← back  |  "Add Photos"  |  Step 3 of 5

Cover Photo (REQUIRED):
  Large dashed-border container (full width, 16:9 aspect ratio)
  Empty state: 
    📷 icon (large, grey)
    "Add Cover Photo"
    "The first thing people see. Make it count."
    [Choose from Gallery]  [Take Photo]
  
  After upload:
    Shows cropped 16:9 preview
    Bottom bar: [Change Photo] [Remove]
  
  Auto-cropped to 16:9 via ImageCropper after selection.
  Compress to 85% quality, max 1200px width.

Additional Photos (OPTIONAL, max 3):
  Section header: "More photos"  +  "Optional"  chip
  Row of 3 dashed boxes (80×80px squares)
  Each: tap to add, long-press to remove
  No crop required for gallery images

Tip card:
  💡 "Good photos get 3× more views. Use well-lit, clear images."

NEXT button
  Hard validation: cover photo is REQUIRED — shows error if missing
```

---

## Step 4: Contact & Tags

```
AppBar: ← back  |  "Contact & Tags"  |  Step 4 of 5

1. Organiser Name *
   Pre-filled with user's displayName from profile
   Editable. maxLength: 60

2. Contact Phone  (optional)
   +91 prefix fixed, free-text for number
   Note helper: "Users can call you directly about the event"

3. Instagram Handle  (optional)
   @ prefix fixed
   Hint: "kochicomedy"

4. Event Tags  (multi-select, any number)
   Subheader: "Help people find your event"
   
   Wrap of tappable chips:
   🆓 Free Entry    🔥 Popular      ✨ First Event
   🌿 Outdoor       👨‍👩‍👧 Family      ⚡ Limited Seats
   🎟️ Register First 🌧️ Indoor       🚗 Parking
   
   Selected: filled coral
   Unselected: outlined

5. Website / Event page  (optional)
   Hint: "https://..."

NEXT → "Review & Submit" button
```

---

## Step 5: Review & Submit

> This screen replaces the old Tier Selection screen.
> It shows a full summary + the current posting fee.

```
AppBar: ← back  |  "Review & Submit"  (no step label — this is the decision page)

SECTION 1: Your Event Summary Card
  ┌────────────────────────────────────────┐
  │ [Cover photo thumbnail — 16:9]         │
  │                                        │
  │ {Category chip}  {Date chip}           │
  │ {Title — bold, large}                  │
  │ 📍 {Location}                          │
  │ {Price badge}  {Tags: first 2}         │
  └────────────────────────────────────────┘
  [Edit] link (navigates back to Step 1)

SECTION 2: Posting Terms
  "What happens next:"
  ✓ Our team reviews your event (usually within 24 hours)
  ✓ Once approved, your event goes live for {eventDurationDays} days
  ✓ You'll get a notification when it's live
  ✓ You can edit contact details after posting
  
  If event has ticketLink:
  ✓ "Book tickets" button will appear on your event — driving registrations

SECTION 3: Posting Fee Box
  ┌────────────────────────────────────────┐
  │  Posting Fee                           │
  │                                        │
  │  FREE  ← if isFreePeriod               │
  │  ₹200  ← if postingFee = 200          │
  │                                        │
  │  {freePeriodReason text if free}       │
  │  "Lists your event for {days} days"    │
  │                                        │
  │  {FreePeriodEndingSoon countdown       │
  │   if applicable — amber warning}       │
  └────────────────────────────────────────┘

CTA BUTTON:
  If isFreePeriod / paymentEnabled=false:
    "Submit Event for Review →"  (coral, full width, 56px)
    Tap → directly create Firestore doc with status:'under_review' → SuccessScreen

  If paymentEnabled=true and postingFee > 0:
    "Continue to Payment →  {postingFeeLabel}"  (coral, full width, 56px)
    Tap → Razorpay opens with dynamic amount → on success → SuccessScreen

Fine print (only shown when payment required):
  "Payment is non-refundable unless your event is rejected by our team."
```

---

## Step 6: Payment (Conditional — Only When Paid)

```
This step is INVISIBLE when isFreePeriod = true.

When visible:
  Razorpay SDK opens as a native bottom sheet.
  Amount: config.postingFeePaise (fetched live from appConfigProvider)
  Description: "KochiGo — List '{eventTitle}' for {eventDurationDays} days"
  Prefilled: user's email + phone from profile

  On SUCCESS:
    → Firestore: status = 'under_review', paymentStatus = 'paid'
    → payments collection: log transaction
    → SuccessScreen

  On FAILURE:
    → Stay on Review & Submit screen
    → SnackBar: "Payment didn't go through. Try again or use a different method."
    → Event doc remains as 'pending_payment' (cleaned up after 24h by admin)
```

---

## Success Screen

```
Full screen, coral gradient

Animated checkmark (pure Flutter animation — no Lottie dependency)

"Submitted! 🎉"
"Under Review"

Details card:
  Event: {title}
  Date: {formatted date}
  Status: "Our team will review within 24 hours"
  Fee paid: "Free" or "₹200" (from config)

Two CTAs:
  Primary: "View My Events"  → ProfileScreen (My Events tab)
  Secondary: "Back to Home"  → HomeScreen (pop all)

Share prompt (subtle, not intrusive):
  "Tell people about your event!"
  → Share button → share_plus with event title + "Coming soon on KochiGo"
```

---

## PostEventFormData (Updated — No Tier Field)

```dart
// lib/screens/post_event/post_event_form_data.dart

class PostEventFormData {
  String? title;
  String? category;
  DateTime? eventDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;         // Optional
  
  String? description;
  String? location;
  String? mapLink;            // Optional
  
  String entryType = 'free';  // 'free' | 'paid'
  String? price;              // "Free" | "₹200" | "₹150–400"
  String? ticketLink;         // Booking URL (BookMyShow etc.) — optional
  String? registrationLink;   // Free event registration — optional
  
  File? coverImage;
  List<File> galleryImages = [];
  
  String? organizerName;
  String? contactPhone;
  String? contactInstagram;
  String? website;
  List<String> tags = [];
  
  // NO tier field — replaced by live config from app_config/pricing
}
```

---

## EventPostService (Updated)

```dart
// lib/services/event_post_service.dart

class EventPostService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> submitEvent({
    required PostEventFormData formData,
    required String userId,
    required int eventDurationDays,  // From AppConfigModel
    required bool requiresPayment,   // From AppConfigModel.requiresPayment
  }) async {
    // 1. Upload cover image
    final coverUrl = await _uploadImage(formData.coverImage!, userId);
    
    // 2. Upload gallery images
    final galleryUrls = <String>[];
    for (final img in formData.galleryImages) {
      galleryUrls.add(await _uploadImage(img, userId));
    }

    final expiresAt = DateTime.now().add(Duration(days: eventDurationDays));

    // 3. Create Firestore document
    final docRef = await _db.collection('events').add({
      'title': formData.title,
      'category': formData.category,
      'date': Timestamp.fromDate(_combineDateAndTime(
        formData.eventDate!, formData.startTime!)),
      'endDate': formData.endTime != null
          ? Timestamp.fromDate(_combineDateAndTime(
              formData.eventDate!, formData.endTime!))
          : null,
      'description': formData.description,
      'location': formData.location,
      'mapLink': formData.mapLink ?? '',
      'imageUrl': coverUrl,
      'imageUrls': [coverUrl, ...galleryUrls],
      'price': formData.price ?? 'Free',
      'ticketLink': formData.ticketLink,         // Booking platform URL
      'registrationLink': formData.registrationLink,
      'organizer': formData.organizerName,
      'contactPhone': formData.contactPhone,
      'contactInstagram': formData.contactInstagram,
      'website': formData.website,
      'tags': formData.tags,
      
      // Flags
      'isFeatured': false,      // Admin can manually promote later
      'isActive': false,
      
      // UGC fields
      'postedBy': userId,
      'postedByName': formData.organizerName,
      
      // Lifecycle — skip payment step if free
      'status': requiresPayment ? 'pending_payment' : 'under_review',
      'paymentStatus': requiresPayment ? 'pending' : 'free',
      
      'expiresAt': Timestamp.fromDate(expiresAt),
      'totalViews': 0,
      'totalShares': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Called after Razorpay success
  Future<void> markPaymentComplete({
    required String eventId,
    required String razorpayPaymentId,
    required int amount,
  }) async {
    final batch = _db.batch();
    
    batch.update(_db.collection('events').doc(eventId), {
      'status': 'under_review',
      'paymentStatus': 'paid',
      'razorpayPaymentId': razorpayPaymentId,
    });
    
    batch.set(_db.collection('payments').doc(), {
      'eventId': eventId,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'amount': amount,  // In rupees
      'razorpayPaymentId': razorpayPaymentId,
      'status': 'captured',
      'paidAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
  
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  
  Future<String> _uploadImage(File file, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('events/$userId/$fileName');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }
}
```

---

## Booking Link — Prominent UI on EventDetailScreen

> This is a key UX insight: the booking link is WHY organizers post.
> It must be impossible to miss on the detail screen.

```dart
// event_detail_screen.dart — between location and description

// Show this when ticketLink OR registrationLink is non-null:

Container(
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        const Color(0xFFFF5247),
        const Color(0xFFFF7A35),
      ],
    ),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.price == 'Free' ? 'FREE EVENT' : event.price!,
              style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              event.price == 'Free' ? 'Register Now' : 'Book Tickets',
              style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      ElevatedButton(
        onPressed: () => openUrl(event.ticketLink ?? event.registrationLink!),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFFF5247),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          event.price == 'Free' ? 'Register' : 'Book Now',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  ),
)

// Track this tap in AnalyticsService:
AnalyticsService.logBookingTap(event.id, event.category);
```

---

## Draft Persistence (Unchanged from v1)

```dart
// If user exits mid-flow:
// Save PostEventFormData as JSON to SharedPreferences key: 'post_event_draft'
// Note: File objects (images) cannot be serialised — save file paths instead
// On next ✚ tap: check for draft → offer [Continue Draft] or [Start Fresh]
// Draft expires after 7 days (check createdAt stored in draft JSON)
```
