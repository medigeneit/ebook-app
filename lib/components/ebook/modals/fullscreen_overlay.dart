import 'package:flutter/material.dart';

class FullscreenOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final Widget child;
  final Color shadeColor;

  const FullscreenOverlay({
    super.key,
    required this.onClose,
    required this.child,
    this.shadeColor = const Color(0x99000000), // black with opacity
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ✅ Full screen shade (tap করলে close)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Container(color: shadeColor),
              ),
            ),

            // ✅ Modal content
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
