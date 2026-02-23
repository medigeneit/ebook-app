import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/collapsible_sidebar.dart';
import 'package:ebook_project/components/contents/app_modal.dart';
import 'package:ebook_project/components/contents/skeletons.dart';
import 'package:ebook_project/components/ebook/ebook_contents_body.dart';
import 'package:ebook_project/components/ebook/ebook_contents_header.dart';
import 'package:ebook_project/components/ebook/modals/discussion_modal.dart';
import 'package:ebook_project/components/ebook/modals/reference_modal.dart';
import 'package:ebook_project/components/ebook/modals/solve_videos_modal.dart';
import 'package:ebook_project/models/ebook_chapter.dart';
import 'package:ebook_project/models/ebook_content.dart';
import 'package:ebook_project/models/ebook_subject.dart';
import 'package:ebook_project/models/ebook_topic.dart';
import 'package:ebook_project/screens/practice/practice_questions.dart';
import 'package:ebook_project/utils/token_store.dart';
import 'package:flutter/material.dart';

class EbookContentsPage extends StatefulWidget {
  final String ebookId;
  final String subjectId;
  final String chapterId;
  final String topicId;
  final String ebookName;

  final String subjectTitle;
  final String chapterTitle;
  final String topicTitle;
  final int? focusContentId;

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
    this.focusContentId = 0,
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

  // modals state
  bool showModalLoader = false;

  String discussionContent = '';
  bool showDiscussionModal = false;

  String referenceContent = '';
  bool showReferenceModal = false;

  List<Map<String, dynamic>> solveVideos = [];
  bool showVideoModal = false;

  // bookmark/flag state
  final Map<int, bool> bookmarked = {}; // contentId -> bool
  final Map<int, bool> flagged = {}; // contentId -> bool
  final Set<int> bookmarkBusy = {};
  final Set<int> flagBusy = {};

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchSidebarSubjects();
    fetchEbookContents();
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

