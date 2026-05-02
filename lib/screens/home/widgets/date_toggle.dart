import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/events_provider.dart';

class DateToggle extends ConsumerWidget {
  const DateToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            _ToggleOption(label: 'Today', value: 'today', selected: selected),
            _ToggleOption(label: 'Weekend', value: 'weekend', selected: selected),
            _ToggleOption(label: 'Week', value: 'week', selected: selected),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends ConsumerWidget {
  final String label;
  final String value;
  final String selected;

  const _ToggleOption({
    required this.label,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(selectedDateFilterProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: isSelected ? AppColors.shadowSm : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
