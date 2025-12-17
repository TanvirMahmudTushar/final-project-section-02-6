import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String? _selectedCourseId;
  DateTimeRange? _dateRange;
  Map<String, Map<String, dynamic>> _summaryData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default date range (last 30 days)
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    _dateRange = DateTimeRange(start: startDate, end: endDate);
  }

  Future<void> _loadSummary() async {
    if (_selectedCourseId == null || _dateRange == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      if (authProvider.user != null) {
        final summary = await attendanceProvider.getAttendanceSummary(
          userId: authProvider.user!.uid,
          courseId: _selectedCourseId!,
          dateRange: _dateRange!,
        );

        setState(() {
          _summaryData = summary;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading summary: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
      ),
      body: Column(
        children: [
          // Course selection and date range
          _buildFilters(context),
          
          // Summary content
          Expanded(
            child: _selectedCourseId == null
                ? const Center(
                    child: Text('Please select a course'),
                  )
                : _buildSummaryContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Course dropdown
            DropdownButtonFormField<String>(
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
                  _summaryData = {};
                });
                if (value != null) {
                  _loadSummary();
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date range picker
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                const Text('Date Range:'),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text(
                      _dateRange == null
                          ? 'Select Date Range'
                          : '${_dateRange!.start.toString().split(' ')[0]} to ${_dateRange!.end.toString().split(' ')[0]}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Refresh button
            if (_selectedCourseId != null && !_isLoading)
              ElevatedButton.icon(
                onPressed: _loadSummary,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Summary'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_summaryData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No attendance data found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Take attendance for this course first',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Convert to list for sorting
    final summaryList = _summaryData.entries.toList();
    
    // Sort by attendance percentage (highest first)
    summaryList.sort((a, b) {
      final percentageA = a.value['attendancePercentage'] ?? 0;
      final percentageB = b.value['attendancePercentage'] ?? 0;
      return percentageB.compareTo(percentageA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summaryList.length,
      itemBuilder: (context, index) {
        final entry = summaryList[index];
        final studentId = entry.key;
        final data = entry.value;
        final percentage = data['attendancePercentage'] ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['studentName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPercentageColor(percentage),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox(
                      label: 'Present',
                      value: '${data['presentCount'] ?? 0}',
                      color: Colors.green,
                    ),
                    _buildStatBox(
                      label: 'Absent',
                      value: '${data['absentCount'] ?? 0}',
                      color: Colors.red,
                    ),
                    _buildStatBox(
                      label: 'Late',
                      value: '${data['lateCount'] ?? 0}',
                      color: Colors.orange,
                    ),
                    _buildStatBox(
                      label: 'Total',
                      value: '${data['totalClasses'] ?? 0}',
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
                
                // Progress bar
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  color: _getPercentageColor(percentage),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = _dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );
    
    if (pickedRange != null) {
      setState(() {
        _dateRange = pickedRange;
        _summaryData = {};
      });
      _loadSummary();
    }
  }
}