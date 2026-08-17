import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/exam_providers.dart';
import '../../domain/entities/exam_result_entity.dart';

import '../../../students/presentation/providers/student_providers.dart';

class ParentExamListScreen extends ConsumerWidget {
  const ParentExamListScreen({super.key});

  static final List<ExamResultEntity> _demoExams = [
    ExamResultEntity(
      id: 'demo_e1',
      studentId: 'demo_student',
      classId: '8-A',
      teacherId: 'teacher_1',
      examName: 'LGS Kurumsal Deneme #3',
      examDate: DateTime.now().subtract(const Duration(days: 3)),
      publisher: 'MatPusula Akademi',
      scores: const {
        'Matematik': SubjectScore(correct: 18, wrong: 2, blank: 0),
        'Fen Bilimleri': SubjectScore(correct: 19, wrong: 1, blank: 0),
        'Türkçe': SubjectScore(correct: 19, wrong: 1, blank: 0),
      },
      totalNet: 85.50,
      totalScore: 442.5,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ExamResultEntity(
      id: 'demo_e2',
      studentId: 'demo_student',
      classId: '8-A',
      teacherId: 'teacher_1',
      examName: 'Matematik Özel Branş Denemesi #2',
      examDate: DateTime.now().subtract(const Duration(days: 10)),
      publisher: 'Pusula Yayınları',
      scores: const {
        'Matematik': SubjectScore(correct: 17, wrong: 3, blank: 0),
        'Fen Bilimleri': SubjectScore(correct: 18, wrong: 2, blank: 0),
        'Türkçe': SubjectScore(correct: 18, wrong: 2, blank: 0),
      },
      totalNet: 78.00,
      totalScore: 415.0,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ExamResultEntity(
      id: 'demo_e3',
      studentId: 'demo_student',
      classId: '8-A',
      teacherId: 'teacher_1',
      examName: 'Seviye Tespit Sınavı #1',
      examDate: DateTime.now().subtract(const Duration(days: 20)),
      publisher: 'Okul Geneli',
      scores: const {
        'Matematik': SubjectScore(correct: 15, wrong: 4, blank: 1),
        'Fen Bilimleri': SubjectScore(correct: 16, wrong: 3, blank: 1),
        'Türkçe': SubjectScore(correct: 17, wrong: 3, blank: 0),
      },
      totalNet: 71.50,
      totalScore: 388.0,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final parentUid = user?.uid ?? '';
    final studentsAsync = ref.watch(parentStudentsStreamProvider(parentUid));
    final studentId = studentsAsync.asData?.value.firstOrNull?.id ?? parentUid;
    final examsAsync = ref.watch(studentExamsStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Çocuğumun Deneme Sonuçları'),
      ),
      body: examsAsync.when(
        data: (realExams) {
          final isDemo = realExams.isEmpty;
          final exams = isDemo ? _demoExams : realExams;
          final chronologicalExams = exams.reversed.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDemo) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: AppColors.parentPrimary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.parentPrimary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Örnek Deneme Sonuçları Gösteriliyor (Öğretmeniniz sınav girdiğinde otomatik güncellenir)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Grafik ──────────────────────────────────────────────────
                Text('Net Gelişim Grafiği 📈', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < chronologicalExams.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    chronologicalExams[idx].examName.split(' ').last,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.border),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chronologicalExams
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value.totalNet,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: AppColors.parentPrimary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.parentPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text('Geçmiş Sınavlar 📝', style: AppTextStyles.h3),
                const SizedBox(height: 12),

                // ── Sınav Kartları ──────────────────────────────────────────
                ...exams.map((exam) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                            Text(exam.examName, style: AppTextStyles.h4),
                            Text(
                              exam.examDate.toTurkishDate(),
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (exam.publisher != null) ...[
                          const SizedBox(height: 2),
                          Text('Yayınevi: ${exam.publisher}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.parentPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Toplam Net', style: AppTextStyles.labelSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      exam.totalNet.toStringAsFixed(2),
                                      style: AppTextStyles.h3.copyWith(color: AppColors.parentPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Puan', style: AppTextStyles.labelSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      exam.totalScore.toStringAsFixed(1),
                                      style: AppTextStyles.h3.copyWith(color: AppColors.accent),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => _buildDemoList(),
      ),
    );
  }

  Widget _buildDemoList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._demoExams.map((exam) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      Text(exam.examName, style: AppTextStyles.h4),
                      Text(exam.examDate.toTurkishDate(), style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Net: ${exam.totalNet}', style: AppTextStyles.h3.copyWith(color: AppColors.parentPrimary)),
                      ),
                      Expanded(
                        child: Text('Puan: ${exam.totalScore}', style: AppTextStyles.h3.copyWith(color: AppColors.accent)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
