import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'fullscreen_overlay.dart';

class WordIndexModal extends StatelessWidget {
  final String word;
  final Map<String, dynamic> data;
  final VoidCallback onClose;
  final void Function(int contentId)? onOpenContent;

  const WordIndexModal({
    super.key,
    required this.word,
    required this.data,
    required this.onClose,
    this.onOpenContent,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final contents = (data['contents'] as List?) ?? const [];
    final topics = (data['topics'] as List?) ?? const [];

    return FullscreenOverlay(
      onClose: onClose,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: w > 520 ? 520 : w * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Word Index: $word',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (topics.isNotEmpty) ...[
                        const Text(
                          'Topics',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...topics.map((t) {
                          final m = (t as Map).cast<String, dynamic>();
                          final title = (m['title'] ?? '').toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(title.isEmpty ? '—' : title),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      const Text(
                        'Matched Questions',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),

                      if (contents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text('কোনো কন্টেন্ট পাওয়া যায়নি।'),
                        )
                      else
                        ...contents.map((c) {
                          final m = (c as Map).cast<String, dynamic>();
                          final id = int.tryParse('${m['id']}') ?? 0;
                          final title = (m['title'] ?? '').toString();

                          return InkWell(
                            onTap: (id > 0 && onOpenContent != null)
                                ? () => onOpenContent!(id)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.search, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Html(
                                      data: title.isEmpty ? '<i>(no title)</i>' : title,
                                      style: {
                                        "*": Style(margin: Margins.zero),
                                      },
                                    ),
                                  ),
                                  if (id > 0 && onOpenContent != null) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}