import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/shimmer_list_loader.dart';
import 'package:ebook_project/screens/ebook_contents.dart';
import 'package:ebook_project/models/ebook_topic.dart';
import 'package:ebook_project/models/ebook_subject.dart';
import 'package:flutter/material.dart';
import 'package:ebook_project/utils/token_store.dart';
import 'package:ebook_project/screens/practice/practice_questions.dart';

import 'package:ebook_project/components/breadcrumb_bar.dart';
import 'package:ebook_project/components/collapsible_sidebar.dart';
import 'package:ebook_project/screens/ebook_chapters.dart';

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
  _EbookTopicsState createState() => _EbookTopicsState();
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

  bool _isLocked(dynamic v) => v == true || v == 1 || v == '1';

  Future<void> fetchSidebarSubjects() async {
    setState(() => sidebarLoading = true);
    try {
      final api = ApiService();
      var endpoint = "/v1/ebooks/${widget.ebookId}/subjects";
      if (widget.practice) endpoint += "?practice=1";
      if (widget.practice) {
        endpoint = await TokenStore.attachPracticeToken(endpoint);
      }

      final data = await api.fetchEbookData(endpoint);
      final list = (data['subjects'] as List? ?? [])
          .map((e) => EbookSubject.fromJson(e))
          .where((s) => s.title.isNotEmpty)
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
    final apiService = ApiService();
    try {
      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics";
      if (widget.practice) endpoint += "?practice=1";
      if (widget.practice) {
        endpoint = await TokenStore.attachPracticeToken(endpoint);
      }

      final data = await apiService.fetchEbookData(endpoint);
      setState(() {
        ebookTopics =
            (data['topics'] as List).map((e) => EbookTopic.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  String get _subjectTitleResolved {
    if (widget.subjectTitle.trim().isNotEmpty) return widget.subjectTitle.trim();
    final hit =
    sidebarSubjects.where((s) => s.id.toString() == widget.subjectId).toList();
    if (hit.isNotEmpty) return hit.first.title;
    return 'SUBJECT';
  }

  String get _chapterTitleResolved =>
      widget.chapterTitle.trim().isNotEmpty ? widget.chapterTitle.trim() : 'CHAPTER';

  // ✅ Tree children loader: Subject -> Chapters, Chapter -> Topics
  Future<List<SidebarItem>> _loadChildren(SidebarItem parent) async {
    final api = ApiService();

    if (parent.type == SidebarItemType.subject) {
      final subjectId = parent.id;

      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters";
      if (widget.practice) endpoint += "?practice=1";
      if (widget.practice) {
        endpoint = await TokenStore.attachPracticeToken(endpoint);
      }

      final data = await api.fetchEbookData(endpoint);
      final chapters = (data['chapters'] as List? ?? []);

      return chapters
          .map<SidebarItem?>((c) {
        final id = (c['id'] ?? '').toString();
        final title = (c['title'] ?? c['name'] ?? '').toString();
        final locked = _isLocked(c['locked']);
        if (title.trim().isEmpty) return null;

        return SidebarItem(
          id: id,
          title: title,
          locked: locked,
          type: SidebarItemType.chapter,
          hasChildren: true,
          meta: {
            'subjectId': subjectId,
            'subjectTitle': parent.title,
          },
        );
      })
          .whereType<SidebarItem>()
          .toList();
    }

    if (parent.type == SidebarItemType.chapter) {
      final subjectId = parent.meta['subjectId'] ?? '';
      final chapterId = parent.id;

      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters/$chapterId/topics";
      if (widget.practice) endpoint += "?practice=1";
      if (widget.practice) {
        endpoint = await TokenStore.attachPracticeToken(endpoint);
      }

      final data = await api.fetchEbookData(endpoint);
      final topics = (data['topics'] as List? ?? []);

      return topics
          .map<SidebarItem?>((t) {
        final id = (t['id'] ?? '').toString();
        final title = (t['title'] ?? t['name'] ?? '').toString();
        final locked = _isLocked(t['locked']);
        if (title.trim().isEmpty) return null;

        return SidebarItem(
          id: id,
          title: title,
          locked: locked,
          type: SidebarItemType.topic,
          hasChildren: false,
          meta: {
            'subjectId': subjectId,
            'chapterId': chapterId,
            'subjectTitle': parent.meta['subjectTitle'] ?? '',
            'chapterTitle': parent.title,
          },
        );
      })
          .whereType<SidebarItem>()
          .toList();
    }

    return [];
  }

  void _handleSidebarTap(SidebarItem it) {
    if (it.locked) {
      _showSubscriptionDialog(context);
      return;
    }

    if (it.type != SidebarItemType.topic) return;

    final subjectId = it.meta['subjectId'] ?? '';
    final chapterId = it.meta['chapterId'] ?? '';
    final topicId = it.id;

    final subjectTitle = (it.meta['subjectTitle'] ?? _subjectTitleResolved).trim();
    final chapterTitle = (it.meta['chapterTitle'] ?? _chapterTitleResolved).trim();
    final topicTitle = it.title.trim();

    final low = topicTitle.toLowerCase();
    final isPracticeQuestions =
    (low == 'practice questions' || low == 'practice question');

    if (widget.practice && !isPracticeQuestions) {
      _showSubscriptionDialog(context);
      return;
    }

    if (isPracticeQuestions) {
      Navigator.pushReplacement(
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EbookContentsPage(
          ebookId: widget.ebookId,
          subjectId: subjectId,
          chapterId: chapterId,
          topicId: topicId,
          ebookName: widget.ebookName,
          subjectTitle: subjectTitle,
          chapterTitle: chapterTitle,
          topicTitle: topicTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<SidebarItem> sidebarItems = sidebarSubjects
        .where((s) => s.title.isNotEmpty)
        .map<SidebarItem>((s) => SidebarItem(
      id: s.id.toString(),
      title: s.title,
      locked: s.locked == true,
      type: SidebarItemType.subject,
      hasChildren: true,
      meta: {'subjectTitle': s.title},
    ))
        .toList();

    return AppLayout(
      title: '${widget.ebookName} Topics',
      body: Stack(
        children: [
          isLoading
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: ShimmerListLoader(),
          )
              : isError
              ? const Center(child: Text('Failed to load topics'))
              : Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                BreadcrumbBar(
                  items: [
                    _subjectTitleResolved.toUpperCase(),
                    _chapterTitleResolved.toUpperCase(),
                  ],
                  onHome: () => Navigator.pop(context),
                  onTapCrumb: (i) {
                    if (i == 0) {
                      // subject click => Chapters page for this subject
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
                    }
                    if (i == 1) {
                      // chapter click => same TopicsPage (nothing) or you can do popUntil etc.
                      // Usually do nothing
                    }
                  },
                ),

                Expanded(
                  child: ebookTopics.isEmpty
                      ? const Center(
                    child: Text(
                      'No Topics Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: ebookTopics.length,
                    itemBuilder: (context, index) {
                      final topic = ebookTopics[index];
                      if (topic.title.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _GridCard(
                        title: topic.title,
                        locked: topic.locked,
                        icon: Icons.description,
                        onTap: () {
                          if (topic.locked) {
                            _showSubscriptionDialog(context);
                            return;
                          }

                          final low = topic.title
                              .trim()
                              .toLowerCase();
                          final isPracticeQuestions =
                          (low == 'practice questions' ||
                              low == 'practice question');

                          if (isPracticeQuestions) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PracticeQuestionsPage(
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
                                subjectTitle:
                                _subjectTitleResolved,
                                chapterTitle:
                                _chapterTitleResolved,
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

          SidebarFloatingButton(
              onTap: () => setState(() => sidebarOpen = true)),

          CollapsibleSidebar(
            open: sidebarOpen,
            onClose: () => setState(() => sidebarOpen = false),
            headerTitle: 'Subjects',
            items: sidebarItems,
            selectedId: widget.subjectId,
            loadChildren: _loadChildren,
            onTap: (it) {
              setState(() => sidebarOpen = false);
              _handleSidebarTap(it);
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
            Icon(icon, size: 28, color: const Color(0xFF0c4a6e)),
            const SizedBox(height: 6),
            Flexible(
              child: Center(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0f172a),
                    height: 1.12,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (locked) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock, color: Colors.redAccent, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
