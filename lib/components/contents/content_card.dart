import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ebook_project/models/ebook_content.dart';
import 'package:ebook_project/components/contents/image_with_placeholder.dart';

import '../../presentation/screens/question_page_with_zoom.dart';

class ContentCard extends StatelessWidget {
  final EbookContent content;
  final bool showCorrect;
  final Map<int, String> selectedTF;   // optionId : 'T'|'F'
  final Map<int, String> selectedSBA;  // contentId : slNo

  final VoidCallback onToggleAnswer;
  final VoidCallback? onTapDiscussion;
  final VoidCallback? onTapReference;
  final VoidCallback? onTapVideo;
  final VoidCallback? onTapNote;

  final void Function(int optionId, String label) onChooseTF;
  final void Function(int contentId, String slNo) onChooseSBA;

  const ContentCard({
    super.key,
    required this.content,
    required this.showCorrect,
    required this.selectedTF,
    required this.selectedSBA,
    required this.onToggleAnswer,
    required this.onChooseTF,
    required this.onChooseSBA,
    this.onTapDiscussion,
    this.onTapReference,
    this.onTapVideo,
    this.onTapNote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.type == 3)
              _ImageFromHtml(htmlString: content.title)
            else
              Html(
                data: "<b>${content.title}</b>",
                style: {"b": Style(fontSize: FontSize(15.5), lineHeight: LineHeight.number(1.45))},
              ),
            const SizedBox(height: 6),
            OptionList(
              content: content,
              showCorrect: showCorrect,
              selectedTF: selectedTF,
              selectedSBA: selectedSBA,
              onChooseTF: onChooseTF,
              onChooseSBA: onChooseSBA,
            ),
            const SizedBox(height: 10),
            ActionBar(
              showAnswerActive: showCorrect,
              onToggleAnswer: onToggleAnswer,
              onTapDiscussion: onTapDiscussion,
              onTapReference: onTapReference,
              onTapVideo: onTapVideo,
              onTapNote: onTapNote,
            ),
          ],
        ),
      ),
    );
  }
}

/* ===== Options ===== */

class OptionList extends StatelessWidget {
  final EbookContent content;
  final bool showCorrect;
  final Map<int, String> selectedTF;
  final Map<int, String> selectedSBA;
  final void Function(int optionId, String label) onChooseTF;
  final void Function(int contentId, String slNo) onChooseSBA;

  const OptionList({
    super.key,
    required this.content,
    required this.showCorrect,
    required this.selectedTF,
    required this.selectedSBA,
    required this.onChooseTF,
    required this.onChooseSBA,
  });

  @override
  Widget build(BuildContext context) {
    // 1) options সবসময় A→B→C→D→E ক্রমে সাজাও
    final opts = [...content.options]
      ..sort((a, b) => (a.slNo ?? '').compareTo(b.slNo ?? ''));

    // 2) answer স্ট্রিং ক্লিন করে শুধুই T/F রেখে uppercase করো
    final cleanAns = (content.answer ?? '')
        .replaceAll(RegExp(r'[^TFtf]'), '')
        .toUpperCase();

    return Column(
      children: List.generate(opts.length, (i) {
        final option = opts[i];

        if (content.type == 1) {
          // TF: answerKey = cleanAns[i] (গার্ড সহ)
          final answerKey = (i < cleanAns.length) ? cleanAns[i] : '';
          final selected = selectedTF[option.id];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TFButton(
                  label: 'T',
                  isSelected: selected == 'T',
                  isCorrect: showCorrect ? (answerKey == 'T') : null,
                  onTap: () => onChooseTF(option.id, 'T'),
                ),
                const SizedBox(width: 6),
                TFButton(
                  label: 'F',
                  isSelected: selected == 'F',
                  isCorrect: showCorrect ? (answerKey == 'F') : null,
                  onTap: () => onChooseTF(option.id, 'F'),
                ),
                const SizedBox(width: 10),
                Expanded(child: Html(data: option.title)),
              ],
            ),
          );
        }

        if (content.type == 2) {
          // SBA: letter match — উভয় পাশই uppercase/trim করো
          final selected = selectedSBA[content.id];
          final isSelected = (selected ?? '').toUpperCase().trim() ==
              (option.slNo ?? '').toUpperCase().trim();
          final isCorrect = (option.slNo ?? '').toUpperCase().trim() ==
              (content.answer ?? '').toUpperCase().trim();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                RoundOptionButton(
                  text: option.slNo ?? '',
                  isSelected: isSelected,
                  verdict: showCorrect
                      ? (isCorrect ? _Verdict.correct : _Verdict.wrong)
                      : _Verdict.neutral,
                  onTap: () => onChooseSBA(content.id, option.slNo ?? ''),
                ),
                const SizedBox(width: 10),
                Expanded(child: Html(data: option.title)),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      }),
    );
  }

}

