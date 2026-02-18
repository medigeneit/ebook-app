import 'package:flutter/material.dart';
import 'package:ebook_project/components/notes/note_bottom_sheet.dart';
import 'package:ebook_project/components/contents/underline_question_dialog.dart';

class ContentEditSheet {
  static void open({
    required BuildContext context,
    required String contentBasePath, // .../contents/{id}
    required String noteBasePath,    // .../contents/{id}/notes
    required String titleHtmlOrText,
    required int contentType,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Text(
                      'Edit',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('Note'),
                onTap: () {
                  Navigator.pop(context);
                  NoteBottomSheet.open(context: context, basePath: noteBasePath);
                },
              ),

              ListTile(
                leading: const Icon(Icons.format_underline),
                title: const Text('Underline Question'),
                subtitle: contentType == 3
                    ? const Text('Image question এ underline কাজ করবে না')
                    : null,
                enabled: contentType != 3,
                onTap: contentType == 3
                    ? null
                    : () {
                  Navigator.pop(context);
                  UnderlineQuestionDialog.open(
                    context: context,
                    basePath: contentBasePath,
                    titleHtmlOrText: titleHtmlOrText,
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
