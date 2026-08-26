import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../../students/domain/entities/student_entity.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final teacherId = user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final studentsAsync =
        ref.watch(classStudentsStreamProvider(
          (classId: widget.classId, teacherId: teacherId),
        ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sınıf Detayı & Öğrenciler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Öğrenci Ekle',
            onPressed: () => _showAddStudentDialog(context, teacherId),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Arama Çubuğu ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppTextField(
              controller: _searchController,
              hint: 'Öğrenci adı veya okul numarası ara...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // ── Öğrenci Listesi ───────────────────────────────────────────────
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                final filtered = students.where((s) {
                  final query = _searchQuery.toLowerCase();
                  return s.name.toLowerCase().contains(query) ||
                      (s.schoolNumber?.contains(query) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: _searchQuery.isEmpty
                        ? 'Henüz Öğrenci Yok'
                        : 'Öğrenci Bulunamadı',
                    subtitle: _searchQuery.isEmpty
                        ? 'Bu sınıfa ilk öğrenciyi eklemek için aşağıdaki butona tıklayın.'
                        : 'Arama kriterlerinize uyan öğrenci bulunamadı.',
                    icon: Icons.person_off_rounded,
                    action: () =>
                        _showAddStudentDialog(context, user?.uid ?? ''),
                    actionLabel: 'Öğrenci Ekle',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return _StudentCard(
                      student: student,
                      onTap: () =>
                          context.push('/teacher/students/${student.id}'),
                      onDelete: () => _confirmDeleteStudent(context, student),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Öğrenci bilgisi yüklenemedi. Lütfen tekrar giriş yapın.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context, user?.uid ?? ''),
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.person_add_rounded,
            color: AppColors.textOnPrimary),
        label: Text('Öğrenci Ekle', style: AppTextStyles.buttonMedium),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, String teacherId) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        title: const Text('Yeni Öğrenci Ekle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Öğrenci Ad Soyad',
                  hint: 'Örn: Ahmet Yılmaz',
                  prefixIcon: Icons.person_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Öğrenci adı zorunludur.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: numberController,
                  label: 'Okul Numarası (İsteğe Bağlı)',
                  hint: 'Örn: 104',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.badge_rounded,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: noteController,
                  label: 'Öğretmen Notu (İsteğe Bağlı)',
                  hint: 'Örn: Problemler konusunu tekrar etmeli.',
                  prefixIcon: Icons.note_alt_rounded,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          PrimaryButton(
            label: 'Kaydet',
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await ref
                    .read(studentNotifierProvider.notifier)
                    .addStudent(
                      classId: widget.classId,
                      teacherId: teacherId,
                      name: nameController.text.trim(),
                      schoolNumber: numberController.text.trim().isEmpty
                          ? null
                          : numberController.text.trim(),
                      teacherNote: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Öğrenci başarıyla eklendi!')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStudent(BuildContext context, StudentEntity student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${student.name} Silinsin mi?'),
        content: const Text(
          'Bu öğrenciyi ve ilgili verileri silmek istediğinize emin misiniz?',
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
                  .read(studentNotifierProvider.notifier)
                  .deleteStudent(student.id, widget.classId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.onDelete,
  });

  final StudentEntity student;
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppColors.teacherPrimary.withValues(alpha: 0.1),
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: AppTextStyles.h3
                      .copyWith(color: AppColors.teacherPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.name,
                            style: AppTextStyles.h4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (student.schoolNumber != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '#${student.schoolNumber}',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          student.hasParent
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: student.hasParent
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            student.hasParent
                                ? 'Veli Bağlı'
                                : 'Veli Bekliyor (Davet Kodu Gerekli)',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: student.hasParent
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.textSecondary),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
