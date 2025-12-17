class Student {
  final String id;
  final String name;
  final String studentId;
  final List<String> courseIds;
  final String? email;
  final String phone;
  final List<String> enrolledCourses;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.studentId,
    required this.phone,
    required this.courseIds,
    required this.email,
    required this.enrolledCourses,
    required this.createdAt,
  });

  // Convert Student to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
      'email': email,
      'enrolledCourses': enrolledCourses,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Student from Firestore document
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      studentId: map['studentId'] ?? '',
      email: map['email'],
      phone: map['phone'] ?? '',
      courseIds: List<String>.from(map['courseIds'] ?? []),
      enrolledCourses: List<String>.from(map['enrolledCourses'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? studentId,
    String? email,
    List<String>? enrolledCourses,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      phone: phone,
      courseIds: courseIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
