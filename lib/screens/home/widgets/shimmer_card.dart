import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// Shimmer placeholder that matches the EventCard layout
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.shimmerBase,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title lines
                  _ShimmerLine(width: double.infinity),
                  SizedBox(height: 6),
                  _ShimmerLine(width: 200),
                  SizedBox(height: 10),
                  // Date line
                  _ShimmerLine(width: 150, height: 12),
                  SizedBox(height: 6),
                  // Location line
                  _ShimmerLine(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerLine({required this.width, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Shows 3 shimmer cards while loading
class ShimmerLoadingList extends StatelessWidget {
  const ShimmerLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }
}
