class Report {
  final int? id;
  final String title;
  final String pdfPath;
  final DateTime createdAt;

  Report({
    this.id,
    required this.title,
    required this.pdfPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pdf_path': pdfPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as int?,
      title: map['title'] as String,
      pdfPath: map['pdf_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Report copyWith({
    int? id,
    String? title,
    String? pdfPath,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
