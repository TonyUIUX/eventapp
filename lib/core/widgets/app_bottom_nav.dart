import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'glass_card.dart';

// lib/core/widgets/app_bottom_nav.dart
// Floating pill-shaped bottom nav — KochiGo v3.1 design system

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;

  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        borderRadius: AppRadius.pill,
        blur: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _PostButton(onTap: () => onTap(2)),
            _NavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap,
              badge: notificationCount,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              index: 4,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.brandCoral : AppColors.textTertiary;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandCoral.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: color,
                size: 24,
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.brandCoral,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.backgroundBase, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Centre gradient circle — Post Event button
class _PostButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PostButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.glowCoral,
              blurRadius: 18,
              spreadRadius: -2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

