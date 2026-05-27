import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

import '../../../providers/events_provider.dart';
import '../../../core/widgets/tap_scale.dart';

// lib/screens/home/widgets/date_toggle.dart
// Dark glassmorphism date selector toggle — Evorra v3.1

class DateToggle extends ConsumerWidget {
  const DateToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.backgroundSheet,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.glassBorder),
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
      child: TapScale(
        onTap: () => ref.read(selectedDateFilterProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.backgroundCard : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? AppColors.glassBorder : Colors.transparent,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
