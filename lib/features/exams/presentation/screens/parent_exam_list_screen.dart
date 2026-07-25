import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/exam_providers.dart';

class ParentExamListScreen extends ConsumerWidget {
  const ParentExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final studentId = user?.uid ?? '';
    final examsAsync = ref.watch(studentExamsStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Çocuğumun Deneme Sonuçları'),
      ),
      body: examsAsync.when(
        data: (exams) {
          if (exams.isEmpty) {
            return const EmptyState(
              title: 'Henüz Sınav Kaydı Yok',
              subtitle:
                  'Öğretmen deneme sınavı sonuçlarını girdiğinde burada görüntülenecektir.',
              icon: Icons.bar_chart_rounded,
            );
          }

          final chronologicalExams = exams.reversed.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Grafik ──────────────────────────────────────────────────
                Text('Net Gelişim Grafiği', style: AppTextStyles.h3),
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
                                    chronologicalExams[idx].examName,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
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
                            color:
                                AppColors.parentPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text('Geçmiş Sınavlar', style: AppTextStyles.h3),
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
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (exam.publisher != null) ...[
                          const SizedBox(height: 2),
                          Text('Yayınevi: ${exam.publisher}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.parentPrimary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Toplam Net',
                                        style: AppTextStyles.labelSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      exam.totalNet.toStringAsFixed(2),
                                      style: AppTextStyles.h3.copyWith(
                                          color: AppColors.parentPrimary),
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
                                  color:
                                      AppColors.accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Puan',
                                        style: AppTextStyles.labelSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      exam.totalScore.toStringAsFixed(1),
                                      style: AppTextStyles.h3
                                          .copyWith(color: AppColors.accent),
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
        error: (err, __) => Center(
          child: Text('Sınavlar yüklenemedi: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}
