/// One entry from the INES Libras dictionary (dicionario.ines.gov.br).
class LibrasEntry {
  final int id;
  final String palavra;
  final String descricao;
  final String exemplo;
  final String libras;
  final String? videoFile;
  final String? imageFile;

  const LibrasEntry({
    required this.id,
    required this.palavra,
    required this.descricao,
    required this.exemplo,
    required this.libras,
    required this.videoFile,
    required this.imageFile,
  });

  factory LibrasEntry.fromJson(Map<String, dynamic> json) {
    return LibrasEntry(
      id: json['id'] as int,
      palavra: (json['palavra'] as String? ?? '').trim(),
      descricao: (json['descricao'] as String? ?? '').trim(),
      exemplo: (json['exemplo'] as String? ?? '').trim(),
      libras: (json['libras'] as String? ?? '').trim(),
      videoFile: (json['video'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['video'] as String).trim(),
      imageFile: (json['image'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['image'] as String).trim(),
    );
  }
}
