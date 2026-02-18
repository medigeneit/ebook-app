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

  final String Function(int contentId) noteBasePath;

  final void Function(int optionId, String label) onChooseTF;
  final void Function(int contentId, String slNo) onChooseSBA;

  // ✅ new
  final Map<int, bool> bookmarked;
  final Map<int, bool> flagged;
  final Set<int> bookmarkBusy;
  final Set<int> flagBusy;
  final VoidCallback Function(int contentId) onTapBookmark;
  final VoidCallback Function(int contentId) onTapFlag;

  final ScrollController? scrollController;
  final int? focusContentId;
  final GlobalKey? focusKey;

  const EbookContentsBody({
    super.key,
    required this.contents,
    required this.selectedTF,
    required this.selectedSBA,
    required this.showCorrect,
    required this.noteBasePath,
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
  });

  @override
  // Widget build(BuildContext context) {
  //   return ListView.separated(
  //     padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
  //     itemCount: contents.length,
  //     separatorBuilder: (_, __) => const SizedBox(height: 8),
  //     itemBuilder: (context, index) {
  //       final content = contents[index];
  //       final isBookmarked = bookmarked[content.id] ?? false;
  //       final isFlagged = flagged[content.id] ?? false;
  //
  //       return ContentCard(
  //         content: content,
  //         showCorrect: showCorrect.contains(content.id),
  //         selectedTF: selectedTF,
  //         selectedSBA: selectedSBA,
  //
  //         // ✅ header icons
  //         isBookmarked: isBookmarked,
  //         isFlagged: isFlagged,
  //         bookmarkLoading: bookmarkBusy.contains(content.id),
  //         flagLoading: flagBusy.contains(content.id),
  //         onTapBookmark: onTapBookmark(content.id),
  //         onTapFlag: onTapFlag(content.id),
  //
  //         onToggleAnswer: () => onToggleAnswer?.call(content.id)(),
  //
  //         onTapDiscussion: content.hasDiscussion
  //             ? () => onTapDiscussion?.call(content.id)()
  //             : null,
  //         onTapReference: content.hasReference
  //             ? () => onTapReference?.call(content.id)()
  //             : null,
  //         onTapVideo: content.hasSolveVideo
  //             ? () => onTapVideo?.call(content.id)()
  //             : null,
  //
  //         onTapNote: () => NoteBottomSheet.open(
  //           context: context,
  //           basePath: noteBasePath(content.id),
  //         ),
  //
  //         onChooseTF: onChooseTF,
  //         onChooseSBA: onChooseSBA,
  //       );
  //     },
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    // focus থাকলে eager build (সব item build হবে → ensureVisible কাজ করবে)
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

              onTapNote: () => NoteBottomSheet.open(
                context: context,
                basePath: noteBasePath(content.id),
              ),

              onChooseTF: onChooseTF,
              onChooseSBA: onChooseSBA,
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

    // focus না থাকলে আগের মত lazy list
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
