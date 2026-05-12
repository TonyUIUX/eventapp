import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import '../screens/detail/event_detail_screen.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

// Production-safe deep link service.
// Uses a GlobalKey<NavigatorState> to avoid capturing BuildContext across
// async gaps (use_build_context_synchronously lint).
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  // Store navigator key instead of BuildContext
  GlobalKey<NavigatorState>? _navigatorKey;
  WidgetRef? _ref;

  void init(BuildContext context, WidgetRef ref) {
    if (_initialized) return;

    // Capture navigator key — safe across async gaps
    _navigatorKey = Navigator.of(context).widget.key as GlobalKey<NavigatorState>?;
    _ref = ref;

    // Handle incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link if app was launched from a link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(uri);
        });
      }
    });

    _initialized = true;
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final ref = _ref;
    final navigatorContext = _navigatorKey?.currentContext;

    if (ref == null) return;
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'event') {
      final eventId = uri.pathSegments[1];

      // Read current stream value, or wait for the first emit
      final eventsValue = ref.read(eventsProvider);
      final List<EventModel> events;
      if (eventsValue is AsyncData<List<EventModel>>) {
        events = eventsValue.value;
      } else {
        // Not yet loaded — wait for the stream to emit
        events = await ref.read(eventsProvider.future);
      }

      final ctx = _navigatorKey?.currentContext ?? navigatorContext;
      if (ctx == null || !ctx.mounted) return;
      try {
        final event = events.firstWhere((e) => e.id == eventId);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event),
          ),
        );
      } catch (e) {
        debugPrint('Event not found for deep link: $eventId');
        final dialogCtx = _navigatorKey?.currentContext;
        if (dialogCtx == null || !dialogCtx.mounted) return;
        showDialog(
          context: dialogCtx,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundSheet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            title: Text('Event Unavailable', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            content: Text('This event has ended or was removed by the organizer.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK', style: AppTextStyles.label.copyWith(color: AppColors.brandCoral)),
              ),
            ],
          ),
        );
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _initialized = false;
    _ref = null;
    _navigatorKey = null;
  }
}
