import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../providers/student_providers.dart';
import '../../data/models/invite_code_model.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentStreamProvider(studentId));
    final activeInviteAsync = ref.watch(activeInviteCodeProvider(studentId));
    final user = ref.watch(currentUserProvider);

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profil Başlık Kartı ──────────────────────────────────────
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

                // ── Veli Durumu ve Davet Kodu ────────────────────────────────
                Text('Veli Durumu & Eşleşme Kodu', style: AppTextStyles.h4),
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
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Aktif davet kodu kartı
                      activeInviteAsync.when(
                        data: (inviteCode) {
                          if (inviteCode != null && inviteCode.isValid) {
                            return _InviteCodeDisplay(inviteCode: inviteCode);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Veli kayıt olurken kullanılan 6 haneli davet kodunu buradan üretebilirsiniz.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              PrimaryButton(
                                label: 'Veli Davet Kodu Üret',
                                icon: Icons.qr_code_rounded,
                                onPressed: () async {
                                  final code = await ref
                                      .read(studentNotifierProvider.notifier)
                                      .generateInviteCode(
                                        studentId: student.id,
                                        teacherId: user?.uid ?? '',
                                      );
                                  if (context.mounted && code != null) {
                                    ref.invalidate(
                                        activeInviteCodeProvider(student.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Davet Kodu Üretildi: ${code.code}')),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) =>
                            const Text('Davet kodu durumu okunamadı.'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Öğretmen Notu & Bilgiler ────────────────────────────────
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
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _InviteCodeDisplay extends StatelessWidget {
  const _InviteCodeDisplay({required this.inviteCode});
  final InviteCodeModel inviteCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teacherPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.teacherPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Aktif Veli Davet Kodu:', style: AppTextStyles.labelMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SelectableText(
                inviteCode.code,
                style: AppTextStyles.h2.copyWith(
                    color: AppColors.teacherPrimary, letterSpacing: 2),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: AppColors.teacherPrimary),
                tooltip: 'Kodu Kopyala',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Davet Kodu (${inviteCode.code}) Panoya Kopyalandı!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bu kodu veliye ileterek kayıt olmasını sağlayın.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
