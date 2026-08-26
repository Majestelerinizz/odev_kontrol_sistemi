import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Çocuğumun Ödevleri'),
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorBody(message: err.toString()),
        data: (students) {
          if (students.isEmpty) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'Bağlı öğrenci yok',
              subtitle:
                  'Davet koduyla kayıt olduktan sonra ödevler burada görünür.',
            );
          }
          final studentId = students.first.id;
          final assignmentsAsync =
              ref.watch(studentAssignmentsStreamProvider(studentId));

          return assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorBody(message: err.toString()),
            data: (assignments) {
              if (assignments.isEmpty) {
                return const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Henüz ödev yok',
                  subtitle:
                      'Öğretmen ödev tanımladığında burada listelenir.',
                );
              }
              final ids =
                  assignments.map((a) => a.homeworkId).toList(growable: false);
              final homeworksAsync = ref.watch(homeworksByIdsProvider(ids));

              return homeworksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorBody(message: err.toString()),
                data: (homeworks) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.pagePadding),
                    itemCount: assignments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      return _ParentHomeworkAssignmentCard(
                        assignment: assignment,
                        homework: homeworks[assignment.homeworkId],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ödevler yüklenemedi.\n$message',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

class _ParentHomeworkAssignmentCard extends StatelessWidget {
  const _ParentHomeworkAssignmentCard({
    required this.assignment,
    this.homework,
  });

  final HomeworkAssignmentEntity assignment;
  final HomeworkEntity? homework;

  @override
  Widget build(BuildContext context) {
    if (homework == null) {
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
            Text('Ödev #${assignment.homeworkId}', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            StatusBadge(status: assignment.status),
          ],
        ),
      );
    }

    final hw = homework!;
    final displayStatus = HomeworkStatusCalculator.calculateDisplayStatus(
      assignment.status,
      hw.dueDate,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.parentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hw.subject,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.parentPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadge(status: displayStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(hw.title, style: AppTextStyles.h4),
          if (hw.sourceName != null || hw.questionRange != null) ...[
            const SizedBox(height: 4),
            Text(
              '${hw.sourceName ?? ''} ${hw.questionRange != null ? "• Soru: ${hw.questionRange}" : ""}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Son Teslim: ${hw.dueDate.toTurkishDate()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color:
                      hw.isOverdue ? AppColors.error : AppColors.textSecondary,
                  fontWeight:
                      hw.isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (assignment.teacherNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'Öğretmen Notu: ${assignment.teacherNote}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
