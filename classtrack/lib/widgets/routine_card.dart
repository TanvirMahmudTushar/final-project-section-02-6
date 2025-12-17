import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/routine.dart';

class RoutineCard extends Widget {
  final Routine routine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onEdit,
    this.onDelete,
  });

  @override
  Element createElement() => _RoutineCardElement(this);
}

class _RoutineCardElement extends ComponentElement {
  _RoutineCardElement(RoutineCard super.widget);

  @override
  RoutineCard get widget => super.widget as RoutineCard;

  @override
  Widget build() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.routine.courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.routine.courseCode,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.routine.startTime} - ${widget.routine.endTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (widget.routine.room != null) ...[
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.room,
                            size: 16,
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.routine.room!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.accentRed,
                  ),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

