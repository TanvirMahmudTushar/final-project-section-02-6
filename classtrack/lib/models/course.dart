class Course {
  final String id;
  final String name;
  final String code;
  final String? description;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.createdAt,
  });

  // Convert Course to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Course from Firestore document
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Course copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    DateTime? createdAt,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