      _prefetchBookmarkFlag(ebookContents);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.focusContentId == null) return;
        final ctx = _focusKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignment: 0.2,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  /// ✅ Base content path (contents/{contentId})
  String _noteBase(int contentId) {
    return "/v1/ebooks/${widget.ebookId}"
        "/subjects/${widget.subjectId}"
        "/chapters/${widget.chapterId}"
        "/topics/${widget.topicId}"
        "/contents/$contentId";
  }

  String _bookmarkPath(int contentId) => "${_noteBase(contentId)}/bookmark";
  String _flagPath(int contentId) => "${_noteBase(contentId)}/flag";

  Future<bool?> _getBookmark(ApiService api, int contentId) async {
    try {
      var ep = _bookmarkPath(contentId);
      ep = await TokenStore.attachPracticeToken(ep);
      final data = await api.fetchEbookData(ep);
      return data['is_bookmarked'] == true;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _getFlag(ApiService api, int contentId) async {
    try {
      var ep = _flagPath(contentId);
      ep = await TokenStore.attachPracticeToken(ep);
      final data = await api.fetchEbookData(ep);
      return data['is_flagged'] == true;
    } catch (_) {
      return null;
    }
  }

  Future<void> _prefetchBookmarkFlag(List<EbookContent> list) async {
    final api = ApiService();
    final ids = list.take(20).map((e) => e.id).toList();

    final bm = <int, bool>{};
    final fl = <int, bool>{};

    for (final id in ids) {
      final b = await _getBookmark(api, id);
      if (b != null) bm[id] = b;

      final f = await _getFlag(api, id);
      if (f != null) fl[id] = f;
    }

    if (!mounted) return;
    setState(() {
      bookmarked.addAll(bm);
      flagged.addAll(fl);
    });
  }

  Future<void> toggleBookmark(int contentId) async {
    if (bookmarkBusy.contains(contentId)) return;

    final prev = bookmarked[contentId] ?? false;

    setState(() {
      bookmarkBusy.add(contentId);
      bookmarked[contentId] = !prev;
    });

    try {
      final api = ApiService();
      var ep = _bookmarkPath(contentId);
      ep = await TokenStore.attachPracticeToken(ep);

      final res = await api.postData(ep, {});
      if (res == null || res['error'] == 1) {
        throw ApiException((res?['message'] ?? 'Bookmark failed').toString());
      }

      final serverVal = res['is_bookmarked'] == true;

      if (!mounted) return;
      setState(() => bookmarked[contentId] = serverVal);
    } catch (e) {
      if (!mounted) return;
      setState(() => bookmarked[contentId] = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() => bookmarkBusy.remove(contentId));
    }
  }

  Future<void> toggleFlag(int contentId) async {
    if (flagBusy.contains(contentId)) return;

    final prev = flagged[contentId] ?? false;

    setState(() {
      flagBusy.add(contentId);
      flagged[contentId] = !prev;
    });

    try {
      final api = ApiService();
      var ep = _flagPath(contentId);
      ep = await TokenStore.attachPracticeToken(ep);

      final res = await api.postData(ep, {});
      if (res == null || res['error'] == 1) {
        throw ApiException((res?['message'] ?? 'Flag failed').toString());
      }

      final serverVal = res['is_flagged'] == true;

      if (!mounted) return;
      setState(() => flagged[contentId] = serverVal);
    } catch (e) {
      if (!mounted) return;
      setState(() => flagged[contentId] = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() => flagBusy.remove(contentId));
    }
  }

  // ✅ NEW: underline save হলে লোকাল লিস্টে title আপডেট (copyWith ছাড়াই)
  void _applyUnderlinedTitle(int contentId, String updatedTitleHtml) {
    final i = ebookContents.indexWhere((e) => e.id == contentId);
    if (i == -1) return;

    final old = ebookContents[i];

    ebookContents[i] = EbookContent(
      id: old.id,
      title: updatedTitleHtml, // ✅ শুধু এটায় change
      type: old.type,
      pageNo: old.pageNo,
      options: old.options,
      answer: old.answer,
      hasDiscussion: old.hasDiscussion,
      hasReference: old.hasReference,
      hasSolveVideo: old.hasSolveVideo,
      hasNote: old.hasNote,
    );
  }

  // resolved titles
  String get _subjectTitleResolved {
    if (widget.subjectTitle.trim().isNotEmpty) return widget.subjectTitle.trim();
    final hit =
    sidebarSubjects.where((s) => s.id.toString() == widget.subjectId);
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
          hasPractice: t.hasPractice,
          type: SidebarItemType.topic,
          hasChildren: false,
          meta: {
            'subjectId': subjectId,
            'subjectTitle':
            parent.meta['subjectTitle'] ?? _subjectTitleResolved,
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
    if (it.locked) return;

    if (it.type == SidebarItemType.topic) {
      final subjectId = it.meta["subjectId"] ?? "";
      final chapterId = it.meta["chapterId"] ?? "";
      final topicId = it.id;

      if (it.title.trim().toLowerCase() == "practice questions" &&
          it.hasPractice == true) {
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
      if (it.title.trim().toLowerCase() == "practice questions") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Practice questions not available')),
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
            subjectTitle: it.meta["subjectTitle"] ?? "",
            chapterTitle: it.meta["chapterTitle"] ?? "",
            topicTitle: it.title,
          ),
        ),
      );
    }
  }

  // ---------- modal fetch ----------
  Future<void> fetchDiscussionContent(int contentId) async {
    setState(() => showModalLoader = true);
    try {
      final api = ApiService();
      final response = await api.fetchRawTextData(
        "${_noteBase(contentId)}/discussion",
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load discussion")),
      );
    }
  }

  Future<void> fetchReferenceContent(int contentId) async {
    setState(() => showModalLoader = true);
    try {
      final api = ApiService();
      final response = await api.fetchRawTextData(
        "${_noteBase(contentId)}/references",
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load references")),
      );
    }
  }

  Future<void> fetchSolveVideos(int contentId) async {
    setState(() => showModalLoader = true);
    try {
      final api = ApiService();
      final data = await api.fetchEbookData(
        "${_noteBase(contentId)}/solve-videos",
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load videos")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidebarItems = sidebarSubjects
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
      title: '${widget.ebookName} Questions',
      bodyPadding: EdgeInsets.zero,
      body: Stack(
        children: [
          isLoading
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
              EbookContentsHeader(
                ebookId: widget.ebookId,
                ebookName: widget.ebookName,
                subjectId: widget.subjectId,
                chapterId: widget.chapterId,
                topicId: widget.topicId,
                subjectTitle: _subjectTitleResolved,
                chapterTitle: _chapterTitleResolved,
                topicTitle: _topicTitleResolved,
              ),
              Expanded(
                child: EbookContentsBody(
                  contents: ebookContents,
                  selectedTF: selectedAnswers,
                  selectedSBA: selectedSBAAnswers,
                  showCorrect: showCorrect,

                  noteBasePath: _noteBase,
                  contentBasePath: _noteBase,

                  bookmarked: bookmarked,
                  flagged: flagged,
                  bookmarkBusy: bookmarkBusy,
                  flagBusy: flagBusy,
                  scrollController: _scrollController,
                  focusContentId: widget.focusContentId,
                  focusKey: _focusKey,

                  onTapBookmark: (cid) => () => toggleBookmark(cid),
                  onTapFlag: (cid) => () => toggleFlag(cid),

                  onToggleAnswer: (cid) => () {
                    setState(() {
                      showCorrect.contains(cid)
                          ? showCorrect.remove(cid)
                          : showCorrect.add(cid);
                    });
                  },

                  onTapDiscussion: (cid) =>
                      () => fetchDiscussionContent(cid),
                  onTapReference: (cid) =>
                      () => fetchReferenceContent(cid),
                  onTapVideo: (cid) => () => fetchSolveVideos(cid),

                  onChooseTF: (optionId, label) {
                    setState(() {
                      final sel = selectedAnswers[optionId];
                      selectedAnswers[optionId] =
                      (sel == label) ? '' : label;
                    });
                  },
                  onChooseSBA: (contentId, slNo) {
                    setState(() {
                      final sel = selectedSBAAnswers[contentId];
                      selectedSBAAnswers[contentId] =
                      (sel == slNo) ? '' : slNo;
                    });
                  },

                  // ✅ এখানে copyWith বাদ, constructor দিয়ে update
                  onUnderlineSaved: (cid, html) {
                    setState(() {
                      _applyUnderlinedTitle(cid, html);
                    });
                  },
                ),
              ),
            ],
          ),

          SidebarFloatingButton(
            onTap: () => setState(() => sidebarOpen = true),
          ),

          CollapsibleSidebar(
            open: sidebarOpen,
            onClose: () => setState(() => sidebarOpen = false),
            headerTitle: 'Subjects',
            items: sidebarItems,
            onTap: (it) {
              setState(() => sidebarOpen = false);
              _onSidebarTap(it);
            },
            loadChildren: _loadChildren,
          ),

          if (showDiscussionModal)
            Positioned.fill(
              child: DiscussionModal(
                html: discussionContent,
                onClose: () => setState(() => showDiscussionModal = false),
              ),
            ),

          if (showReferenceModal)
            Positioned.fill(
              child: ReferenceModal(
                html: referenceContent,
                onClose: () => setState(() => showReferenceModal = false),
              ),
            ),

          if (showVideoModal)
            Positioned.fill(
              child: SolveVideosModal(
                videos: solveVideos,
                onClose: () => setState(() => showVideoModal = false),
              ),
            ),

          if (showModalLoader) const AppModalLoader(),
        ],
      ),
    );
  }
}
