import 'package:flutter/material.dart';
import 'package:ebook_project/components/breadcrumb_bar.dart';
import 'package:ebook_project/screens/ebook_subjects.dart';
import 'package:ebook_project/screens/ebook_chapters.dart';
import 'package:ebook_project/screens/ebook_topics.dart';

class EbookContentsHeader extends StatelessWidget {
  final String ebookId;
  final String ebookName;

  final String subjectId;
  final String chapterId;
  final String topicId;

  final String subjectTitle;
  final String chapterTitle;
  final String topicTitle;

  const EbookContentsHeader({
    super.key,
    required this.ebookId,
    required this.ebookName,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.subjectTitle,
    required this.chapterTitle,
    required this.topicTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: BreadcrumbBar(
        items: [
          'SUBJECTS',
          subjectTitle.toUpperCase(),
          chapterTitle.toUpperCase(),
          topicTitle.toUpperCase(),
        ],
        onHome: () => Navigator.pop(context),
        onItemTap: [
              () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EbookSubjectsPage(
                  ebookId: ebookId,
                  ebookName: ebookName,
                ),
              ),
            );
          },
              () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EbookChaptersPage(
                  ebookId: ebookId,
                  subjectId: subjectId,
                  ebookName: ebookName,
                  subjectTitle: subjectTitle,
                ),
              ),
            );
          },
              () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EbookTopicsPage(
                  ebookId: ebookId,
                  subjectId: subjectId,
                  chapterId: chapterId,
                  ebookName: ebookName,
                  subjectTitle: subjectTitle,
                  chapterTitle: chapterTitle,
                ),
              ),
            );
          },
          null,
        ],
      ),
    );
  }
}
