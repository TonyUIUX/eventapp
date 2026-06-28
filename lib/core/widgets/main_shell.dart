// lib/core/widgets/main_shell.dart
// Extracted from main.dart so any screen can import MainShell
// without creating a circular dependency on main.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/post_event/post_event_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/deep_link_service.dart';

// MainShell — floating bottom nav using Stack + Positioned.
// Preserves scroll state via IndexedStack.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {

  // Height of the floating nav bar including bottom padding.
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
    ref.read(selectedTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Content area with bottom padding so nothing hides under nav
          Positioned.fill(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: _navBarHeight),
                child: IndexedStack(
                  index: currentIndex,
                  children: _screens,
                ),
              ),
            ),
          ),

          // Floating pill nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
              notificationCount: unreadCount,
            ),
          ),
        ],
      ),
    );
  }
}
