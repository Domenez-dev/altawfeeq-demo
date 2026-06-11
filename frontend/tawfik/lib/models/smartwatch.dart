class Smartwatch {
  final int? id;
  final String name;
  final String address;

  Smartwatch({
    this.id,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }

  factory Smartwatch.fromMap(Map<String, dynamic> map) {
    return Smartwatch(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
    );
  }

  Smartwatch copyWith({
    int? id,
    String? name,
    String? address,
  }) {
    return Smartwatch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }
}
