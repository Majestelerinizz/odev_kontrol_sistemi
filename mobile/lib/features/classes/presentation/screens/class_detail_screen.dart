import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../students/data/models/invite_code_model.dart';
import '../providers/class_providers.dart';

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
    final studentsAsync = ref.watch(classStudentsStreamProvider(
      (classId: widget.classId, teacherId: teacherId),
    ));
    final inviteAsync = ref.watch(activeClassInviteProvider(widget.classId));
    final classAsync = ref.watch(classStreamProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: classAsync.when(
          data: (cls) => Text(cls?.name ?? 'Sınıf Detayı'),
          loading: () => const Text('Sınıf Detayı'),
          error: (_, __) => const Text('Sınıf Detayı'),
        ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: inviteAsync.when(
              data: (invite) => _ClassInviteBanner(
                invite: invite,
                isGenerating: ref.watch(classNotifierProvider).isLoading,
                onGenerate: () => _generateInvite(teacherId),
                onRegenerate: () =>
                    _generateInvite(teacherId, regenerate: true),
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => _ClassInviteBanner(
                invite: null,
                isGenerating: false,
                onGenerate: () => _generateInvite(teacherId),
                onRegenerate: () =>
                    _generateInvite(teacherId, regenerate: true),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppTextField(
              controller: _searchController,
              hint: 'Öğrenci adı veya okul numarası ara...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
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

  Future<void> _generateInvite(String teacherId,
      {bool regenerate = false}) async {
    final code =
        await ref.read(classNotifierProvider.notifier).generateClassInviteCode(
              classId: widget.classId,
              teacherId: teacherId,
            );
    ref.invalidate(activeClassInviteProvider(widget.classId));
    if (!mounted) return;
    if (code != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            regenerate
                ? 'Sınıf kodu yenilendi: ${code.code}'
                : 'Sınıf davet kodu oluşturuldu: ${code.code}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Davet kodu oluşturulamadı.')),
      );
    }
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
                    ref.invalidate(activeClassInviteProvider(widget.classId));
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
              ref.invalidate(activeClassInviteProvider(widget.classId));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _ClassInviteBanner extends StatelessWidget {
  const _ClassInviteBanner({
    required this.invite,
    required this.isGenerating,
    required this.onGenerate,
    required this.onRegenerate,
  });

  final InviteCodeModel? invite;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (invite == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sınıf Davet Kodu', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              'Tek bir kod oluşturun; tüm veliler aynı kodla kayıt olup çocuğunu seçsin.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Sınıf Davet Kodu Oluştur',
              icon: Icons.qr_code_rounded,
              isLoading: isGenerating,
              onPressed: onGenerate,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teacherPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: AppColors.teacherPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Sınıf Davet Kodu', style: AppTextStyles.labelMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Paylaşılabilir',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SelectableText(
                invite!.code,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.teacherPrimary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: AppColors.teacherPrimary),
                tooltip: 'Kodu Kopyala',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invite!.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sınıf kodu (${invite!.code}) panoya kopyalandı',
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.teacherPrimary),
                tooltip: 'Kodu Yenile',
                onPressed: isGenerating ? null : onRegenerate,
              ),
            ],
          ),
          Text(
            'Bu kodu sınıf grubuna bir kez paylaşmanız yeterli. '
            'Veliler kayıtta çocuğunu listeden seçer.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
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
                                : 'Veli Bekliyor (Sınıf Kodu ile)',
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
