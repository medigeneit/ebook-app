import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/utils/token_store.dart';

class WordIndexSheet extends StatefulWidget {
  final String word;

  // ✅ ids String (আপনার EbookContentsPage এর সাথে match)
  final String ebookId;
  final String subjectId;
  final String chapterId;
  final String topicId;

  /// ✅ Vue router-link এর মতো open (পেজে নিয়ে যাবে + focus)
  final void Function({
  required String ebookId,
  required String subjectId,
  required String chapterId,
  required String topicId,
  required int contentId,
  }) onOpenQuestion;

  const WordIndexSheet({
    super.key,
    required this.word,
    required this.ebookId,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.onOpenQuestion,
  });

  static Future<void> open({
    required BuildContext context,
    required String word,
    required String ebookId,
    required String subjectId,
    required String chapterId,
    required String topicId,
    required void Function({
    required String ebookId,
    required String subjectId,
    required String chapterId,
    required String topicId,
    required int contentId,
    }) onOpenQuestion,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordIndexSheet(
        word: word,
        ebookId: ebookId,
        subjectId: subjectId,
        chapterId: chapterId,
        topicId: topicId,
        onOpenQuestion: onOpenQuestion,
      ),
    );
  }

  @override
  State<WordIndexSheet> createState() => _WordIndexSheetState();
}

class _WordIndexSheetState extends State<WordIndexSheet> {
  bool loading = true;
  String? error;

  /// API থেকে topics list আসবে
  List<dynamic> topics = [];

  /// accordion open state
  final Set<int> expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      topics = [];
    });

    try {
      final api = ApiService();

      var ep =
          "/v1/ebooks/${widget.ebookId}/subjects/${widget.subjectId}/chapters/${widget.chapterId}/topics/${widget.topicId}/word-contain-contents"
          "?word=${Uri.encodeQueryComponent(widget.word)}";

      ep = await TokenStore.attachPracticeToken(ep);

      final data = await api.fetchEbookData(ep);

      final list = (data['topics'] as List?) ?? [];

      if (!mounted) return;
      setState(() {
        topics = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _highlightHtml(String html, String word) {
    final w = word.trim();
    if (w.isEmpty) return html;
    final re = RegExp(RegExp.escape(w), caseSensitive: false);
    return html.replaceAllMapped(re, (m) => "<mark>${m.group(0)}</mark>");
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.86;

    return Container(
      height: maxH,
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Word Index • ${widget.word}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: loading
                  ? const _Skeleton()
                  : (error != null)
                  ? _ErrorView(msg: error!, onRetry: _load)
                  : (topics.isEmpty)
                  ? const Center(child: Text("কোনো ডাটা পাওয়া যায়নি"))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                itemCount: topics.length,
                itemBuilder: (ctx, i) {
                  final topic = (topics[i] as Map).cast<String, dynamic>();
                  final qs = (topic['questions'] as List?) ?? const [];

                  final title =
                      "${topic['subject_name'] ?? ''} > ${topic['chapter_name'] ?? ''} > ${topic['topic_name'] ?? ''}";

                  final isOpen = expanded.contains(i);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isOpen) {
                                expanded.remove(i);
                              } else {
                                expanded.add(i);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${i + 1}. $title",
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    "${qs.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                        if (isOpen) const Divider(height: 1),
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Column(
                              children: List.generate(qs.length, (qIndex) {
                                final q = (qs[qIndex] as Map).cast<String, dynamic>();
                                final qId = int.tryParse("${q['id']}") ?? 0;

                                final qTitle = (q['question_title'] ?? '').toString();
                                final qOptions = (q['question_options'] as List?) ?? const [];

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(context);

                                    Future.microtask(() {
                                      widget.onOpenQuestion(
                                        ebookId: "${topic['book_id'] ?? widget.ebookId}",
                                        subjectId: "${topic['subject_id'] ?? widget.subjectId}",
                                        chapterId: "${topic['chapter_id'] ?? widget.chapterId}",
                                        topicId: "${topic['id'] ?? widget.topicId}",
                                        contentId: qId,
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${qIndex + 1}. ",
                                                style: const TextStyle(fontWeight: FontWeight.w900)),
                                            Expanded(
                                              child: Html(
                                                data: _highlightHtml(qTitle, widget.word),
                                                style: {
                                                  "*": Style(margin: Margins.zero),
                                                  "mark": Style(
                                                    backgroundColor: const Color(0xFFFFEB3B),
                                                    fontWeight: FontWeight.w900,
                                                    padding: HtmlPaddings.symmetric(horizontal: 3, vertical: 1),
                                                  ),
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 18),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: List.generate(qOptions.length, (oi) {
                                              final o = (qOptions[oi] as Map).cast<String, dynamic>();
                                              final ans = (o['answer'] ?? '').toString();
                                              return Html(
                                                data: _highlightHtml(ans, widget.word),
                                                style: {
                                                  "*": Style(margin: Margins.zero),
                                                  "mark": Style(
                                                    backgroundColor: const Color(0xFFFFEB3B),
                                                    fontWeight: FontWeight.w900,
                                                    padding: HtmlPaddings.symmetric(horizontal: 3, vertical: 1),
                                                  ),
                                                },
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: 6,
      itemBuilder: (_, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: const [
              _SkBar(h: 14),
              SizedBox(height: 10),
              _SkBar(h: 12),
              SizedBox(height: 10),
              _SkBar(h: 12, w: 240),
            ],
          ),
        );
      },
    );
  }
}

class _SkBar extends StatelessWidget {
  final double h;
  final double? w;
  const _SkBar({required this.h, this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h,
      width: w ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 34),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}