# 🎨 Rebrand, Naming & Dark UI Design System

> This doc transforms KochiGo from a light-mode local app
> into a premium dark glassmorphism social events platform.
> EXISTING backend, Firebase, Razorpay — ALL UNCHANGED.
> ONLY the visual layer is being upgraded.

---

## 🏷️ Top 10 App Name Suggestions

Scale: India-first → Global capable. No city lock-in.

| # | Name | Meaning | Domain Feel | Why It Works |
|---|---|---|---|---|
| 1 | **Evora** | Event + Aura | Premium, global | Sounds like a lifestyle brand. Short, memorable, works in any city. |
| 2 | **Gatherly** | Gathering + community | Warm, social | Explains itself. "Gatherly mein dekha?" works in India naturally. |
| 3 | **Scenix** | The Scene + mix | Urban, cool | "What's the scene?" is universal. Easy to say in Hindi/Malayalam. |
| 4 | **Flockr** | Flock together | Tech-startup | People flock to events. r-suffix is globally familiar (Flickr, Tumblr). |
| 5 | **Vivra** | Vibrant + Vibe + Live | Energetic | "Vivra" sounds alive. Works across India. Premium app store feel. |
| 6 | **Spotly** | Spotlight your events | Creator-first | Organiser-centric naming. "Get spotly" as a verb — powerful branding. |
| 7 | **Hapstr** | What's Happening + -str | Casual, youthful | "Hapstr pe hai" — fits Indian slang. Event discovery at its core. |
| 8 | **Nexgig** | Next Gig | Music/event culture | Strong in comedy/music scene. Niche but expandable to all events. |
| 9 | **Revlr** | Revel + explore | Night-life, cultural | Revelling = celebrating. Works for parties, meetups, cultural events. |
| 10 | **Eventara** | Event + Era | Indian heritage feel | "Tara" means star in Sanskrit. EventAra — the era of events. Indian-global. |

### 🏆 Top 3 Recommendation

**#1 → Vivra** — Sounds alive, premium, works pan-India  
**#2 → Evora** — Global app store presence, luxury feel  
**#3 → Scenix** — Urban India youth market, instantly understood  

> For this doc, the app will be referred to as **[AppName]**.
> Replace with your chosen name throughout.

---

## 🌑 Dark Glassmorphism Design System

### Philosophy
> "Every screen should feel like you're looking through frosted glass
>  at something happening right now — alive, warm, electric."

Three visual layers:
```
Layer 1 (deepest):  Dark background — near-black navy
Layer 2 (middle):   Glassmorphism cards — frosted, semi-transparent
Layer 3 (surface):  Glowing content — gradients, neon accents, white text
```

---

### Color System

```dart
// lib/core/constants/app_colors.dart — FULL REPLACEMENT

class AppColors {

  // ── BACKGROUNDS ──────────────────────────────────────────────
  // The deep base. Never use pure black — navy feels warmer.
  static const Color backgroundDeep   = Color(0xFF08090F); // Deepest bg
  static const Color backgroundBase   = Color(0xFF0D0E1A); // Main scaffold
  static const Color backgroundCard   = Color(0xFF13141F); // Card surface
  static const Color backgroundSheet  = Color(0xFF181928); // Bottom sheets

  // ── GLASS SURFACES ───────────────────────────────────────────
  // Semi-transparent overlays. Use with BackdropFilter blur.
  static const Color glassSurface     = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder      = Color(0x26FFFFFF); // 15% white
  static const Color glassHighlight   = Color(0x0DFFFFFF); // 5% white

  // ── BRAND GRADIENT (Primary) ─────────────────────────────────
  // Coral stays as brand anchor. Paired with deep purple.
  static const Color brandCoral       = Color(0xFFFF5247); // KochiGo coral
  static const Color brandPurple      = Color(0xFF7C3AFF); // Deep violet
  static const Color brandPink        = Color(0xFFE040FB); // Vivid magenta

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF5247), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientVertical = LinearGradient(
    colors: [Color(0xFFFF5247), Color(0xFF7C3AFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── ACCENT GRADIENTS (Cards, Categories) ─────────────────────
  static const LinearGradient accentGreenTeal = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentPurplePink = LinearGradient(
    colors: [Color(0xFF7C3AFF), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentOrangeYellow = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentBlueViolet = LinearGradient(
    colors: [Color(0xFF4361EE), Color(0xFF7C3AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Category gradient map ─────────────────────────────────────
  static const Map<String, LinearGradient> categoryGradients = {
    'comedy':   LinearGradient(colors: [Color(0xFFFFD60A), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'music':    LinearGradient(colors: [Color(0xFF7C3AFF), Color(0xFFE040FB)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'tech':     LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'fitness':  LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'art':      LinearGradient(colors: [Color(0xFFE040FB), Color(0xFFFF5247)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'workshop': LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'food':     LinearGradient(colors: [Color(0xFFFF5247), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
    'business': LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF7C3AFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
  };

  // ── GLOW COLORS (for shadows and borders) ────────────────────
  static const Color glowCoral   = Color(0x40FF5247); // 25% coral
  static const Color glowPurple  = Color(0x407C3AFF); // 25% purple
  static const Color glowGreen   = Color(0x4000C9A7); // 25% teal

  // ── TEXT ─────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF1F1F5); // Near white
  static const Color textSecondary  = Color(0xFF8E8EA0); // Muted grey
  static const Color textTertiary   = Color(0xFF52526A); // Subtle hints
  static const Color textOnGradient = Color(0xFFFFFFFF); // Always white on gradient

  // ── STATUS ───────────────────────────────────────────────────
  static const Color success  = Color(0xFF00C9A7);
  static const Color warning  = Color(0xFFFFD60A);
  static const Color error    = Color(0xFFFF5247);
  static const Color info     = Color(0xFF4361EE);

  // ── LEGACY (keep for backwards compat during migration) ──────
  static const Color primary        = brandCoral;
  static const Color background     = backgroundBase;
  static const Color surface        = backgroundCard;
}
```

