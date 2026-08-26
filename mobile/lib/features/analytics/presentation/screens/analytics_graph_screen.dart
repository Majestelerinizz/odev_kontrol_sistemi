import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../../exams/presentation/providers/exam_providers.dart';

class AnalyticsGraphScreen extends ConsumerWidget {
  const AnalyticsGraphScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final teacherId = user?.isTeacher == true ? user?.uid : null;
    final studentAsync = ref.watch(studentStreamProvider(studentId));
    final examsAsync = ref.watch(studentExamsStreamProvider(studentId, teacherId: teacherId));
    final goalAsync = ref.watch(studentGoalStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gelişim & Net Analizi'),
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Öğrenci bulunamadı.'));
          }

          return examsAsync.when(
            data: (exams) {
              if (exams.isEmpty) {
                return EmptyState(
                  title: 'Henüz Deneme Kaydı Yok',
                  subtitle:
                      '${student.name} için henüz girilmiş deneme sınavı bulunmuyor.',
                  icon: Icons.show_chart_rounded,
                );
              }

              // Sınavları tarihe göre eskiden yeniye doğru sırala (Grafik sol->sağ akışı için)
              final chronologicalExams = exams.reversed.toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Öğrenci Başlık Kartı ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.cardRadius),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.teacherPrimary
                                .withValues(alpha: 0.1),
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: AppTextStyles.h3
                                  .copyWith(color: AppColors.teacherPrimary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: AppTextStyles.h3),
                                Text('No: ${student.schoolNumber}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Hedef İlerleme Kartı ────────────────────────────────
                    goalAsync.when(
                      data: (goal) {
                        final target = goal?.targetValue ?? student.targetScore;
                        final latestExam = exams.first;
                        final current = latestExam.totalScore > 0
                            ? latestExam.totalScore
                            : latestExam.totalNet;
                        final remaining = (target - current).clamp(0, 500);
                        final progress = target > 0
                            ? (current / target).clamp(0.0, 1.0)
                            : 0.0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSizes.cardRadius),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Hedef Takibi', style: AppTextStyles.h4),
                                  Text(
                                    '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(0)}',
                                    style: AppTextStyles.h4
                                        .copyWith(color: AppColors.accent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white,
                                color: AppColors.accent,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                remaining > 0
                                    ? 'Hedefe Kalan: ${remaining.toStringAsFixed(1)} Puan'
                                    : '🎉 Tebrikler! Hedefe ulaşıldı!',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),
                    Text('Net İlerleme Grafiği', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    // ── fl_chart Çizgi Grafiği ────────────────────────────────
                    Container(
                      height: 240,
                      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.cardRadius),
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
                                  if (idx >= 0 &&
                                      idx < chronologicalExams.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        chronologicalExams[idx].examName,
                                        style: AppTextStyles.caption,
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
                              color: AppColors.teacherPrimary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.teacherPrimary
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('Son Sınav Ders Dağılımı', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    // ── Son Sınav Ders Bazlı Skoru ──────────────────────────────
                    ...exams.first.scores.entries.map((e) {
                      final subject = e.key;
                      final score = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.cardRadius),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(subject, style: AppTextStyles.labelLarge),
                            Text(
                              '${score.correct} D / ${score.wrong} Y → ${score.net.toStringAsFixed(2)} Net',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.teacherPrimary,
                                fontWeight: FontWeight.bold,
                              ),
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
            error: (err, __) => Center(child: Text('Sınavlar yüklenemedi: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Öğrenci okunamadı: $err')),
      ),
    );
  }
}
