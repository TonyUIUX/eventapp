# 🔬 Functional Integration Test Guide — KochiGo

> For Antigravity reference. Covers every live connection:
> Firebase Auth · Firestore CRUD · Storage · Razorpay · Config · FCM

---

## Test Environment Setup

```
Firestore: Real project (NOT emulator) — test against live Firebase
Razorpay: Test mode keys via --dart-define
Flutter: Debug build (flutter run)

Firestore test event IDs to have ready:
  event_active_001    → status: active, isActive: true
  event_pending_001   → status: under_review, isActive: false
  event_expired_001   → status: expired, isActive: false

Test users (create in Firebase Console → Auth):
  user_a@test.com / Test@1234   → Regular user
  org_b@test.com / Test@1234    → isVerifiedOrg: true in users collection
```

---

## DB Read/Write Contract (Quick Reference)

```
READ  events/       → where isActive==true AND status=='active'
WRITE events/       → authenticated only, postedBy==uid, isActive=false on create
READ  users/{uid}   → public
WRITE users/{uid}   → own doc only, cannot touch isVerifiedOrg/totalEventsPosted
WRITE payments/     → authenticated, userId==uid
READ  payments/     → own records only
WRITE notifications/→ users update isRead only
WRITE reports/      → authenticated, reportedBy==uid
READ  app_config/   → public, no write from app
```
