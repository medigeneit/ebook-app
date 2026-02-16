import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/models/ebook_content.dart';
import 'package:ebook_project/models/ebook_subject.dart';
import 'package:ebook_project/models/ebook_chapter.dart';
import 'package:ebook_project/models/ebook_topic.dart';
import 'package:ebook_project/utils/token_store.dart';

import 'package:ebook_project/components/contents/content_card.dart';
import 'package:ebook_project/components/contents/skeletons.dart';
import 'package:ebook_project/components/contents/app_modal.dart';
import 'package:ebook_project/screens/youtube_player_page.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:ebook_project/components/breadcrumb_bar.dart';
import 'package:ebook_project/components/collapsible_sidebar.dart';

import 'package:ebook_project/screens/ebook_subjects.dart';
import 'package:ebook_project/screens/ebook_chapters.dart';
import 'package:ebook_project/screens/ebook_topics.dart';
import 'package:ebook_project/screens/practice/practice_questions.dart';

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

  Future<void> fetchSidebarSubjects() async {
    setState(() => sidebarLoading = true);
    try {
      final api = ApiService();
      var endpoint = "/v1/ebooks/${widget.ebookId}/subjects";
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

  Future<void> fetchEbookContents() async {
    try {
      final api = ApiService();
      final data = await api.fetchEbookData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents",
      );

      if (!mounted) return;
      setState(() {
        ebookContents = (data['contents'] as List? ?? [])
            .map((e) => EbookContent.fromJson(e))
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

  String get _topicTitleResolved =>
      widget.topicTitle.trim().isNotEmpty ? widget.topicTitle.trim() : 'TOPIC';

  // ---------- Sidebar tree loaders ----------
  Future<List<SidebarItem>> _loadChildren(SidebarItem parent) async {
    final api = ApiService();

    if (parent.type == SidebarItemType.subject) {
      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/${parent.id}/chapters";
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
          meta: {'subjectId': parent.id, 'subjectTitle': parent.title},
        ),
      )
          .toList();
    }

    if (parent.type == SidebarItemType.chapter) {
      final subjectId = parent.meta['subjectId'] ?? widget.subjectId;

      var endpoint =
          "/v1/ebooks/${widget.ebookId}/subjects/$subjectId/chapters/${parent.id}/topics";
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
    if (it.locked) return;

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

  // ---------- Existing modal fetch ----------
  Future<void> fetchDiscussionContent(String contentId) async {
    setState(() => showModalLoader = true);
    try {
      final api = ApiService();
      final response = await api.fetchRawTextData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents/$contentId/discussion",
      );
      if (!mounted) return;
      setState(() {
        discussionContent = response;
        showDiscussionModal = true;
        showModalLoader = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => showModalLoader = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load discussion")));
    }
  }

  Future<void> fetchSolveVideos(String contentId) async {
    setState(() => showModalLoader = true);
    try {
      final api = ApiService();
      final data = await api.fetchEbookData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents/$contentId/solve-videos",
      );

      solveVideos = (data['solve_videos'] as List? ?? [])
          .map((e) => {
        'title': e['title'] ?? 'Video',
        'video_url': e['link'] ?? e['video_url'],
      })
          .where((v) => v['video_url'] != null)
          .toList();

      if (!mounted) return;
      setState(() {
        showVideoModal = true;
        showModalLoader = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => showModalLoader = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load videos")));
    }
  }

  Future<void> fetchReferenceContent(String contentId) async {
    setState(() => showModalLoader = true);
    try {
      final api = ApiService();
      final response = await api.fetchRawTextData(
        "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/contents/$contentId/references",
      );
      if (!mounted) return;
      setState(() {
        referenceContent = response;
        showReferenceModal = true;
        showModalLoader = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => showModalLoader = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load references")));
    }
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
                    'SUBJECTS',
                    _subjectTitleResolved.toUpperCase(),
                    _chapterTitleResolved.toUpperCase(),
                    _topicTitleResolved.toUpperCase(),
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
                            subjectTitle: _subjectTitleResolved,
                          ),
                        ),
                      );
                    },
                        () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EbookTopicsPage(
                            ebookId: widget.ebookId,
                            subjectId: widget.subjectId,
                            chapterId: widget.chapterId,
                            ebookName: widget.ebookName,
                            subjectTitle: _subjectTitleResolved,
                            chapterTitle: _chapterTitleResolved,
                          ),
                        ),
                      );
                    },
                    null,
                  ],
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
          selectedKey: 't:${widget.topicId}',
          loadChildren: _loadChildren,
          onTap: (it) {
            setState(() => sidebarOpen = false);
            _onSidebarTap(it);
          },
        ),

        if (showDiscussionModal)
          AppModal(
            title: 'Discussion',
            onClose: () => setState(() => showDiscussionModal = false),
            child: SingleChildScrollView(
              child: Html(data: discussionContent),
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
              child: Html(data: referenceContent),
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
