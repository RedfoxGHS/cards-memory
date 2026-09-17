import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import 'video_preview.dart';

/// A tappable flashcard that flips between its front and back faces.
///
/// [reversed] swaps which side (front/back) is shown first, independent of
/// the flip animation direction — used by the Reverso/Misto practice modes.
class FlashcardWidget extends StatefulWidget {
  final Flashcard card;
  final String frontLabel;
  final String backLabel;
  final bool flipped;
  final bool reversed;
  final bool isLibras;
  final VoidCallback onTap;

  const FlashcardWidget({
    super.key,
    required this.card,
    required this.frontLabel,
    required this.backLabel,
    required this.flipped,
    this.reversed = false,
    this.isLibras = false,
    required this.onTap,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void didUpdateWidget(covariant FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipped != oldWidget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final scheme = Theme.of(context).colorScheme;
    final frontFace = _CardFace(
      label: widget.frontLabel,
      text: card.frontText,
      imagePath: card.frontImagePath,
      videoPath: card.frontVideoPath,
      color: scheme.primaryContainer,
      textColor: scheme.onPrimaryContainer,
      videoOnly: widget.isLibras && card.frontVideoPath != null,
    );
    final backFace = _CardFace(
      label: widget.backLabel,
      text: card.backText,
      imagePath: card.backImagePath,
      videoPath: card.backVideoPath,
      color: scheme.secondaryContainer,
      textColor: scheme.onSecondaryContainer,
      videoOnly: widget.isLibras && card.backVideoPath != null,
    );
    final firstFace = widget.reversed ? backFace : frontFace;
    final secondFace = widget.reversed ? frontFace : backFace;

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * pi;
              final showFirst = angle < pi / 2;
              final displayAngle = showFirst ? angle : angle - pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(displayAngle),
                child: showFirst ? firstFace : secondFace,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final String? imagePath;
  final String? videoPath;
  final Color color;
  final Color textColor;
  final bool videoOnly;

  const _CardFace({
    required this.label,
    required this.text,
    required this.imagePath,
    required this.videoPath,
    required this.color,
    required this.textColor,
    this.videoOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = videoPath != null || imagePath != null;
    final hasText = !videoOnly && text.trim().isNotEmpty;
    final media = !hasMedia
        ? null
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: videoPath != null
                ? VideoPreview(path: videoPath!)
                : Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
          );

    if (videoOnly && media != null) {
      // The sign itself is the whole answer — no label, no caption.
      return Card(
        color: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: media,
        ),
      );
    }

    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 16),
            if (media != null) Expanded(child: media),
            if (hasMedia && hasText) const SizedBox(height: 16),
            if (hasText)
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
