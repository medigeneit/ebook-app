import 'package:flutter/material.dart';

class BreadcrumbBar extends StatelessWidget {
  /// Example: ["SUBJECTS", "ANATOMY", "CHAPTER 1", "TOPICS"]
  final List<String> items;

  /// Home icon click
  final VoidCallback? onHome;

  /// Crumb click: index pass করে
  /// index = 0 means first item, index = items.length-1 means last
  final void Function(int index)? onTapCrumb;

  /// Optional: last crumb clickable হবে কিনা
  final bool lastCrumbClickable;

  const BreadcrumbBar({
    super.key,
    required this.items,
    this.onHome,
    this.onTapCrumb,
    this.lastCrumbClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InkWell(
            onTap: onHome,
            child: const Icon(Icons.home, size: 18, color: Color(0xFF0c4a6e)),
          ),
          const SizedBox(width: 8),
          ..._crumbs(context),
        ],
      ),
    );
  }

  List<Widget> _crumbs(BuildContext context) {
    final out = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      out.add(const Icon(Icons.chevron_right, size: 18, color: Colors.black45));

      final isLast = i == items.length - 1;
      final clickable = onTapCrumb != null && (!isLast || lastCrumbClickable);

      out.add(
        InkWell(
          onTap: clickable ? () => onTapCrumb!(i) : null,
          child: Text(
            items[i],
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: clickable ? const Color(0xFF0c4a6e) : const Color(0xFF111827),
              decoration: clickable ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      );

      if (i != items.length - 1) out.add(const SizedBox(width: 8));
    }
    return out;
  }
}
