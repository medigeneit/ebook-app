import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'fullscreen_overlay.dart';

class DiscussionModal extends StatelessWidget {
  final String html;
  final VoidCallback onClose;

  const DiscussionModal({
    super.key,
    required this.html,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return FullscreenOverlay(
      onClose: onClose,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: w > 520 ? 520 : w * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Row(
                  children: [
                    const Text(
                      'Discussion',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Html(data: html),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
