import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ebook_project/screens/youtube_player_page.dart';
import 'fullscreen_overlay.dart';

class SolveVideosModal extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final VoidCallback onClose;

  const SolveVideosModal({
    super.key,
    required this.videos,
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
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Row(
                  children: [
                    const Text(
                      'Solve Videos',
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
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = videos[i];
                    final title = "${v['title'] ?? 'Video'} ${i + 1}";
                    final url = v['video_url'];
                    final videoId = YoutubePlayer.convertUrlToId(url ?? '');

                    if (url == null || videoId == null) {
                      return const ListTile(
                        leading: Icon(Icons.error, color: Colors.red),
                        title: Text('Invalid video URL'),
                      );
                    }

                    return ListTile(
                      leading: const Icon(Icons.play_circle_fill, size: 32),
                      title: Text(title, style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => YoutubePlayerPage(videoId: videoId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
