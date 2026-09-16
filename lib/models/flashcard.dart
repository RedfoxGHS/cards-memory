class Flashcard {
  final int? id;
  final int categoryId;
  final String frontText;
  final String? frontImagePath;
  final String backText;
  final String? backImagePath;
  final int timesCorrect;
  final int timesWrong;
  final DateTime createdAt;
  final DateTime? lastPracticedAt;

  Flashcard({
    this.id,
    required this.categoryId,
    required this.frontText,
    this.frontImagePath,
    required this.backText,
    this.backImagePath,
    this.timesCorrect = 0,
    this.timesWrong = 0,
    DateTime? createdAt,
    this.lastPracticedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get timesPracticed => timesCorrect + timesWrong;

  double get errorRate =>
      timesPracticed == 0 ? 0 : timesWrong / timesPracticed;

  /// Score used to prioritize cards during practice selection.
  /// Higher score = higher priority (practiced less and/or missed more).
  double get priorityScore {
    final wrongWeight = (timesWrong + 1) / (timesPracticed + 1);
    final noveltyWeight = 1 / (timesPracticed + 1);
    return wrongWeight * 2 + noveltyWeight;
  }

  Flashcard copyWith({
    int? id,
    int? categoryId,
    String? frontText,
    String? frontImagePath,
    bool clearFrontImage = false,
    String? backText,
    String? backImagePath,
    bool clearBackImage = false,
    int? timesCorrect,
    int? timesWrong,
    DateTime? lastPracticedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      frontText: frontText ?? this.frontText,
      frontImagePath: clearFrontImage
          ? null
          : (frontImagePath ?? this.frontImagePath),
      backText: backText ?? this.backText,
      backImagePath:
          clearBackImage ? null : (backImagePath ?? this.backImagePath),
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesWrong: timesWrong ?? this.timesWrong,
      createdAt: createdAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'frontText': frontText,
      'frontImagePath': frontImagePath,
      'backText': backText,
      'backImagePath': backImagePath,
      'timesCorrect': timesCorrect,
      'timesWrong': timesWrong,
      'createdAt': createdAt.toIso8601String(),
      'lastPracticedAt': lastPracticedAt?.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      frontText: map['frontText'] as String,
      frontImagePath: map['frontImagePath'] as String?,
      backText: map['backText'] as String,
      backImagePath: map['backImagePath'] as String?,
      timesCorrect: map['timesCorrect'] as int? ?? 0,
      timesWrong: map['timesWrong'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastPracticedAt: map['lastPracticedAt'] == null
          ? null
          : DateTime.parse(map['lastPracticedAt'] as String),
    );
  }
}
