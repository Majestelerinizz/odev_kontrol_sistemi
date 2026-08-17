import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odev_takip/features/auth/presentation/providers/auth_providers.dart';
import 'package:odev_takip/core/theme/app_colors.dart';
import 'package:odev_takip/core/theme/app_text_styles.dart';
import 'package:odev_takip/core/theme/app_sizes.dart';
import 'package:odev_takip/core/widgets/matpusula_logo.dart';

import '../../../../core/widgets/notification_permission_dialog.dart';
import '../../../students/presentation/providers/student_providers.dart';

/// Veli ana panel ekranı.
/// Çocuğun günlük ödev özeti, son deneme sonucu, hedef ve bildirimler.
class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionDialog.showIfFirstTime(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    final studentsAsync = ref.watch(parentStudentsStreamProvider(user?.uid ?? ''));
    final activeStudent = studentsAsync.asData?.value.firstOrNull;

    final studentName = activeStudent != null
        ? '${activeStudent.name} (${activeStudent.classId} Sınıfı)'
        : 'Mustafa Yıldız (8-B Sınıfı)';

    final schoolNo = activeStudent?.schoolNumber != null
        ? 'Okul No: ${activeStudent!.schoolNumber}'
        : 'Okul No: 354';

    final teacherNoteText = activeStudent?.teacherNote ??
        'Matematik dersinde üslü ifadeler ve çarpanlara ayırma konularında gayet başarılı.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.parentPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.parentPrimary, AppColors.parentLight],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const MatPusulaLogo(size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'MatPusula',
                          style: AppTextStyles.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Merhaba, ${user?.name.split(' ').first ?? 'Veli'} 👋',
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Çocuğunuzun güncel durumu aşağıda.',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/parent/notifications'),
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Çocuk seçimi ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parentSurface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.parentPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.face_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bağlı Öğrenci Profili', style: AppTextStyles.labelSmall),
                            const SizedBox(height: 2),
                            Text(
                              studentName,
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.parentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          schoolNo,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Bugünkü durum kartları ─────────────────────────────────
                const _ParentSectionTitle('Özet Durumu 📊'),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Bugünkü Ödev',
                        value: '2 Ödev',
                        icon: Icons.assignment_rounded,
                        color: AppColors.parentPrimary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Tamamlanan',
                        value: '1 Ödev',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Son Deneme Net',
                        value: '85.50',
                        icon: Icons.bar_chart_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Hedef Başarısı',
                        value: '%88',
                        icon: Icons.track_changes_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                // ── Öğretmen notu ─────────────────────────────────────────
                const SizedBox(height: 24),
                const _ParentSectionTitle('Son Öğretmen Notu 📝'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.teacherPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sticky_note_2_rounded, color: AppColors.teacherPrimary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Öğretmen Değerlendirmesi',
                              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              teacherNoteText,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Son bildirimler ────────────────────────────────────────
                const SizedBox(height: 24),
                const _ParentSectionTitle('Son Duyuru & Bildirimler 🔔'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: AppColors.parentPrimary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LGS Kurumsal Deneme #3 Açıklandı!',
                              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toplam 85.50 Net ile sınıfta 2. sırada.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Çıkış ──────────────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(parentAuthProvider.notifier).signOut();
                      if (context.mounted) context.go('/welcome');
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.textSecondary),
                    label: Text(
                      'Çıkış Yap',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentSectionTitle extends StatelessWidget {
  const _ParentSectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.h4);
  }
}

class _ParentSummaryCard extends StatelessWidget {
  const _ParentSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.h3.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
