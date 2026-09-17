import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/flashcard.dart';
import '../providers/app_state.dart';
import 'card_form_screen.dart';
import 'category_form_screen.dart';
import 'practice_setup_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Flashcard>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<AppState>().flashcardsFor(widget.category.id!);
  }

  Future<void> _refresh() async {
    setState(_reload);
  }

  Future<void> _deleteCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir biblioteca?'),
        content: Text(
          'Todos os cartões de "${widget.category.name}" serão apagados '
          'permanentemente, incluindo as fotos. Essa ação não pode ser '
          'desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppState>().deleteCategory(widget.category);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar biblioteca',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryFormScreen(category: category),
                ),
              );
              _refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir biblioteca',
            onPressed: _deleteCategory,
          ),
        ],
      ),
      body: FutureBuilder<List<Flashcard>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snapshot.data!;
          if (cards.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.note_add_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('Nenhum cartão ainda. Toque em "+" para criar o primeiro.'),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PracticeSetupScreen(initialCategory: category),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Praticar esta biblioteca'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 16),
                for (final card in cards) _CardTile(category: category, card: card, onChanged: _refresh),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CardFormScreen(category: category),
            ),
          );
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final Category category;
  final Flashcard card;
  final VoidCallback onChanged;

  const _CardTile({
    required this.category,
    required this.card,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final practiced = card.timesPracticed;
    final errorPct = practiced == 0 ? 0 : (card.errorRate * 100).round();
    final thumbnailPath = card.frontImagePath ?? card.backImagePath;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: thumbnailPath != null
              ? FileImage(File(thumbnailPath))
              : null,
          child: thumbnailPath == null
              ? Text(card.frontText.isNotEmpty ? card.frontText[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(card.frontText),
        subtitle: Text(
          practiced == 0
              ? 'Ainda não praticado'
              : 'Praticado $practiced vez${practiced == 1 ? '' : 'es'} · $errorPct% de erro',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CardFormScreen(category: category, card: card),
                ),
              );
              onChanged();
            } else if (value == 'delete') {
              final appState = context.read<AppState>();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir cartão?'),
                  content: Text('"${card.frontText}" será removido.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await appState.deleteFlashcard(card);
                onChanged();
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}
