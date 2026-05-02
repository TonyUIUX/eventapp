import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/saved_events_provider.dart';
import '../../providers/events_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/staggered_list.dart';
import '../../core/widgets/gradient_button.dart';
import '../home/widgets/event_card.dart';

// lib/screens/saved/saved_screen.dart
// Dark glassmorphism Saved Screen — KochiGo v3.1

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Saved Events',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
      ),
      body: savedAsync.when(
        data: (events) => events.isEmpty
            ? const _EmptySaved()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => StaggeredListItem(
                          index: index,
                          maxStagger: 6,
                          child: EventCard(event: events[index]),
                        ),
                        childCount: events.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
                ],
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandCoral),
        ),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(eventsProvider),
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Nothing Saved Yet',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Long-press any event card to bookmark it\nfor quick access later.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😵', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.lg),
            const Text('Something Went Wrong', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We couldn\'t load your saved events.\nCheck your connection and try again.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(label: 'Try Again', onTap: onRetry, height: 48),
          ],
        ),
      ),
    );
  }
}
