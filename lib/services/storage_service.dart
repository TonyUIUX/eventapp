import 'dart:typed_data';
import 'storage/cloudinary_storage_service.dart';
import 'storage/firebase_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StorageService — Facade
//
// ⚡ TO SWITCH STORAGE PROVIDER:
//   • Cloudinary (current, free):  _useCloudinary = true
//   • Firebase Storage (needs Blaze plan): _useCloudinary = false
//
// Both implementations are fully preserved in lib/services/storage/
// ─────────────────────────────────────────────────────────────────────────────
class StorageService {
  // ✅ Change this ONE line to switch providers:
  static const bool _useCloudinary = true;

  final _cloudinary = CloudinaryStorageService();
  final _firebase = FirebaseStorageService();

  /// Upload event image bytes — returns public CDN/download URL.
  Future<String> uploadEventImage(
    Uint8List imageBytes,
    String eventId,
    String filename,
  ) =>
      _useCloudinary
          ? _cloudinary.uploadEventImage(imageBytes, eventId, filename)
          : _firebase.uploadEventImage(imageBytes, eventId, filename);

  /// Upload profile image bytes — returns public CDN/download URL.
  Future<String> uploadProfileImage(
          Uint8List imageBytes, String userId) =>
      _useCloudinary
          ? _cloudinary.uploadProfileImage(imageBytes, userId)
          : _firebase.uploadProfileImage(imageBytes, userId);

  /// Delete image by URL.
  Future<void> deleteImage(String downloadUrl) =>
      _useCloudinary
          ? _cloudinary.deleteImage(downloadUrl)
          : _firebase.deleteImage(downloadUrl);

  /// List all image URLs for an event.
  Future<List<String>> getEventImages(String eventId) =>
      _useCloudinary
          ? _cloudinary.getEventImages(eventId)
          : _firebase.getEventImages(eventId);
}
