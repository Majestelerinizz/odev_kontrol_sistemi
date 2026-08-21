import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/homework_providers.dart';
import '../../domain/entities/homework_entity.dart';
import '../../domain/entities/homework_assignment_entity.dart';
import '../../../students/presentation/providers/student_providers.dart';

class ParentHomeworkListScreen extends ConsumerWidget {
  const ParentHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final parentUid = user?.uid ?? '';
    final studentsAsync = ref.watch(parentStudentsStreamProvider(parentUid));
    final activeStudent = studentsAsync.valueOrNull?.firstOrNull;
    final studentId = activeStudent?.id ?? parentUid;
    final assignmentsAsync = ref.watch(studentAssignmentsStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Çocuğumun Ödevleri'),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.parentPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, size: 40, color: AppColors.parentPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text('Henüz Ödev Bulunmuyor', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text(
                      'Öğretmeniniz ödev tanımladığında teslim tarihi ve ödev detayları burada listelenecektir.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _ParentHomeworkAssignmentCard(
                assignment: assignment,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ödevler yüklenirken bir hata oluştu: $e')),
      ),
    );
  }
}

class _ParentHomeworkAssignmentCard extends ConsumerWidget {
  const _ParentHomeworkAssignmentCard({
    required this.assignment,
  });
  final HomeworkAssignmentEntity assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(homeworkDetailProvider(assignment.homeworkId));

    return homeworkAsync.when(
      data: (homework) {
        if (homework == null) return const SizedBox.shrink();
        return _buildCardContent(context, homework);
      },
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCardContent(BuildContext context, HomeworkEntity homework) {
    final displayStatus = HomeworkStatusCalculator.calculateDisplayStatus(
      assignment.status,
      homework.dueDate,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.parentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  homework.subject,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.parentPrimary,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(displayStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            homework.title,
            style: AppTextStyles.h4,
          ),
          if (homework.description != null && homework.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              homework.description!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Teslim: ${homework.dueDate.toTurkishDate()}',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (homework.questionRange != null && homework.questionRange!.isNotEmpty) ...[
                const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  homework.questionRange!,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (assignment.teacherNote != null && assignment.teacherNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 16, color: AppColors.teacherPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Öğretmen Notu:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teacherPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          assignment.teacherNote!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label = HomeworkStatusCalculator.statusLabel(status);

    switch (status) {
      case 'completed':
        bg = AppColors.successLight;
        text = AppColors.success;
        break;
      case 'overdue':
      case 'missed':
        bg = AppColors.errorLight;
        text = AppColors.error;
        break;
      case 'pending':
      default:
        bg = AppColors.parentPrimary.withValues(alpha: 0.1);
        text = AppColors.parentPrimary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
