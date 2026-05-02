import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// A row with an icon and text, used in the detail screen
class InfoRow extends StatelessWidget {
  final IconData icon;
  final Widget content;

  const InfoRow({super.key, required this.icon, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(child: content),
        ],
      ),
    );
  }
}
