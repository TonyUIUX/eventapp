import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../providers/saved_events_provider.dart';
import '../../../services/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../core/widgets/dark_shimmer.dart';
import '../../detail/event_detail_screen.dart';

// lib/screens/home/widgets/event_card.dart
// Dark glassmorphism EventCard — KochiGo v3.1 (doc 26 spec)

class EventCard extends ConsumerWidget {
  final EventModel event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TapScale(
      onTap: () {
        AnalyticsService.instance.logEventView(event.id, event.title);
        Navigator.push(
          context,
          SlideUpFadeRoute(page: EventDetailScreen(event: event)),
        );
      },
      onLongPress: () {
        final isSaved = ref.read(savedEventIdsProvider).contains(event.id);
        ref.read(savedEventIdsProvider.notifier).toggle(event.id);
        AnalyticsService.instance.logEventSaved(event.id, saved: !isSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? 'Removed from saved' : 'Event saved ✓', style: const TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.backgroundDeep.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image section ─────────────────────────────────────────
              Stack(
                children: [
                  // Hero image 16:9
                  Hero(
                    tag: 'event_image_${event.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: event.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const DarkShimmer(
                            width: double.infinity,
                            height: 200,
                            borderRadius: AppRadius.xl,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.backgroundSheet,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textTertiary,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient fade: transparent → backgroundCard
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.backgroundCard,
                          ],
                          stops: [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Category badge — top-left gradient pill
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _CategoryBadge(category: event.category),
                  ),

                  // Price badge — top-right
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: _PriceBadge(price: event.price),
                  ),

                  // Featured glow border overlay
                  if (event.isFeatured)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.xl),
                            ),
                            border: Border.all(
                              color: AppColors.brandCoral.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Content area ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: AppTextStyles.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Date row — coral icon + text
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.brandCoral,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppDateUtils.formatCardDate(event.date),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.brandCoral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Location row
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.location,
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Tags Wrap
                    if (event.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: event.tags.take(3).map(
                          (tag) => _TagChip(tag: tag),
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Badge ────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.categoryGradients[category.toLowerCase()] ??
        AppColors.brandGradient;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        category.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Price Badge ───────────────────────────────────────────────────────────────
class _PriceBadge extends StatelessWidget {
  final String price;
  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    final isFree = price.toLowerCase() == 'free';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        isFree ? '🎫 FREE' : price,
        style: AppTextStyles.caption.copyWith(
          color: isFree ? AppColors.success : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Tag Chip ──────────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        '#$tag',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
