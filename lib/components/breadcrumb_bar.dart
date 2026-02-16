import 'package:flutter/material.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/theme/app_typography.dart';

class BreadcrumbBar extends StatelessWidget {
  final List<String>
      items; // ["SUBJECTS", "PATHOLOGY", "ALL DEFINITION AT A GLANCE", ...]
  final List<VoidCallback?>? onItemTap; // same length (optional)
  final VoidCallback? onHome;

  /// 1 => first + … + last
  /// 2 => first + second + … + last
  final int leadingCount;

  const BreadcrumbBar({
    super.key,
    required this.items,
    this.onItemTap,
    this.onHome,
    this.leadingCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final crumbs = _buildCollapsedItems(context, items, leadingCount);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowSm, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onHome,
            child: const Icon(Icons.home, size: 18, color: AppColors.blue900),
          ),
          const SizedBox(width: 10),

          // No scroll, chip style, overflow safe
          Expanded(
            child: SizedBox(
              height: 34,
              child: Stack(
                children: [
                  // scrollable crumbs
                  ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    padding: const EdgeInsets.only(right: 26),
                    // ✅ indicator space
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right,
                          size: 16, color: Colors.black45),
                    ),
                    itemBuilder: (context, idx) {
                      final cb = (onItemTap != null && idx < onItemTap!.length)
                          ? onItemTap![idx]
                          : null;

                      return _crumbChip(
                        context,
                        label: items[idx],
                        onTap: cb,
                        isLast: idx == items.length - 1,
                      );
                    },
                  ),

                  // ✅ right fade + arrow indicator (always visible)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 26,
                        alignment: Alignment.centerRight,
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
                        child: const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BottomSheet ----------
  void _openAllPathsSheet(BuildContext context) {
    if (items.length <= 3) return;

    // leading 1/2 বাদ দিয়ে last বাদ দিয়ে মাঝখানের অংশ
    final lead = leadingCount.clamp(1, 2);
    final middleStart = lead;
    final middleEnd = items.length - 1; // last excluded

    final middleIndexes = <int>[];
    for (int i = middleStart; i < middleEnd; i++) {
      middleIndexes.add(i);
    }

    if (middleIndexes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree_outlined,
                        size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      'Paths',
                      style: AppTypography.breadcrumbItem.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: middleIndexes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final originalIndex = middleIndexes[i];
                      final label = items[originalIndex];
                      final cb = (onItemTap != null &&
                              originalIndex < onItemTap!.length)
                          ? onItemTap![originalIndex]
                          : null;

                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        leading: const Icon(Icons.chevron_right,
                            size: 18, color: Colors.black45),
                        title: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.breadcrumbItem.copyWith(
                            fontSize: 12,
                            color:
                                cb != null ? AppColors.blue900 : Colors.black87,
                            decoration: cb != null
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                        onTap: cb == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                cb();
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- helpers ----------
  _CrumbChipData _mapToData(int originalIndex) {
    final cb = (onItemTap != null && originalIndex < onItemTap!.length)
        ? onItemTap![originalIndex]
        : null;
    return _CrumbChipData(
        label: items[originalIndex], onTap: cb, isEllipsis: false);
  }

  List<_CrumbChipData> _buildCollapsedItems(
      BuildContext context, List<String> items, int leadingCount) {
    if (items.isEmpty) return [];

    // ছোট হলে সব দেখাও
    if (items.length <= 3) {
      return List.generate(items.length, (i) => _mapToData(i));
    }

    final lead = leadingCount.clamp(1, 2);
    final out = <_CrumbChipData>[];

    // first (and maybe second)
    for (int i = 0; i < lead && i < items.length - 1; i++) {
      out.add(_mapToData(i));
    }

    // ellipsis
    out.add(const _CrumbChipData(label: '…', onTap: null, isEllipsis: true));

    // last
    out.add(_mapToData(items.length - 1));

    return out;
  }

  Widget _ellipsisChip(BuildContext context, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        label: Text('…',
            style:
                AppTypography.breadcrumbItem.copyWith(color: Colors.black54)),
        backgroundColor: const Color(0xFFF3F4F6),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _crumbChip(BuildContext context,
      {required String label, VoidCallback? onTap, required bool isLast}) {
    final maxW = MediaQuery.of(context).size.width * (isLast ? 0.45 : 0.28);

    final textStyle = AppTypography.breadcrumbItem.copyWith(
      color: isLast ? AppColors.blue900 : Colors.black87,
      decoration:
          onTap != null ? TextDecoration.underline : TextDecoration.none,
    );

    final chip = Chip(
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
      backgroundColor:
          isLast ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }
}

class _CrumbChipData {
  final String label;
  final VoidCallback? onTap;
  final bool isEllipsis;

  const _CrumbChipData({
    required this.label,
    required this.onTap,
    required this.isEllipsis,
  });
}
