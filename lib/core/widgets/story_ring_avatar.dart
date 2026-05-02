import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'tap_scale.dart';

// lib/core/widgets/story_ring_avatar.dart
// Gradient-ringed avatar widget — like Instagram stories — KochiGo v3.1

class StoryRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final bool hasNew;        // Gradient ring when there's unseen content
  final bool isAddButton;   // First slot: "Your Story" + add button
  final VoidCallback? onTap;
  final double size;

  const StoryRingAvatar({
    required this.label,
    this.imageUrl,
    this.hasNew = false,
    this.isAddButton = false,
    this.onTap,
    this.size = 60,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasNew
                  ? AppColors.brandGradient
                  : const LinearGradient(
                      colors: [AppColors.textTertiary, AppColors.textTertiary],
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundBase,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: isAddButton
                      ? Container(
                          color: AppColors.backgroundCard,
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.brandCoral,
                            size: 28,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl ?? '',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.backgroundCard,
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: hasNew
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
