import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../data/admin_providers.dart';
import '../shell/admin_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Veri yüklenemedi: $e')),
        data: (stats) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Platform özeti',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: () => ref.invalidate(dashboardStatsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Salt okunur gözetim paneli. Öğretmen işlemleri mobil uygulamada yapılır.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AdminResponsive(
              mobile: Column(
                children: _statCards(stats),
              ),
              tablet: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _statCards(stats),
              ),
              desktop: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _statCards(stats),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/teachers'),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Öğretmenleri gör'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/broadcast'),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Toplu bildirim gönder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _statCards(stats) {
    return [
      SizedBox(
        width: 220,
        child: adminStatCard(
          label: 'Öğretmen',
          value: '${stats.teacherCount}',
          icon: Icons.school_outlined,
        ),
      ),
      SizedBox(
        width: 220,
        child: adminStatCard(
          label: 'Veli',
          value: '${stats.parentCount}',
          icon: Icons.family_restroom_outlined,
        ),
      ),
      SizedBox(
        width: 220,
        child: adminStatCard(
          label: 'Öğrenci',
          value: '${stats.studentCount}',
          icon: Icons.person_outline,
        ),
      ),
      SizedBox(
        width: 220,
        child: adminStatCard(
          label: 'Sınıf',
          value: '${stats.classCount}',
          icon: Icons.class_outlined,
        ),
      ),
      SizedBox(
        width: 220,
        child: adminStatCard(
          label: 'Son 7 gün (öğretmen)',
          value: '${stats.recentTeachers}',
          icon: Icons.trending_up_rounded,
        ),
      ),
    ];
  }
}