/* ===== Buttons ===== */

class TFButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool? isCorrect; // null = neutral
  final VoidCallback onTap;

  const TFButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (isCorrect != null) {
      bg = isCorrect! ? Colors.green.shade700 : Colors.red.shade700;
      fg = Colors.white;
    } else {
      bg = isSelected ? Colors.blue.shade700 : Colors.grey.shade300;
      fg = isSelected ? Colors.white : Colors.black87;
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
          side: const BorderSide(color: Colors.black26, width: 1.2),
        ),
        elevation: isSelected ? 1.5 : 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

enum _Verdict { neutral, correct, wrong }

class RoundOptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final _Verdict verdict;
  final VoidCallback onTap;

  const RoundOptionButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.verdict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;

    switch (verdict) {
      case _Verdict.correct:
        bg = Colors.green.shade700; break;
      case _Verdict.wrong:
        bg = Colors.red.shade700; break;
      case _Verdict.neutral:
        bg = isSelected ? Colors.blue.shade700 : Colors.grey.shade300;
        fg = isSelected ? Colors.white : Colors.black87;
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
          side: const BorderSide(color: Colors.black26, width: 1.2),
        ),
        elevation: isSelected ? 1.5 : 0,
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

/* ===== Image from HTML ===== */

class _ImageFromHtml extends StatelessWidget {
  final String htmlString;
  const _ImageFromHtml({required this.htmlString});

  @override
  Widget build(BuildContext context) {
    final RegExp exp = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = exp.firstMatch(htmlString);
    final imageUrl = match?.group(1);

    if (imageUrl == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Image not found'),
      );
    }

    return Column(
      children: [
        // ClipRRect(
        //   borderRadius: BorderRadius.circular(12),
        //   child: ImageWithPlaceholder(imageUrl: imageUrl),
        // ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220, // ✅ এখানে বাড়ান
            width: double.infinity,
            child: ZoomableQuestionImage(
              imageUrl: imageUrl,
              heroTag: 'qimg_$imageUrl',
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

/* ===== Action bar ===== */

/* ===== Action bar (side-by-side) ===== */

class ActionBar extends StatelessWidget {
  final bool showAnswerActive;
  final VoidCallback onToggleAnswer;
  final VoidCallback? onTapDiscussion;
  final VoidCallback? onTapReference;
  final VoidCallback? onTapVideo;
  final VoidCallback? onTapNote;

  const ActionBar({
    super.key,
    required this.showAnswerActive,
    required this.onToggleAnswer,
    this.onTapDiscussion,
    this.onTapReference,
    this.onTapVideo,
    this.onTapNote,
  });

  @override
  Widget build(BuildContext context) {
    // যেসব বাটন আছে তাদের লিস্ট বানালাম
    final btns = <Widget>[
      _PrimaryPillButton(
        label: showAnswerActive ? "Hide Answer" : "Answer",
        isActive: showAnswerActive,
        onTap: onToggleAnswer,
      ),
      if (onTapDiscussion != null)
        _PrimaryPillButton(label: "Discussion", onTap: onTapDiscussion!),
      if (onTapReference != null)
        _PrimaryPillButton(label: "Reference", onTap: onTapReference!),
      if (onTapVideo != null)
        _PrimaryPillButton(label: "Video", onTap: onTapVideo!),
      if (onTapNote != null)
        _PrimaryPillButton(label: "Note", onTap: onTapNote!),
    ];

    if (btns.isEmpty) return const SizedBox.shrink();

    // সব বাটনকে এক লাইনে, সমান প্রস্থে দেখাই
    return Row(
      children: List.generate(btns.length * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(width: 8); // গ্যাপ
        final idx = i ~/ 2;
        return Expanded(child: btns[idx]);
      }),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PrimaryPillButton({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44, // ফিক্সড হাইট
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue[800] : Colors.blue[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isActive ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 12), // Expanded বলে বড় padding দরকার নেই
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

