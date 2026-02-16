import 'package:flutter/material.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/theme/app_typography.dart';

class BreadcrumbBar extends StatelessWidget {
  final List<String> items; // e.g. ["SUBJECTS", "ANATOMY", "HISTOLOGY"]
  final List<VoidCallback?>? onItemTap; // same length (optional)
  final VoidCallback? onHome;

  const BreadcrumbBar({
    super.key,
    required this.items,
    this.onItemTap,
    this.onHome,
  });

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
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InkWell(
            onTap: onHome,
            child: const Icon(Icons.home, size: 18, color: AppColors.blue900),
          ),
          const SizedBox(width: 8),
          ..._crumbs(),
        ],
      ),
    );
  }

  List<Widget> _crumbs() {
    final out = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      out.add(const Icon(Icons.chevron_right, size: 18, color: Colors.black45));

      final cb = (onItemTap != null && i < onItemTap!.length) ? onItemTap![i] : null;

      out.add(
        InkWell(
          onTap: cb,
          child: Text(
            items[i],
            style: AppTypography.breadcrumbItem.copyWith(
              decoration: cb != null ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      );

      if (i != items.length - 1) out.add(const SizedBox(width: 8));
    }
    return out;
  }
}
