class Routine {
  final String id;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String day;
  final String startTime;
  final String endTime;
  final String? room;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      courseCode: map['courseCode'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      room: map['room'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Routine copyWith({
    String? id,
    String? courseId,
    String? courseName,
    String? courseCode,
    String? day,
    String? startTime,
    String? endTime,
    String? room,
    DateTime? createdAt,
  }) {
    return Routine(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

