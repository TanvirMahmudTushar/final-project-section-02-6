import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CourseCard extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.courseName,
    required this.courseCode,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(
                        color: onTap != null
                            ? AppColors.primaryBlue
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: onTap != null
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseCode,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: AppColors.accentRed,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
