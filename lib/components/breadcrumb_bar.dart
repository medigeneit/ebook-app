import 'package:flutter/material.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/theme/app_typography.dart';

class BreadcrumbBar extends StatefulWidget {
  final List<String> items;
  final List<VoidCallback?>? onItemTap;
  final VoidCallback? onHome;

  final int leadingCount;

  const BreadcrumbBar({
    super.key,
    required this.items,
    this.onItemTap,
    this.onHome,
    this.leadingCount = 2,
  });

  @override
  State<BreadcrumbBar> createState() => _BreadcrumbBarState();
}

class _BreadcrumbBarState extends State<BreadcrumbBar> {
  final ScrollController _sc = ScrollController();

  bool _canScrollRight = false;
  bool _canScrollLeft = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_recalc);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
  }

  @override
  void didUpdateWidget(covariant BreadcrumbBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
    }
  }

  void _recalc() {
    if (!_sc.hasClients) return;

    final max = _sc.position.maxScrollExtent;
    final off = _sc.offset;

    final canRight = max > 0 && off < max - 1;
    final canLeft = max > 0 && off > 1;

    if (canRight != _canScrollRight || canLeft != _canScrollLeft) {
      setState(() {
        _canScrollRight = canRight;
        _canScrollLeft = canLeft;
      });
    }
  }

  void _scrollByPage({required bool toRight}) {
    if (!_sc.hasClients) return;

    final viewport = _sc.position.viewportDimension; // visible width
    final delta = viewport * 0.8; // এক ক্লিকে 80% width পরিমান স্ক্রল

    final target = toRight ? (_sc.offset + delta) : (_sc.offset - delta);
    final clamped = target.clamp(0.0, _sc.position.maxScrollExtent);

    _sc.animateTo(
      clamped,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _sc.removeListener(_recalc);
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowSm, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onHome,
            child: const Icon(Icons.home, size: 18, color: AppColors.blue900),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: SizedBox(
              height: 34,
              child: Stack(
                children: [
                  // scrollable crumbs
                  ListView.separated(
                    controller: _sc,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.items.length,
                    padding: const EdgeInsets.only(right: 36), // ✅ button space
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4), // gap কমালাম
                      child: Icon(Icons.chevron_right, size: 16, color: Colors.black45),
                    ),
                    itemBuilder: (context, idx) {
                      final cb = (widget.onItemTap != null && idx < widget.onItemTap!.length)
                          ? widget.onItemTap![idx]
                          : null;

                      return _crumbChip(
                        context,
                        label: widget.items[idx],
                        onTap: cb,
                        isLast: idx == widget.items.length - 1,
                      );
                    },
                  ),

                  // ✅ right fade (hint)
                  Positioned(
                    right: 34,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.white.withOpacity(0.0),
                              AppColors.white.withOpacity(0.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ✅ RIGHT BUTTON (click => scroll right)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _ScrollButton(
                      enabled: _canScrollRight,
                      icon: Icons.chevron_right,
                      onTap: () => _scrollByPage(toRight: true),
                    ),
                  ),

                  // (optional) LEFT BUTTON (তুমি চাইলে রাখো)
                  // Positioned(
                  //   left: 0,
                  //   top: 0,
                  //   bottom: 0,
                  //   child: _ScrollButton(
                  //     enabled: _canScrollLeft,
                  //     icon: Icons.chevron_left,
                  //     onTap: () => _scrollByPage(toRight: false),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crumbChip(
      BuildContext context, {
        required String label,
        VoidCallback? onTap,
        required bool isLast,
      }) {
    final maxW = MediaQuery.of(context).size.width * (isLast ? 0.45 : 0.28);

    final textStyle = AppTypography.breadcrumbItem.copyWith(
      color: isLast ? AppColors.blue900 : Colors.black87,
      decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
    );

    final chip = Chip(
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: textStyle,
        ),
      ),
      backgroundColor: isLast ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }
}

class _ScrollButton extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  const _ScrollButton({
    required this.enabled,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF3F4F6) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black54 : Colors.black26,
        ),
      ),
    );
  }
}
