import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import 'practice_screen.dart';

enum PracticeMode {
  normal('Normal', 'Mostra a frente primeiro'),
  reverso('Reverso', 'Mostra o verso primeiro'),
  misto('Misto', 'Sorteia o lado a cada cartão');

  final String label;
  final String description;

  const PracticeMode(this.label, this.description);
}

class PracticeSetupScreen extends StatefulWidget {
  final Category? initialCategory;

  const PracticeSetupScreen({super.key, this.initialCategory});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  Category? _selectedCategory;
  double _count = 10;
  PracticeMode _mode = PracticeMode.normal;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = state.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Praticar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biblioteca', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<Category?>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<Category?>(
                  value: null,
                  child: Text('Todas as bibliotecas'),
                ),
                for (final c in categories)
                  DropdownMenuItem<Category?>(value: c, child: Text(c.name)),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 28),
            Text('Modo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<PracticeMode>(
              segments: [
                for (final mode in PracticeMode.values)
                  ButtonSegment(value: mode, label: Text(mode.label)),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 8),
            Text(
              _mode.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            Text(
              'Quantidade de palavras: ${_count.round()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _count,
              min: 10,
              max: 30,
              divisions: 20,
              label: _count.round().toString(),
              onChanged: (v) => setState(() => _count = v),
            ),
            const SizedBox(height: 8),
            const Text(
              'As palavras que você praticou menos ou errou mais aparecem '
              'primeiro.',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _starting ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Começar'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final cards = await Repository.instance.pickPracticeCards(
        categoryId: _selectedCategory?.id,
        count: _count.round(),
      );
      if (!mounted) return;
      if (cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum cartão encontrado. Adicione palavras primeiro.'),
          ),
        );
        return;
      }
      final random = Random();
      final reversedFlags = List<bool>.generate(cards.length, (i) {
        switch (_mode) {
          case PracticeMode.normal:
            return false;
          case PracticeMode.reverso:
            return true;
          case PracticeMode.misto:
            return random.nextBool();
        }
      });
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeScreen(
            cards: cards,
            category: _selectedCategory,
            reversedFlags: reversedFlags,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}
