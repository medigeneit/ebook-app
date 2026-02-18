import 'package:ebook_project/screens/saved_contents_list_page.dart';
import 'package:flutter/material.dart';

class MyFlagsPage extends StatelessWidget {
  const MyFlagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SavedContentsListPage(mode: SavedListMode.flags);
  }
}
