import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';

class CourseProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load courses
  void loadCourses(String userId) {
    _firestoreService
        .getCoursesStream(userId)
        .listen(
          (courses) {
            _courses = courses;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Add course
  Future<bool> addCourse(
    String userId,
    String name,
    String code, {
    String? description,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        code: code,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addCourse(userId, course);

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

  // Update course
  Future<bool> updateCourse(String userId, Course course) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateCourse(userId, course);

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

  // Delete course
  Future<bool> deleteCourse(String userId, String courseId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteCourse(userId, courseId);

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

  // Get course by ID
  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
