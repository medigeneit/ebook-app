import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ✅ Copy-paste ready page
/// - type==3 + imageUrl থাকলে: image tap => zoom dialog
/// - basic MCQ UI + prev/next
///
/// আপনার প্রজেক্টে আসল Question/Option model থাকলে নিচের AppQuestion model টা বাদ দিয়ে
/// আপনার model অনুযায়ী ফিল্ড map করে দিন।
class QuestionPageWithZoom extends StatefulWidget {
  final String title;
  final List<AppQuestion> questions;

  /// Optional: যখন উত্তর সিলেক্ট হবে তখন বাইরে পাঠাতে চাইলে
  final void Function(AppQuestion q, int selectedIndex)? onAnswer;

  const QuestionPageWithZoom({
    super.key,
    required this.title,
    required this.questions,
    this.onAnswer,
  });

  @override
  State<QuestionPageWithZoom> createState() => _QuestionPageWithZoomState();
}

class _QuestionPageWithZoomState extends State<QuestionPageWithZoom> {
  int index = 0;

  /// questionId => selectedOptionIndex
  final Map<int, int> selected = {};

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    if (qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No questions found')),
      );
    }

    final q = qs[index];
    final total = qs.length;
    final sel = selected[q.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (index + 1) / total,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${index + 1}/$total',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
                  _QuestionHeaderCard(
                    qNo: index + 1,
                    questionText: q.text,
                    type: q.type,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Type 3 + image => zoomable
                  if (q.type == 3 && (q.imageUrl?.trim().isNotEmpty ?? false))
                    ZoomableQuestionImage(
                      imageUrl: q.imageUrl!.trim(),
                      heroTag: 'qimg_${q.id}_$index',
                    ),

                  if (q.type == 3 && (q.imageUrl?.trim().isNotEmpty ?? false))
                    const SizedBox(height: 12),

                  _OptionsCard(
                    options: q.options,
                    selectedIndex: sel,
                    onSelect: (optIndex) {
                      HapticFeedback.selectionClick();
                      setState(() => selected[q.id] = optIndex);
                      widget.onAnswer?.call(q, optIndex);
                    },
                  ),

                  if (q.note?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    _InfoNote(note: q.note!.trim()),
                  ],
                ],
              ),
            ),

            // bottom controls
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: const Border(
                  top: BorderSide(color: Color(0x11000000)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: index == 0
                          ? null
                          : () => setState(() => index -= 1),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Prev'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: index == total - 1
                          ? null
                          : () => setState(() => index += 1),
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- UI PARTS ----------------------------- */

class _QuestionHeaderCard extends StatelessWidget {
  final int qNo;
  final String questionText;
  final int type;

  const _QuestionHeaderCard({
    required this.qNo,
    required this.questionText,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0F000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                  child: Text(
                    'Q$qNo  •  Type $type',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(
                questionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _OptionsCard({
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const Text('No options available');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: Column(
        children: List.generate(options.length, (i) {
          final isLast = i == options.length - 1;
          return Column(
            children: [
              RadioListTile<int>(
                value: i,
                groupValue: selectedIndex,
                onChanged: (_) => onSelect(i),
                title: Text(
                  options[i],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (!isLast)
                const Divider(height: 1, thickness: 1, color: Color(0x0A000000)),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String note;
  const _InfoNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- ZOOM IMAGE PART -------------------------- */

class ZoomableQuestionImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ZoomableQuestionImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openZoom(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9, // thumbnail ratio (আপনি চাইলে 4/3)
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, p) {
                      if (p == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, e, s) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 44),
                    ),
                  ),
                ),
              ),

              // zoom hint
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openZoom(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 6.0,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(60),
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, p) {
                        if (p == null) return child;
                        return const SizedBox(
                          height: 260,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, e, s) => const SizedBox(
                        height: 260,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 54,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // close button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ----------------------------- DEMO MODEL ---------------------------- */

class AppQuestion {
  final int id;

  /// আপনার শর্ত: type==3 হলে image zoom লাগবে
  final int type;

  final String text;
  final String? imageUrl;
  final List<String> options;

  /// optional note/explanation
  final String? note;

  AppQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.options,
    this.imageUrl,
    this.note,
  });
}
