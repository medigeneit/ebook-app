import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/models/ebook_content.dart';
import 'package:ebook_project/models/ebook_subject.dart';

import 'package:ebook_project/components/contents/content_card.dart';
import 'package:ebook_project/components/contents/skeletons.dart';
import 'package:ebook_project/components/contents/app_modal.dart';
import 'package:ebook_project/screens/youtube_player_page.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:ebook_project/components/breadcrumb_bar.dart';
import 'package:ebook_project/components/collapsible_sidebar.dart';
import 'package:ebook_project/screens/ebook_chapters.dart';
import 'package:ebook_project/screens/practice/practice_questions.dart';

import 'ebook_topics.dart';

class EbookContentsPage extends StatefulWidget {
  final String ebookId;
  final String subjectId;
  final String chapterId;
  final String topicId;
  final String ebookName;

  final String subjectTitle;
  final String chapterTitle;
  final String topicTitle;

  const EbookContentsPage({
    super.key,
    required this.ebookId,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.ebookName,
    this.subjectTitle = '',
    this.chapterTitle = '',
    this.topicTitle = '',
  });

  @override
  State<EbookContentsPage> createState() => _EbookContentsPageState();
}

class _EbookContentsPageState extends State<EbookContentsPage> {
  List<EbookContent> ebookContents = [];
  bool isLoading = true;
  bool isError = false;

  // selections
  final Map<int, String> selectedAnswers = {};
  final Map<int, String> selectedSBAAnswers = {};
  final Set<int> showCorrect = {};

  // sidebar subjects
  List<EbookSubject> sidebarSubjects = [];
  bool sidebarOpen = false;
  bool sidebarLoading = true;

  // modals
  bool showModalLoader = false;
  String discussionContent = '';
  bool showDiscussionModal = false;
  List<Map<String, dynamic>> solveVideos = [];
  bool showVideoModal = false;
  String referenceContent = '';
  bool showReferenceModal = false;
  final Map<int, String> notes = {};
  bool showNoteModal = false;
  int? activeNoteContentId;
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSidebarSubjects();
    fetchEbookContents();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  bool _isLocked(dynamic v) => v == true || v == 1 || v == '1';

