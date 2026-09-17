import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Desktop platforms need the FFI-based sqflite implementation.
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(join(appDir.path, 'cards_memory'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = join(dbDir.path, 'cards_memory.db');

    return openDatabase(
      dbPath,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            frontLabel TEXT NOT NULL DEFAULT 'Palavra',
            backLabel TEXT NOT NULL DEFAULT 'Significado',
            colorValue INTEGER NOT NULL,
            isLibras INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE flashcards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            categoryId INTEGER NOT NULL,
            frontText TEXT NOT NULL,
            frontImagePath TEXT,
            frontVideoPath TEXT,
            backText TEXT NOT NULL,
            backImagePath TEXT,
            backVideoPath TEXT,
            timesCorrect INTEGER NOT NULL DEFAULT 0,
            timesWrong INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            lastPracticedAt TEXT,
            FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE libras_choices (
            wordKey TEXT PRIMARY KEY,
            entryId INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE categories ADD COLUMN isLibras INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE flashcards ADD COLUMN frontVideoPath TEXT",
          );
          await db.execute(
            "ALTER TABLE flashcards ADD COLUMN backVideoPath TEXT",
          );
          await db.execute('''
            CREATE TABLE IF NOT EXISTS libras_choices (
              wordKey TEXT PRIMARY KEY,
              entryId INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          // Early Libras cards stored the sign (video/image) on the front
          // face together with the word. The sign now belongs on the back
          // face (the word is the front, quizzed side) — move it over for
          // any card created before that fix.
          await db.execute('''
            UPDATE flashcards
            SET backVideoPath = frontVideoPath,
                backImagePath = COALESCE(backImagePath, frontImagePath),
                frontVideoPath = NULL,
                frontImagePath = NULL
            WHERE frontVideoPath IS NOT NULL
              AND categoryId IN (SELECT id FROM categories WHERE isLibras = 1)
          ''');
        }
      },
    );
  }

  Future<String> imagesDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(join(appDir.path, 'cards_memory', 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  Future<String> videosDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(join(appDir.path, 'cards_memory', 'videos'));
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    return videosDir.path;
  }

  Future<String> librasCacheFilePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(join(appDir.path, 'cards_memory', 'cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return join(cacheDir.path, 'libras_dicionario.json');
  }
}
