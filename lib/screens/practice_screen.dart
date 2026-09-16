import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/flashcard.dart';
import '../providers/app_state.dart';
import '../widgets/flashcard_widget.dart';
import 'practice_summary_screen.dart';

class PracticeScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final Category? category;

  const PracticeScreen({super.key, required this.cards, this.category});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _index = 0;
  bool _flipped = false;
  int _correct = 0;
  int _wrong = 0;
  late Map<int, Category> _categoriesById;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _categoriesById = {for (final c in state.categories) c.id!: c};
  }

  Flashcard get _currentCard => widget.cards[_index];

  Category get _currentCategory =>
      widget.category ?? _categoriesById[_currentCard.categoryId]!;

  Future<void> _answer(bool correct) async {
    if (!_flipped) return;
    await context.read<AppState>().recordResult(_currentCard, correct: correct);
    setState(() {
      if (correct) {
        _correct++;
      } else {
        _wrong++;
      }
    });

    if (_index == widget.cards.length - 1) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PracticeSummaryScreen(
            correct: _correct,
            wrong: _wrong,
            total: widget.cards.length,
          ),
        ),
      );
      return;
    }

    setState(() {
      _index++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_index + 1) / widget.cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${widget.cards.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: progress),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: FlashcardWidget(
                        key: ValueKey(_currentCard.id),
                        card: _currentCard,
                        frontLabel: _currentCategory.frontLabel,
                        backLabel: _currentCategory.backLabel,
                        flipped: _flipped,
                        onTap: () => setState(() => _flipped = !_flipped),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_flipped)
                      const Text(
                        'Toque no cartão para ver a resposta',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _answer(false),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Errei'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _answer(true),
                              icon: const Icon(Icons.check),
                              label: const Text('Acertei'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