  Future<void> fetchSidebarSubjects() async {
    setState(() => sidebarLoading = true);
    try {
      final api = ApiService();
      final endpoint = "/v1/ebooks/${widget.ebookId}/subjects";
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

  Future<void> fetchEbookContents() async {
    final apiService = ApiService();
    try {
      final data = await apiService.fetchEbookData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents",
      );
      setState(() {
        ebookContents =
            (data['contents'] as List).map((e) => EbookContent.fromJson(e)).toList();
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

  String get _topicTitleResolved =>
      widget.topicTitle.trim().isNotEmpty ? widget.topicTitle.trim() : 'TOPIC';

  // ✅ Tree children loader
  Future<List<SidebarItem>> _loadChildren(SidebarItem parent) async {
    final api = ApiService();

    if (parent.type == SidebarItemType.subject) {
      final subjectId = parent.id;
      final data = await api.fetchEbookData(
        "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters",
      );
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

      final data = await api.fetchEbookData(
        "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters/$chapterId/topics",
      );
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
    if (it.locked) return;

    if (it.type != SidebarItemType.topic) return;

    final subjectId = it.meta['subjectId'] ?? '';
    final chapterId = it.meta['chapterId'] ?? '';
    final topicId = it.id;

    final subjectTitle = (it.meta['subjectTitle'] ?? '').trim();
    final chapterTitle = (it.meta['chapterTitle'] ?? '').trim();
    final topicTitle = it.title.trim();

    final low = topicTitle.toLowerCase();
    final isPracticeQuestions =
    (low == 'practice questions' || low == 'practice question');

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

  Future<void> fetchDiscussionContent(String contentId) async {
    setState(() => showModalLoader = true);
    final apiService = ApiService();
    try {
      final response = await apiService.fetchRawTextData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents/$contentId/discussion",
      );
      setState(() {
        discussionContent = response;
        showDiscussionModal = true;
        showModalLoader = false;
      });
    } catch (_) {
      setState(() => showModalLoader = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load discussion")),
      );
    }
  }

  Future<void> fetchSolveVideos(String contentId) async {
    setState(() => showModalLoader = true);
    final apiService = ApiService();
    try {
      final data = await apiService.fetchEbookData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents/$contentId/solve-videos",
      );

      solveVideos = (data['solve_videos'] as List)
          .map((e) => {
        'title': e['title'] ?? 'Video',
        'video_url': e['link'] ?? e['video_url'],
      })
          .where((v) => v['video_url'] != null)
          .toList();

      setState(() {
        showVideoModal = true;
        showModalLoader = false;
      });
    } catch (_) {
      setState(() => showModalLoader = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load videos")));
    }
  }

  Future<void> fetchReferenceContent(String contentId) async {
    setState(() => showModalLoader = true);
    final apiService = ApiService();
    try {
      final response = await apiService.fetchRawTextData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents/$contentId/references",
      );
      setState(() {
        referenceContent = response;
        showReferenceModal = true;
        showModalLoader = false;
      });
    } catch (_) {
      setState(() => showModalLoader = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load references")));
    }
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

    return Stack(
      children: [
        AppLayout(
          title: '${widget.ebookName} Questions',
          body: isLoading
              ? ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, _) => const EbookSkeletonCard(),
          )
              : isError
              ? const Center(child: Text('Failed to load contents'))
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: BreadcrumbBar(
                  items: [
                    _subjectTitleResolved.toUpperCase(),
                    _chapterTitleResolved.toUpperCase(),
                    _topicTitleResolved.toUpperCase(),
                  ],
                  onHome: () => Navigator.pop(context),
                  onTapCrumb: (i) {
                    if (i == 0) {
                      // subject => chapters
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EbookChaptersPage(
                            ebookId: widget.ebookId,
                            subjectId: widget.subjectId,
                            ebookName: widget.ebookName,
                            subjectTitle: _subjectTitleResolved,
                          ),
                        ),
                      );
                      return;
                    }

                    if (i == 1) {
                      // chapter => topics
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EbookTopicsPage(
                            ebookId: widget.ebookId,
                            subjectId: widget.subjectId,
                            chapterId: widget.chapterId,
                            ebookName: widget.ebookName,
                            practice: false, // contents এ practice allow না হলে
                            subjectTitle: _subjectTitleResolved,
                            chapterTitle: _chapterTitleResolved,
                          ),
                        ),
                      );
                      return;
                    }

                    if (i == 2) {
                      // topic => generally do nothing (already here) OR go back to topics
                      Navigator.pop(context);
                    }
                  },
                ),

              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  itemCount: ebookContents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final content = ebookContents[index];
                    return ContentCard(
                      content: content,
                      showCorrect: showCorrect.contains(content.id),
                      selectedTF: selectedAnswers,
                      selectedSBA: selectedSBAAnswers,
                      onToggleAnswer: () {
                        setState(() {
                          showCorrect.contains(content.id)
                              ? showCorrect.remove(content.id)
                              : showCorrect.add(content.id);
                        });
                      },
                      onTapDiscussion: content.hasDiscussion
                          ? () => fetchDiscussionContent(content.id.toString())
                          : null,
                      onTapReference: content.hasReference
                          ? () => fetchReferenceContent(content.id.toString())
                          : null,
                      onTapVideo: content.hasSolveVideo
                          ? () => fetchSolveVideos(content.id.toString())
                          : null,
                      onTapNote: content.hasNote
                          ? () {
                        setState(() {
                          activeNoteContentId = content.id;
                          noteController.text = notes[content.id] ?? '';
                          showNoteModal = true;
                        });
                      }
                          : null,
                      onChooseTF: (optionId, label) {
                        setState(() {
                          final sel = selectedAnswers[optionId];
                          selectedAnswers[optionId] = (sel == label) ? '' : label;
                        });
                      },
                      onChooseSBA: (contentId, slNo) {
                        setState(() {
                          final sel = selectedSBAAnswers[contentId];
                          selectedSBAAnswers[contentId] = (sel == slNo) ? '' : slNo;
                        });
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
            setState(() => sidebarOpen = false);
            _handleSidebarTap(it);
          },
        ),

        if (showDiscussionModal)
          AppModal(
            title: 'Discussion',
            onClose: () => setState(() => showDiscussionModal = false),
            child: SingleChildScrollView(
              child: Html(
                data: discussionContent,
                style: {
                  "*": Style(
                    backgroundColor: Colors.transparent,
                    fontSize: FontSize.medium,
                    color: Colors.black,
                  ),
                  "p": Style(margin: Margins.only(bottom: 6)),
                },
              ),
            ),
          ),

        if (showVideoModal)
          AppModal(
            title: 'Solve Videos',
            onClose: () => setState(() => showVideoModal = false),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: solveVideos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = solveVideos[i];
                final title = "${v['title']} ${i + 1}";
                final url = v['video_url'];
                final videoId = YoutubePlayer.convertUrlToId(url ?? '');

                if (url == null || videoId == null) {
                  return const ListTile(
                    leading: Icon(Icons.error, color: Colors.red),
                    title: Text('Invalid video URL'),
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.play_circle_fill, size: 32),
                  title: Text(title, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => YoutubePlayerPage(videoId: videoId),
                    ));
                  },
                );
              },
            ),
          ),

        if (showReferenceModal)
          AppModal(
            title: 'Reference',
            onClose: () => setState(() => showReferenceModal = false),
            child: SingleChildScrollView(
              child: Html(
                data: referenceContent,
                style: {
                  "*": Style(
                    backgroundColor: Colors.transparent,
                    fontSize: FontSize.medium,
                    color: Colors.black,
                  ),
                  "p": Style(margin: Margins.only(bottom: 6)),
                },
              ),
            ),
          ),

        if (showNoteModal)
          AppModal(
            title: 'Note',
            onClose: () => setState(() => showNoteModal = false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: noteController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Write your note here',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final id = activeNoteContentId;
                    if (id != null) {
                      setState(() {
                        notes[id] = noteController.text.trim();
                        showNoteModal = false;
                      });
                    } else {
                      setState(() => showNoteModal = false);
                    }
                  },
                  child: const Text('Save Note'),
                ),
              ],
            ),
          ),

        if (showModalLoader) const AppModalLoader(),
      ],
    );
  }
}
