import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _websiteController;

  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProfileProvider).value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _instagramController = TextEditingController(text: user?.instagramHandle ?? '');
    _websiteController = TextEditingController(text: user?.website ?? '');
    _profileImageUrl = user?.photoUrl;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(authStateProvider).value;
        if (user == null) return;

        final bytes = await picked.readAsBytes();
        final url = await StorageService().uploadProfileImage(bytes, user.uid);
        setState(() => _profileImageUrl = url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Upload failed: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
          ));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'instagramHandle': _instagramController.text.trim(),
        'website': _websiteController.text.trim(),
        'photoUrl': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving profile: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.backgroundCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBase,
        title: Text('Edit Profile', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.brandCoral, strokeWidth: 2))))
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: AppTextStyles.label.copyWith(color: AppColors.brandCoral)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.backgroundCard,
                        border: Border.all(color: AppColors.glassBorder),
                        image: _profileImageUrl != null
                            ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _profileImageUrl == null ? const Icon(Icons.person_rounded, size: 50, color: AppColors.textTertiary) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              _EditGlassTextField(
                controller: _nameController,
                labelText: 'Display Name',
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _EditGlassTextField(
                controller: _bioController,
                labelText: 'Bio',
                maxLines: 3,
                maxLength: 120,
              ),
              const SizedBox(height: 16),
              _EditGlassTextField(
                controller: _instagramController,
                labelText: 'Instagram Handle',
                hintText: '@username',
              ),
              const SizedBox(height: 16),
              _EditGlassTextField(
                controller: _websiteController,
                labelText: 'Website',
                hintText: 'https://',
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  const _EditGlassTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: AppTextStyles.body.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.brandCoral),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
