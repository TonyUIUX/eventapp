import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

// lib/core/widgets/gradient_app_bar.dart
// Gradient app bar per doc 26 — KochiGo v3.1

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showGradientTitle;
  final bool centerTitle;

  const GradientAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.showGradientTitle = false,
    this.centerTitle = false,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: showGradientTitle
          ? ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.brandGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                title,
                style: AppTextStyles.heading1.copyWith(color: Colors.white),
              ),
            )
          : Text(title, style: AppTextStyles.heading2),
      actions: actions,
    );
  }
}
