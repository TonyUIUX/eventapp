import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_bottom_nav.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/post_event/post_event_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/maintenance/maintenance_screen.dart';
import 'services/rating_service.dart';
import 'services/push_notification_service.dart';
import 'services/deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/smart_cache_service.dart';
import 'providers/app_config_provider.dart';
import 'providers/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence (Settings API — works on web + mobile).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  await RatingService.trackLaunch();
  await PushNotificationService.instance.init();

  // Prime the local event cache in the background
  // so the app is ready even when offline
  SmartCacheService.instance.warmUpCache();

  runApp(
    ProviderScope(
      child: KochiGoApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class KochiGoApp extends ConsumerWidget {
  final bool showOnboarding;
  const KochiGoApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMaintenance = ref.watch(maintenanceModeProvider);

    return MaterialApp(
      title: 'Vivra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        if (isMaintenance) {
          return const MaintenanceScreen();
        }
        return child!;
      },
      home: showOnboarding ? const OnboardingScreen() : const MainShell(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MainShell — floating bottom nav using Stack + Positioned
// Preserves scroll state via IndexedStack.
// ──────────────────────────────────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  // Height of the floating nav bar including bottom padding.
  // Body uses this as bottom padding so content is never hidden.
  static const double _navBarHeight = 88.0;

  static const List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    PostEventScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.init(context, ref);
    });
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      // No bottomNavigationBar — nav floats over content via Stack.
      body: Stack(
        children: [
          // ── Content area with bottom padding so nothing hides under nav ──
          Positioned.fill(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: _navBarHeight),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
          ),

          // ── Floating pill nav bar ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              notificationCount: unreadCount,
            ),
          ),
        ],
      ),
    );
  }
}
