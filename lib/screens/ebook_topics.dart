import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/shimmer_list_loader.dart';
import 'package:ebook_project/models/ebook_subject.dart';
import 'package:ebook_project/models/ebook_chapter.dart';
import 'package:ebook_project/models/ebook_topic.dart';
import 'package:ebook_project/screens/ebook_subjects.dart';
import 'package:ebook_project/screens/ebook_chapters.dart';
import 'package:ebook_project/screens/ebook_contents.dart';
import 'package:ebook_project/utils/token_store.dart';
import 'package:flutter/material.dart';
import 'package:ebook_project/screens/practice/practice_questions.dart';

import 'package:ebook_project/components/breadcrumb_bar.dart';
import 'package:ebook_project/components/collapsible_sidebar.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/theme/app_typography.dart';

class EbookTopicsPage extends StatefulWidget {
  final String ebookId;
  final String subjectId;
  final String chapterId;
  final String ebookName;
  final bool practice;

  final String subjectTitle;
  final String chapterTitle;

  const EbookTopicsPage({
    super.key,
    required this.ebookId,
    required this.subjectId,
    required this.chapterId,
    required this.ebookName,
    this.practice = false,
    this.subjectTitle = '',
    this.chapterTitle = '',
  });

  @override
  State<EbookTopicsPage> createState() => _EbookTopicsState();
}

class _EbookTopicsState extends State<EbookTopicsPage> {
  List<EbookTopic> ebookTopics = [];
  List<EbookSubject> sidebarSubjects = [];

  bool isLoading = true;
  bool isError = false;

