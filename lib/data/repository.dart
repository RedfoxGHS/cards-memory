import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/flashcard.dart';
import 'database_helper.dart';

class Repository {
  Repository._internal();

  static final Repository instance = Repository._internal();

  final _uuid = const Uuid();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ---------- Categories ----------

  Future<List<Category>> getCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return rows.map(Category.fromMap).toList();
  }

  Future<Category> createCategory(Category category) async {
    final db = await _db;
    final id = await db.insert('categories', category.toMap()..remove('id'));
    return category.copyWith(id: id);
  }

  Future<void> updateCategory(Category category) async {
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await _db;
    // Delete image files belonging to this category's cards first.
    final cards = await getFlashcards(categoryId);
    for (final card in cards) {
      await _deleteImageFile(card.frontImagePath);
      await _deleteImageFile(card.backImagePath);
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  // ---------- Flashcards ----------

  Future<List<Flashcard>> getFlashcards(int categoryId) async {
    final db = await _db;
    final rows = await db.query(
      'flashcards',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final db = await _db;
    final rows = await db.query('flashcards', orderBy: 'createdAt DESC');
    return rows.map(Flashcard.fromMap).toList();
  }

  Future<int> getFlashcardCount(int categoryId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE categoryId = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Flashcard> createFlashcard(Flashcard card) async {
    final db = await _db;
    final id = await db.insert('flashcards', card.toMap()..remove('id'));
    return card.copyWith(id: id);
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final db = await _db;
    await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteFlashcard(Flashcard card) async {
    final db = await _db;
    await _deleteImageFile(card.frontImagePath);
    await _deleteImageFile(card.backImagePath);
    await db.delete('flashcards', where: 'id = ?', whereArgs: [card.id]);
  }

  Future<void> recordResult(Flashcard card, {required bool correct}) async {
    final updated = card.copyWith(
      timesCorrect: card.timesCorrect + (correct ? 1 : 0),
      timesWrong: card.timesWrong + (correct ? 0 : 1),
      lastPracticedAt: DateTime.now(),
    );
    await updateFlashcard(updated);
  }

  /// Picks up to [count] cards for a practice session, prioritizing cards
  /// that were practiced less and/or missed more often.
  Future<List<Flashcard>> pickPracticeCards({
    int? categoryId,
    required int count,
  }) async {
    final all = categoryId == null
        ? await getAllFlashcards()
        : await getFlashcards(categoryId);
    all.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return all.take(count).toList();
  }

  // ---------- Images ----------

  Future<String> saveImageFile(File sourceFile) async {
    final dirPath = await DatabaseHelper.instance.imagesDirPath();
    final ext = p.extension(sourceFile.path);
    final fileName = '${_uuid.v4()}$ext';
    final destPath = p.join(dirPath, fileName);
    await sourceFile.copy(destPath);
    return destPath;
  }

  Future<void> _deleteImageFile(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
