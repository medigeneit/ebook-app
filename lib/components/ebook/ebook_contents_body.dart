import 'package:flutter/material.dart';
import 'package:ebook_project/models/ebook_content.dart';
import 'package:ebook_project/components/contents/content_card.dart';
import 'package:ebook_project/components/notes/note_bottom_sheet.dart';
import 'package:ebook_project/components/contents/underline_question_dialog.dart';

class EbookContentsBody extends StatelessWidget {
  final List<EbookContent> contents;

  final Map<int, String> selectedTF;
  final Map<int, String> selectedSBA;
  final Set<int> showCorrect;

  final VoidCallback Function(int contentId)? onToggleAnswer;
  final VoidCallback Function(int contentId)? onTapDiscussion;
  final VoidCallback Function(int contentId)? onTapReference;
  final VoidCallback Function(int contentId)? onTapVideo;

  /// ✅ base path: .../contents/{id}
  final String Function(int contentId) noteBasePath;

  /// ✅ base path: .../contents/{id} (underline এও এইটাই লাগবে)
  final String Function(int contentId) contentBasePath;

  final void Function(int optionId, String label) onChooseTF;
  final void Function(int contentId, String slNo) onChooseSBA;

  final Map<int, bool> bookmarked;
  final Map<int, bool> flagged;
  final Set<int> bookmarkBusy;
  final Set<int> flagBusy;
  final VoidCallback Function(int contentId) onTapBookmark;
  final VoidCallback Function(int contentId) onTapFlag;

  final ScrollController? scrollController;
  final int? focusContentId;
  final GlobalKey? focusKey;

  /// ✅ underline save হলে parent কে notify
  final void Function(int contentId, String updatedTitleHtml)? onUnderlineSaved;

  /// ✅ NEW: Word index tap callback
  final void Function(String word)? onTapWord;

  const EbookContentsBody({
    super.key,
    required this.contents,
    required this.selectedTF,
    required this.selectedSBA,
    required this.showCorrect,
    required this.noteBasePath,
    required this.contentBasePath,
    required this.onChooseTF,
    required this.onChooseSBA,
    required this.bookmarked,
    required this.flagged,
    required this.bookmarkBusy,
    required this.flagBusy,
    required this.onTapBookmark,
    required this.onTapFlag,
    this.onToggleAnswer,
    this.onTapDiscussion,
    this.onTapReference,
    this.onTapVideo,
    this.scrollController,
    this.focusContentId,
    this.focusKey,
    this.onUnderlineSaved,
    this.onTapWord, // ✅ NEW
  });

  Future<void> _openUnderline({
    required BuildContext context,
    required EbookContent content,
  }) async {
    if (content.type == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image question এ underline কাজ করবে না')),
      );
      return;
    }

    final updatedHtml = await UnderlineQuestionDialog.open(
      context: context,
      basePath: contentBasePath(content.id),
      titleHtmlOrText: content.title,
    );

    if (updatedHtml == null) return;

    onUnderlineSaved?.call(content.id, updatedHtml);
  }

  @override
  Widget build(BuildContext context) {
    if (focusContentId != null) {
      final children = <Widget>[];
      for (final content in contents) {
        final isBookmarked = bookmarked[content.id] ?? false;
        final isFlagged = flagged[content.id] ?? false;

        children.add(
          Container(
            key: (content.id == focusContentId) ? focusKey : null,
            child: ContentCard(
              content: content,
              showCorrect: showCorrect.contains(content.id),
              selectedTF: selectedTF,
              selectedSBA: selectedSBA,

              isBookmarked: isBookmarked,
              isFlagged: isFlagged,
              bookmarkLoading: bookmarkBusy.contains(content.id),
              flagLoading: flagBusy.contains(content.id),
              onTapBookmark: onTapBookmark(content.id),
              onTapFlag: onTapFlag(content.id),

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

              onTapEdit: () => _openUnderline(context: context, content: content),

              onTapNote: () => NoteBottomSheet.open(
                context: context,
                basePath: noteBasePath(content.id),
              ),

              onChooseTF: onChooseTF,
              onChooseSBA: onChooseSBA,

              /// ✅ NEW
              onTapWord: onTapWord,
            ),
          ),
        );

        children.add(const SizedBox(height: 8));
      }

      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: children,
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: contents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final content = contents[index];
        final isBookmarked = bookmarked[content.id] ?? false;
        final isFlagged = flagged[content.id] ?? false;

        return ContentCard(
          content: content,
          showCorrect: showCorrect.contains(content.id),
          selectedTF: selectedTF,
          selectedSBA: selectedSBA,

          isBookmarked: isBookmarked,
          isFlagged: isFlagged,
          bookmarkLoading: bookmarkBusy.contains(content.id),
          flagLoading: flagBusy.contains(content.id),
          onTapBookmark: onTapBookmark(content.id),
          onTapFlag: onTapFlag(content.id),

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

          onTapEdit: () => _openUnderline(context: context, content: content),

          onTapNote: () => NoteBottomSheet.open(
            context: context,
            basePath: noteBasePath(content.id),
          ),

          onChooseTF: onChooseTF,
          onChooseSBA: onChooseSBA,

          /// ✅ NEW
          onTapWord: onTapWord,
        );
      },
    );
  }
}