import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../providers/student_providers.dart';
import '../../../classes/presentation/providers/class_providers.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentStreamProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Öğrenci Profil Detayı'),
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Öğrenci bulunamadı.'));
          }

          final classAsync = ref.watch(classStreamProvider(student.classId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.teacherPrimary.withValues(alpha: 0.1),
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.h1
                              .copyWith(color: AppColors.teacherPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: AppTextStyles.h3),
                            const SizedBox(height: 4),
                            Text(
                              student.schoolNumber != null
                                  ? 'Okul No: #${student.schoolNumber}'
                                  : 'Okul No Belirtilmemiş',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text('Veli Durumu', style: AppTextStyles.h4),
                const SizedBox(height: 10),

                Container(
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
                        children: [
                          Icon(
                            student.hasParent
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            color: student.hasParent
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              student.hasParent
                                  ? 'Veli Hesabı Bağlı (${student.parentIds.length} Veli)'
                                  : 'Henüz Veli Hesabı Bağlanmadı',
                              style: AppTextStyles.h4.copyWith(
                                color: student.hasParent
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!student.hasParent) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Veliler, sınıf detayındaki ortak sınıf davet kodu ile kayıt olur. '
                          'Her öğrenci için ayrı kod üretmeye gerek yoktur.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        classAsync.when(
                          data: (cls) {
                            if (cls?.inviteCode == null) {
                              return Text(
                                'Sınıf davet kodu henüz oluşturulmamış. '
                                'Sınıf detayından kod üretin.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            return Text(
                              'Sınıf kodu: ${cls!.inviteCode}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.teacherPrimary,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text('Öğretmen Notları & Hedef', style: AppTextStyles.h4),
                const SizedBox(height: 10),

                Container(
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
                          Text('Hedef Puan', style: AppTextStyles.labelMedium),
                          Text('${student.targetScore.toInt()} Puan',
                              style: AppTextStyles.h4
                                  .copyWith(color: AppColors.teacherPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text('Özel Not:', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        student.teacherNote ?? 'Henüz eklenmiş özel not yok.',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: student.teacherNote != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Öğrenci bilgisi yüklenemedi: $err',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error)),
        ),
      ),
    );
  }
}
