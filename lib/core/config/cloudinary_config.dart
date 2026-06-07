// ─────────────────────────────────────────────────────────────────────────────
// Cloudinary Configuration
//
// SETUP STEPS (do this once):
//   1. Sign up FREE at https://cloudinary.com/users/register_free
//      (no credit card required)
//
//   2. After login → go to Dashboard
//      Copy your "Cloud name" (e.g.  dxyz12345)
//
//   3. Go to Settings → Upload → "Upload presets" → Add upload preset
//      • Preset name : evorra_unsigned
//      • Signing mode: Unsigned   ← important!
//      • Click Save
//
//   4. Replace YOUR_CLOUD_NAME_HERE below with your actual cloud name
//
// ─────────────────────────────────────────────────────────────────────────────
class CloudinaryConfig {
  /// ↓↓↓ Replace this with your Cloudinary cloud name ↓↓↓
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'drgnkdho1',
  );

  /// Must match the unsigned upload preset you created in Cloudinary dashboard.
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'evorra_unsigned',
  );

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Returns false if cloud name is still the placeholder — triggers a clear error.
  static bool get isConfigured => cloudName != 'YOUR_CLOUD_NAME_HERE';
}
