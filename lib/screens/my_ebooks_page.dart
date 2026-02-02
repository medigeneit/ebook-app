import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/ebook_library_section.dart';
import 'package:flutter/material.dart';

class MyEbooksPage extends StatelessWidget {
  const MyEbooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'My Ebooks',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          // SizedBox(height: 8),
          // _SectionHeader(),
          // SizedBox(height: 4),
          Expanded(child: EbookLibrarySection()),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        'All the ebooks you own are listed below. Tap any card to continue reading right away.',
        style: theme.bodyLarge?.copyWith(color: Colors.white70),
      ),
    );
  }
}
