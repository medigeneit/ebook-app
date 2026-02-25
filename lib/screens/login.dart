import 'dart:ui' as ui;
import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/screens/app.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/main.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebook_project/services/local_storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String title, String message,
      {Color bgColor = AppColors.primary, IconData? icon}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: bgColor,
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
      shouldIconPulse: false,
      titleText: const Text('', style: TextStyle(height: 0)),
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Invalid Input', 'Please check your entries.',
          bgColor: AppColors.warning, icon: Icons.warning_amber_rounded);
      return;
    }
    setState(() => _loading = true);

    final api = ApiService();
    final username = _username.text.trim();
    final password = _password.text.trim();

    try {
      final raw = await api.postData('/login', {
        'username': username,
        'password': password,
      });

      if (raw == null) {
        _snack('Server Error', 'Please try again later.',
            bgColor: AppColors.danger, icon: Icons.error_outline);
        return;
      }

      final Map<String, dynamic> data = (raw is Map)
          ? Map<String, dynamic>.from(raw as Map)
          : <String, dynamic>{};

      final errVal = data['error'];
      final int error = (errVal is int)
          ? errVal
          : (errVal is bool)
              ? (errVal ? 1 : 0)
              : (errVal is String)
                  ? (int.tryParse(errVal) ?? 0)
                  : 0;

      if (error > 0) {
        _snack(
            'Login Failed', (data['message'] ?? 'Please try again.').toString(),
            bgColor: AppColors.danger, icon: Icons.error_outline);
        return;
      }

      final token = data['token']?.toString();
      final name = data['name']?.toString() ?? 'User';

      if (token == null || token.isEmpty) {
        _snack('Token Missing', 'Unable to proceed.',
            bgColor: AppColors.danger, icon: Icons.error_outline);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('userName', name);
      await LocalStorageService.setString(LocalStorageService.token, token);

      _snack('Welcome back!', 'Signed in successfully.',
          bgColor: AppColors.success, icon: Icons.check_circle_rounded);

      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 450));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyHomePage(title: "My Ebooks")),
      );
    } catch (e) {
      _snack('Network Error', e.toString(),
          bgColor: AppColors.danger, icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _loginCard(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: context.loginCardMaxWidth),
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 18 : 22,
            vertical: context.isMobile ? 20 : 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset('assets/app-icon.png', height: 64),
                ),
                SizedBox(height: context.gapM),
                Text("Welcome back!", style: t.displaySmall),
                const SizedBox(height: 6),
                Text("Sign in to your account",
                    style: t.bodyLarge, textAlign: TextAlign.center),
                SizedBox(height: context.gapL),

                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Username is required'
                      : null,
                ),
                SizedBox(height: context.gapM),

                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                SizedBox(height: context.gapL),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ),
                SizedBox(height: context.gapM),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () =>
                              Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text("Forgot password?"),
                    ),
                    const SizedBox(width: 12),
                    const Text("•"),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.pushNamed(context, '/sign-up'),
                      child: const Text("Create account"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftInfoPanel(BuildContext context) {
    // বড় স্ক্রিনে বাম প্যানেলের subtle info/branding
    final t = Theme.of(context).textTheme;
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerTintA, AppColors.headerTintB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 56, color: Colors.black54),
                const SizedBox(height: 16),
                Text("All your ebooks,\norganized beautifully.",
                    style: t.displaySmall),
                const SizedBox(height: 8),
                Text(
                  "Access courses, track progress, and read anywhere.",
                  style: t.bodyLarge,
                ),
                const Spacer(),
                const Text("© Ebook Project",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "Login",
      showDrawer: false,
      showNavBar: false,
      body: Stack(
        children: [
          // Soft blobs (background)
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.headerTintA, AppColors.headerTintB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.headerTintB, AppColors.headerTintA],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),

          // Responsive content bound
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 6 : 10,
                  vertical: context.isMobile ? 10 : 16,
                ),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    // tablet/desktop = 2 columns
                    if (ResponsiveContext(ctx).isTablet ||
                        ResponsiveContext(ctx).isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 11,
                            child: Padding(
                              padding: EdgeInsets.only(right: ctx.gapM),
                              child: _leftInfoPanel(ctx),
                            ),
                          ),
                          Expanded(
                            flex: 10,
                            child: Center(child: _loginCard(ctx)),
                          ),
                        ],
                      );
                    }

                    // mobile = single column
                    return Center(child: _loginCard(ctx));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
