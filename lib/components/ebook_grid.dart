// lib/components/ebook_grid.dart
import 'package:ebook_project/models/ebook.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EbookGrid extends StatelessWidget {
  final List<Ebook> ebooks;
  final bool isLoading;
  final Map<int, bool?> practiceAvailability;
  final Future<void> Function(BuildContext, Ebook) onCardTap;
  final Future<void> Function(Ebook)? onBuyTap;
  final bool showStatusBadge;

  const EbookGrid({
    super.key,
    required this.ebooks,
    required this.isLoading,
    required this.practiceAvailability,
    required this.onCardTap,
    this.onBuyTap,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        const gridPadding = 12.0;
        const spacing = 12.0;

        final cross = _gridCountForWidth(w);

        // টাইলের (কার্ডের) আনুমানিক প্রস্থ বের করি
        final tileW =
            (w - (gridPadding * 2) - (spacing * (cross - 1))) / cross;

        // খুব ছোট টাইল হলে meta কমিয়ে “dense” করা
        final dense = tileW < 175;

        // টাইলের উচ্চতা (mainAxisExtent) হিসাব:
        // coverHeight (2/3 ratio -> h = w * 1.5) + extra UI space
        final mainAxisExtent = _mainAxisExtent(
          tileW,
          dense: dense,
          showBuy: onBuyTap != null,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(gridPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,

            // ✅ এটিই মূল fix: টাইলের height নির্দিষ্ট করে দিলাম
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: ebooks.length,
          itemBuilder: (_, i) => _EbookGridCard(
            ebook: ebooks[i],
            tileIndex: i,
            dense: dense,
            hasPractice: practiceAvailability[ebooks[i].id],
            onCardTap: onCardTap,
            onBuyTap: onBuyTap,
            showStatusBadge: showStatusBadge,
          ),
        );
      },
    );
  }

  int _gridCountForWidth(double w) {
    if (w >= 1280) return 5;
    if (w >= 1024) return 4;
    if (w >= 768) return 3;
    return 2;
  }

  double _mainAxisExtent(double tileWidth,
      {required bool dense, required bool showBuy}) {
    // কার্ডের ভিতরের padding = 10 (left+right)
    // তাই cover এর effective width কিছুটা কমে
    final innerW = (tileWidth - 20).clamp(120, 9999);

    // cover: AspectRatio(2/3) => height = width * 3/2
    final coverH = innerW * 1.5;

    // নিচের UI অংশের জন্য extra space (buffer সহ)
    // dense হলে meta লাইন বাদ, তাই extra কম
    final extra = dense
        ? (20 /*card padding vertical*/ +
        8 /*gap after cover*/ +
        40 /*title*/ +
        12 /*gaps*/ +
        (showBuy ? 36 : 0) +
        8 /*buffer*/)
        : (20 /*card padding vertical*/ +
        8 /*gap after cover*/ +
        44 /*title*/ +
        6 /*gap*/ +
        22 /*meta row 1*/ +
        3 /*gap*/ +
        22 /*meta row 2*/ +
        10 /*gaps*/ +
        (showBuy ? 36 : 0) +
        10 /*buffer*/);

    return coverH + extra;
  }
}

class _EbookGridCard extends StatelessWidget {
  final Ebook ebook;
  final int tileIndex;
  final bool dense;
  final bool? hasPractice;
  final Future<void> Function(BuildContext, Ebook) onCardTap;
  final Future<void> Function(Ebook)? onBuyTap;
  final bool showStatusBadge;

  const _EbookGridCard({
    required this.ebook,
    required this.tileIndex,
    required this.dense,
    this.hasPractice,
    required this.onCardTap,
    this.onBuyTap,
    this.showStatusBadge = true,
  });

  String? get _normalizedStatus {
    final status = ebook.status;
    if (status == null) return null;
    return status.toString().trim().toLowerCase();
  }

  bool get _isActive {
    final status = _normalizedStatus;
    return status == 'active' ||
        status == '1' ||
        status == 'true' ||
        ebook.status == 1 ||
        ebook.status == true;
  }

  bool get _isExpired =>
      ebook.isExpired == true || _normalizedStatus == 'expired';

  bool get _isPending => !_isExpired && !_isActive;

  Color get _statusColor =>
      _isExpired ? Colors.red : (_isActive ? Colors.green : Colors.orange);

  Future<void> _onTap(BuildContext context) async {
    await onCardTap(context, ebook);
  }

  Widget _buildPracticeBadge() {
    if (hasPractice != true) return const SizedBox.shrink();
    if (_isActive && !_isExpired) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'Practice',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    if (!_isPending && !_isExpired) return const SizedBox.shrink();

    final label = _isExpired ? 'Expired' : 'Pending';
    final icon = _isExpired ? Icons.error_rounded : Icons.schedule_rounded;
    final color = _statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.85), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    return FractionallySizedBox(
      widthFactor: 0.78,
      child: SizedBox(
        height: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradientDeep(),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                HapticFeedback.lightImpact();
                onBuyTap?.call(ebook);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_checkout_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Buy',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppColors.glassShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onTap(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _CoverImage(
                          imageUrl: ebook.image,
                          fallbackUrl:
                          'https://banglamed.s3.ap-south-1.amazonaws.com/images/default_book.png',
                        ),
                      ),
                      if (showStatusBadge)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IgnorePointer(
                            ignoring: true,
                            child: _buildStatusChip(),
                          ),
                        ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: _buildPracticeBadge(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Title (dense হলে একটু ছোট)
                SizedBox(
                  height: dense ? 40 : 44,
                  width: double.infinity,
                  child: Center(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: Text(
                        ebook.name,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: dense ? 14.5 : 15.5,
                          height: 1.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                if (!dense) ...[
                  _TinyMeta(icon: Icons.timelapse_outlined, value: ebook.validity),
                  const SizedBox(height: 3),
                  _TinyMeta(icon: Icons.event_outlined, value: ebook.ending),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 6),

                if (onBuyTap != null) _buildBuyButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyMeta extends StatelessWidget {
  final IconData icon;
  final String? value;
  const _TinyMeta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = value ?? 'N/A';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  static const _imageHost = 'http://banglamed.net.test';
  final String imageUrl;
  final String fallbackUrl;
  const _CoverImage({required this.imageUrl, required this.fallbackUrl});

  @override
  Widget build(BuildContext context) {
    final String cover =
    (imageUrl.isNotEmpty) ? _normalize(imageUrl) : _normalize(fallbackUrl);

    return Container(
      color: Colors.grey.shade100, // contain হলে সুন্দর ব্যাকগ্রাউন্ড
      alignment: Alignment.center,
      child: Image.network(
        cover,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.menu_book_outlined,
                  size: 36, color: Colors.black38),
            ),
          );
        },
        errorBuilder: (context, error, stack) {
          return Image.network(
            fallbackUrl,
            fit: BoxFit.contain, // ✅ fallback-ও contain
            errorBuilder: (context, _, __) {
              return Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.menu_book_outlined,
                      size: 36, color: Colors.black38),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return fallbackUrl;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return trimmed;
    }
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$_imageHost$path';
  }
}
