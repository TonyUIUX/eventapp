# 🛡️ Moderation, Notifications & Admin Upgrades — KochiGo v3.0

---

## 1. Event Moderation System

### Why It Matters
Users are now posting events directly. Without moderation:
- Spam, fake events, offensive content will appear
- Trust in the platform drops immediately
- You're legally exposed (consumer platform responsibility)

### Moderation Flow

```
Event submitted (status: under_review)
    ↓
Admin gets push notification + sees in dashboard
    ↓
Admin reviews: image, title, description, location
    ↓
APPROVE                         REJECT
    ↓                               ↓
status: 'active'           status: 'rejected'
isActive: true             adminNote: "reason"
                               ↓
                     Notification to user
                     + Optional refund
```

### Admin Review Screen (Upgrade to admin_app)

```
New screen: admin_app/lib/screens/review_queue_screen.dart

Shows events with status == 'under_review', sorted by createdAt ASC

Each item shows:
  - Event image (large preview)
  - Title, category, date, location
  - Tier badge (Basic / Boost / Premium)
  - Poster name + their past event count
  - Full description
  - "Approve" (green) and "Reject" (red) buttons

On Approve:
  events/{id}.status = 'active'
  events/{id}.isActive = true
  → Creates notification doc for user
  → (Optional) Sends FCM push notification

On Reject:
  Shows dialog: "Reason for rejection"
    Options: Spam | Fake event | Inappropriate content | Wrong category | Other
    + optional free-text field
  events/{id}.status = 'rejected'
  events/{id}.adminNote = reason
  → Creates notification doc for user
  → (Optional) Trigger refund in Razorpay dashboard manually

Admin Dashboard stats (add to existing):
  - Pending Review: {count} (badge in nav)
  - Today's Revenue: ₹{sum}
  - Active Events: {count}
  - Total Users: {count}
```

### Moderation Service (admin_app)

```dart
// admin_app/lib/services/moderation_service.dart

class ModerationService {
  final _db = FirebaseFirestore.instance;

  // Get pending events
  Stream<List<EventModel>> getPendingEvents() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'under_review')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(EventModel.fromFirestore).toList());
  }

  Future<void> approveEvent(String eventId) async {
    final batch = _db.batch();
    
    final eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'status': 'active',
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Get event to find userId
    final eventDoc = await eventRef.get();
    final event = EventModel.fromFirestore(eventDoc);
    
    if (event.postedBy != null) {
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': event.postedBy,
        'type': 'event_approved',
        'title': 'Your event is LIVE! 🎉',
        'body': '"${event.title}" is now visible to everyone in Kochi.',
        'eventId': eventId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> rejectEvent(String eventId, String reason) async {
    final batch = _db.batch();
    
    final eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'status': 'rejected',
      'isActive': false,
      'adminNote': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    final eventDoc = await eventRef.get();
    final event = EventModel.fromFirestore(eventDoc);
    
    if (event.postedBy != null) {
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': event.postedBy,
        'type': 'event_rejected',
        'title': 'Event not approved',
        'body': '"${event.title}" was not approved. Reason: $reason. Contact us if you think this is a mistake.',
        'eventId': eventId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
```

---

## 2. Notifications Screen (User App)

### New Screen

```
lib/screens/notifications/notifications_screen.dart

AppBar: "Notifications" + "Mark all read" action

Stream of notifications where userId == current user's UID
Sorted by createdAt DESC

Each notification item:
  - Unread: coral left border + light coral bg
  - Read: normal white bg
  - Icon based on type:
      event_approved → ✅ green
      event_rejected → ❌ red
      event_expiring → ⏰ amber
      event_views_milestone → 🔥 orange
      system → 📣 blue
  - Title (bold if unread)
  - Body text (2 lines, ellipsis)
  - Relative time ("2 hours ago" via timeago package)
  - Tap → navigate to relevant event OR profile
  - Tap → marks as read (isRead: true)

Empty state: "No notifications yet"
```

### Badge Count on Bottom Nav

```dart
// Show unread count badge on notification tab icon

final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0);
  
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);
});

// In bottom nav:
Badge(
  isLabelVisible: unreadCount > 0,
  label: Text('$unreadCount'),
  child: Icon(Icons.notifications_outlined),
)
```

---

## 3. Report Event Feature (User App)

### Where
Three-dot menu (⋮) on EventDetailScreen → "Report this event"

```dart
// Bottom sheet with options:
// Spam or misleading
// Fake event / doesn't exist
// Inappropriate content
// Wrong category
// Other (free text)

// On submit: creates reports/{autoId} document
// Shows SnackBar: "Report submitted. We'll review within 24 hours."
// Does NOT hide the event for the reporting user
```

---

## 4. Re-boost Feature (Event Renewal)

When a user's event expires, they can pay again to re-activate it.

### Where
ProfileScreen → Expired Events tab → "Re-boost →" chip

### Flow
```
User taps "Re-boost →" on expired event
    ↓
Goes to TierSelectionScreen (same as Step 5 of posting flow)
  BUT: shows existing event preview, not a form
    ↓
Selects new tier (can upgrade or downgrade)
    ↓
Razorpay payment
    ↓
On success:
  events/{id}.status = 'under_review'
  events/{id}.isActive = false
  events/{id}.paymentStatus = 'paid'
  events/{id}.tier = newTier
  events/{id}.isFeatured = newTier == 'premium'
  events/{id}.expiresAt = now + 7 or 30 days
  → Admin reviews again (quick review, likely to approve)
```

---

## 5. Event Edit Feature

Users can edit their event ONLY if status is `under_review` or `active`.
Cannot edit: tier, paymentStatus, postedBy, createdAt.

```dart
// On EventDetailScreen — show "Edit" button in AppBar 
// ONLY if current user's UID == event.postedBy

// Navigate to PostEventScreen pre-filled with existing event data
// Show confirmation before saving: "Edits will be reviewed again by our team"
// On save: status stays 'active' if minor edit, OR goes to 'under_review' if image/title changed

// For v3.0 simplicity: all edits go to under_review (event is hidden while under review)
// Future v4: quick edits (price, contact) don't require review
```

---

## 6. User-Facing Event Status Indicators

On EventCard and ProfileScreen, show status clearly:

```dart
// In EventCard (only shown on ProfileScreen / poster's view, not public feed)

String statusText;
Color statusColor;

switch (event.status) {
  case 'under_review':
    statusText = '🕐 Under Review';
    statusColor = Colors.amber;
    break;
  case 'rejected':
    statusText = '❌ Not Approved';
    statusColor = Colors.red;
    break;
  case 'expired':
    statusText = '💤 Expired';
    statusColor = Colors.grey;
    break;
  case 'active':
    // Show expiry date if within 2 days
    final daysLeft = event.expiresAt?.difference(DateTime.now()).inDays ?? 99;
    if (daysLeft <= 2) {
      statusText = '⚠️ Expires in ${daysLeft}d';
      statusColor = Colors.orange;
    }
    break;
}
```
