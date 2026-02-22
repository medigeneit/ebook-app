import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/api/routes.dart';
import 'package:ebook_project/services/device_guard.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  final String title;
  final VoidCallback onHomeTap;
  final VoidCallback onLoginTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onDeviceVerificationTap;

  const CustomDrawer({
    Key? key,
    required this.title,
    required this.onHomeTap,
    required this.onLoginTap,
    required this.onSettingsTap,
    required this.onProfileTap,
    this.onDeviceVerificationTap,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      isLoggedIn = token != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGradientDeep().colors.first.withOpacity(0.08),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradientDeep(),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  child: Image.asset(
                    'assets/bm-logo-white.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // if(currentRoute != '/')
            buildDrawerItem(
                icon: FontAwesomeIcons.homeAlt,
                label: 'Home',
                onTap: currentRoute != '/' ? widget.onHomeTap : () {},
                route: '/'),
            // if(currentRoute != '/profile')
            buildDrawerItem(
                icon: FontAwesomeIcons.user,
                label: 'Profile',
                onTap: currentRoute != '/profile' ? widget.onProfileTap : () {},
                route: '/profile'),
            // buildDrawerItem(
            //   icon: FontAwesomeIcons.cog,
            //   label: 'Settings',
            //   onTap: widget.onSettingsTap,
            // ),
            if (widget.onDeviceVerificationTap != null)
              buildDrawerItem(
                icon: FontAwesomeIcons.shieldAlt,
                label: 'Device Verification',
                onTap: () async {
                  final verified = await DeviceGuard.I.isVerified();
                  if (verified) {
                    Navigator.pushNamed(context, '/device-info');
                  } else {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(
                      context,
                      '/device-verification',
                      arguments: {'redirectTo': '/device-info'},
                    );
                  }
                },
                route: '/device-info',
              ),
            if (!isLoggedIn)
              buildDrawerItem(
                icon: FontAwesomeIcons.signInAlt,
                label: 'Login',
                onTap: widget.onLoginTap,
              ),
            if (isLoggedIn)
              buildDrawerItem(
                icon: FontAwesomeIcons.signOutAlt,
                label: 'Logout',
                onTap: () async => await ApiService().logout(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildDrawerItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      String? route}) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    bool isSelected = (route != null && route == currentRoute);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppColors.blue600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        horizontalTitleGap: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileColor: isSelected ? AppColors.blue600 : null,
        onTap: onTap,
      ),
    );
  }
}
