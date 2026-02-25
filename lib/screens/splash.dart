import 'dart:async';
import 'dart:ui';
import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/utils/device_info_util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: .96, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));

    _ac.forward();
    _bootstrap();
  }


  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1100));

    await DeviceInfoUtil.saveDeviceInfo();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    String nextRoute = '/';

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(nextRoute, (route) => false);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          const _SoftGradientBg(),

          // Subtle blurred blobs
          const _BlurBlob(
              top: -80,
              left: -40,
              size: 220,
              color: Color(0xFF38BDF8),
              opacity: .30),
          const _BlurBlob(
              bottom: -60,
              right: -50,
              size: 200,
              color: Color(0xFFA78BFA),
              opacity: .28),
          const _BlurBlob(
              top: 120,
              right: -40,
              size: 160,
              color: Color(0xFF34D399),
              opacity: .24),

          // Center: logo + app name
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.10),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(.16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/app-icon.png',
                          height: 72,
                          width: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF38BDF8), Color(0xFFA78BFA)],
                              ),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Banglamed Ebooks',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // ছোট লোডিং ইন্ডিকেটর (টেক্সট ছাড়াই)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom: developer branding (minimal)
          Positioned(
            bottom: 18,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.developer_mode_rounded,
                    size: 14, color: Colors.white.withOpacity(.85)),
                const SizedBox(width: 6),
                Text(
                  'Digiit Gate IT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient background
class _SoftGradientBg extends StatelessWidget {
  const _SoftGradientBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1.0, -1.0),
          end: Alignment(1.0, 1.0),
          colors: [
            Color(0xFF0EA5E9), // sky-500
            Color(0xFF6366F1), // indigo-500
          ],
        ),
      ),
    );
  }
}

/// Blurred color bubbles
class _BlurBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final double? top, left, right, bottom;

  const _BlurBlob({
    super.key,
    required this.size,
    required this.color,
    required this.opacity,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final blob = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: blob,
      ),
    );
  }
}
