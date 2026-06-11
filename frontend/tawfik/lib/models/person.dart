class Person {
  final int? id;
  final String name;
  final String imagePath;
  final DateTime createdAt;

  Person({
    this.id,
    required this.name,
    required this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      imagePath: map['image_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Person copyWith({
    int? id,
    String? name,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
