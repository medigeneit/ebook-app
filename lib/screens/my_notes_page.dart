import 'package:ebook_project/screens/saved_contents_list_page.dart';
import 'package:flutter/material.dart';

class MyNotesPage extends StatelessWidget {
  const MyNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SavedContentsListPage(mode: SavedListMode.notes);
  }
}