  bool sidebarOpen = false;
  bool sidebarLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSidebarSubjects();
    fetchEbookTopics();
  }

  Future<void> fetchSidebarSubjects() async {
    setState(() => sidebarLoading = true);
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
      setState(() {
        sidebarSubjects = list;
        sidebarLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => sidebarLoading = false);
    }
  }

  Future<void> fetchEbookTopics() async {
    try {
      final api = ApiService();
      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);

      if (!mounted) return;
      setState(() {
        ebookTopics = (data['topics'] as List? ?? [])
            .map((t) => EbookTopic.fromJson(t))
            .where((t) => t.title.trim().isNotEmpty)
            .toList();
        isLoading = false;
        isError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  String get _subjectTitleResolved {
    if (widget.subjectTitle.trim().isNotEmpty) return widget.subjectTitle.trim();
    final hit = sidebarSubjects.where((s) => s.id.toString() == widget.subjectId);
    return hit.isNotEmpty ? hit.first.title : 'SUBJECT';
  }

  String get _chapterTitleResolved =>
      widget.chapterTitle.trim().isNotEmpty ? widget.chapterTitle.trim() : 'CHAPTER';

  Future<List<SidebarItem>> _loadChildren(SidebarItem parent) async {
    final api = ApiService();

    if (parent.type == SidebarItemType.subject) {
      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/${parent.id}/chapters";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);
      final chapters = (data['chapters'] as List? ?? [])
          .map((e) => EbookChapter.fromJson(e))
          .where((c) => c.title.trim().isNotEmpty)
          .toList();

      return chapters
          .map<SidebarItem>(
            (c) => SidebarItem(
          id: c.id.toString(),
          title: c.title,
          locked: c.locked == true,
          type: SidebarItemType.chapter,
          hasChildren: true,
          meta: {
            'subjectId': parent.id,
            'subjectTitle': parent.title,
          },
        ),
      )
          .toList();
    }

    if (parent.type == SidebarItemType.chapter) {
      final subjectId = parent.meta['subjectId'] ?? widget.subjectId;

      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters/${parent.id}/topics";
      if (widget.practice) endpoint += "?practice=1";
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final data = await api.fetchEbookData(endpoint);
      final topics = (data['topics'] as List? ?? [])
          .map((e) => EbookTopic.fromJson(e))
          .where((t) => t.title.trim().isNotEmpty)
          .toList();

      return topics
          .map<SidebarItem>(
            (t) => SidebarItem(
          id: t.id.toString(),
          title: t.title,
          locked: t.locked == true,
          type: SidebarItemType.topic,
          hasChildren: false,
          meta: {
            'subjectId': subjectId,
            'subjectTitle': parent.meta['subjectTitle'] ?? _subjectTitleResolved,
            'chapterId': parent.id,
            'chapterTitle': parent.title,
          },
        ),
      )
          .toList();
    }

    return const <SidebarItem>[];
  }

  void _onSidebarTap(SidebarItem it) {
    // locked হলে তোমার subscription dialog
    if (it.locked) {
      _showSubscriptionDialog(context);
      return;
    }

    // ✅ TOPIC click => direct CONTENTS page
    if (it.type == SidebarItemType.topic) {
      final subjectId = it.meta["subjectId"] ?? "";
      final chapterId = it.meta["chapterId"] ?? "";
      final topicId = it.id;

      // Practice Questions special case (চাইলে)
      if (it.title.trim().toLowerCase() == "practice questions") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PracticeQuestionsPage(
              ebookId: widget.ebookId,
              subjectId: subjectId,
              chapterId: chapterId,
              topicId: topicId,
              ebookName: widget.ebookName,
            ),
          ),
        );
        return;
      }

      // practice mode হলে content না খুলে dialog (আগের নিয়ম)
      if (widget.practice == true) {
        _showSubscriptionDialog(context);
        return;
      }

      // ✅ contents page (same page হলে pushReplacement better)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EbookContentsPage(
            ebookId: widget.ebookId,
            subjectId: subjectId,
            chapterId: chapterId,
            topicId: topicId,
            ebookName: widget.ebookName,
            subjectTitle: it.meta["subjectTitle"] ?? "",
            chapterTitle: it.meta["chapterTitle"] ?? "",
            topicTitle: it.title,
          ),
        ),
      );

      return;
    }

    // subject/chapter locked হলে আগে থেকেই _toggleExpand এ onTap call হতে পারে
  }

  @override
  Widget build(BuildContext context) {
    final List<SidebarItem> sidebarItems = sidebarSubjects
        .map<SidebarItem>(
          (s) => SidebarItem(
        id: s.id.toString(),
        title: s.title,
        locked: s.locked == true,
        type: SidebarItemType.subject,
        hasChildren: true,
      ),
    )
        .toList();

    return AppLayout(
      title: '${widget.ebookName} Topics',
      bodyPadding: EdgeInsets.zero,
      body: Stack(
        children: [
          isLoading
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: ShimmerListLoader(),
          )
              : isError
              ? const Center(child: Text('Failed to load topics'))
              : Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                BreadcrumbBar(
                  items: [
                    'SUBJECTS',
                    _subjectTitleResolved.toUpperCase(),
                    _chapterTitleResolved.toUpperCase(),
                  ],
                  onHome: () => Navigator.pop(context),
                  onItemTap: [
                        () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EbookSubjectsPage(
                            ebookId: widget.ebookId,
                            ebookName: widget.ebookName,
                            practice: widget.practice,
                          ),
                        ),
                      );
                    },
                        () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EbookChaptersPage(
                            ebookId: widget.ebookId,
                            subjectId: widget.subjectId,
                            ebookName: widget.ebookName,
                            practice: widget.practice,
                            subjectTitle: _subjectTitleResolved,
                          ),
                        ),
                      );
                    },
                    null,
                  ],
                ),
                Expanded(
                  child: ebookTopics.isEmpty
                      ? const Center(child: Text('No Topics Available'))
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: ebookTopics.length,
                    itemBuilder: (context, index) {
                      final topic = ebookTopics[index];

                      return _GridCard(
                        title: topic.title,
                        locked: topic.locked == true,
                        icon: Icons.description,
                        onTap: () {
                          if (topic.locked == true) {
                            _showSubscriptionDialog(context);
                            return;
                          }

                          if (topic.title.trim().toLowerCase() ==
                              'practice questions') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PracticeQuestionsPage(
                                  ebookId: widget.ebookId,
                                  subjectId: widget.subjectId,
                                  chapterId: widget.chapterId,
                                  topicId: topic.id.toString(),
                                  ebookName: widget.ebookName,
                                ),
                              ),
                            );
                            return;
                          }

                          if (widget.practice) {
                            _showSubscriptionDialog(context);
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EbookContentsPage(
                                ebookId: widget.ebookId,
                                subjectId: widget.subjectId,
                                chapterId: widget.chapterId,
                                topicId: topic.id.toString(),
                                ebookName: widget.ebookName,
                                subjectTitle: _subjectTitleResolved,
                                chapterTitle: _chapterTitleResolved,
                                topicTitle: topic.title,
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
            selectedKey: 'c:${widget.chapterId}',
            loadChildren: _loadChildren,
            onTap: (it) {
              setState(() => sidebarOpen = false);
              _onSidebarTap(it);
            },
          ),

          if (sidebarLoading && sidebarSubjects.isEmpty) const SizedBox.shrink(),
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
          'This topic is locked in practice mode. Please subscribe or purchase access to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowSm, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cardIconTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: AppColors.cardIconBlue),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.gridCardTitle,
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
