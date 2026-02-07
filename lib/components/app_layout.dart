// lib/components/app_layout.dart
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ebook_project/components/under_maintanance_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_drawer.dart';

/// ------------------------------
/// App primary gradient (blue 600 → 800)
/// ------------------------------
LinearGradient appPrimaryGradient() => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.blueShade600,
        AppColors.blueShade800,
      ],
    );

/// ------------------------------
/// GradientIcon: active হলে গ্রেডিয়েন্ট রঙ, না হলে স্লেট টোন
/// ------------------------------
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size;

  const GradientIcon(
    this.icon, {
    super.key,
    required this.active,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) {
      // Inactive → neutral/slate tone
      return Icon(icon, size: size, color: AppColors.slate500); // slate-500
    }
    // Active → gradient fill
    return ShaderMask(
      shaderCallback: (rect) => appPrimaryGradient().createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

class AppLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showDrawer;
  final bool showNavBar;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    this.showDrawer = true,
    this.showNavBar = true,
  });

  int _currentIndex(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.name ?? '/';
    switch (name) {
      case '/':
        return 0;
      case '/my-ebooks':
        return 1;
      case '/profile':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _currentIndex(context);
    return Scaffold(
      // ===== AppBar: simple + consistent gradient =====
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: appPrimaryGradient()),
        ),
      ),

      // ===== Drawer =====
      endDrawer: showDrawer
          ? CustomDrawer(
              title: 'My Ebooks',
              onLoginTap: () => Navigator.pushNamed(context, '/login'),
              onHomeTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false),
              onSettingsTap: () => Navigator.pushNamed(context, '/settings'),
              onProfileTap: () => Navigator.pushNamed(context, '/profile'),
              onDeviceVerificationTap: () =>
                  Navigator.pushNamed(context, '/device-verification'),
            )
          : null,

      // ===== Body =====
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: body,
        ),
      ),

      // ===== Bottom Navigation (Material convention) =====
      // কোনো অতিরিক্ত ব্যাকগ্রাউন্ড/কন্টেইনার নেই
      // bottomNavigationBar: showNavBar
      //     ? NavigationBar(
      //         backgroundColor: Colors.transparent, // surface-এ মিশে যায়
      //         height: 64,
      //         elevation: 0,
      //         indicatorColor:
      //             AppColors.blueShade600.withOpacity(0.12), // subtle
      //         labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      //         selectedIndex: selected,
      //         onDestinationSelected: (index) {
      //           if (index == selected) return;
      //           HapticFeedback.selectionClick();
      //
      //           switch (index) {
      //             case 0:
      //               Navigator.pushReplacementNamed(context, '/');
      //               break;
      //             case 1:
      //               Navigator.pushReplacementNamed(context, '/my-ebooks');
      //               break;
      //             case 2:
      //               Navigator.pushReplacementNamed(context, '/profile');
      //               break;
      //           }
      //         },
      //         destinations: [
      //           NavigationDestination(
      //             icon:
      //                 GradientIcon(Icons.home_rounded, active: false, size: 24),
      //             selectedIcon:
      //                 GradientIcon(Icons.home_rounded, active: true, size: 24),
      //             label: 'Home',
      //           ),
      //           NavigationDestination(
      //             icon: GradientIcon(Icons.auto_stories_rounded,
      //                 active: false, size: 24),
      //             selectedIcon: GradientIcon(Icons.auto_stories_rounded,
      //                 active: true, size: 24),
      //             label: 'My Ebooks',
      //           ),
      //           NavigationDestination(
      //             icon: GradientIcon(Icons.account_circle_rounded,
      //                 active: false, size: 24),
      //             selectedIcon: GradientIcon(Icons.account_circle_rounded,
      //                 active: true, size: 24),
      //             label: 'Profile',
      //           ),
      //         ],
      //       )
      //     : null,

      bottomNavigationBar: showNavBar
          ? _AnimatedNavBar(
        selectedIndex: selected,
        onSelect: (index) {
          if (index == selected) return;
          HapticFeedback.selectionClick();
          _handleNavTap(context, index);
        },
      )
          : null,

    );
  }

  Future<void> _handleNavTap(BuildContext context, int index) async {
    if (index == 1) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
        return;
      }
    }

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/my-ebooks');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
class _AnimatedNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AnimatedNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ✅ Animated indicator (slide + fade)
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: _alignForIndex(selectedIndex),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Container(
                      width: _itemWidth(context),
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.blueShade600.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ Items row
              Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      active: selectedIndex == 0,
                      label: 'Home',
                      icon: Icons.home_rounded,
                      onTap: () => onSelect(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      active: selectedIndex == 1,
                      label: 'My Ebooks',
                      icon: Icons.auto_stories_rounded,
                      onTap: () => onSelect(1),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      active: selectedIndex == 2,
                      label: 'Profile',
                      icon: Icons.account_circle_rounded,
                      onTap: () => onSelect(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _alignForIndex(int i) {
    if (i == 0) return Alignment.centerLeft;
    if (i == 1) return Alignment.center;
    return Alignment.centerRight;
  }

  double _itemWidth(BuildContext context) {
    // container width -> 3 items
    final w = MediaQuery.of(context).size.width - (12 + 12);
    return (w / 3) - 12; // padding compensate
  }
}

class _NavItem extends StatelessWidget {
  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItem({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: active ? 1 : 0.72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                scale: active ? 1.08 : 1.0,
                child: GradientIcon(
                  icon,
                  active: active,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

