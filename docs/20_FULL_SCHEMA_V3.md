# 🗄️ Complete Firestore Schema — KochiGo v3.0

> This is the single source of truth for ALL Firestore data structures.
> Every field, every collection, every security rule.

---

## Collection: `events` (MODIFIED from v2.0)

New fields added in v3.0 are marked ★

```
events/{eventId}

  ─── Core Info ──────────────────────────────────
  title            String       Event name (max 80 chars)
  category         String       See valid categories below
  description      String       Full description (max 1000 chars)
  date             Timestamp    Start date + time
  endDate          Timestamp?   ★ Optional end time
  location         String       Venue name + area
  mapLink          String       Google Maps URL
  
  ─── Media ──────────────────────────────────────
  imageUrl         String       Primary cover image URL (Firebase Storage)
  imageUrls        String[]     ★ All images including cover (index 0 = cover)
  
  ─── Pricing ────────────────────────────────────
  price            String       "Free" | "₹200" | "₹100–500"
  ticketLink       String?      External ticket URL
  
  ─── Contact ────────────────────────────────────
  organizer        String       Organiser display name
  contactPhone     String?      "+91XXXXXXXXXX"
  contactInstagram String?      "@handle"
  website          String?      ★ Event/organiser website
  
  ─── Tags & Metadata ────────────────────────────
  tags             String[]     ["free", "outdoor", "family"] etc.
  
  ─── Discovery ──────────────────────────────────
  isFeatured       Boolean      Shows in featured carousel (Premium tier = true)
  isActive         Boolean      Feed visibility. false = hidden
  
  ─── UGC / Posting (NEW ★) ──────────────────────
  postedBy         String       ★ Firebase UID of event creator
  postedByName     String       ★ Creator's display name (denormalized for queries)
  postedByPhotoUrl String?      ★ Creator's avatar URL (denormalized)
  isVerifiedOrg    Boolean      ★ Denormalized from user — shows verified badge
  
  ─── Tier & Payment (NEW ★) ─────────────────────
  tier             String       ★ 'basic' | 'boost' | 'premium'
  status           String       ★ See Event Status below
  paymentStatus    String       ★ 'pending' | 'paid' | 'refunded' | 'failed'
  expiresAt        Timestamp?   ★ Auto-set after payment (7 or 30 days from paid)
  razorpayPaymentId String?     ★ For admin reference
  
  ─── Analytics ──────────────────────────────────
  totalViews       Number       Incremented on detail screen open
  totalShares      Number       ★ Incremented on share action
  
  ─── Admin ──────────────────────────────────────
  adminNote        String?      ★ Admin rejection reason (visible to poster)
  reportCount      Number       ★ How many times users reported this event
  
  ─── Timestamps ─────────────────────────────────
  createdAt        Timestamp    
  updatedAt        Timestamp?   ★ Set on any admin edit
```

### Valid Categories (exact strings)
```
comedy | music | tech | fitness | art | workshop | food | kids | business | health
```

### Valid Tier Values
```
basic | boost | premium
```

### Valid Status Values (Event Lifecycle)
```
pending_payment  → Created, waiting for payment
payment_failed   → Razorpay returned failure
under_review     → Paid, waiting for admin approval
active           → Approved, visible in feed
rejected         → Admin rejected (with reason)
expired          → expiresAt timestamp passed
```

### Valid Tags
```
free | popular | new | outdoor | family | limited | registration_required | 
adults_only | indoor | parking_available | online
```

---

## Collection: `users` (NEW ★)

```
users/{uid}

  uid              String       Firebase Auth UID (= document ID)
  displayName      String       Full name
  email            String?      Null for phone-only users
  phone            String?      With country code "+91..."
  photoUrl         String?      Firebase Storage or Google photo URL
  bio              String?      Max 120 chars
  instagramHandle  String?      "@handle"
  website          String?      
  
  isVerifiedOrg    Boolean      Admin-set only. Verified organiser badge.
  
  totalEventsPosted  Number     Incremented on successful publish
  totalViews       Number       Sum of views across all their events
  
  fcmToken         String?      For push notifications (updated on app open)
  
  createdAt        Timestamp    
  lastActiveAt     Timestamp    Updated on app open
```

---

## Collection: `payments` (NEW ★)

```
payments/{autoId}

  eventId          String       Reference to events/{id}
  userId           String       Firebase UID
  tier             String       'basic' | 'boost' | 'premium'
  amount           Number       In rupees (49 | 149 | 349)
  
  razorpayPaymentId  String     From Razorpay success response
  razorpayOrderId    String?    If using Razorpay Orders API
  razorpaySignature  String?    For server-side verification (future)
  
  status           String       'captured' | 'failed' | 'refunded'
  refundReason     String?      "event_rejected" | "admin_manual"
  
  paidAt           Timestamp    
  refundedAt       Timestamp?   
```

---

## Collection: `notifications` (NEW ★)

```
notifications/{autoId}

  userId           String       Target user's UID
  type             String       See types below
  title            String       Notification heading
  body             String       Notification body
  eventId          String?      If related to an event
  isRead           Boolean      false = unread
  createdAt        Timestamp    
```

### Notification Types
```
event_approved      → "Your event '{title}' is now live!"
event_rejected      → "Your event '{title}' was not approved. Reason: {reason}"
event_expiring      → "Your event expires in 2 days. Re-boost?"
event_views_milestone → "Your event hit 100 views! 🎉"
system              → General announcements
```

---

## Collection: `reports` (NEW ★)

```
reports/{autoId}

  eventId          String       Reported event
  reportedBy       String       UID of reporter
  reason           String       'spam' | 'inappropriate' | 'fake' | 'wrong_category' | 'other'
  details          String?      Additional context
  status           String       'pending' | 'reviewed' | 'dismissed'
  createdAt        Timestamp    
```

