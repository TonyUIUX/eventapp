import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/tap_scale.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/utils/app_router.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../detail/event_detail_screen.dart';
import '../../services/firestore_service.dart';

// lib/screens/notifications/notifications_screen.dart
// Dark glassmorphism Notifications Screen — KochiGo v3.1

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final user = ref.read(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Notifications', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (user != null)
            TextButton(
              onPressed: () => NotificationService.instance.markAllAsRead(user.uid),
              child: Text(
                'Mark all read',
                style: AppTextStyles.label.copyWith(color: AppColors.brandCoral),
              ),
            ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) return const _EmptyState();
          
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            physics: const BouncingScrollPhysics(),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _NotificationTile(notif: notifs[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandCoral)),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(notificationsProvider)),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notif;
  const _NotificationTile({required this.notif});

  IconData _getIcon() {
    switch (notif.type) {
      case NotificationType.event_approved: return Icons.check_circle_rounded;
      case NotificationType.event_rejected: return Icons.cancel_rounded;
      case NotificationType.event_reminder: return Icons.alarm_rounded;
      case NotificationType.system_broadcast: return Icons.campaign_rounded;
    }
  }

  Color _getColor() {
    switch (notif.type) {
      case NotificationType.event_approved: return AppColors.success;
      case NotificationType.event_rejected: return AppColors.error;
      case NotificationType.event_reminder: return Colors.amber;
      case NotificationType.system_broadcast: return AppColors.brandPurple;
    }
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 7) return '${time.day}/${time.month}/${time.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _handleTap(BuildContext context, WidgetRef ref) async {
    NotificationService.instance.markAsRead(notif.id);
    
    if (notif.relatedId != null && notif.relatedId!.isNotEmpty) {
      try {
        final eventsAsync = ref.read(eventsProvider);
        EventModel? event;
        if (eventsAsync is AsyncData) {
          event = eventsAsync.value?.where((e) => e.id == notif.relatedId!).firstOrNull;
        }
        event ??= await FirestoreService.instance.getEventById(notif.relatedId!);
        
        if (event != null && context.mounted) {
          Navigator.push(context, SlideUpFadeRoute(page: EventDetailScreen(event: event)));
        }
      } catch (e) {
        // Silently fail if event not found or deleted
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TapScale(
      onTap: () => _handleTap(context, ref),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.backgroundCard : AppColors.glassHighlight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(
            left: BorderSide(
              color: notif.isRead ? AppColors.glassBorder : AppColors.brandCoral,
              width: notif.isRead ? 1 : 3,
            ),
            top: const BorderSide(color: AppColors.glassBorder),
            right: const BorderSide(color: AppColors.glassBorder),
            bottom: const BorderSide(color: AppColors.glassBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getColor().withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), color: _getColor(), size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: notif.isRead 
                        ? AppTextStyles.body.copyWith(color: Colors.white)
                        : AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRelativeTime(notif.createdAt),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.xl),
            const Text('All Caught Up', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You have no new notifications right now.\nCheck back later!',
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
            const Text('Connection Issue', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We couldn\'t load your notifications.\nCheck your connection and try again.',
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
