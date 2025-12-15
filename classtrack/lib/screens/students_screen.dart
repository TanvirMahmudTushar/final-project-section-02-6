import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/student_card.dart';
import '../models/student.dart';
import '../models/course.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    if (authProvider.user != null) {
      courseProvider.loadCourses(authProvider.user!.uid);
    }
  }

  void _loadStudents() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null && _selectedCourseId != null) {
      studentProvider.loadStudentsByCourse(
        authProvider.user!.uid,
        _selectedCourseId!,
      );
    }
  }

  void _showAddStudentDialog() {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course first'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final studentIdController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Student',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  hintText: 'e.g., Alice Johnson',
                  labelText: 'Student Name',
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: studentIdController,
                  hintText: 'e.g., STU001',
                  labelText: 'Student ID',
                  prefixIcon: Icons.badge,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  hintText: 'student@example.com (optional)',
                  labelText: 'Email (Optional)',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
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
            Consumer<StudentProvider>(
              builder: (context, studentProvider, _) {
                return CustomButton(
                  text: 'Add',
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        studentIdController.text.isNotEmpty) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      final success = await studentProvider.addStudent(
                        authProvider.user!.uid,
                        nameController.text,
                        studentIdController.text,
                        email: emailController.text.isNotEmpty
                            ? emailController.text
                            : null,
                        enrolledCourses: [_selectedCourseId!],
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student added successfully'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      } else if (context.mounted &&
                          studentProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(studentProvider.errorMessage!),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: AppColors.accentRed,
                        ),
                      );
                    }
                  },
                  isLoading: studentProvider.isLoading,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditStudentDialog(Student student) {
    final nameController = TextEditingController(text: student.name);
    final studentIdController = TextEditingController(text: student.studentId);
    final emailController = TextEditingController(text: student.email ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Student',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  hintText: 'e.g., Alice Johnson',
                  labelText: 'Student Name',
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: studentIdController,
                  hintText: 'e.g., STU001',
                  labelText: 'Student ID',
                  prefixIcon: Icons.badge,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  hintText: 'student@example.com (optional)',
                  labelText: 'Email (Optional)',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
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
            Consumer<StudentProvider>(
              builder: (context, studentProvider, _) {
                return CustomButton(
                  text: 'Save',
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        studentIdController.text.isNotEmpty) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      final updatedStudent = student.copyWith(
                        name: nameController.text,
                        studentId: studentIdController.text,
                        email: emailController.text.isNotEmpty
                            ? emailController.text
                            : null,
                      );

                      final success = await studentProvider.updateStudent(
                        authProvider.user!.uid,
                        updatedStudent,
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student updated successfully'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      } else if (context.mounted &&
                          studentProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(studentProvider.errorMessage!),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                    }
                  },
                  isLoading: studentProvider.isLoading,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Student',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete "$studentName"?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Consumer<StudentProvider>(
              builder: (context, studentProvider, _) {
                return TextButton(
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    final success = await studentProvider.deleteStudent(
                      authProvider.user!.uid,
                      studentId,
                    );

                    if (success) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student deleted successfully'),
                            backgroundColor: AppColors.accentGreen,
                          ),
                        );
                      }
                    } else if (context.mounted &&
                        studentProvider.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(studentProvider.errorMessage!),
                          backgroundColor: AppColors.accentRed,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.accentRed),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Student Enrollment',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage students by course',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Course selector
              const Text(
                'Select Course',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<CourseProvider>(
                builder: (context, courseProvider, _) {
                  if (courseProvider.courses.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No courses available. Add a course first.',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCourseId,
                        hint: const Text(
                          'Select a course',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        isExpanded: true,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        items: courseProvider.courses.map((Course course) {
                          return DropdownMenuItem<String>(
                            value: course.id,
                            child: Text('${course.name} (${course.code})'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCourseId = newValue;
                          });
                          _loadStudents();
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Add student button
              if (_selectedCourseId != null)
                Consumer<CourseProvider>(
                  builder: (context, courseProvider, _) {
                    final course = courseProvider.getCourseById(
                      _selectedCourseId!,
                    );
                    return CustomButton(
                      text: '+ Add Student to ${course?.name ?? "Course"}',
                      onPressed: _showAddStudentDialog,
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Students list
              Expanded(
                child: _selectedCourseId == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Select a course to view students',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Consumer<StudentProvider>(
                        builder: (context, studentProvider, _) {
                          if (studentProvider.students.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add,
                                    size: 64,
                                    color: AppColors.textHint,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No students enrolled',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add students to this course',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: studentProvider.students.length,
                            itemBuilder: (context, index) {
                              final student = studentProvider.students[index];
                              return StudentCard(
                                studentName: student.name,
                                studentId: student.studentId,
                                onEdit: () => _showEditStudentDialog(student),
                                onDelete: () => _showDeleteConfirmation(
                                  student.id,
                                  student.name,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
