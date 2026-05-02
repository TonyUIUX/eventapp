import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_spacing.dart';
import 'glass_card.dart';

// lib/core/widgets/dark_shimmer.dart
// Dark-mode shimmer loading placeholders — KochiGo v3.1
// Replace ALL existing shimmer usages with DarkShimmer/EventCardSkeleton.

class DarkShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const DarkShimmer({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E2E),
      highlightColor: const Color(0xFF2E2E42),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Full event card skeleton that matches the dark EventCard shape.
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarkShimmer(
            width: double.infinity,
            height: 160,
            borderRadius: AppRadius.md,
          ),
          SizedBox(height: 12),
          DarkShimmer(width: double.infinity, height: 18),
          SizedBox(height: 8),
          DarkShimmer(width: 140, height: 13),
          SizedBox(height: 6),
          DarkShimmer(width: 100, height: 13),
        ],
      ),
    );
  }
}
