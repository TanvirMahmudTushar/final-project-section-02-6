import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/routine.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== COURSES ====================

  // Get all courses stream
  Stream<List<Course>> getCoursesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Course.fromMap(doc.data());
          }).toList();
        });
  }

  // Add a new course
  Future<void> addCourse(String userId, Course course) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(course.id)
        .set(course.toMap());
  }

  // Update a course
  Future<void> updateCourse(String userId, Course course) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(course.id)
        .update(course.toMap());
  }

  // Delete a course
  Future<void> deleteCourse(String userId, String courseId) async {
    // Delete all students enrolled in this course
    final students = await _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .where('enrolledCourses', arrayContains: courseId)
        .get();

    for (var doc in students.docs) {
      final student = Student.fromMap(doc.data());
      final updatedCourses = student.enrolledCourses
          .where((id) => id != courseId)
          .toList();

      if (updatedCourses.isEmpty) {
        // Delete student if no courses left
        await doc.reference.delete();
      } else {
        // Update student's enrolled courses
        await doc.reference.update({'enrolledCourses': updatedCourses});
      }
    }

    // Delete the course
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseId)
        .delete();
  }

  // ==================== STUDENTS ====================

  // Get all students stream
  Stream<List<Student>> getStudentsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Student.fromMap(doc.data());
          }).toList();
        });
  }

  // Get students by course stream
  Stream<List<Student>> getStudentsByCourseStream(
    String userId,
    String courseId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .where('enrolledCourses', arrayContains: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Student.fromMap(doc.data());
          }).toList();
        });
  }

  // Add a new student
  Future<void> addStudent(String userId, Student student) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .doc(student.id)
        .set(student.toMap());
  }

  // Update a student
  Future<void> updateStudent(String userId, Student student) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .doc(student.id)
        .update(student.toMap());
  }

  // Delete a student
  Future<void> deleteStudent(String userId, String studentId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  // Enroll student in a course
  Future<void> enrollStudentInCourse(
    String userId,
    String studentId,
    String courseId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .doc(studentId)
        .update({
          'enrolledCourses': FieldValue.arrayUnion([courseId]),
        });
  }

  // Unenroll student from a course
  Future<void> unenrollStudentFromCourse(
    String userId,
    String studentId,
    String courseId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('students')
        .doc(studentId)
        .update({
          'enrolledCourses': FieldValue.arrayRemove([courseId]),
        });
  }

  // ==================== COURSE CONTENT ====================

  // Save AI-generated course content
  Future<void> saveCourseContent(
    String userId,
    String courseId,
    Map<String, dynamic> content,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseId)
        .collection('content')
        .doc('ai_generated')
        .set({
          'content': content,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
  }

  // Get saved course content
  Future<Map<String, dynamic>?> getCourseContent(
    String userId,
    String courseId,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseId)
        .collection('content')
        .doc('ai_generated')
        .get();

    if (doc.exists && doc.data() != null) {
      return doc.data()!['content'] as Map<String, dynamic>?;
    }
    return null;
  }

  // Delete course content
  Future<void> deleteCourseContent(String userId, String courseId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseId)
        .collection('content')
        .doc('ai_generated')
        .delete();
  }

  // ==================== ROUTINES ====================

  Stream<List<Routine>> getRoutinesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('routines')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Routine.fromMap(doc.data());
          }).toList();
        });
  }

  Future<void> addRoutine(String userId, Routine routine) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(routine.id)
        .set(routine.toMap());
  }

  Future<void> updateRoutine(String userId, Routine routine) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(routine.id)
        .update(routine.toMap());
  }

  Future<void> deleteRoutine(String userId, String routineId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(routineId)
        .delete();
  }
}