---

### Typography

```dart
// lib/core/constants/app_text_styles.dart — FULL REPLACEMENT

class AppTextStyles {
  // Font family: Poppins (already bundled as asset)

  // ── DISPLAY ──────────────────────────────────────────────────
  static const TextStyle display = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.1,
  );

  // ── HEADINGS ─────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── BODY ─────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  // ── LABELS & CAPTIONS ────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.6,
  );

  // ── BUTTONS ──────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
```

---

### Spacing & Radius Tokens

```dart
// lib/core/constants/app_spacing.dart

class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm   = 8.0;
  static const double md   = 14.0;
  static const double lg   = 20.0;
  static const double xl   = 28.0;
  static const double xxl  = 40.0;
  static const double pill = 100.0;
}
```

---

### ThemeData (Dark)

```dart
// lib/core/theme/app_theme.dart

ThemeData get darkTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.backgroundBase,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.brandCoral,
    secondary: AppColors.brandPurple,
    surface: AppColors.backgroundCard,
    background: AppColors.backgroundBase,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSurface: AppColors.textPrimary,
    onBackground: AppColors.textPrimary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: AppColors.textPrimary,
    titleTextStyle: AppTextStyles.heading2,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: AppColors.brandCoral,
    unselectedItemColor: AppColors.textTertiary,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    type: BottomNavigationBarType.fixed,
  ),
  useMaterial3: true,
  fontFamily: 'Poppins',
);
```

---

### Glass Card Widget (Reusable)

```dart
// lib/core/widgets/glass_card.dart

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? glowColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.lg,
    this.blur = 20,
    this.glowColor,
    this.gradient,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          color: gradient == null ? AppColors.glassSurface : null,
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: glowColor != null
            ? [BoxShadow(
                color: glowColor!,
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              )]
            : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### Gradient Button Widget

```dart
// lib/core/widgets/gradient_button.dart

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;
  final double height;
  final Widget? icon;
  final bool isLoading;

  const GradientButton({
    required this.label,
    required this.onTap,
    this.gradient = AppColors.brandGradient,
    this.height = 54,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowCoral,
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(label, style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                  )),
                ],
              ),
        ),
      ),
    );
  }
}
```

---

### Bottom Navigation Bar (Pill Style)

```dart
// lib/core/widgets/app_bottom_nav.dart
// Floating pill-shaped bottom nav like in the reference image

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        borderRadius: AppRadius.pill,
        blur: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded, index: 0, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.search_rounded, index: 1, current: currentIndex, onTap: onTap),
            _PostButton(onTap: () => onTap(2)),  // Center gradient + button
            _NavItem(icon: Icons.notifications_outlined, index: 3,
              current: currentIndex, onTap: onTap, badge: notificationCount),
            _NavItem(icon: Icons.person_outline_rounded, index: 4,
              current: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

// The center ✚ Post button — gradient circle
class _PostButton extends StatelessWidget {
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.glowCoral, blurRadius: 16, spreadRadius: -2),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
```
