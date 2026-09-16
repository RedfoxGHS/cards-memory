import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;

import '../data/repository.dart';
import '../models/category.dart';
import '../models/flashcard.dart';

class AppState extends ChangeNotifier {
  final Repository _repo = Repository.instance;

  List<Category> _categories = [];
  final Map<int, int> _cardCounts = {};
  bool _loading = true;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;

  int cardCountFor(int categoryId) => _cardCounts[categoryId] ?? 0;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _categories = await _repo.getCategories();
    _cardCounts.clear();
    for (final c in _categories) {
      _cardCounts[c.id!] = await _repo.getFlashcardCount(c.id!);
    }
    _loading = false;
    notifyListeners();
  }

  Future<Category> addCategory({
    required String name,
    required String frontLabel,
    required String backLabel,
    required int colorValue,
  }) async {
    final category = await _repo.createCategory(
      Category(
        name: name,
        frontLabel: frontLabel,
        backLabel: backLabel,
        colorValue: colorValue,
      ),
    );
    await load();
    return category;
  }

  Future<void> updateCategory(Category category) async {
    await _repo.updateCategory(category);
    await load();
  }

  Future<void> deleteCategory(Category category) async {
    await _repo.deleteCategory(category.id!);
    await load();
  }

  Future<List<Flashcard>> flashcardsFor(int categoryId) {
    return _repo.getFlashcards(categoryId);
  }

  Future<Flashcard> addFlashcard({
    required int categoryId,
    required String frontText,
    File? frontImage,
    required String backText,
    File? backImage,
  }) async {
    String? frontPath;
    String? backPath;
    if (frontImage != null) {
      frontPath = await _repo.saveImageFile(frontImage);
    }
    if (backImage != null) {
      backPath = await _repo.saveImageFile(backImage);
    }
    final card = await _repo.createFlashcard(
      Flashcard(
        categoryId: categoryId,
        frontText: frontText,
        frontImagePath: frontPath,
        backText: backText,
        backImagePath: backPath,
      ),
    );
    _cardCounts[categoryId] = (_cardCounts[categoryId] ?? 0) + 1;
    notifyListeners();
    return card;
  }

  Future<void> updateFlashcard(
    Flashcard existing, {
    required String frontText,
    File? newFrontImage,
    bool removeFrontImage = false,
    required String backText,
    File? newBackImage,
    bool removeBackImage = false,
  }) async {
    String? frontPath = existing.frontImagePath;
    String? backPath = existing.backImagePath;

    if (newFrontImage != null) {
      frontPath = await _repo.saveImageFile(newFrontImage);
    } else if (removeFrontImage) {
      frontPath = null;
    }

    if (newBackImage != null) {
      backPath = await _repo.saveImageFile(newBackImage);
    } else if (removeBackImage) {
      backPath = null;
    }

    final updated = existing.copyWith(
      frontText: frontText,
      backText: backText,
      frontImagePath: frontPath,
      clearFrontImage: frontPath == null,
      backImagePath: backPath,
      clearBackImage: backPath == null,
    );
    await _repo.updateFlashcard(updated);
  }

  Future<void> deleteFlashcard(Flashcard card) async {
    await _repo.deleteFlashcard(card);
    final current = _cardCounts[card.categoryId] ?? 1;
    _cardCounts[card.categoryId] = current > 0 ? current - 1 : 0;
    notifyListeners();
  }

  Future<void> recordResult(Flashcard card, {required bool correct}) {
    return _repo.recordResult(card, correct: correct);
  }

  Future<List<Flashcard>> pickPracticeCards({
    int? categoryId,
    required int count,
  }) {
    return _repo.pickPracticeCards(categoryId: categoryId, count: count);
  }

  Future<int> totalCardCount() async {
    final all = await _repo.getAllFlashcards();
    return all.length;
  }
}
