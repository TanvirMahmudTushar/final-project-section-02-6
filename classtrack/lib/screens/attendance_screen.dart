import 'package:classtrack/models/attendance.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';
import 'take_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          // History button
          if (_selectedCourseId != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                _showAttendanceHistory(context);
              },
              tooltip: 'View Attendance History',
            ),
        ],
      ),
      body: Column(
        children: [
          // Course selection dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Select Course',
                border: OutlineInputBorder(),
              ),
              items: courseProvider.courses.map((course) {
                return DropdownMenuItem(
                  value: course.id,
                  child: Text(course.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourseId = value;
                });
                if (value != null && authProvider.user != null) {
                  attendanceProvider.loadAttendanceForCourse(
                    authProvider.user!.uid,
                    value,
                  );
                }
              },
            ),
          ),
          
          // Take Attendance Button
          if (_selectedCourseId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakeAttendanceScreen(
                          courseId: _selectedCourseId!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Take New Attendance'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Attendance History
          Expanded(
            child: _buildAttendanceHistory(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    
    if (_selectedCourseId == null) {
      return const Center(
        child: Text('Please select a course'),
      );
    }

    if (attendanceProvider.attendanceList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No attendance records yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Take attendance to see history here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: attendanceProvider.attendanceList.length,
      itemBuilder: (context, index) {
        final attendance = attendanceProvider.attendanceList[index];
        final presentCount = attendance.records
            .where((record) => record.status == 'Present')
            .length;
        final totalCount = attendance.records.length;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  attendance.date.day.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            title: Text(
              _formatDate(attendance.date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Present: $presentCount/$totalCount students',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Time: ${_formatTime(attendance.date)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAttendanceDetails(context, attendance);
            },
          ),
        );
      },
    );
  }

  void _showAttendanceHistory(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attendance History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: attendanceProvider.attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceProvider.attendanceList[index];
                    return Card(
                      child: ListTile(
                        title: Text(_formatDate(attendance.date)),
                        subtitle: Text('${attendance.records.length} students'),
                        trailing: Text(_formatTime(attendance.date)),
                        onTap: () {
                          Navigator.pop(context);
                          _showAttendanceDetails(context, attendance);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttendanceDetails(BuildContext context, Attendance attendance) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Attendance - ${_formatDate(attendance.date)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: attendance.records.length,
              itemBuilder: (context, index) {
                final record = attendance.records[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(record.studentName[0]),
                  ),
                  title: Text(record.studentName),
                  subtitle: Text(record.studentId),
                  trailing: Chip(
                    label: Text(
                      record.status,
                      style: TextStyle(
                        color: _getStatusColor(record.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getStatusColor(record.status).withOpacity(0.1),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}