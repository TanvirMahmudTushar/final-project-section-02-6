import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/course_card.dart';
import '../models/course.dart';
import 'course_content_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    if (authProvider.user != null) {
      courseProvider.loadCourses(authProvider.user!.uid);
    }
  }

  void _showAddCourseDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Course',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  hintText: 'e.g., Data Structures',
                  labelText: 'Course Name',
                  prefixIcon: Icons.book,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: codeController,
                  hintText: 'e.g., CS201',
                  labelText: 'Course Code',
                  prefixIcon: Icons.code,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: descriptionController,
                  hintText: 'Optional description',
                  labelText: 'Description (Optional)',
                  maxLines: 3,
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
            Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                return CustomButton(
                  text: 'Add',
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        codeController.text.isNotEmpty) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      final success = await courseProvider.addCourse(
                        authProvider.user!.uid,
                        nameController.text,
                        codeController.text,
                        description: descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : null,
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Course added successfully'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      } else if (context.mounted &&
                          courseProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(courseProvider.errorMessage!),
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
                  isLoading: courseProvider.isLoading,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditCourseDialog(Course course) {
    final nameController = TextEditingController(text: course.name);
    final codeController = TextEditingController(text: course.code);
    final descriptionController = TextEditingController(
      text: course.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Course',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  hintText: 'e.g., Data Structures',
                  labelText: 'Course Name',
                  prefixIcon: Icons.book,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: codeController,
                  hintText: 'e.g., CS201',
                  labelText: 'Course Code',
                  prefixIcon: Icons.code,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: descriptionController,
                  hintText: 'Optional description',
                  labelText: 'Description (Optional)',
                  maxLines: 3,
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
            Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                return CustomButton(
                  text: 'Save',
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        codeController.text.isNotEmpty) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      final updatedCourse = course.copyWith(
                        name: nameController.text,
                        code: codeController.text,
                        description: descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : null,
                      );

                      final success = await courseProvider.updateCourse(
                        authProvider.user!.uid,
                        updatedCourse,
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Course updated successfully'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      } else if (context.mounted &&
                          courseProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(courseProvider.errorMessage!),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                    }
                  },
                  isLoading: courseProvider.isLoading,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String courseId, String courseName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Course',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete "$courseName"? This will also remove all enrolled students.',
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
            Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                return TextButton(
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    final success = await courseProvider.deleteCourse(
                      authProvider.user!.uid,
                      courseId,
                    );

                    if (success) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Course deleted successfully'),
                            backgroundColor: AppColors.accentGreen,
                          ),
                        );
                      }
                    } else if (context.mounted &&
                        courseProvider.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(courseProvider.errorMessage!),
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
                'Course Management',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage all your courses',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Add course button
              CustomButton(
                text: '+ Add Course',
                onPressed: _showAddCourseDialog,
              ),
              const SizedBox(height: 24),

              // Courses list
              Expanded(
                child: Consumer<CourseProvider>(
                  builder: (context, courseProvider, _) {
                    if (courseProvider.courses.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No courses yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first course to get started',
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
                      itemCount: courseProvider.courses.length,
                      itemBuilder: (context, index) {
                        final course = courseProvider.courses[index];
                        return CourseCard(
                          courseName: course.name,
                          courseCode: course.code,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CourseContentScreen(course: course),
                              ),
                            );
                          },
                          onEdit: () => _showEditCourseDialog(course),
                          onDelete: () =>
                              _showDeleteConfirmation(course.id, course.name),
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
