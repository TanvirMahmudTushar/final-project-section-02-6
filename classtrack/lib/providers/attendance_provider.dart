import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/student.dart';

class AttendanceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Attendance> _attendanceList = [];

  List<Attendance> get attendanceList => _attendanceList;

  Future<void> loadAttendanceForCourse(String userId, String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .get();

      _attendanceList = [];
      for (final doc in snapshot.docs) {
        try {
          final attendance = Attendance.fromFirestore(doc.data(), doc.id);
          _attendanceList.add(attendance);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }

      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        print('Error loading attendance: $error');
      }
      rethrow;
    }
  }

  // ADD THIS METHOD
  Stream<List<Attendance>> getAttendanceStream(String userId, String courseId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .snapshots()
          .asyncMap((snapshot) {
            final attendanceList = <Attendance>[];

            for (final doc in snapshot.docs) {
              try {
                final attendance = Attendance.fromFirestore(doc.data(), doc.id);
                attendanceList.add(attendance);
              } catch (e) {
                print('Error parsing attendance document ${doc.id}: $e');
              }
            }

            return attendanceList;
          });
    } catch (error) {
      print('Error in getAttendanceStream: $error');
      return Stream.value([]);
    }
  }

  Future<void> markAttendance({
    required String userId,
    required String courseId,
    required DateTime date,
    required Map<String, String> attendanceMap,
    required List<Student> students,
  }) async {
    try {
      print('Saving attendance for ${students.length} students');

      final List<Map<String, dynamic>> records = [];

      // Create records array
      for (final entry in attendanceMap.entries) {
        final student = students.firstWhere(
          (s) => s.id == entry.key,
          orElse: () => Student(
            id: '',
            name: 'Unknown',
            studentId: 'N/A',
            email: '',
            enrolledCourses: [],
            createdAt: DateTime.now(),
          ),
        );

        records.add({
          'studentId': entry.key,
          'studentName': student.name,
          'status': entry.value,
        });
      }

      final attendanceData = {
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'records': records,
      };

      // Create document ID using date
      final dateStr = date.toIso8601String().split('T')[0];
      final attendanceId =
          '${dateStr}_${DateTime.now().millisecondsSinceEpoch}';

      print(
        'Saving to: users/$userId/courses/$courseId/attendance/$attendanceId',
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .doc(attendanceId)
          .set(attendanceData);

      print('Attendance saved successfully!');

      // Reload attendance
      await loadAttendanceForCourse(userId, courseId);

      notifyListeners();
    } catch (error) {
      print('Error marking attendance: $error');
      rethrow;
    }
  }

  // Add this method to your AttendanceProvider class
  Future<Map<String, Map<String, dynamic>>> getAttendanceSummary({
    required String userId,
    required String courseId,
    required DateTimeRange dateRange,
  }) async {
    try {
      // Get all attendance records for this course within date range
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .get();

      // Process attendance data
      final Map<String, Map<String, dynamic>> summary = {};

      for (final doc in snapshot.docs) {
        final attendance = Attendance.fromFirestore(doc.data(), doc.id);

        for (final record in attendance.records) {
          if (!summary.containsKey(record.studentId)) {
            summary[record.studentId] = {
              'studentName': record.studentName,
              'totalClasses': 0,
              'presentCount': 0,
              'absentCount': 0,
              'lateCount': 0,
              'excusedCount': 0,
            };
          }

          final studentSummary = summary[record.studentId]!;
          studentSummary['totalClasses'] = studentSummary['totalClasses'] + 1;

          switch (record.status.toLowerCase()) {
            case 'present':
              studentSummary['presentCount'] =
                  studentSummary['presentCount'] + 1;
              break;
            case 'absent':
              studentSummary['absentCount'] = studentSummary['absentCount'] + 1;
              break;
            case 'late':
              studentSummary['lateCount'] = studentSummary['lateCount'] + 1;
              break;
            case 'excused':
              studentSummary['excusedCount'] =
                  studentSummary['excusedCount'] + 1;
              break;
          }
        }
      }

      // Calculate percentages
      for (final studentId in summary.keys) {
        final studentSummary = summary[studentId]!;
        final totalClasses = studentSummary['totalClasses'] as int;

        if (totalClasses > 0) {
          final presentCount = studentSummary['presentCount'] as int;
          studentSummary['attendancePercentage'] =
              (presentCount / totalClasses * 100).round();
        } else {
          studentSummary['attendancePercentage'] = 0;
        }
      }

      return summary;
    } catch (error) {
      print('Error getting attendance summary: $error');
      rethrow;
    }
  }
}
