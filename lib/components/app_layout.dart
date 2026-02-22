// lib/components/app_layout.dart
import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_drawer.dart';
import 'package:ebook_project/state/nav_state.dart';

import 'package:url_launcher/url_launcher.dart';

/// ------------------------------
/// App primary gradient (blue 600 → 800)
/// ------------------------------
LinearGradient appPrimaryGradient() => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: AppColors.primaryGradientDeep().colors,
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
      return Icon(icon, size: size, color: AppColors.slate500); // slate-500
    }
    return Icon(
      icon,
      size: size,
      color: AppColors.primaryDeep,
    );
  }
}

class AppLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showDrawer;
  final bool showNavBar;
  final EdgeInsetsGeometry bodyPadding;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    this.showDrawer = true,
    this.showNavBar = true,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavState.index,
      builder: (context, selected, _) {
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
            onLoginTap: () {
              // Login পেজে গেলে Home/others না, আপনার ইচ্ছা মতো রাখতে পারেন
              Navigator.pushNamed(context, '/login');
            },
            onHomeTap: () {
              NavState.index.value = 0; // ✅ Home selected
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false);
            },
            onSettingsTap: () => Navigator.pushNamed(context, '/settings'),
            onProfileTap: () {
              NavState.index.value = 2; // ✅ Profile selected
              Navigator.pushNamed(context, '/profile');
            },
            onDeviceVerificationTap: () =>
                Navigator.pushNamed(context, '/device-verification'),
          )
              : null,

          // ===== Body =====
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: bodyPadding,
              child: body,
            ),
          ),

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
      },
    );
  }

  Future<void> _handleNavTap(BuildContext context, int index) async {
    // ✅ Website ট্যাব হলে: ব্রাউজার ওপেন, Nav state আগেরটাই থাকবে
    if (index == 3) {
      HapticFeedback.selectionClick();
      await _openWebsite();
      return;
    }

    // ✅ এখানে ট্যাব স্টেট সেট করি
    NavState.index.value = index;

    if (index == 1) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      try {
        final res = await ApiService().fetchEbookData('/v1/check-active-doctor-device');
        final isActive = res['is_active'] == true;
        if (!isActive) {
          Navigator.pushReplacementNamed(context, '/device-verification');
          return;
        }
      } catch (_) {
        Navigator.pushReplacementNamed(context, '/device-verification');
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

Future<void> _openWebsite() async {
  final uri = Uri.parse('https://banglamed.net');
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication, // ✅ বাহিরের ব্রাউজারে ওপেন
  );
  if (!ok) {
    // চাইলে snackbar দেখাতে পারেন
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
            color: cs.surface.withOpacity(0.98),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
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
                  Expanded(
                    child: _NavItem(
                      active: false, // ✅ website এ active দেখাতে না চাইলে false রাখুন
                      label: 'Website',
                      icon: Icons.public_rounded,
                      onTap: () => onSelect(3),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
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
                  color: active ? AppColors.primaryDeep : cs.onSurfaceVariant,
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
