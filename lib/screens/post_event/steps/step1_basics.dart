import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/post_event_form_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_constants.dart' hide AppSpacing, AppRadius;
import '../../../../core/widgets/tap_scale.dart';

class Step1Basics extends StatelessWidget {
  final PostEventFormData formData;
  final VoidCallback onUpdate;
  
  final Map<String, String> _categoryEmojis = {
    'all': '✨',
    'music': '🎵',
    'comedy': '😂',
    'tech': '💻',
    'fitness': '🏃',
    'art': '🎨',
    'workshop': '🛠️',
    'food': '🍔',
    'business': '💼',
  };

  Step1Basics({super.key, required this.formData, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EVENT NAME', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          _GlassTextField(
            initialValue: formData.title,
            hintText: 'e.g. Sunday Soul Sante',
            onChanged: (v) { formData.title = v; onUpdate(); },
          ),
          
          const SizedBox(height: 32),
          
          Text('DATE & TIME', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          TapScale(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: formData.date ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.brandCoral,
                        surface: AppColors.backgroundCard,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null && context.mounted) {
                final time = await showTimePicker(
                  context: context, 
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.brandCoral,
                          surface: AppColors.backgroundCard,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  formData.date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  onUpdate();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formData.date == null ? 'Select Date & Time' : DateFormat('MMM dd, yyyy - hh:mm a').format(formData.date!),
                      style: AppTextStyles.body.copyWith(
                        color: formData.date == null ? AppColors.textTertiary : Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded, color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text('CATEGORY', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: AppConstants.categories.length,
            itemBuilder: (context, index) {
              final cat = AppConstants.categories[index];
              final isSelected = formData.category == cat;
              final String label = cat[0].toUpperCase() + cat.substring(1);
              final gradient = AppColors.categoryGradients[cat] ?? AppColors.brandGradient;

              return TapScale(
                onTap: () {
                  formData.category = cat;
                  onUpdate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.glassSurface : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.brandCoral : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brandCoral.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _categoryEmojis[cat] ?? '✨',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.label.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.brandCoral, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48), // Bottom padding
        ],
      ),
    );
  }
}

// Reusable Glass Text Field for forms
class _GlassTextField extends StatelessWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _GlassTextField({
    this.initialValue,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
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
