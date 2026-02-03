// lib/components/ebook_grid.dart
import 'package:ebook_project/components/under_maintanance_snackbar.dart';
import 'package:ebook_project/models/ebook.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
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
        final cross = _gridCountForWidth(w);
        final aspect = _aspectForWidth(w);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspect,
          ),
          itemCount: ebooks.length,
          itemBuilder: (_, i) => _EbookGridCard(
            ebook: ebooks[i],
            tileIndex: i,
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

  double _aspectForWidth(double w) {
    if (w >= 1280) return 0.78;
    if (w >= 1024) return 0.80;
    if (w >= 768) return 0.72;
    return 0.64;
  }
}

class _EbookGridCard extends StatelessWidget {
  final Ebook ebook;
  final int tileIndex;
  final bool? hasPractice;
  final Future<void> Function(BuildContext, Ebook) onCardTap;
  final Future<void> Function(Ebook)? onBuyTap;
  final bool showStatusBadge;

  const _EbookGridCard({
    required this.ebook,
    required this.tileIndex,
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

  Color get _statusColor =>
      _isExpired ? Colors.red : (_isActive ? Colors.green : Colors.orange);

  bool get _isPending => !_isExpired && !_isActive;

  // Future<void> _goRenewOrExternal() async {
  //   showUnderMaintenanceSnackbar();
  // }

  Future<void> _onTap(BuildContext context) async {
    // if (_isExpired) {
    //   await onCardTap(context, ebook);
    //   return;
    // }
    // if (_isPending) {
    //   await _goRenewOrExternal();
    //   return;
    // }
    await onCardTap(context, ebook);
  }

  Widget _buildPracticeBadge() {
    if (hasPractice != true) {
      return const SizedBox.shrink();
    }

    if (_isActive && !_isExpired) {
      return const SizedBox.shrink();
    }

    final color = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Practice',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget _buildBuyButton() {
  //   return SizedBox(
  //     height: 34,
  //     child: DecoratedBox(
  //       decoration: BoxDecoration(
  //         gradient: AppColors.primaryGradientSoft(),
  //         borderRadius: BorderRadius.circular(10),
  //         boxShadow: AppColors.glassShadow,
  //       ),
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(10),
  //           onTap: () => onBuyTap?.call(ebook),
  //           child: Center(
  //             child: Text(
  //               'Buy',
  //               style: const TextStyle(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.onGradient,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBuyButton(BuildContext context) {
    final enabled = onBuyTap != null;

    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradientSoft() : null,
          color: enabled ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled ? AppColors.glassShadow : const [],
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: !enabled
                ? null
                : () {
              HapticFeedback.lightImpact();
              onBuyTap?.call(ebook);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // left icon capsule
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 16,
                      color: AppColors.onGradient,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // text
                  const Expanded(
                    child: Text(
                      'Buy Now',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppColors.onGradient,
                      ),
                    ),
                  ),

                  // arrow bubble
                  // Container(
                  //   width: 30,
                  //   height: 30,
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withOpacity(0.16),
                  //     borderRadius: BorderRadius.circular(999),
                  //   ),
                  //   child: const Icon(
                  //     Icons.arrow_forward_rounded,
                  //     size: 18,
                  //     color: AppColors.onGradient,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, c) {
              final dense = c.maxHeight < 260;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _isExpired
                                      ? 'Expired'
                                      : (_isActive ? 'Active' : 'Pending'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                ),
                              ),
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
                  Builder(builder: (context) {
                    final titleBoxH = dense ? 36.0 : 48.0;
                    return SizedBox(
                      height: titleBoxH,
                      width: double.infinity,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: c.maxWidth,
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                  textScaler: const TextScaler.linear(1.0)),
                              child: Text(
                                ebook.name,
                                softWrap: true,
                                maxLines: dense ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  height: 1.15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (!dense) ...[
                    const SizedBox(height: 6),
                    _TinyMeta(
                        icon: Icons.timelapse_outlined, value: ebook.validity),
                    const SizedBox(height: 3),
                    _TinyMeta(icon: Icons.event_outlined, value: ebook.ending),
                  ],
                  const SizedBox(height: 8),
                  if (onBuyTap != null) _buildBuyButton(context),
                ],
              );
            },
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

    return Image.network(
      cover,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child:
                Icon(Icons.menu_book_outlined, size: 36, color: Colors.black38),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return Image.network(
          fallbackUrl,
          fit: BoxFit.cover,
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
