import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../data/admin_providers.dart';
import '../shell/admin_shell.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Aktivite yüklenemedi: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz aktivite kaydı yok.'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Son aktiviteler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(activityProvider),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Icon(_iconFor(item.type), color: AppColors.primary),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                      trailing: Text(formatAdminDate(item.createdAt)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'teacher' => Icons.school_outlined,
      'homework' => Icons.assignment_outlined,
      'exam' => Icons.bar_chart_outlined,
      'message' => Icons.forum_outlined,
      _ => Icons.info_outline,
    };
  }
}
