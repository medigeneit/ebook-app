import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/theme/app_typography.dart';

enum SidebarItemType { subject, chapter, topic }

class SidebarItem {
  final String id;
  final String title;
  final bool locked;
  final bool hasPractice;

  final SidebarItemType type;
  final bool hasChildren;

  /// subjectId/chapterId carry করার জন্য
  final Map<String, String> meta;

  const SidebarItem({
    required this.id,
    required this.title,
    required this.type,
    this.locked = false,
    this.hasPractice = false,
    this.hasChildren = false,
    this.meta = const {},
  });

  String get key {
    String p = 'i';
    switch (type) {
      case SidebarItemType.subject:
        p = 's';
        break;
      case SidebarItemType.chapter:
        p = 'c';
        break;
      case SidebarItemType.topic:
        p = 't';
        break;
    }
    return '$p:$id';
  }
}

class CollapsibleSidebar extends StatefulWidget {
  final bool open;
  final VoidCallback onClose;

  final String headerTitle;

  final List<SidebarItem> items;

  /// topic click করলে navigate callback
  final void Function(SidebarItem item) onTap;

  /// unique selected highlight (e.g. "s:12", "c:55", "t:99")
  final String? selectedKey;

  final Future<List<SidebarItem>> Function(SidebarItem parent)? loadChildren;

  const CollapsibleSidebar({
    super.key,
    required this.open,
    required this.onClose,
    required this.items,
    required this.onTap,
    this.selectedKey,
    this.loadChildren,
    this.headerTitle = 'Subjects',
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  final Set<String> _expanded = {};
  final Map<String, List<SidebarItem>> _childrenByParentKey = {};
  final Set<String> _loadingParentKeys = {};

  double get _panelW => MediaQuery.of(context).size.width * 0.78;

  IconData _iconFor(SidebarItemType type) {
    switch (type) {
      case SidebarItemType.subject:
        return FontAwesomeIcons.book;
      case SidebarItemType.chapter:
        return FontAwesomeIcons.folderOpen;
      case SidebarItemType.topic:
        return FontAwesomeIcons.fileLines;
    }
  }

  Future<void> _toggleExpand(SidebarItem item) async {
    final k = item.key;

    // locked হলে expand না, parent এ callback (dialog)
    if (item.locked) {
      widget.onTap(item);
      return;
    }

    final willExpand = !_expanded.contains(k);

    setState(() {
      if (willExpand) {
        _expanded.add(k);
      } else {
        _expanded.remove(k);
      }
    });

    if (!willExpand) return;

    if (_childrenByParentKey.containsKey(k)) return;
    if (widget.loadChildren == null) return;
    if (!item.hasChildren) return;

    setState(() => _loadingParentKeys.add(k));
    try {
      final kids = await widget.loadChildren!(item);
      if (!mounted) return;
      setState(() {
        _childrenByParentKey[k] = kids;
      });
    } finally {
      if (!mounted) return;
      setState(() => _loadingParentKeys.remove(k));
    }
  }

  Widget _buildNode(SidebarItem it, int level) {
    final selected = widget.selectedKey != null && it.key == widget.selectedKey;
    final expanded = _expanded.contains(it.key);
    final loading = _loadingParentKeys.contains(it.key);
    final children = _childrenByParentKey[it.key] ?? const <SidebarItem>[];

    final showExpandArrow = it.hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            if (it.type == SidebarItemType.topic) {
              widget.onTap(it);
              widget.onClose();
              return;
            }
            _toggleExpand(it);
          },
          child: Container(
            margin: EdgeInsets.fromLTRB(10 + (level * 8.0), 4, 10, 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.sidebarSelectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: showExpandArrow
                      ? Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    color: Colors.white70,
                    size: 20,
                  )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),

                Icon(_iconFor(it.type), size: 15, color: AppColors.white),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    it.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sidebarItem,
                  ),
                ),

                if (it.locked)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock, color: Colors.redAccent, size: 16),
                  ),
              ],
            ),
          ),
        ),

        if (expanded)
          Padding(
            padding: EdgeInsets.only(left: 18 + (level * 8.0)),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.white24, width: 1)),
              ),
              child: loading && children.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(14),
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                  ),
                ),
              )
                  : Column(
                children: children.map((c) => _buildNode(c, level + 1)).toList(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelW = _panelW;

    return Stack(
      children: [
        if (widget.open)
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: AppColors.sidebarOverlay),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: 0,
          bottom: 0,
          left: widget.open ? 0 : -panelW,
          width: panelW,
          child: Material(
            color: AppColors.sidebarBg,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Row(
                      children: [
                        Text(widget.headerTitle, style: AppTypography.sidebarHeader),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: widget.items.map((it) => _buildNode(it, 0)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SidebarFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  const SidebarFloatingButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      bottom: 10,
      child: SafeArea(
        top: false,
        child: Material(
          elevation: 6,
          color: AppColors.floatingBtnBg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.menu, color: AppColors.blue900),
            ),
          ),
        ),
      ),
    );
  }
}
