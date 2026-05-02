import 'package:flutter/material.dart';
import '../../../../models/post_event_form_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tap_scale.dart';

class Step4Organizer extends StatelessWidget {
  final PostEventFormData formData;
  final VoidCallback onUpdate;
  
  const Step4Organizer({super.key, required this.formData, required this.onUpdate});

  // Predefined standard tags
  static const List<String> _availableTags = [
    'Music', 'Food', 'Nightlife', 'Workshop', 
    'Art', 'Comedy', 'Fitness', 'Networking', 'Pop-Up'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORGANIZER DETAILS', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          _GlassTextField(
            initialValue: formData.organizer,
            hintText: 'Organizer Name (Required)',
            icon: Icons.business_rounded,
            onChanged: (v) { formData.organizer = v; onUpdate(); },
          ),
          const SizedBox(height: 16),
          _GlassTextField(
            initialValue: formData.contactPhone,
            hintText: 'Contact Phone',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            onChanged: (v) { formData.contactPhone = v; onUpdate(); },
          ),
          const SizedBox(height: 16),
          _GlassTextField(
            initialValue: formData.contactInstagram,
            hintText: 'Instagram Handle (@username)',
            icon: Icons.alternate_email_rounded,
            onChanged: (v) { formData.contactInstagram = v; onUpdate(); },
          ),
          const SizedBox(height: 16),
          _GlassTextField(
            initialValue: formData.website,
            hintText: 'Website (Optional)',
            icon: Icons.language_rounded,
            onChanged: (v) { formData.website = v; onUpdate(); },
          ),
          
          const SizedBox(height: 32),
          
          Text('TAGS', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          Text('Select up to 3 tags to help people find your event.', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableTags.map((tag) {
              final isSelected = formData.tags.contains(tag);
              return TapScale(
                onTap: () {
                  if (isSelected) {
                    formData.tags.remove(tag);
                  } else if (formData.tags.length < 3) {
                    formData.tags.add(tag);
                  }
                  onUpdate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.brandGradient : null,
                    color: isSelected ? null : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: isSelected ? Colors.transparent : AppColors.glassBorder),
                  ),
                  child: Text(
                    '#$tag',
                    style: AppTextStyles.label.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48), // Bottom padding
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final String? initialValue;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _GlassTextField({
    this.initialValue,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
