import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/firestore_service.dart';

class RoutineProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadRoutines(String userId) {
    _firestoreService.getRoutinesStream(userId).listen(
      (routines) {
        _routines = routines;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  List<Routine> getRoutinesByDay(String day) {
    return _routines.where((routine) => routine.day == day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Map<String, List<Routine>> getWeeklyRoutines() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final Map<String, List<Routine>> weekly = {};

    for (var day in days) {
      weekly[day] = getRoutinesByDay(day);
    }

    return weekly;
  }

  Future<bool> addRoutine(
    String userId,
    String courseId,
    String courseName,
    String courseCode,
    String day,
    String startTime,
    String endTime, {
    String? room,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final routine = Routine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        courseName: courseName,
        courseCode: courseCode,
        day: day,
        startTime: startTime,
        endTime: endTime,
        room: room,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addRoutine(userId, routine);

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

  Future<bool> updateRoutine(String userId, Routine routine) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateRoutine(userId, routine);

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

  Future<bool> deleteRoutine(String userId, String routineId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteRoutine(userId, routineId);

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

  bool hasConflict(String day, String startTime, String endTime,
      {String? excludeRoutineId}) {
    final dayRoutines = getRoutinesByDay(day)
        .where((r) => r.id != excludeRoutineId)
        .toList();

    for (var routine in dayRoutines) {
      if (_timeOverlaps(startTime, endTime, routine.startTime, routine.endTime)) {
        return true;
      }
    }
    return false;
  }

  bool _timeOverlaps(
      String start1, String end1, String start2, String end2) {
    final s1 = _timeToMinutes(start1);
    final e1 = _timeToMinutes(end1);
    final s2 = _timeToMinutes(start2);
    final e2 = _timeToMinutes(end2);

    return (s1 < e2 && e1 > s2);
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

