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
import 'package:ebook_project/models/note_item.dart';

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

  // NOTE state
  int? activeNoteContentId;
  final TextEditingController noteController = TextEditingController();
  List<NoteItem> noteList = [];
  bool noteLoading = false;
  int? editingNoteId; // null => create, else edit

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

  // ---------------- NOTE API helpers ----------------
  String _noteBase(int contentId) {
    return "/v1/ebooks/${widget.ebookId}"
        "/subjects/${widget.subjectId}"
        "/chapters/${widget.chapterId}"
        "/topics/${widget.topicId}"
        "/contents/$contentId";
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final mon = months[d.month - 1];
    return "$day $mon ${d.year}";
  }

  Future<void> _fetchNotes(int contentId) async {
    noteLoading = true;
    if (mounted) setState(() {});

    try {
      final api = ApiService();
      final endpoint = "${_noteBase(contentId)}/notes";
      final data = await api.fetchEbookData(endpoint);

      final list = (data['notes'] as List? ?? [])
          .map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
          .toList();

      noteList = list;
      noteLoading = false;
      if (mounted) setState(() {});
    } catch (_) {
      noteLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveOrUpdateNote() async {
    final contentId = activeNoteContentId;
    if (contentId == null) return;

    final text = noteController.text.trim();
    if (text.isEmpty) return;

    noteLoading = true;
    if (mounted) setState(() {});

    final api = ApiService();

    try {
      if (editingNoteId == null) {
        final endpoint = "${_noteBase(contentId)}/save";
        await api.postData(endpoint, {'text': text});
      } else {
        final endpoint = "${_noteBase(contentId)}/notes/$editingNoteId/edit";
        await api.postData(endpoint, {'text': text});
      }

      await _fetchNotes(contentId);

      editingNoteId = null;
      noteController.clear();
      noteLoading = false;
      if (mounted) setState(() {});
    } catch (_) {
      noteLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteNote(int noteId) async {
    final contentId = activeNoteContentId;
    if (contentId == null) return;

    noteLoading = true;
    if (mounted) setState(() {});

    try {
      final api = ApiService();
      final endpoint = "${_noteBase(contentId)}/notes/$noteId/delete";
      await api.deleteData(endpoint);

      await _fetchNotes(contentId);

      noteLoading = false;
      if (mounted) setState(() {});
    } catch (_) {
      noteLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _startEdit(NoteItem note) {
    editingNoteId = note.id;
    noteController.text = note.noteDetail;
    if (mounted) setState(() {});
  }

  // ---------------- NOTE BottomSheet (App friendly) ----------------
  void _showNoteSheet(int contentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) {
        // ✅ BottomSheet local states
        bool sheetLoading = true;
        List<NoteItem> sheetNotes = [];
        int? sheetEditingId;
        final sheetController = noteController;

        // reset controller for new content
        sheetController.clear();

        Future<void> sheetFetch() async {
          sheetLoading = true;

          try {
            final api = ApiService();
            final endpoint = "${_noteBase(contentId)}/notes";
            final data = await api.fetchEbookData(endpoint);

            sheetNotes = (data['notes'] as List? ?? [])
                .map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
                .toList();

            sheetLoading = false;
          } catch (_) {
            sheetLoading = false;
            // চাইলে এখানে snack দেখাতে পারেন
          }
        }

        Future<void> sheetSave(StateSetter sheetSetState) async {
          final text = sheetController.text.trim();
          if (text.isEmpty) return;

          sheetSetState(() => sheetLoading = true);

          try {
            final api = ApiService();

            if (sheetEditingId == null) {
              // create
              final endpoint = "${_noteBase(contentId)}/save";
              await api.postData(endpoint, {'text': text});
            } else {
              // edit
              final endpoint = "${_noteBase(contentId)}/notes/$sheetEditingId/edit";
              await api.postData(endpoint, {'text': text});
            }

            // refresh list
            await sheetFetch();

            sheetEditingId = null;
            sheetController.clear();

            sheetSetState(() {});
          } catch (_) {
            sheetSetState(() => sheetLoading = false);
          }
        }

        Future<void> sheetDelete(int noteId, StateSetter sheetSetState) async {
          sheetSetState(() => sheetLoading = true);
          try {
            final api = ApiService();
            final endpoint = "${_noteBase(contentId)}/notes/$noteId/delete";
            await api.deleteData(endpoint);

            await sheetFetch();
            sheetSetState(() {});
          } catch (_) {
            sheetSetState(() => sheetLoading = false);
          }
        }

        // ✅ init fetch exactly once
        bool inited = false;

        return StatefulBuilder(
          builder: (sheetCtx, sheetSetState) {
            if (!inited) {
              inited = true;
              Future.microtask(() async {
                await sheetFetch();
                if (Navigator.of(sheetCtx).canPop()) {
                  sheetSetState(() {});
                }
              });
            }

            final canSave = !sheetLoading && sheetController.text.trim().isNotEmpty;

            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.55,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Text(
                              'Note',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          children: [
                            if (sheetEditingId != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Editing note…',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        sheetEditingId = null;
                                        sheetController.clear();
                                        sheetSetState(() {});
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ),

                            TextField(
                              controller: sheetController,
                              minLines: 3,
                              maxLines: 5,
                              onChanged: (_) => sheetSetState(() {}), // ✅ enable Save immediately
                              decoration: InputDecoration(
                                hintText: 'Write Your Note Here ...',
                                filled: true,
                                fillColor: const Color(0xFFF6F7FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: canSave ? () => sheetSave(sheetSetState) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B7A2E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  sheetEditingId == null ? 'Save' : 'Update',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Text(
                                  'Note List: ${sheetNotes.length}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                ),
                                const Spacer(),
                                if (!sheetLoading && sheetNotes.isNotEmpty)
                                  Text(
                                    'Scroll ↓',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (sheetLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 28),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (sheetNotes.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 22),
                                child: Center(
                                  child: Text(
                                    'No notes yet',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...sheetNotes.map((n) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFEDEFF5)),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(n.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        n.noteDetail,
                                        style: const TextStyle(fontSize: 15, height: 1.35),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              sheetEditingId = n.id;
                                              sheetController.text = n.noteDetail;
                                              sheetSetState(() {});
                                            },
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          InkWell(
                                            onTap: () => sheetDelete(n.id, sheetSetState),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.delete, size: 18, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),

                            const SizedBox(height: 70),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, -2))
                          ],
                        ),
                        child: SizedBox(
                          height: 46,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  // ---------------- Sidebar titles ----------------
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
      var endpoint = "/v1/ebooks/${widget.ebookId}/subjects/${parent.id}/chapters";
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
    if (it.locked) return;

    if (it.type == SidebarItemType.topic) {
      final subjectId = it.meta["subjectId"] ?? "";
      final chapterId = it.meta["chapterId"] ?? "";
      final topicId = it.id;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load discussion")),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load references")),
      );
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

                      // ✅ NOTE: app friendly bottom sheet
                      onTapNote: () => _showNoteSheet(content.id),

                      onChooseTF: (optionId, label) {
                        setState(() {
                          final sel = selectedAnswers[optionId];
                          selectedAnswers[optionId] = (sel == label) ? '' : label;
                        });
                      },
                      onChooseSBA: (contentId, slNo) {
                        setState(() {
                          final sel = selectedSBAAnswers[contentId];
                          selectedSBAAnswers[contentId] =
                          (sel == slNo) ? '' : slNo;
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
            child: SingleChildScrollView(child: Html(data: discussionContent)),
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
            child: SingleChildScrollView(child: Html(data: referenceContent)),
          ),

        if (showModalLoader) const AppModalLoader(),
      ],
    );
  }
}