---

## Security Rules (Complete v3.0)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─── EVENTS ────────────────────────────────────────────────
    match /events/{eventId} {
      // Anyone can read active events
      allow read: if resource.data.isActive == true 
                  || request.auth != null && request.auth.uid == resource.data.postedBy;
      
      // Logged-in users can CREATE (app handles status flow)
      allow create: if request.auth != null
                    && request.resource.data.postedBy == request.auth.uid
                    && request.resource.data.isActive == false
                    && request.resource.data.status == 'pending_payment';
      
      // Only the event poster can update LIMITED fields (draft edits before payment)
      allow update: if request.auth != null
                    && request.auth.uid == resource.data.postedBy
                    && resource.data.status == 'pending_payment'
                    // Cannot change these fields after creation:
                    && !request.resource.data.diff(resource.data)
                        .affectedKeys().hasAny([
                          'postedBy', 'isActive', 'isFeatured', 
                          'status', 'tier', 'totalViews', 'isVerifiedOrg'
                        ]);
      
      // Nobody deletes events from the app (soft delete via isActive only)
      allow delete: if false;
    }

    // ─── USERS ─────────────────────────────────────────────────
    match /users/{userId} {
      allow read: if true;
      
      allow create: if request.auth != null 
                    && request.auth.uid == userId;
      
      allow update: if request.auth != null 
                    && request.auth.uid == userId
                    // Prevent self-elevation of privileged fields
                    && !request.resource.data.diff(resource.data)
                        .affectedKeys().hasAny([
                          'isVerifiedOrg', 'totalEventsPosted', 'totalViews'
                        ]);
    }

    // ─── PAYMENTS ──────────────────────────────────────────────
    match /payments/{paymentId} {
      // Users can only see their own payments
      allow read: if request.auth != null 
                  && resource.data.userId == request.auth.uid;
      
      // App can create payment records
      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid;
      
      // No updates or deletes from app (admin-only via Firebase Console)
      allow update, delete: if false;
    }

    // ─── NOTIFICATIONS ─────────────────────────────────────────
    match /notifications/{notifId} {
      // Users can only read their own notifications
      allow read: if request.auth != null 
                  && resource.data.userId == request.auth.uid;
      
      // Users can only update isRead on their own notifications
      allow update: if request.auth != null
                    && resource.data.userId == request.auth.uid
                    && request.resource.data.diff(resource.data)
                        .affectedKeys().hasOnly(['isRead']);
      
      // Only backend (admin) can create/delete notifications
      allow create, delete: if false;
    }

    // ─── REPORTS ───────────────────────────────────────────────
    match /reports/{reportId} {
      // Logged-in users can submit reports
      allow create: if request.auth != null
                    && request.resource.data.reportedBy == request.auth.uid;
      
      // No reading reports from app (admin-only)
      allow read, update, delete: if false;
    }
  }
}
```

---

## Firestore Indexes Required (v3.0)

Create ALL of these in Firebase Console → Firestore → Indexes:

| Collection | Field 1 | Field 2 | Field 3 | Purpose |
|---|---|---|---|---|
| `events` | `isActive` ASC | `date` ASC | — | Main feed query |
| `events` | `isActive` ASC | `isFeatured` ASC | `date` ASC | Featured carousel |
| `events` | `isActive` ASC | `category` ASC | `date` ASC | Category filter |
| `events` | `postedBy` ASC | `status` ASC | `createdAt` DESC | My events (profile) |
| `events` | `status` ASC | `createdAt` DESC | — | Admin review queue |
| `events` | `tier` ASC | `isActive` ASC | `date` ASC | Boost/trending query |
| `payments` | `userId` ASC | `paidAt` DESC | — | User payment history |
| `notifications` | `userId` ASC | `createdAt` DESC | — | Notification feed |

---

## Updated EventModel (Dart — all new fields)

```dart
// lib/models/event_model.dart — ADD these fields to existing model:

// UGC fields
final String? postedBy;
final String? postedByName;
final String? postedByPhotoUrl;
final bool isVerifiedOrg;

// Tier & Payment
final String tier;          // Default: 'basic'
final String status;        // Default: 'active' for existing seeded events
final String paymentStatus; // Default: 'paid' for existing seeded events
final DateTime? expiresAt;

// Additional
final List<String> imageUrls;
final String? website;
final DateTime? endDate;
final int totalShares;

// In fromFirestore():
postedBy: d['postedBy'],
postedByName: d['postedByName'],
postedByPhotoUrl: d['postedByPhotoUrl'],
isVerifiedOrg: d['isVerifiedOrg'] ?? false,
tier: d['tier'] ?? 'basic',
status: d['status'] ?? 'active',
paymentStatus: d['paymentStatus'] ?? 'paid',
expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
imageUrls: List<String>.from(d['imageUrls'] ?? [d['imageUrl'] ?? '']),
website: d['website'],
endDate: (d['endDate'] as Timestamp?)?.toDate(),
totalShares: d['totalShares'] ?? 0,
```

---

## Migrate Existing Seed Data

After v3.0 launch, run this update on existing events in Firebase Console:
Add these fields to all existing seeded events so the EventModel doesn't fail:

```javascript
// Paste in Firebase Console browser console or in seed script
{
  "postedBy": "admin",
  "postedByName": "KochiGo Team",
  "isVerifiedOrg": true,
  "tier": "premium",
  "status": "active",
  "paymentStatus": "paid",
  "totalShares": 0,
  "imageUrls": ["<existing imageUrl value>"]
}
```
