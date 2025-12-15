import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/firestore_service.dart';

class StudentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Student> _students = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all students
  void loadStudents(String userId) {
    _firestoreService
        .getStudentsStream(userId)
        .listen(
          (students) {
            _students = students;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load students by course
  void loadStudentsByCourse(String userId, String courseId) {
    _firestoreService
        .getStudentsByCourseStream(userId, courseId)
        .listen(
          (students) {
            _students = students;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Add student
  Future<bool> addStudent(
    String userId,
    String name,
    String studentId, {
    String? email,
    List<String>? enrolledCourses,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final student = Student(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        studentId: studentId,
        email: email,
        enrolledCourses: enrolledCourses ?? [],
        createdAt: DateTime.now(),
      );

      await _firestoreService.addStudent(userId, student);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update student
  Future<bool> updateStudent(String userId, Student student) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateStudent(userId, student);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete student
  Future<bool> deleteStudent(String userId, String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteStudent(userId, studentId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Enroll student in course
  Future<bool> enrollInCourse(
    String userId,
    String studentId,
    String courseId,
  ) async {
    try {
      await _firestoreService.enrollStudentInCourse(
        userId,
        studentId,
        courseId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
