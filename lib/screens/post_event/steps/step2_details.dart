import 'package:flutter/material.dart';
import '../../../../models/post_event_form_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';

class Step2Details extends StatelessWidget {
  final PostEventFormData formData;
  final VoidCallback onUpdate;
  
  const Step2Details({super.key, required this.formData, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESCRIPTION', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          _GlassTextField(
            initialValue: formData.description,
            hintText: 'Describe the vibe, the artists, or what to expect...',
            maxLines: 5,
            onChanged: (v) { formData.description = v; onUpdate(); },
          ),
          
          const SizedBox(height: 32),
          
          Text('VENUE LOCATION', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          _GlassTextField(
            initialValue: formData.location,
            hintText: 'e.g. Kashi Art Café, Fort Kochi',
            onChanged: (v) { formData.location = v; onUpdate(); },
          ),
          const SizedBox(height: 16),
          _GlassTextField(
            initialValue: formData.mapLink,
            hintText: 'Google Maps Link (Optional)',
            onChanged: (v) { formData.mapLink = v; onUpdate(); },
          ),
          
          const SizedBox(height: 32),
          
          Text('ENTRY TYPE', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 12),
          
          // Custom Toggle
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      formData.entryType = 'free';
                      onUpdate();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: formData.entryType == 'free' ? AppColors.brandGradient : null,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Free Entry',
                        style: AppTextStyles.label.copyWith(
                          color: formData.entryType == 'free' ? Colors.white : AppColors.textSecondary,
                          fontWeight: formData.entryType == 'free' ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      formData.entryType = 'paid';
                      onUpdate();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: formData.entryType == 'paid' ? AppColors.brandGradient : null,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Paid / Tickets',
                        style: AppTextStyles.label.copyWith(
                          color: formData.entryType == 'paid' ? Colors.white : AppColors.textSecondary,
                          fontWeight: formData.entryType == 'paid' ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (formData.entryType == 'paid') ...[
            _AccentGlassTextField(
              initialValue: formData.price == 'Free' ? '' : formData.price,
              hintText: 'Price Info (e.g. ₹499 onwards)',
              onChanged: (v) { formData.price = v; onUpdate(); },
            ),
            const SizedBox(height: 16),
            _AccentGlassTextField(
              initialValue: formData.ticketLink,
              hintText: 'Ticket Link (e.g. BookMyShow)',
              onChanged: (v) { formData.ticketLink = v; onUpdate(); },
            ),
          ] else ...[
            _AccentGlassTextField(
              initialValue: formData.registrationLink,
              hintText: 'Registration Link (e.g. Google Form - Optional)',
              onChanged: (v) { formData.registrationLink = v; onUpdate(); },
            ),
          ],
          
          const SizedBox(height: 48), // Bottom padding
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _GlassTextField({
    this.initialValue,
    required this.hintText,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _AccentGlassTextField extends StatelessWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _AccentGlassTextField({
    this.initialValue,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: const Border(
          left: BorderSide(color: AppColors.brandCoral, width: 4),
          top: BorderSide(color: AppColors.glassBorder),
          right: BorderSide(color: AppColors.glassBorder),
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        style: AppTextStyles.body.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
