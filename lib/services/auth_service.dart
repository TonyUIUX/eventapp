import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get uid => currentUser?.uid;
  bool get isLoggedIn => currentUser != null;

  // Google Sign In — handles both web (popup) and mobile (intent)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use signInWithPopup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserProfile(userCredential.user!);
        }
        return userCredential;
      } else {
        // Mobile: use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User cancelled

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserProfile(userCredential.user!);
        }

        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Google sign-in error: ${e.code} — ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Google sign-in unknown error: $e');
      rethrow;
    }
  }

  // Email/Password Sign Up
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.updateDisplayName(displayName);
      await _createUserProfile(userCredential.user!, nameOverride: displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] SignUp error: ${e.code} — ${e.message}');
      rethrow;
    }
  }

  // Email/Password Sign In
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] SignIn error: ${e.code} — ${e.message}');
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Phone Auth verification
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // OTP Sign In
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
    }
    return userCred;
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      if (!kIsWeb) _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  // Create User Profile Document
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
}
