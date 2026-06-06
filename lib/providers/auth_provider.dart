import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  
  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

/// Derived provider — true only when Firestore users/{uid}.role == 'superadmin'.
/// No emails or UIDs are ever checked in Dart code.
final isSuperAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  return profile.valueOrNull?.isSuperAdmin ?? false;
});
