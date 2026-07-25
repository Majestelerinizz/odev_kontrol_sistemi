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
import '../../domain/entities/homework_assignment_entity.dart';

class ParentHomeworkListScreen extends ConsumerWidget {
  const ParentHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Veliye bağlı ilk öğrenciyi veya seçili öğrenciyi bul
    // Not: Gerçek veride veli profilindeki bağlı öğrenci ID'si kullanılır.
    // Şimdilik veli hesabı akışındaki bağlı ilk çocuk verisini dinliyoruz.
    final studentId = user?.uid ?? ''; 
    final assignmentsAsync = ref.watch(studentAssignmentsStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Çocuğumun Ödevleri'),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyState(
              title: 'Henüz Verilmiş Ödev Yok',
              subtitle: 'Öğretmeniniz ödev atadığında burada görüntülenecektir.',
              icon: Icons.assignment_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _ParentHomeworkAssignmentCard(assignment: assignment);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Text('Ödevler yüklenemedi: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _ParentHomeworkAssignmentCard extends ConsumerWidget {
  const _ParentHomeworkAssignmentCard({required this.assignment});
  final HomeworkAssignmentEntity assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(homeworkDetailProvider(assignment.homeworkId));

    return homeworkAsync.when(
      data: (homework) {
        if (homework == null) return const SizedBox.shrink();

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.parentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      homework.subject,
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
              Text(homework.title, style: AppTextStyles.h4),
              if (homework.sourceName != null ||
                  homework.questionRange != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${homework.sourceName ?? ''} ${homework.questionRange != null ? "• Soru: ${homework.questionRange}" : ""}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Son Teslim: ${homework.dueDate.toTurkishDate()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: homework.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: homework.isOverdue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (assignment.teacherNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.parentPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Öğretmen Notu: ${assignment.teacherNote}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
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
}
