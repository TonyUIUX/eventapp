import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool isAdmin;
  final String role; // 'user' | 'superadmin'
  final int totalEventsPosted;
  final int totalViews;
  final int followersCount;
  final int followingCount;
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
    this.isVerifiedOrg = false,
    this.isAdmin = false,
    this.role = 'user',
    this.totalEventsPosted = 0,
    this.totalViews = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'],
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      instagramHandle: data['instagramHandle'],
      website: data['website'],
      isVerifiedOrg: data['isVerifiedOrg'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      role: data['role'] ?? 'user',
      totalEventsPosted: data['totalEventsPosted'] ?? 0,
      totalViews: data['totalViews'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Returns true only when the Firestore `role` field is 'superadmin'.
  /// Never checks email or UID — Firestore is the single source of truth.
  bool get isSuperAdmin => role == 'superadmin';

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'instagramHandle': instagramHandle,
      'website': website,
      'isVerifiedOrg': isVerifiedOrg,
      'isAdmin': isAdmin,
      'role': role,
      'totalEventsPosted': totalEventsPosted,
      'totalViews': totalViews,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
