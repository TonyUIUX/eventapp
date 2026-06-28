import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── GoogleSignIn instance ────────────────────────────────────────────────
  // serverClientId is the OAuth 2.0 Web Client ID from Firebase Console →
  // Authentication → Sign-in method → Google → Web SDK configuration →
  // "Web client ID".  It looks like: XXXXXX.apps.googleusercontent.com
  //
  // WHY REQUIRED: Firebase Auth on Android needs the idToken signed by the
  // server client. Without it signInWithCredential() throws DEVELOPER_ERROR.
  //
  // ⚠️  Replace the placeholder below with your actual Web Client ID.
  static const String _webClientId =
      '179045522471-dnfrbpj3pvl3lsv4hmiumikj6pv3c68j.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId ensures we get back an idToken that Firebase can verify.
    serverClientId: kIsWeb ? null : _webClientId,
  );

  // ── Auth state ────────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get uid => currentUser?.uid;
  bool get isLoggedIn => currentUser != null;

  // ── Google Sign-In ────────────────────────────────────────────────────────
  /// Returns [UserCredential] on success, [null] if the user cancelled.
  /// Throws [FirebaseAuthException] or [PlatformException] on real errors.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ── Web: popup flow ────────────────────────────────────────────────
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserProfile(userCredential.user!);
        }
        return userCredential;
      } else {
        // ── Mobile: native Google account picker ───────────────────────────
        // Force account selection every time so users aren't locked to one
        // account.  Disconnect first (no-op if not signed in).
        await _googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // User tapped "Back" / cancelled the picker — not an error.
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Both tokens are required; if either is null the credential is invalid.
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'google-sign-in-failed',
            message:
                'Could not retrieve Google authentication tokens. '
                'Ensure the OAuth Web Client ID is configured correctly.',
          );
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserProfile(userCredential.user!);
        } else {
          // Update lastActiveAt for returning users.
          await _updateLastActive(userCredential.user!.uid);
        }

        return userCredential;
      }
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      debugPrint('[AuthService] Google sign-in PlatformException: ${e.code} — ${e.message}');
      // Convert PlatformException codes to FirebaseAuthException so callers
      // only have to handle one exception type.
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_failed') {
        // User cancelled — treat as null return instead of an error.
        return null;
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.message ?? 'Google Sign-In failed. Please try again.',
      );
    } catch (e) {
      debugPrint('[AuthService] Google sign-in unknown error: $e');
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In failed. Please try again.',
      );
    }
  }

  // ── Email / Password Sign-Up ──────────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name in Firebase Auth AND Firestore atomically.
      await Future.wait([
        userCredential.user!.updateDisplayName(displayName.trim()),
        _createUserProfile(userCredential.user!, nameOverride: displayName.trim()),
      ]);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] SignUp error: ${e.code} — ${e.message}');
      rethrow;
    }
  }

  // ── Email / Password Sign-In ──────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _updateLastActive(cred.user!.uid);
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] SignIn error: ${e.code} — ${e.message}');
      rethrow;
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Phone Auth ────────────────────────────────────────────────────────────
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on Android (SMS auto-read).
        try {
          final cred = await _auth.signInWithCredential(credential);
          if (cred.additionalUserInfo?.isNewUser ?? false) {
            await _createUserProfile(cred.user!);
          }
        } catch (e) {
          debugPrint('[AuthService] Auto phone sign-in error: $e');
        }
      },
      verificationFailed: onFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('[AuthService] Phone code auto-retrieval timeout');
      },
    );
  }

  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    if (userCred.additionalUserInfo?.isNewUser ?? false) {
      await _createUserProfile(userCred.user!);
    } else {
      await _updateLastActive(userCred.user!.uid);
    }
    return userCred;
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      // Disconnect Google so the account picker appears fresh next sign-in.
      if (!kIsWeb) {
        await _googleSignIn.disconnect().catchError(
          (_) => _googleSignIn.signOut(),
        );
      }
    } catch (_) {
      // Ignore Google sign-out errors — Firebase sign-out is what matters.
    }
    await _auth.signOut();
  }

  // ── Account Deletion ──────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // 1. Delete user document from Firestore
      await _db.collection('users').doc(user.uid).delete();
      
      // 2. Delete the auth user
      await user.delete();
      
      // 3. Disconnect from Google (if applicable)
      if (!kIsWeb) {
        await _googleSignIn.disconnect().catchError((_) => null);
      }
    } catch (e) {
      throw Exception('Failed to delete account. Please try re-authenticating first.');
    }
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────
  Future<void> _createUserProfile(User user, {String? nameOverride}) async {
    final uid = user.uid;
    final docRef = _db.collection('users').doc(uid);

    await docRef.set({
      'uid': uid,
      'displayName': nameOverride ?? user.displayName ?? 'New User',
      'email': user.email,
      'phone': user.phoneNumber,
      'photoUrl': user.photoURL,
      'bio': '',
      'instagramHandle': '',
      'website': '',
      'isVerifiedOrg': false,
      'totalEventsPosted': 0,
      'totalViews': 0,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateLastActive(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-critical — don't block sign-in flow.
    }
  }
}
