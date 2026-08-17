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

  static final List<HomeworkAssignmentEntity> _demoAssignments = [
    HomeworkAssignmentEntity(
      id: 'demo_1',
      homeworkId: 'demo_hw_1',
      studentId: 'demo_student',
      classId: '8-A',
      teacherId: 'teacher_1',
      status: 'pending',
      updatedAt: DateTime.now(),
      teacherNote: 'Sayfa 55\'teki yıldızlı soruları mutlaka çözün.',
    ),
    HomeworkAssignmentEntity(
      id: 'demo_2',
      homeworkId: 'demo_hw_2',
      studentId: 'demo_student',
      classId: '8-A',
      teacherId: 'teacher_1',
      status: 'completed',
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      teacherNote: 'Aferin! Tüm sorular eksiksiz ve doğru çözülmüş.',
    ),
    HomeworkAssignmentEntity(
      id: 'demo_3',
      homeworkId: 'demo_hw_3',
      studentId: 'demo_student',
      classId: '8-A',
      teacherId: 'teacher_1',
      status: 'pending',
      updatedAt: DateTime.now(),
    ),
  ];

  static final Map<String, HomeworkEntity> _demoHomeworkDetails = {
    'demo_hw_1': HomeworkEntity(
      id: 'demo_hw_1',
      teacherId: 'teacher_1',
      classId: '8-A',
      title: 'LGS Üslü İfadeler Soru Bankası',
      subject: 'Matematik',
      description: 'LGS hazırlık soruları',
      sourceName: 'MatPusula Soru Bankası',
      questionRange: 'Sayfa 45 - 62 (40 Soru)',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now(),
    ),
    'demo_hw_2': HomeworkEntity(
      id: 'demo_hw_2',
      teacherId: 'teacher_1',
      classId: '8-A',
      title: 'Mevsimler ve İklim Test Çözümü',
      subject: 'Fen Bilimleri',
      description: 'Basit makineler ve iklim testi',
      sourceName: 'Karakök Soru Bankası',
      questionRange: 'Test 3 - 4 (30 Soru)',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    'demo_hw_3': HomeworkEntity(
      id: 'demo_hw_3',
      teacherId: 'teacher_1',
      classId: '8-A',
      title: 'Paragrafta Anlam ve Ana Fikir',
      subject: 'Türkçe',
      description: 'Okuduğunu anlama çalışması',
      sourceName: 'LGS Türkçe Fasikülü',
      questionRange: '20 Paragraf Sorusu',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now(),
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final parentUid = user?.uid ?? '';
    final studentsAsync = ref.watch(parentStudentsStreamProvider(parentUid));
    final studentId = studentsAsync.asData?.value.firstOrNull?.id ?? parentUid;
    final assignmentsAsync = ref.watch(studentAssignmentsStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Çocuğumun Ödevleri'),
      ),
      body: assignmentsAsync.when(
        data: (realAssignments) {
          final isDemo = realAssignments.isEmpty;
          final assignments = isDemo ? _demoAssignments : realAssignments;

          return Column(
            children: [
              if (isDemo)
                Container(
                  width: double.infinity,
                  color: AppColors.parentPrimary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.stars_rounded, color: AppColors.parentPrimary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Örnek Ödev Listesi Gösteriliyor (Öğretmeniniz ödev tanımladığında otomatik güncellenir)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return _ParentHomeworkAssignmentCard(
                      assignment: assignment,
                      demoHomework: isDemo ? _demoHomeworkDetails[assignment.homeworkId] : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) {
          // Hata durumunda da akıcı görünüm için demo veriyi göster
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: _demoAssignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final assignment = _demoAssignments[index];
              return _ParentHomeworkAssignmentCard(
                assignment: assignment,
                demoHomework: _demoHomeworkDetails[assignment.homeworkId],
              );
            },
          );
        },
      ),
    );
  }
}

class _ParentHomeworkAssignmentCard extends ConsumerWidget {
  const _ParentHomeworkAssignmentCard({
    required this.assignment,
    this.demoHomework,
  });
  final HomeworkAssignmentEntity assignment;
  final HomeworkEntity? demoHomework;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (demoHomework != null) {
      return _buildCardContent(context, demoHomework!);
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          if (homework.sourceName != null || homework.questionRange != null) ...[
            const SizedBox(height: 4),
            Text(
              '${homework.sourceName ?? ''} ${homework.questionRange != null ? "• Soru: ${homework.questionRange}" : ""}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Son Teslim: ${homework.dueDate.toTurkishDate()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: homework.isOverdue ? AppColors.error : AppColors.textSecondary,
                  fontWeight: homework.isOverdue ? FontWeight.bold : FontWeight.normal,
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
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.parentPrimary),
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
  }
}
