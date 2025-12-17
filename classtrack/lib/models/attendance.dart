import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final DateTime date;
  final DateTime createdAt;
  final List<AttendanceRecord> records;

  Attendance({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.records,
  });

  factory Attendance.fromFirestore(Map<String, dynamic> data, String id) {
  return Attendance(
    id: id,
    date: (data['date'] as Timestamp).toDate(),
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    records: (data['records'] as List<dynamic>).map((record) {
      return AttendanceRecord(
        studentId: record['studentId'] ?? '',
        studentName: record['studentName'] ?? 'Unknown',  // Add this
        status: record['status'] ?? 'Absent',
      );
    }).toList(),
  );
}

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'createdAt': createdAt,
      'records': records.map((record) => record.toMap()).toList(),
    };
  }
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String status;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'status': status,
    };
  }
}
