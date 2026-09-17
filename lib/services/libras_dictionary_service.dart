import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/database_helper.dart';
import '../models/libras_entry.dart';

/// Looks up signs in the official INES Libras dictionary
/// (dicionario.ines.gov.br) and downloads their video/image.
///
/// The site ships its whole word list as a static JS file
/// (`public/site/js/palavras.js`, `var palavras = [...]`) instead of an
/// API, so we fetch and cache that once and query it locally afterwards.
class LibrasDictionaryService {
  LibrasDictionaryService._internal();

  static final LibrasDictionaryService instance =
      LibrasDictionaryService._internal();

  static const _baseUrl = 'https://dicionario.ines.gov.br';
  static const _indexUrl = '$_baseUrl/public/site/js/palavras.js';

  List<LibrasEntry>? _index;

  static const _diacriticsMap = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Uppercase, accent-free form used to compare words regardless of
  /// how the user typed them.
  static String normalize(String text) {
    final lower = text.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacriticsMap[char] ?? char);
    }
    return buffer.toString().toUpperCase();
  }

  Future<List<LibrasEntry>> _loadIndex() async {
    if (_index != null) return _index!;

    final cachePath = await DatabaseHelper.instance.librasCacheFilePath();
    final cacheFile = File(cachePath);
    if (await cacheFile.exists()) {
      final raw = await cacheFile.readAsString();
      _index = _parseEntries(raw);
      return _index!;
    }

    final response = await http.get(Uri.parse(_indexUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível acessar o dicionário do INES '
        '(HTTP ${response.statusCode}).',
      );
    }
    final json = _extractJsonArray(response.body);
    await cacheFile.writeAsString(json);
    _index = _parseEntries(json);
    return _index!;
  }

  /// `palavras.js` is `var palavras = [ ... ];` — pull out just the array.
  String _extractJsonArray(String source) {
    final start = source.indexOf('[');
    final end = source.lastIndexOf(']');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException('Formato inesperado do dicionário INES.');
    }
    return source.substring(start, end + 1);
  }

  List<LibrasEntry> _parseEntries(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .where((e) => (e['palavra'] as String?)?.trim().isNotEmpty ?? false)
        .map(LibrasEntry.fromJson)
        .where((e) => e.videoFile != null)
        .toList();
  }

  /// Forces re-download of the dictionary index on next lookup.
  Future<void> clearIndexCache() async {
    _index = null;
    final cachePath = await DatabaseHelper.instance.librasCacheFilePath();
    final cacheFile = File(cachePath);
    if (await cacheFile.exists()) await cacheFile.delete();
  }

  /// Finds every dictionary entry whose word matches [word], including
  /// numbered variants with a different sign (e.g. ABRIR1, ABRIR2).
  Future<List<LibrasEntry>> findMatches(String word) async {
    final query = normalize(word);
    if (query.isEmpty) return [];
    final entries = await _loadIndex();
    return entries.where((e) {
      final base = normalize(e.palavra).replaceFirst(RegExp(r'\d+$'), '');
      return base == query;
    }).toList()
      ..sort((a, b) => a.palavra.compareTo(b.palavra));
  }

  Future<LibrasEntry?> findById(int id) async {
    final entries = await _loadIndex();
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  String videoUrl(LibrasEntry entry) =>
      '$_baseUrl/public/media/palavras/videos/${entry.videoFile}';

  String? imageUrl(LibrasEntry entry) => entry.imageFile == null
      ? null
      : '$_baseUrl/public/media/palavras/images/${entry.imageFile}';

  Future<List<int>> downloadVideo(LibrasEntry entry) =>
      _downloadBytes(videoUrl(entry));

  Future<List<int>?> downloadImage(LibrasEntry entry) async {
    final url = imageUrl(entry);
    if (url == null) return null;
    try {
      return await _downloadBytes(url);
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> _downloadBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Falha ao baixar mídia do INES (HTTP ${response.statusCode}).');
    }
    return response.bodyBytes;
  }
}
