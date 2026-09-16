class Category {
  final int? id;
  final String name;
  final String frontLabel;
  final String backLabel;
  final int colorValue;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    this.frontLabel = 'Palavra',
    this.backLabel = 'Significado',
    required this.colorValue,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Category copyWith({
    int? id,
    String? name,
    String? frontLabel,
    String? backLabel,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      frontLabel: frontLabel ?? this.frontLabel,
      backLabel: backLabel ?? this.backLabel,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frontLabel': frontLabel,
      'backLabel': backLabel,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      frontLabel: map['frontLabel'] as String? ?? 'Palavra',
      backLabel: map['backLabel'] as String? ?? 'Significado',
      colorValue: map['colorValue'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
