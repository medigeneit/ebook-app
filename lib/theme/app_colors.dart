import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF3B82F6); // Blue 500 (milder)
  static const Color primaryDeep = Color(0xFF2563EB); // Blue 600 (slightly deeper)
  static const Color secondary = Color(0xFF6366F1); // Indigo 500
  static const Color accent = Color(0xFF10B981); // Emerald 500

  // Neutrals
  static const Color bg = Color(0xFFF8FAFC); // very light
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600

  // Inputs
  static const Color inputFill = Colors.white;
  static const Color inputBorder = Color(0xFFE5E7EB); // Slate 200
  static const Color inputFocus = primary;

  // Header / subtle gradients (low alpha)
  static const Color headerTintA = Color(0x143B82F6); // 8% of primary
  static const Color headerTintB = Color(0x106366F1); // 6% of secondary

  // NavBar
  static const Color navBg = Color(0xFFF2F4F8);
  static const Color navIndicator = Color(0x263B82F6); // 15% primary

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  // Card shadow
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 10),
    ),
  ];

  // app_colors.dart (Add these)
  // Cards
  static const Color cardBorder = Color(0xFFE5E7EB); // subtle border

  // Chips
  static const Color chipActiveBg = Color(0xE616A34A); // success with opacity
  static const Color chipExpiredBg = Color(0xE6DC2626); // danger with opacity

  // Buttons (toned)
  static const Color btnRead = primary; // main action
  static const Color btnRenew = Color(0xFFEF4444); // red 500 (outlined/tonal)
  static const Color btnContinue = Color(0xFF6366F1); // indigo 500

// Pastel tints (50-range)
  static const Color cardTintNeutral = Color(0xFFF8FAFC); // Slate-50
  static const Color cardTintBlue = Color(0xFFEFF6FF); // Blue-50
  static const Color cardTintIndigo = Color(0xFFEEF2FF); // Indigo-50
  static const Color cardTintEmerald = Color(0xFFECFDF5); // Emerald-50
  static const Color cardTintAmber = Color(0xFFFFFBEB); // Amber-50
  static const Color cardTintRose = Color(0xFFFFF1F2); // Rose-50

  static const List<Color> cardTints = [
    cardTintNeutral,
    cardTintBlue,
    cardTintIndigo,
    cardTintEmerald,
    cardTintAmber,
    cardTintRose,
  ];

// সূক্ষ্ম সহায়তাকারী
  static Color cardTintByIndex(int i) => cardTints[i % cardTints.length];

  static Color cardTintByStatus(String status) =>
      status == 'Active' ? cardTintEmerald : cardTintRose;

  static const List<List<Color>> cardGradientSets = [
    [Color(0xFF2563EB), Color(0xFF1E40AF)], // blue → blue-800
    [Color(0xFF4F46E5), Color(0xFF4338CA)], // indigo-600 → indigo-700
    [Color(0xFF059669), Color(0xFF047857)], // emerald-600 → 700
    [Color(0xFF0891B2), Color(0xFF0E7490)], // cyan-600 → 700
    [Color(0xFFD97706), Color(0xFFB45309)], // amber-600 → 700
    [Color(0xFF7C3AED), Color(0xFF6D28D9)], // violet-600 → 700
    [Color(0xFFDB2777), Color(0xFFBE185D)], // pink-600 → 700
    [Color(0xFF16A34A), Color(0xFF166534)], // green-600 → 800
  ];

  static List<Color> cardGradientByIndex(int i) =>
      cardGradientSets[i % cardGradientSets.length];

// Text/controls on top of gradient
  static const Color onGradient = Colors.white;
  static const Color onGradientSoft = Color(0xE6FFFFFF); // 90% white

