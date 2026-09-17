import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;

import '../data/repository.dart';
import '../models/category.dart';
import '../models/flashcard.dart';
import '../models/libras_entry.dart';
import '../services/libras_dictionary_service.dart';

class AppState extends ChangeNotifier {
  final Repository _repo = Repository.instance;
  final LibrasDictionaryService _libras = LibrasDictionaryService.instance;

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
    bool isLibras = false,
  }) async {
    final category = await _repo.createCategory(
      Category(
        name: name,
        frontLabel: frontLabel,
        backLabel: backLabel,
        colorValue: colorValue,
        isLibras: isLibras,
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
    String? frontImagePath,
    String? frontVideoPath,
    required String backText,
    File? backImage,
    String? backImagePath,
    String? backVideoPath,
  }) async {
    String? frontPath = frontImagePath;
    String? backPath = backImagePath;
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
        frontVideoPath: frontVideoPath,
        backText: backText,
        backImagePath: backPath,
        backVideoPath: backVideoPath,
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
    String? newFrontImagePath,
    bool removeFrontImage = false,
    String? newFrontVideoPath,
    bool removeFrontVideo = false,
    required String backText,
    File? newBackImage,
    String? newBackImagePath,
    bool removeBackImage = false,
    String? newBackVideoPath,
    bool removeBackVideo = false,
  }) async {
    String? frontPath = newFrontImagePath ?? existing.frontImagePath;
    String? backPath = newBackImagePath ?? existing.backImagePath;
    String? frontVideo = newFrontVideoPath ?? existing.frontVideoPath;
    String? backVideo = newBackVideoPath ?? existing.backVideoPath;

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

    if (removeFrontVideo) frontVideo = null;
    if (removeBackVideo) backVideo = null;

    final updated = existing.copyWith(
      frontText: frontText,
      backText: backText,
      frontImagePath: frontPath,
      clearFrontImage: frontPath == null,
      frontVideoPath: frontVideo,
      clearFrontVideo: frontVideo == null,
      backImagePath: backPath,
      clearBackImage: backPath == null,
      backVideoPath: backVideo,
      clearBackVideo: backVideo == null,
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

  // ---------- Libras dictionary ----------

  /// All dictionary entries matching [word] (e.g. ABRIR1/ABRIR2 for "abrir").
  Future<List<LibrasEntry>> findLibrasMatches(String word) {
    return _libras.findMatches(word);
  }

  /// The entry previously chosen by the user for this exact word, if any.
  Future<LibrasEntry?> rememberedLibrasChoice(String word) async {
    final key = LibrasDictionaryService.normalize(word);
    final entryId = await _repo.getLibrasChoice(key);
    if (entryId == null) return null;
    return _libras.findById(entryId);
  }

  Future<void> rememberLibrasChoice(String word, LibrasEntry entry) {
    final key = LibrasDictionaryService.normalize(word);
    return _repo.setLibrasChoice(key, entry.id);
  }

  String? librasImageUrl(LibrasEntry entry) => _libras.imageUrl(entry);

  /// Downloads the entry's video (and image, when available) and stores
  /// them locally, returning their on-disk paths.
  Future<({String videoPath, String? imagePath})> downloadLibrasMedia(
    LibrasEntry entry,
  ) async {
    final videoBytes = await _libras.downloadVideo(entry);
    final videoPath = await _repo.saveVideoBytes(videoBytes);

    String? imagePath;
    final imageBytes = await _libras.downloadImage(entry);
    if (imageBytes != null) {
      imagePath = await _repo.saveImageBytes(imageBytes);
    }
    return (videoPath: videoPath, imagePath: imagePath);
  }
}
