import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odev_takip/features/auth/presentation/providers/auth_providers.dart';
import 'package:odev_takip/core/theme/app_colors.dart';
import 'package:odev_takip/core/theme/app_text_styles.dart';
import 'package:odev_takip/core/theme/app_sizes.dart';
import 'package:odev_takip/core/widgets/matpusula_logo.dart';

import '../../../../core/widgets/notification_permission_dialog.dart';
import '../../../classes/presentation/providers/class_providers.dart';
import '../../../exams/presentation/providers/exam_providers.dart';
import '../../../homeworks/presentation/providers/homework_providers.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
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

    // ── Veliye bağlı öğrenci ────────────────────────────────────────────────
    final studentsAsync = ref.watch(parentStudentsStreamProvider(user?.uid ?? ''));
    final activeStudent = studentsAsync.valueOrNull?.firstOrNull;

    // ── Sınıf bilgisi ─────────────────────────────────────────────────────────
    final classAsync = ref.watch(classStreamProvider(activeStudent?.classId ?? ''));
    final className = classAsync.valueOrNull?.name ?? '';

    final studentName = activeStudent != null
        ? (className.isNotEmpty
            ? '${activeStudent.name} ($className Sınıfı)'
            : activeStudent.name)
        : 'Bağlı Öğrenci Aranıyor...';

    final schoolNo = activeStudent?.schoolNumber != null && activeStudent!.schoolNumber!.isNotEmpty
        ? 'Okul No: ${activeStudent.schoolNumber}'
        : (activeStudent != null ? 'Kayıtlı Öğrenci' : 'Bağlantı Yok');

    final greetingName = activeStudent != null
        ? '${activeStudent.name} Velisi'
        : (user?.name != null && !user!.name.startsWith('parent_') ? user.name : 'Veli');

    // ── Canlı Ödev İstatistikleri ───────────────────────────────────────────
    final assignmentsAsync = ref.watch(studentAssignmentsStreamProvider(activeStudent?.id ?? ''));
    final assignments = assignmentsAsync.valueOrNull ?? [];
    final activeHomeworkCount = assignments.where((a) => !a.isCompleted).length;
    final completedHomeworkCount = assignments.where((a) => a.isCompleted).length;

    // ── Canlı Deneme Sınavı İstatistikleri ──────────────────────────────────
    final examsAsync = ref.watch(studentExamsStreamProvider(activeStudent?.id ?? ''));
    final exams = examsAsync.valueOrNull ?? [];
    final lastExam = exams.firstOrNull;
    final lastNetStr = lastExam != null ? lastExam.totalNet.toStringAsFixed(2) : '-';

    // ── Canlı Hedef Durumu ─────────────────────────────────────────────────
    final goalAsync = ref.watch(studentGoalStreamProvider(activeStudent?.id ?? ''));
    final goal = goalAsync.valueOrNull;
    final goalPercentStr = goal != null
        ? '%${goal.progressPercentage.clamp(0, 100).toStringAsFixed(0)}'
        : (lastExam != null
            ? '%${((lastExam.totalNet / 90.0) * 100).clamp(0, 100).toStringAsFixed(0)}'
            : '-');

    // ── Öğretmen Notu ───────────────────────────────────────────────────────
    final teacherNoteText = (activeStudent?.teacherNote != null && activeStudent!.teacherNote!.trim().isNotEmpty)
        ? activeStudent.teacherNote!.trim()
        : 'Öğretmeniniz henüz özel bir değerlendirme notu girmedi.';

    // ── Duyurular / Mesajlar ───────────────────────────────────────────────
    final messagesAsync = ref.watch(parentMessagesStreamProvider);
    final messages = messagesAsync.valueOrNull ?? [];
    final latestMessage = messages.firstOrNull;

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
                      'Merhaba, $greetingName 👋',
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
                // ── Çocuk Bilgi Kartı ─────────────────────────────────────────
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

                // ── Bugünkü Durum Kartları (Canlı Veri) ─────────────────────
                const _ParentSectionTitle('Özet Durumu 📊'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Aktif Ödev',
                        value: '$activeHomeworkCount Ödev',
                        icon: Icons.assignment_rounded,
                        color: AppColors.parentPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Tamamlanan',
                        value: '$completedHomeworkCount Ödev',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Son Deneme Net',
                        value: lastNetStr,
                        icon: Icons.bar_chart_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ParentSummaryCard(
                        label: 'Hedef Başarısı',
                        value: goalPercentStr,
                        icon: Icons.track_changes_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                // ── Öğretmen Notu (Canlı Veri) ─────────────────────────────
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

                // ── Son Bildirim / Duyuru (Canlı Veri) ────────────────────
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
                              latestMessage?.title ?? 'Duyuru Paneli',
                              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latestMessage?.body ?? 'Henüz yeni bir duyuru veya mesaj bulunmuyor.',
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