// Chips (on gradient)
  static const Color chipOnGradientBg = Color(0x33FFFFFF); // 20% white
  static const Color chipOnGradientBorder = Color(0x66FFFFFF); // 40% white

  static LinearGradient _glassyPair(List<Color> pair, double opacity) {
    final c1 = pair[0];
    final c2 = pair[1];
    final mid =
        Color.lerp(c1, Colors.white, .08)!; // লাইট মিক্স (রিডেবিলিটি বজায়)
    return LinearGradient(
      colors: [
        c1.withOpacity(opacity),
        mid.withOpacity(opacity),
        c2.withOpacity(opacity),
      ],
      stops: const [0.0, 0.55, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// 🔵 ডিফল্ট (unknown/fallback)
  static const List<Color> _gDefault = [
    Color(0xFF2563EB),
    Color(0xFF1E40AF)
  ]; // blue 600→800
  /// ✅ Active
  static const List<Color> _gActive = [
    Color(0xFF059669),
    Color(0xFF047857)
  ]; // emerald 600→700
  /// ❌ Expired
  static const List<Color> _gExpired = [
    Color(0xFFDB2777),
    Color(0xFFBE185D)
  ]; // pink 600→700
  /// ⏳ Pending
  static const List<Color> _gPending = [
    Color(0xFFD97706),
    Color(0xFFB45309)
  ]; // amber 600→700

  /// 🎨 স্ট্যাটাস টেক্সট (Active/Expired/Pending) অনুযায়ী glassy gradient
  static LinearGradient glassyGradientByStatus(String status,
      {double opacity = 1.0}) {
    final s = status.trim().toLowerCase();
    if (s == 'active') return _glassyPair(_gActive, opacity);
    if (s == 'expired') return _glassyPair(_gExpired, opacity);
    if (s == 'pending') return _glassyPair(_gPending, opacity);
    return _glassyPair(_gDefault, opacity);
  }

  /// 🧠 ইবুক ফ্ল্যাগ দিয়ে নির্ধারণ (আরও রোবাস্ট)
  /// - `isExpired == true` হলে সরাসরি Expired
  /// - নাহলে `statusText` (Active/Pending/Expired) প্রাধান্য
  /// - নাহলে `status == 1` হলে Active, অন্যথায় Pending
  static LinearGradient glassyGradientForEbook({
    bool? isExpired,
    int? status,
    String? statusText,
    double opacity = 1.0,
  }) {
    if (isExpired == true) {
      return _glassyPair(_gExpired, opacity);
    }
    if (statusText != null && statusText.trim().isNotEmpty) {
      return glassyGradientByStatus(statusText, opacity: opacity);
    }
    if (status == 1) return _glassyPair(_gActive, opacity);
    if (status == 0) return _glassyPair(_gPending, opacity);
    return _glassyPair(_gDefault, opacity);
  }

  static LinearGradient glassyGradientByIndex(int i, {double opacity = 1.0}) {
    final g = cardGradientSets[i % cardGradientSets.length];
    final c1 = g.first;
    final c2 = g.last;
    final mid = Color.lerp(c1, Colors.white, .08)!; // আগে .22 ছিল, এখন .08
    return LinearGradient(
      colors: [
        c1.withOpacity(opacity),
        mid.withOpacity(opacity),
        c2.withOpacity(opacity)
      ],
      stops: const [0.0, 0.55, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// ডায়াগোনাল শাইন (টপ-লেফট → বটম-রাইট)
  static const LinearGradient glassShineDiagonal = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// টপ-লেফট গ্লেয়ার (র্যাডিয়াল হাইলাইট)
  static const RadialGradient glassGleamTL = RadialGradient(
    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
    radius: 0.85,
    center: Alignment(-0.9, -0.9),
  );

  /// শ্যাডো একটু নরম + রিম হালকা হাইলাইট
  static const List<BoxShadow> glassShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 10)),
  ];

  static const Color blue600 = Color(0xFF2563EB); // Colors.blue.shade600
  static const Color blue800 = Color(0xFF1E40AF); // Colors.blue.shade800

  static final Color blueShade600 =
      Colors.blue.shade600; // Colors.blue.shade800
  static final Color blueShade800 =
      Colors.blue.shade800; // Colors.blue.shade800

// Inactive icon color
  static const Color slate500 = Color(0xFF64748B); // Colors.slate.shade500

// Convenience (if not already declared in your file)
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

// NavigationBar indicator → Colors.blue.shade600.withOpacity(0.12)
// 0.12 * 255 ≈ 0x1F
  static const Color navIndicatorBlue600_12 = Color(0x1F2563EB);

// Optional helper: the same gradient used in app_layout.dart
  static LinearGradient primaryGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [blue600, blue800],
      );

  static LinearGradient primaryGradientDeep() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      );

  static LinearGradient primaryGradientSoft() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          blue600.withOpacity(0.85),
          blue800.withOpacity(0.75),
        ],
      );

  // --- Sidebar / Navigation ---
  static const Color sidebarBg = Color(0xFF0B5B77);
  static const Color sidebarOverlay = Color(0x73000000); // = Colors.black45
  static const Color sidebarSelectedBg = Color(0x1FFFFFFF); // white 12%
  static const Color shadowSm = Color(0x1F000000); // = Colors.black12

// --- Cards ---
  static const Color gridCardBg = Color(0xFFFBEAEC);

// --- Floating button ---
  static const Color floatingBtnBg = Color(0xFFF3F4F6);

  static const Color text = Color(0xFF0F172A); // slate-900 type

  static const Color blue900 = Color(0xFF0C4A6E); // তোমার UI তে যেটা ব্যবহার করছো

}
