# 🔐 Authentication & User Profiles — KochiGo v3.0

---

## Auth Strategy

Three sign-in methods (in priority order):

| Method | Why |
|---|---|
| **Google Sign-In** | Fastest — 1 tap, most used in India, zero typing |
| **Phone (OTP)** | Fallback for users without Google account; very Indian-market friendly |
| **Email + Password** | For organisers who want a "business" account separate from personal Google |

Firebase Auth handles all three. No custom auth server needed.

---

## New Packages

```yaml
firebase_auth: ^5.x.x
google_sign_in: ^6.x.x
```

---

## Firestore: `users` Collection

```
users/{uid}/
  uid              String     Firebase Auth UID (same as document ID)
  displayName      String     Full name
  email            String?    Email (null for phone-only users)
  phone            String?    Phone with country code
  photoUrl         String?    Profile picture URL (Firebase Storage or Google photo)
  bio              String?    Short bio, max 120 chars. e.g. "Comedy show organiser, Fort Kochi"
  instagramHandle  String?    "@handle" — for organiser branding
  website          String?    Optional URL
  isVerifiedOrg    Boolean    Admin-set. Shows ✓ badge on profile and event cards.
  totalEventsPosted  Number   Incremented on each successful publish
  totalViews       Number     Sum of views across all their events
  createdAt        Timestamp
  lastActiveAt     Timestamp
```

---

## Auth Service

```dart
// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  // Reactive stream — app rebuilds on auth state change
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  // ─── GOOGLE SIGN IN ───────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      // Create user profile in Firestore if new user
      if (userCred.additionalUserInfo?.isNewUser == true) {
        await _createUserProfile(
          uid: userCred.user!.uid,
          displayName: userCred.user!.displayName ?? 'Kochi User',
          email: userCred.user!.email,
          photoUrl: userCred.user!.photoURL,
        );
      }

      return userCred;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  // ─── EMAIL + PASSWORD ─────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCred.user!.updateDisplayName(displayName);

    await _createUserProfile(
      uid: userCred.user!.uid,
      displayName: displayName,
      email: email,
    );

    return userCred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── PHONE OTP ────────────────────────────────────────────────
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onAutoVerified,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // e.g. "+919876543210"
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    final userCred = await _auth.signInWithCredential(credential);

    if (userCred.additionalUserInfo?.isNewUser == true) {
      await _createUserProfile(
        uid: userCred.user!.uid,
        displayName: 'Kochi User',
        phone: phoneNumber,
      );
    }

    return userCred;
  }

  // ─── SIGN OUT ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── INTERNAL ─────────────────────────────────────────────────
  Future<void> _createUserProfile({
    required String uid,
    required String displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': null,
      'instagramHandle': null,
      'website': null,
      'isVerifiedOrg': false,
      'totalEventsPosted': 0,
      'totalViews': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## Auth Provider (Riverpod)

```dart
// lib/providers/auth_provider.dart

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Reactive current user stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// Current user profile from Firestore
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
```

---

## AuthGate Widget

```dart
// lib/core/auth_gate.dart
// Use this to wrap any action that requires login

class AuthGate extends ConsumerWidget {
  final Widget child;
  final String reason; // e.g. "to post events" / "to save events"

  const AuthGate({required this.child, this.reason = '', super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user != null ? child : _LoginPromptSheet(reason: reason),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => child,
    );
  }
}

// Shows a bottom sheet with Google sign-in + "Create account" option
// Does NOT navigate away — sheet appears over current screen
```

---

## Screens

### Screen: AuthScreen (full page)

Used when user explicitly navigates to login (e.g. taps Profile tab while logged out).

```
Layout (top to bottom):
  1. KochiGo logo + tagline: "Kochi's Event Community"
  2. Tab bar: "Sign In" | "Create Account"
  
  SIGN IN TAB:
    - [G] "Continue with Google" button (priority — white card, Google logo)
    - Divider with "or"
    - Email TextField
    - Password TextField (obscured, show/hide toggle)
    - "Forgot password?" text link → sends reset email
    - "Sign In" filled button
    - Below: "New to KochiGo? Create account"

  CREATE ACCOUNT TAB:
    - [G] "Sign up with Google" button
    - Divider with "or"
    - Full Name TextField
    - Email TextField
    - Password TextField
    - Confirm Password TextField
    - "Create Account" filled button
    - Terms text: "By creating an account, you agree to our Terms & Privacy Policy"

  PHONE TAB (accessible via "Use phone number" text button below tabs):
    - Phone number field with +91 prefix
    - "Send OTP" button
    - → OTP screen (6-digit input with auto-focus and timer)
```

### Screen: ProfileScreen

```
Layout:
  1. Header Section:
     - Profile photo (circular, 80px) — tappable to change
     - Display name (large, bold)
     - Bio (if set, grey text)
     - Stats row: [Events Posted: 3] [Total Views: 1.2K]
     - "Edit Profile" outlined button
     - Instagram link (if set)

  2. My Events Section:
     - Tab bar: "Active (2)" | "Pending (1)" | "Expired (0)"
     - Each tab shows EventCard (same widget, reused)
     - Active events: show views count + expiry date chip
     - Pending events: show "Under Review" amber badge + "Est. review in 24h"
     - Expired events: show "Re-boost →" action chip that starts payment flow

  3. Saved Events Section:
     - Existing saved events list (moved from bottom nav to profile)

  4. Account Section:
     - "Share my profile" row
     - "Notification preferences" row
     - "Help & Support" row
     - "Sign Out" row (red text)
```

### Screen: EditProfileScreen

```
Fields:
  - Profile photo (image_picker)
  - Display Name
  - Bio (max 120 chars, character counter)
  - Instagram Handle
  - Website URL
  - Phone (optional, for contact)

Save button: top-right AppBar action
Writes directly to users/{uid} in Firestore
```

### Screen: PublicProfileScreen

Shown when tapping "More from this organizer" on EventDetailScreen.

```
Same as ProfileScreen but:
  - No "Edit Profile" button
  - No Saved Events section
  - Shows organizer's active events only
  - "Follow" button (v4 feature — placeholder for now, shows but does nothing)
```

---

## UserModel

```dart
// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String? instagramHandle;
  final String? website;
  final bool isVerifiedOrg;
  final int totalEventsPosted;
  final int totalViews;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.email,
    this.phone,
    this.photoUrl,
    this.bio,
    this.instagramHandle,
    this.website,
    required this.isVerifiedOrg,
    required this.totalEventsPosted,
    required this.totalViews,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: d['displayName'] ?? 'User',
      email: d['email'],
      phone: d['phone'],
      photoUrl: d['photoUrl'],
      bio: d['bio'],
      instagramHandle: d['instagramHandle'],
      website: d['website'],
      isVerifiedOrg: d['isVerifiedOrg'] ?? false,
      totalEventsPosted: d['totalEventsPosted'] ?? 0,
      totalViews: d['totalViews'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
```

---

## Security Rules Update for Users Collection

```
match /users/{userId} {
  // Anyone can read public profiles
  allow read: if true;
  
  // Only the user themselves can write their own profile
  allow write: if request.auth != null && request.auth.uid == userId;
  
  // Prevent users from setting isVerifiedOrg to true themselves
  allow update: if request.auth != null 
    && request.auth.uid == userId
    && !request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(['isVerifiedOrg', 'totalEventsPosted', 'totalViews']);
}
```
