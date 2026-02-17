import 'package:flutter/material.dart';
import 'package:ebook_project/models/ebook_content.dart';
import 'package:ebook_project/components/contents/content_card.dart';
import 'package:ebook_project/components/notes/note_bottom_sheet.dart';

class EbookContentsBody extends StatelessWidget {
  final List<EbookContent> contents;

  final Map<int, String> selectedTF;
  final Map<int, String> selectedSBA;
  final Set<int> showCorrect;

  final VoidCallback Function(int contentId)? onToggleAnswer;
  final VoidCallback Function(int contentId)? onTapDiscussion;
  final VoidCallback Function(int contentId)? onTapReference;
  final VoidCallback Function(int contentId)? onTapVideo;

  // Note basePath builder
  final String Function(int contentId) noteBasePath;

  // choose actions
  final void Function(int optionId, String label) onChooseTF;
  final void Function(int contentId, String slNo) onChooseSBA;

  const EbookContentsBody({
    super.key,
    required this.contents,
    required this.selectedTF,
    required this.selectedSBA,
    required this.showCorrect,
    required this.noteBasePath,
    required this.onChooseTF,
    required this.onChooseSBA,
    this.onToggleAnswer,
    this.onTapDiscussion,
    this.onTapReference,
    this.onTapVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: contents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final content = contents[index];

        return ContentCard(
          content: content,
          showCorrect: showCorrect.contains(content.id),
          selectedTF: selectedTF,
          selectedSBA: selectedSBA,

          onToggleAnswer: () => onToggleAnswer?.call(content.id)(),

          onTapDiscussion: content.hasDiscussion
              ? () => onTapDiscussion?.call(content.id)()
              : null,
          onTapReference: content.hasReference
              ? () => onTapReference?.call(content.id)()
              : null,
          onTapVideo: content.hasSolveVideo
              ? () => onTapVideo?.call(content.id)()
              : null,

          // ✅ Note bottom sheet component
          onTapNote: () => NoteBottomSheet.open(
            context: context,
            basePath: noteBasePath(content.id),
          ),

          onChooseTF: onChooseTF,
          onChooseSBA: onChooseSBA,
        );
      },
    );
  }
}
