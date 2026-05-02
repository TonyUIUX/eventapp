import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/event_model.dart';
import '../../../providers/events_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../detail/event_detail_screen.dart';

class TrendingSection extends ConsumerWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingEventsProvider);
    final category = ref.watch(selectedCategoryProvider);

    if (category != 'all') return const SizedBox.shrink();

    return trendingAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  const Text('Trending Now', style: AppTextStyles.heading2),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _TrendingCard(event: event);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final EventModel event;
  const _TrendingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final trendingCount = (event.id.hashCode.abs() % 40) + 12;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      height: 110,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '🔥 $trendingCount',
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
