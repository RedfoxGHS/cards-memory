import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/flashcard.dart';

/// A tappable flashcard that flips between its front and back faces.
class FlashcardWidget extends StatefulWidget {
  final Flashcard card;
  final String frontLabel;
  final String backLabel;
  final bool flipped;
  final VoidCallback onTap;

  const FlashcardWidget({
    super.key,
    required this.card,
    required this.frontLabel,
    required this.backLabel,
    required this.flipped,
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * pi;
              final showFront = angle < pi / 2;
              final displayAngle = showFront ? angle : angle - pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(displayAngle),
                child: showFront
                    ? _CardFace(
                        label: widget.frontLabel,
                        text: widget.card.frontText,
                        imagePath: widget.card.frontImagePath,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      )
                    : _CardFace(
                        label: widget.backLabel,
                        text: widget.card.backText,
                        imagePath: widget.card.backImagePath,
                        color:
                            Theme.of(context).colorScheme.secondaryContainer,
                        textColor: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
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
  final Color color;
  final Color textColor;

  const _CardFace({
    required this.label,
    required this.text,
    required this.imagePath,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
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
            if (imagePath != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            if (imagePath != null) const SizedBox(height: 16),
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
