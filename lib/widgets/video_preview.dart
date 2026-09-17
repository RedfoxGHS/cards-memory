import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a local video file automatically, looping; tap to play/pause.
class VideoPreview extends StatefulWidget {
  final String path;

  const VideoPreview({super.key, required this.path});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _controller?.dispose();
      _controller = null;
      _init();
    }
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.file(File(widget.path));
    await controller.initialize();
    await controller.setLooping(true);
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    await controller.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return GestureDetector(
      onTap: () => setState(() {
        controller.value.isPlaying ? controller.pause() : controller.play();
      }),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 1
            : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) => value.isPlaying
                  ? const SizedBox.shrink()
                  : const Icon(
                      Icons.play_circle_fill,
                      size: 48,
                      color: Colors.white70,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
