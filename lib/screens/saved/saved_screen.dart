import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/saved_events_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../home/widgets/event_card.dart';

// Shows the user's saved/bookmarked events
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Events'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: savedAsync.when(
        data: (events) => events.isEmpty
            ? const _EmptySaved()
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(event: event);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandCoral)),
        error: (e, _) => const Center(
          child: Text('Something went wrong', style: AppTextStyles.bodySecondary),
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline, size: 64, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text('Nothing saved yet', style: AppTextStyles.heading2),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Tap the save button on any event to bookmark it',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
