import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/shimmer_list_loader.dart';
import 'package:ebook_project/screens/ebook_topics.dart';
import 'package:ebook_project/models/ebook_chapter.dart';
import 'package:ebook_project/models/ebook_subject.dart';
import 'package:ebook_project/utils/token_store.dart';
import 'package:flutter/material.dart';

import 'package:ebook_project/components/breadcrumb_bar.dart';
import 'package:ebook_project/components/collapsible_sidebar.dart';

class EbookChaptersPage extends StatefulWidget {
  final String ebookId;
  final String subjectId;
  final String ebookName;
  final bool practice;
  final String subjectTitle;

  const EbookChaptersPage({
    super.key,
    required this.ebookId,
    required this.subjectId,
    required this.ebookName,
    this.practice = false,
    this.subjectTitle = '',
  });

  @override
  State<EbookChaptersPage> createState() => _EbookChaptersState();
}

class _EbookChaptersState extends State<EbookChaptersPage> {
  List<EbookChapter> ebookChapters = [];
  List<EbookSubject> sidebarSubjects = [];

  bool isLoading = true;
  bool isError = false;

  bool sidebarOpen = false;

  @override
  void initState() {
    super.initState();
    fetchSidebarSubjects();
    fetchEbookChapters();
  }

  Future<void> fetchSidebarSubjects() async {
    try {
      final api = ApiService();
      var endpoint = "/v1/ebooks/${widget.ebookId}/subjects";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);
      final list = (data['subjects'] as List? ?? [])
          .map((e) => EbookSubject.fromJson(e))
          .where((s) => s.title.trim().isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() => sidebarSubjects = list);
    } catch (_) {}
  }

  Future<void> fetchEbookChapters() async {
    final api = ApiService();
    try {
      var endpoint = "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);
      if (!mounted) return;
      setState(() {
        ebookChapters =
            (data['chapters'] as List? ?? []).map((e) => EbookChapter.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  String get _subjectTitleResolved {
    if (widget.subjectTitle.trim().isNotEmpty) return widget.subjectTitle.trim();
    final hit = sidebarSubjects.where((s) => s.id.toString() == widget.subjectId).toList();
    if (hit.isNotEmpty) return hit.first.title;
    return 'SUBJECT';
  }

  Future<List<SidebarItem>> _loadChildren(SidebarItem parent) async {
    final api = ApiService();

    if (parent.type == SidebarItemType.subject) {
      var endpoint = "/v1/ebooks/${widget.ebookId}/subjects/${parent.id}/chapters";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);
      final chapters = (data['chapters'] as List? ?? []);

      return chapters
          .map((c) {
        final title = (c['title'] ?? '').toString();
        if (title.trim().isEmpty) return null;
        return SidebarItem(
          id: (c['id'] ?? '').toString(),
          title: title,
          locked: c['locked'] == true,
          type: SidebarItemType.chapter,
          hasChildren: true,
          meta: {'subjectId': parent.id},
        );
      })
          .whereType<SidebarItem>()
          .toList();
    }

    if (parent.type == SidebarItemType.chapter) {
      final subjectId = parent.meta['subjectId'] ?? '';
      if (subjectId.isEmpty) return [];
      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters/${parent.id}/topics";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);
      final topics = (data['topics'] as List? ?? []);

      return topics
          .map((t) {
        final title = (t['title'] ?? '').toString();
        if (title.trim().isEmpty) return null;
        return SidebarItem(
          id: (t['id'] ?? '').toString(),
          title: title,
          locked: t['locked'] == true,
          type: SidebarItemType.topic,
          hasChildren: false,
          meta: {'subjectId': subjectId, 'chapterId': parent.id},
        );
      })
          .whereType<SidebarItem>()
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final List<SidebarItem> sidebarItems = sidebarSubjects
        .map<SidebarItem>((s) => SidebarItem(
      id: s.id.toString(),
      title: s.title,
      locked: s.locked == true,
      type: SidebarItemType.subject,
      hasChildren: true,
    ))
        .toList();

    return AppLayout(
      title: '${widget.ebookName} Chapters',
      body: Stack(
        children: [
          isLoading
              ? const Padding(padding: EdgeInsets.all(12.0), child: ShimmerListLoader())
              : isError
              ? const Center(child: Text('Failed to load chapters'))
              : Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                BreadcrumbBar(
                  items: [_subjectTitleResolved.toUpperCase()],
                  onHome: () => Navigator.pop(context),
                  onTapCrumb: (i) {
                    // i=0 => subject title click
                    Navigator.pop(context); // chapters থেকে back করলে subjects এ যায়
                  },
                ),
                Expanded(
                  child: ebookChapters.isEmpty
                      ? const Center(
                    child: Text(
                      'No Chapters Available',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: ebookChapters.length,
                    itemBuilder: (_, i) {
                      final c = ebookChapters[i];
                      if (c.title.trim().isEmpty) return const SizedBox.shrink();

                      return _GridCard(
                        title: c.title,
                        locked: c.locked == true,
                        icon: Icons.menu_book,
                        onTap: () {
                          if (c.locked == true) {
                            _showSubscriptionDialog(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EbookTopicsPage(
                                ebookId: widget.ebookId,
                                subjectId: widget.subjectId,
                                chapterId: c.id.toString(),
                                ebookName: widget.ebookName,
                                practice: widget.practice,
                                subjectTitle: _subjectTitleResolved,
                                chapterTitle: c.title,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SidebarFloatingButton(onTap: () => setState(() => sidebarOpen = true)),

          CollapsibleSidebar(
            open: sidebarOpen,
            onClose: () => setState(() => sidebarOpen = false),
            headerTitle: 'Subjects',
            items: sidebarItems,
            selectedId: widget.subjectId,
            loadChildren: _loadChildren,
            onTap: (it) {
              // locked click => dialog
              if (it.locked) {
                _showSubscriptionDialog(context);
                return;
              }
              // subject click => open its chapters page
              if (it.type == SidebarItemType.subject) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EbookChaptersPage(
                      ebookId: widget.ebookId,
                      subjectId: it.id,
                      ebookName: widget.ebookName,
                      practice: widget.practice,
                      subjectTitle: it.title,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Subscription Required'),
        content: const Text(
          'This item is locked in practice mode. Please subscribe or purchase access to continue.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/choose-plan/${widget.ebookId}');
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String title;
  final bool locked;
  final IconData icon;
  final VoidCallback onTap;

  const _GridCard({
    required this.title,
    required this.locked,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBEAEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF0c4a6e)),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0f172a),
                    height: 1.15,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
            if (locked) ...[
              const SizedBox(height: 6),
              const Icon(Icons.lock, color: Colors.redAccent, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
