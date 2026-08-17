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
import '../providers/class_providers.dart';
import '../../domain/entities/class_entity.dart';

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Yeni Sınıf Ekle',
            onPressed: () => _showAddClassDialog(context, ref, user?.uid ?? ''),
          ),
        ],
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return EmptyState(
              title: 'Henüz Sınıf Yok',
              subtitle:
                  'Öğrencilerinizi ekleyip ödev atamak için önce bir sınıf oluşturun.',
              icon: Icons.school_rounded,
              action: () =>
                  _showAddClassDialog(context, ref, user?.uid ?? ''),
              actionLabel: 'Sınıf Oluştur',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = classes[index];
              return _ClassCard(
                classEntity: item,
                onTap: () => context.push('/teacher/classes/${item.id}'),
                onDelete: () => _confirmDeleteClass(context, ref, item),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Sınıflar yüklenemedi: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context, ref, user?.uid ?? ''),
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni Sınıf', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddClassDialog(
      BuildContext context, WidgetRef ref, String teacherId) {
    final nameController = TextEditingController();
    final schoolController = TextEditingController();
    int selectedGrade = 8;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            ),
            title: const Text('Yeni Sınıf Oluştur'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: 'Sınıf Adı',
                      hint: 'Örn: 8-A, 12-SAY',
                      prefixIcon: Icons.group_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Sınıf adı zorunludur.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedGrade,
                      decoration: InputDecoration(
                        labelText: 'Sınıf Seviyesi',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.inputRadius),
                        ),
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}. Sınıf'),
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedGrade = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: schoolController,
                      label: 'Okul Adı (İsteğe Bağlı)',
                      hint: 'Örn: Atatürk Ortaokulu',
                      prefixIcon: Icons.location_city_rounded,
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
                label: 'Oluştur',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final success = await ref
                        .read(classNotifierProvider.notifier)
                        .createClass(
                          teacherId: teacherId,
                          name: nameController.text.trim(),
                          gradeLevel: selectedGrade,
                          schoolName: schoolController.text.trim().isEmpty
                              ? null
                              : schoolController.text.trim(),
                        );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sınıf başarıyla oluşturuldu!')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteClass(
      BuildContext context, WidgetRef ref, ClassEntity classEntity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${classEntity.name} Sınıfını Sil'),
        content: const Text(
          'Bu sınıfı silmek istediğinize emin misiniz? Sınıfa ait öğrenciler bu işlemden etkilenebilir.',
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
                  .read(classNotifierProvider.notifier)
                  .deleteClass(classEntity.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classEntity,
    required this.onTap,
    required this.onDelete,
  });

  final ClassEntity classEntity;
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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.teacherPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${classEntity.gradeLevel}',
                    style: AppTextStyles.h2
                        .copyWith(color: AppColors.teacherPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classEntity.name, style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      '${classEntity.studentCount} Öğrenci • ${classEntity.schoolName ?? 'Okul Tanımsız'}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_rounded),
                          title: const Text('Detay & Öğrenciler'),
                          onTap: () {
                            Navigator.pop(ctx);
                            onTap();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error),
                          title: const Text('Sınıfı Sil',
                              style: TextStyle(color: AppColors.error)),
                          onTap: () {
                            Navigator.pop(ctx);
                            onDelete();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
