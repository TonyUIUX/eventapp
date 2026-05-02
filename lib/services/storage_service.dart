import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// Firebase Storage service — cross-platform (uses Uint8List, not dart:io File)
// Used by the Admin Panel for event image management.
class StorageService {
  final _storage = FirebaseStorage.instance;
  static const _eventsPath = 'events';

  /// Upload image bytes and return the public download URL.
  /// [eventId]  — Firestore document ID of the event
  /// [filename] — e.g. 'cover.jpg' or '${uuid}.jpg'
  Future<String> uploadEventImage(
    Uint8List imageBytes,
    String eventId,
    String filename,
  ) async {
    final ref = _storage.ref().child('$_eventsPath/$eventId/$filename');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final task = await ref.putData(imageBytes, metadata);
    return task.ref.getDownloadURL();
  }

  /// Delete a single image by its full download URL.
  Future<void> deleteImage(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (e) {
      debugPrint('StorageService.deleteImage error: $e');
    }
  }

  /// List all image download URLs for a given event.
  Future<List<String>> getEventImages(String eventId) async {
    final result =
        await _storage.ref().child('$_eventsPath/$eventId').listAll();
    return Future.wait(result.items.map((item) => item.getDownloadURL()));
  }

  /// Upload user profile image and return the public download URL.
  Future<String> uploadProfileImage(Uint8List imageBytes, String userId) async {
    final ref = _storage.ref().child('profiles/$userId/avatar.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final task = await ref.putData(imageBytes, metadata);
    return task.ref.getDownloadURL();
  }
}
