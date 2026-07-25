import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../providers/homework_providers.dart';
import '../../domain/entities/homework_entity.dart';

class TeacherHomeworkListScreen extends ConsumerStatefulWidget {
  const TeacherHomeworkListScreen({super.key});

  @override
  ConsumerState<TeacherHomeworkListScreen> createState() =>
      _TeacherHomeworkListScreenState();
}

class _TeacherHomeworkListScreenState
    extends ConsumerState<TeacherHomeworkListScreen> {
  String _selectedSubject = 'Tümü';
  final List<String> _subjects = [
    'Tümü',
    'Matematik',
    'Türkçe',
    'Fen Bilimleri',
    'Sosyal Bilgiler',
    'İngilizce',
    'Din Kültürü',
  ];

  @override
  Widget build(BuildContext context) {
    final homeworksAsync = ref.watch(teacherHomeworksStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ödev Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Yeni Ödev Ver',
            onPressed: () => context.push('/teacher/homeworks/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Ders Seçim Filtresi ──────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final isSelected = _selectedSubject == subject;
                return ChoiceChip(
                  label: Text(subject),
                  selected: isSelected,
                  selectedColor: AppColors.teacherPrimary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSubject = subject);
                  },
                );
              },
            ),
          ),

          // ── Ödev Listesi ──────────────────────────────────────────────────
          Expanded(
            child: homeworksAsync.when(
              data: (homeworks) {
                final filtered = _selectedSubject == 'Tümü'
                    ? homeworks
                    : homeworks
                        .where((h) => h.subject == _selectedSubject)
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'Henüz Ödev Yok',
                    subtitle: _selectedSubject == 'Tümü'
                        ? 'Sınıfınıza ilk ödevi atamak için aşağıdaki butona tıklayın.'
                        : '$_selectedSubject dersi için henüz ödev bulunmuyor.',
                    icon: Icons.assignment_turned_in_rounded,
                    action: () => context.push('/teacher/homeworks/new'),
                    actionLabel: 'Yeni Ödev Oluştur',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final homework = filtered[index];
                    return _TeacherHomeworkCard(
                      homework: homework,
                      onTap: () =>
                          context.push('/teacher/homeworks/${homework.id}'),
                      onDelete: () => _confirmDeleteHomework(context, homework),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Ödevler yüklenemedi: $err',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/homeworks/new'),
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni Ödev', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _confirmDeleteHomework(BuildContext context, HomeworkEntity homework) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${homework.title} Silinsin mi?'),
        content: const Text(
          'Bu ödevi ve ilgili öğrenci teslim kayıtlarını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(homeworkNotifierProvider.notifier)
                  .deleteHomework(homework.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _TeacherHomeworkCard extends StatelessWidget {
  const _TeacherHomeworkCard({
    required this.homework,
    required this.onTap,
    required this.onDelete,
  });

  final HomeworkEntity homework;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                      color: AppColors.teacherPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      homework.subject,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.teacherPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Teslim: ${homework.dueDate.toTurkishDate()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: homework.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight:
                          homework.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(homework.title, style: AppTextStyles.h4),
              if (homework.sourceName != null || homework.questionRange != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${homework.sourceName ?? ''} ${homework.questionRange != null ? "• Soru: ${homework.questionRange}" : ""}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kontrol Et & Durum Güncelle',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.teacherPrimary,
                          fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
