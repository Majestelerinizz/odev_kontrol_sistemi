import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../classes/presentation/providers/class_providers.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../providers/exam_providers.dart';
import '../../domain/entities/exam_result_entity.dart';

class TeacherExamListScreen extends ConsumerStatefulWidget {
  const TeacherExamListScreen({super.key});

  @override
  ConsumerState<TeacherExamListScreen> createState() =>
      _TeacherExamListScreenState();
}

class _TeacherExamListScreenState extends ConsumerState<TeacherExamListScreen> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesStreamProvider);
    final user = ref.watch(currentUserProvider);
    final teacherId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deneme Sınavı Sonuçları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_enhance_rounded),
            tooltip: 'AI Kamera ile Fotoğraf Tara',
            onPressed: () => context.push('/teacher/exams/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Sonuç Gir',
            onPressed: () => context.push('/teacher/exams/create'),
          ),
        ],
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return EmptyState(
              title: 'Henüz Sınıfınız Yok',
              subtitle: 'Sınav sonucu girebilmek için önce bir sınıf oluşturun.',
              icon: Icons.bar_chart_rounded,
              action: () => context.go('/teacher/classes'),
              actionLabel: 'Sınıflarıma Git',
            );
          }

          _selectedClassId ??= classes.first.id;
          final examsAsync = ref.watch(classExamsStreamProvider(
            (classId: _selectedClassId!, teacherId: teacherId),
          ));

          return Column(
            children: [
              // ── Sınıf Seçim Çubuğu ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Sınıf Filtresi',
                    prefixIcon: const Icon(Icons.group_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                  items: classes
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} (${c.studentCount} Öğrenci)'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedClassId = val);
                  },
                ),
              ),

              // ── Deneme Sonuçları Listesi ────────────────────────────────────
              Expanded(
                child: examsAsync.when(
                  data: (exams) {
                    if (exams.isEmpty) {
                      return EmptyState(
                        title: 'Bu Sınıfta Sınav Kaydı Yok',
                        subtitle:
                            'Seçili sınıf için henüz deneme sonucu girilmedi.',
                        icon: Icons.assignment_late_rounded,
                        action: () => context.push('/teacher/exams/new'),
                        actionLabel: 'Deneme Sonucu Gir',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.pagePadding),
                      itemCount: exams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final exam = exams[index];
                        return _TeacherExamCard(
                          exam: exam,
                          onAnalyticsTap: () => context.push(
                              '/teacher/analytics/${exam.studentId}'),
                          onDelete: () => _confirmDeleteExam(context, exam),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, __) => Center(
                      child: Text('Sınavlar yüklenemedi: $err',
                          style: const TextStyle(color: AppColors.error))),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Sınıflar yüklenemedi: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/exams/new'),
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
        label: const Text('Deneme Sonucu Gir',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _confirmDeleteExam(BuildContext context, ExamResultEntity exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${exam.examName} Kaydı Silinsin mi?'),
        content: const Text('Bu sınav sonucunu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(examNotifierProvider.notifier)
                  .deleteExam(exam.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _TeacherExamCard extends ConsumerWidget {
  const _TeacherExamCard({
    required this.exam,
    required this.onAnalyticsTap,
    required this.onDelete,
  });

  final ExamResultEntity exam;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentStreamProvider(exam.studentId));
    final studentName = studentAsync.valueOrNull?.name ?? 'Yükleniyor...';

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
              Text(studentName, style: AppTextStyles.h4),
              Text(
                exam.examDate.toTurkishDate(),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(exam.examName, style: AppTextStyles.bodyMedium),
              if (exam.publisher != null) ...[
                const SizedBox(width: 6),
                Text('(${exam.publisher})',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Net & Puan Özet Rozetleri
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teacherPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Toplam Net', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        exam.totalNet.toStringAsFixed(2),
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.teacherPrimary),
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
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onAnalyticsTap,
                icon: const Icon(Icons.show_chart_rounded, size: 18),
                label: const Text('Gelişim Grafiğini Gör'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
