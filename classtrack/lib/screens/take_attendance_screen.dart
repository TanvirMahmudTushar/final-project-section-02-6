import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String courseId;

  const TakeAttendanceScreen({super.key, required this.courseId});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final Map<String, String> _attendanceStatus = {};
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final course = courseProvider.getCourseById(widget.courseId);

    // DEBUG: Print course ID
    print('TAKE ATTENDANCE SCREEN - Course ID: ${widget.courseId}');

    // === DEBUG: Detailed student enrollment check ===
    print('=== DEBUG: Checking student enrollment ===');
    print('Course ID from widget: ${widget.courseId}');
    print('Course name: ${course?.name}');
    print('Total students in provider: ${studentProvider.students.length}');

    // Check what each student has
    for (var i = 0; i < studentProvider.students.length; i++) {
      final student = studentProvider.students[i];
      print('\nStudent ${i + 1}: ${student.name} (ID: ${student.id})');
      print('  - enrolledCourses type: ${student.enrolledCourses.runtimeType}');
      print('  - enrolledCourses content: ${student.enrolledCourses}');
      print('  - enrolledCourses length: ${student.enrolledCourses.length}');

      // Check if courseId exists in enrolledCourses
      final hasCourse = student.enrolledCourses.contains(widget.courseId);
      print('  - Contains course ${widget.courseId}? $hasCourse');

      // If not found, print what's actually in enrolledCourses
      if (!hasCourse && student.enrolledCourses.isNotEmpty) {
        print('  - Actual course IDs in student:');
        for (var courseId in student.enrolledCourses) {
          print('      * $courseId');
        }
      }
    }

    // Now filter students properly
    final enrolledStudents = studentProvider.students.where((student) {
      final isEnrolled = student.enrolledCourses.contains(widget.courseId);
      print('${student.name}: enrolled? $isEnrolled');
      return isEnrolled;
    }).toList();

    print('\n=== FILTER RESULTS ===');
    print('Total enrolled students: ${enrolledStudents.length}');

    // If no enrolled students, show warning but still show all for testing
    final displayStudents = enrolledStudents.isNotEmpty
        ? enrolledStudents
        : studentProvider.students;

    if (enrolledStudents.isEmpty && studentProvider.students.isNotEmpty) {
      print('⚠️ WARNING: No students enrolled in this course!');
      print('Showing ALL students for testing purposes.');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance - ${course?.name ?? "Course"}'),
      ),
      body: displayStudents.isEmpty
          ? const Center(child: Text('No students found. Add students first.'))
          : ListView(
              children: [
                // Date selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          _selectedDate.toString().split(' ')[0],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student list
                ...displayStudents.map((student) {
                  // Initialize status if not set
                  _attendanceStatus[student.id] =
                      _attendanceStatus[student.id] ?? 'Present';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(student.name[0])),
                      title: Text(student.name),
                      subtitle: Text('ID: ${student.studentId}'),
                      trailing: DropdownButton<String>(
                        value: _attendanceStatus[student.id],
                        items: const [
                          DropdownMenuItem(
                            value: 'Present',
                            child: Text('Present'),
                          ),
                          DropdownMenuItem(
                            value: 'Absent',
                            child: Text('Absent'),
                          ),
                          DropdownMenuItem(value: 'Late', child: Text('Late')),
                          DropdownMenuItem(
                            value: 'Excused',
                            child: Text('Excused'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _attendanceStatus[student.id] = value!;
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
      floatingActionButton: displayStudents.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final attendanceProvider = Provider.of<AttendanceProvider>(
                  context,
                  listen: false,
                );
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                if (authProvider.user != null) {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await attendanceProvider.markAttendance(
                      userId: authProvider.user!.uid,
                      courseId: widget.courseId,
                      date: _selectedDate,
                      attendanceMap: _attendanceStatus,
                      students: displayStudents,
                    );

                    // Close loading dialog
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Attendance saved successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Navigate back to attendance screen after a delay
                    await Future.delayed(const Duration(seconds: 1));

                    if (mounted) {
                      Navigator.pop(context); // Go back to attendance screen
                    }
                  } catch (error) {
                    Navigator.pop(context); // Close loading dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : null,
    );
  }
}
