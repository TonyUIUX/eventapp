import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/cloudinary_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cloudinary Storage implementation (ACTIVE)
// Free tier: 25 GB storage, 25 GB bandwidth/month — no credit card needed
//
// Setup steps:
//   1. Sign up free at cloudinary.com
//   2. Create unsigned upload preset named 'evorra_unsigned'
//   3. Set your cloud name in lib/core/config/cloudinary_config.dart
// ─────────────────────────────────────────────────────────────────────────────
class CloudinaryStorageService {
  static const _eventsFolder = 'evorra/events';
  static const _profilesFolder = 'evorra/profiles';

  /// Upload event image bytes and return the public CDN URL.
  Future<String> uploadEventImage(
    Uint8List imageBytes,
    String eventId,
    String filename,
  ) async {
    return _upload(
      imageBytes: imageBytes,
      folder: '$_eventsFolder/$eventId',
      publicId: filename.replaceAll('.jpg', ''),
    );
  }

  /// Upload profile image bytes and return the public CDN URL.
  Future<String> uploadProfileImage(
      Uint8List imageBytes, String userId) async {
    return _upload(
      imageBytes: imageBytes,
      folder: '$_profilesFolder/$userId',
      publicId: 'avatar',
    );
  }

  /// Delete image — requires signed API (admin only), skipped for free tier.
  Future<void> deleteImage(String downloadUrl) async {
    debugPrint('CloudinaryStorageService: deleteImage skipped (needs signed API)');
  }

  /// List event images — not supported via unsigned API, returns empty list.
  Future<List<String>> getEventImages(String eventId) async => [];

  // ── Private upload ────────────────────────────────────────────────────────
  Future<String> _upload({
    required Uint8List imageBytes,
    required String folder,
    required String publicId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary cloud name not set.\n'
        'Open lib/core/config/cloudinary_config.dart and replace YOUR_CLOUD_NAME_HERE.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    );

    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.fields['folder'] = folder;
    request.fields['public_id'] = publicId;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: '$publicId.jpg',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      debugPrint('Cloudinary error body: ${response.body}');
      throw Exception(
          'Cloudinary upload failed (HTTP ${response.statusCode}).\n'
          'Check your cloud name and upload preset in CloudinaryConfig.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null) throw Exception('Cloudinary response missing secure_url');

    debugPrint('✅ Cloudinary upload success: $url');
    return url;
  }
}
