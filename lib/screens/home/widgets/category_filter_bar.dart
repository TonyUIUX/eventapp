import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart' hide AppSpacing, AppRadius;
import '../../../providers/events_provider.dart';
import '../../../services/analytics_service.dart';
import '../../../core/widgets/tap_scale.dart';

// lib/screens/home/widgets/category_filter_bar.dart
// Dark glassmorphism category selector — Evorra v3.1

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        physics: const BouncingScrollPhysics(),
        itemCount: AppCategories.all.length,
        itemBuilder: (context, index) {
          final cat = AppCategories.all[index];
          final isSelected = selected == cat['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _CategoryChip(
              label: cat['label']!,
              emoji: cat['emoji']!,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = cat['value']!;
                AnalyticsService.instance.logCategoryFilter(cat['value']!);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandCoral : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandCoral.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
