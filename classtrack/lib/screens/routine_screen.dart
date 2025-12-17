import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/course_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/routine_card.dart';
import '../models/routine.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _selectedDay = 'Monday';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final routineProvider = Provider.of<RoutineProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      routineProvider.loadRoutines(authProvider.user!.uid);
    }
  }

  void _showAddRoutineDialog() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    if (courseProvider.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add courses first'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    String? selectedCourseId = courseProvider.courses.first.id;
    String selectedDay = _selectedDay;
    final startTimeController = TextEditingController(text: '09:00');
    final endTimeController = TextEditingController(text: '10:30');
    final roomController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Add Routine',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedCourseId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: courseProvider.courses.map((course) {
                          return DropdownMenuItem(
                            value: course.id,
                            child: Text('${course.name} (${course.code})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCourseId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Day',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedDay,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: _days.map((day) {
                          return DropdownMenuItem(value: day, child: Text(day));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDay = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: startTimeController,
                            hintText: '09:00',
                            labelText: 'Start Time',
                            prefixIcon: Icons.access_time,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: endTimeController,
                            hintText: '10:30',
                            labelText: 'End Time',
                            prefixIcon: Icons.access_time_filled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: roomController,
                      hintText: 'e.g., Room 101',
                      labelText: 'Room (Optional)',
                      prefixIcon: Icons.room,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Consumer<RoutineProvider>(
                  builder: (context, routineProvider, _) {
                    return CustomButton(
                      text: 'Add',
                      onPressed: () async {
                        if (selectedCourseId != null &&
                            startTimeController.text.isNotEmpty &&
                            endTimeController.text.isNotEmpty) {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          if (routineProvider.hasConflict(
                            selectedDay,
                            startTimeController.text,
                            endTimeController.text,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Time conflict with existing routine!',
                                ),
                                backgroundColor: AppColors.accentRed,
                              ),
                            );
                            return;
                          }

                          final selectedCourse = courseProvider.courses
                              .firstWhere((c) => c.id == selectedCourseId);

                          final success = await routineProvider.addRoutine(
                            authProvider.user!.uid,
                            selectedCourseId!,
                            selectedCourse.name,
                            selectedCourse.code,
                            selectedDay,
                            startTimeController.text,
                            endTimeController.text,
                            room: roomController.text.isNotEmpty
                                ? roomController.text
                                : null,
                          );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Routine added successfully'),
                                backgroundColor: AppColors.accentGreen,
                              ),
                            );
                          } else if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add routine: ${routineProvider.errorMessage ?? "Unknown error"}',
                                ),
                                backgroundColor: AppColors.accentRed,
                              ),
                            );
                          }
                        }
                      },
                      isLoading: routineProvider.isLoading,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditRoutineDialog(Routine routine) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    String? selectedCourseId = routine.courseId;
    String selectedDay = routine.day;
    final startTimeController = TextEditingController(text: routine.startTime);
    final endTimeController = TextEditingController(text: routine.endTime);
    final roomController = TextEditingController(text: routine.room ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Routine',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedCourseId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: courseProvider.courses.map((course) {
                          return DropdownMenuItem(
                            value: course.id,
                            child: Text('${course.name} (${course.code})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCourseId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Day',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedDay,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: _days.map((day) {
                          return DropdownMenuItem(value: day, child: Text(day));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDay = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: startTimeController,
                            hintText: '09:00',
                            labelText: 'Start Time',
                            prefixIcon: Icons.access_time,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: endTimeController,
                            hintText: '10:30',
                            labelText: 'End Time',
                            prefixIcon: Icons.access_time_filled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: roomController,
                      hintText: 'e.g., Room 101',
                      labelText: 'Room (Optional)',
                      prefixIcon: Icons.room,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Consumer<RoutineProvider>(
                  builder: (context, routineProvider, _) {
                    return CustomButton(
                      text: 'Update',
                      onPressed: () async {
                        if (selectedCourseId != null &&
                            startTimeController.text.isNotEmpty &&
                            endTimeController.text.isNotEmpty) {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          if (routineProvider.hasConflict(
                            selectedDay,
                            startTimeController.text,
                            endTimeController.text,
                            excludeRoutineId: routine.id,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Time conflict with existing routine!',
                                ),
                                backgroundColor: AppColors.accentRed,
                              ),
                            );
                            return;
                          }

                          final selectedCourse = courseProvider.courses
                              .firstWhere((c) => c.id == selectedCourseId);

                          final updatedRoutine = routine.copyWith(
                            courseId: selectedCourseId,
                            courseName: selectedCourse.name,
                            courseCode: selectedCourse.code,
                            day: selectedDay,
                            startTime: startTimeController.text,
                            endTime: endTimeController.text,
                            room: roomController.text.isNotEmpty
                                ? roomController.text
                                : null,
                          );

                          final success = await routineProvider.updateRoutine(
                            authProvider.user!.uid,
                            updatedRoutine,
                          );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Routine updated successfully'),
                                backgroundColor: AppColors.accentGreen,
                              ),
                            );
                          }
                        }
                      },
                      isLoading: routineProvider.isLoading,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Routine',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this routine?\n${routine.courseName} on ${routine.day}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final routineProvider = Provider.of<RoutineProvider>(
        context,
        listen: false,
      );

      final success = await routineProvider.deleteRoutine(
        authProvider.user!.uid,
        routine.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Routine deleted successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _days.map((day) {
                  final isSelected = day == _selectedDay;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(day.substring(0, 3)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.inputBackground,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Consumer<RoutineProvider>(
              builder: (context, routineProvider, _) {
                final routines = routineProvider.getRoutinesByDay(_selectedDay);

                if (routineProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  );
                }

                if (routines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No routines for $_selectedDay',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add a new routine',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return RoutineCard(
                      routine: routine,
                      onEdit: () => _showEditRoutineDialog(routine),
                      onDelete: () => _deleteRoutine(routine),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoutineDialog,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
