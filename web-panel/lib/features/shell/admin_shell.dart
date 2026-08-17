import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (path: '/', label: 'Genel Bakış', icon: Icons.dashboard_outlined),
    (path: '/teachers', label: 'Öğretmenler', icon: Icons.school_outlined),
    (path: '/students', label: 'Öğrenciler', icon: Icons.groups_outlined),
    (path: '/activity', label: 'Aktivite', icon: Icons.timeline_outlined),
    (path: '/broadcast', label: 'Toplu Bildirim', icon: Icons.campaign_outlined),
  ];

  int _indexFor(String location) {
    if (location.startsWith('/teachers')) return 1;
    if (location.startsWith('/students')) return 2;
    if (location.startsWith('/activity')) return 3;
    if (location.startsWith('/broadcast')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider);
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFor(location);
    final mode = layoutModeForWidth(MediaQuery.sizeOf(context).width);

    if (mode == AdminLayoutMode.mobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MatPusula Admin'),
          actions: [
            IconButton(
              tooltip: 'Çıkış',
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        drawer: _AdminDrawer(
          selected: selected,
          adminName: admin?.name ?? '',
          onSelect: (index) {
            Navigator.pop(context);
            context.go(_destinations[index].path);
          },
        ),
        body: child,
      );
    }

    final extended = mode == AdminLayoutMode.desktop;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: selected,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primarySurface,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme:
                const IconThemeData(color: AppColors.textSecondary),
            onDestinationSelected: (index) =>
                context.go(_destinations[index].path),
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/matpusula_logo.png', height: 32),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: [
              for (final item in _destinations)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _destinations[selected].label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          admin?.name.isNotEmpty == true
                              ? admin!.name
                              : admin?.email ?? '',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Çıkış',
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) context.go('/login');
                          },
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.selected,
    required this.adminName,
    required this.onSelect,
  });

  final int selected;
  final String adminName;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/matpusula_logo.png', height: 40),
                const SizedBox(height: 12),
                const Text(
                  'Yönetici Paneli',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  adminName,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          for (var i = 0; i < AdminShell._destinations.length; i++)
            ListTile(
              selected: selected == i,
              leading: Icon(AdminShell._destinations[i].icon),
              title: Text(AdminShell._destinations[i].label),
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

String formatAdminDate(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

Widget adminStatCard({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
