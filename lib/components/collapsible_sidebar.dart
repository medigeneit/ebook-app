import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SidebarItemType { subject, chapter, topic }

class SidebarItem {
  final String id;
  final String title;
  final bool locked;

  final SidebarItemType type;
  final bool hasChildren;

  /// carry ids for navigation: subjectId/chapterId
  final Map<String, String> meta;

  const SidebarItem({
    required this.id,
    required this.title,
    required this.type,
    this.locked = false,
    this.hasChildren = false,
    this.meta = const {},
  });
}

class CollapsibleSidebar extends StatefulWidget {
  final bool open;
  final VoidCallback onClose;

  /// Root level items (subjects)
  final List<SidebarItem> items;

  /// Leaf (topic) click করলে navigate/handle
  final void Function(SidebarItem item) onTap;

  final String? selectedId;

  /// Lazy load:
  /// subject -> chapters
  /// chapter -> topics
  final Future<List<SidebarItem>> Function(SidebarItem parent)? loadChildren;

  /// header title (optional)
  final String headerTitle;

  const CollapsibleSidebar({
    super.key,
    required this.open,
    required this.onClose,
    required this.items,
    required this.onTap,
    this.selectedId,
    this.loadChildren,
    this.headerTitle = 'Subjects',
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  final Set<String> _expanded = {};
  final Map<String, List<SidebarItem>> _childrenByParent = {};
  final Set<String> _loadingParentIds = {};

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
    final id = "${item.type.name}:${item.id}";

    if (item.locked) {
      widget.onTap(item);
      return;
    }

    final willExpand = !_expanded.contains(id);

    setState(() {
      if (willExpand) {
        _expanded.add(id);
      } else {
        _expanded.remove(id);
      }
    });

    if (!willExpand) return;
    if (_childrenByParent.containsKey(id)) return;

    if (widget.loadChildren == null) return;
    if (!item.hasChildren) return;

    setState(() => _loadingParentIds.add(id));
    try {
      final kids = await widget.loadChildren!(item);
      if (!mounted) return;
      setState(() => _childrenByParent[id] = kids);
    } finally {
      if (!mounted) return;
      setState(() => _loadingParentIds.remove(id));
    }
  }

  Widget _buildNode(SidebarItem it, int level) {
    final key = "${it.type.name}:${it.id}";
    final selected = widget.selectedId != null && it.id == widget.selectedId;
    final expanded = _expanded.contains(key);
    final loading = _loadingParentIds.contains(key);
    final children = _childrenByParent[key] ?? const <SidebarItem>[];

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
            margin: EdgeInsets.fromLTRB(10 + (level * 10.0), 4, 10, 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
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
                Icon(_iconFor(it.type), size: 15, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    it.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
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
            padding: EdgeInsets.only(left: 18 + (level * 10.0)),
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
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
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
            child: Container(color: Colors.black45),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: 0,
          bottom: 0,
          left: widget.open ? 0 : -panelW,
          width: panelW,
          child: Material(
            color: const Color(0xFF0b5b77),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Row(
                      children: [
                        Text(
                          widget.headerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close, color: Colors.white),
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
          color: const Color(0xFFF3F4F6),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.menu, color: Color(0xFF0c4a6e)), // three-dot feel
            ),
          ),
        ),
      ),
    );
  }
}
