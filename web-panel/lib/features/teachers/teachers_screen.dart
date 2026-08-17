import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../data/admin_providers.dart';
import '../shell/admin_shell.dart';

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  final _items = <TeacherSummary>[];
  PaginationCursor? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _cursor = null;
        _hasMore = true;
      }
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      final page = await repo.fetchTeachers(cursor: _cursor);
      setState(() {
        _items.addAll(page.items);
        _cursor = PaginationCursor(lastDocument: page.lastDocument);
        _hasMore = page.hasMore;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = layoutModeForWidth(MediaQuery.sizeOf(context).width) ==
        AdminLayoutMode.mobile;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kayıtlı öğretmenler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.error)),
          Expanded(
            child: isMobile ? _mobileList() : _table(),
          ),
          if (_hasMore)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _loading
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: _load,
                        child: const Text('Daha fazla yükle'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mobileList() {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = _items[index];
        return Card(
          child: ListTile(
            title: Text(t.name),
            subtitle: Text('${t.email}\n${t.classCount} sınıf · ${t.studentCount} öğrenci'),
            isThreeLine: true,
            onTap: () => context.go('/teachers/${t.uid}'),
          ),
        );
      },
    );
  }

  Widget _table() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Ad')),
          DataColumn(label: Text('E-posta')),
          DataColumn(label: Text('Sınıf')),
          DataColumn(label: Text('Öğrenci')),
          DataColumn(label: Text('Kayıt')),
          DataColumn(label: Text('Durum')),
        ],
        rows: [
          for (final t in _items)
            DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => context.go('/teachers/${t.uid}'),
                    child: Text(t.name),
                  ),
                ),
                DataCell(Text(t.email)),
                DataCell(Text('${t.classCount}')),
                DataCell(Text('${t.studentCount}')),
                DataCell(Text(formatAdminDate(t.createdAt))),
                DataCell(Text(t.isActive ? 'Aktif' : 'Pasif')),
              ],
            ),
        ],
      ),
    );
  }
}

class TeacherDetailScreen extends ConsumerStatefulWidget {
  const TeacherDetailScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends ConsumerState<TeacherDetailScreen> {
  TeacherSummary? _teacher;
  List<ClassSummary> _classes = [];
  List<StudentSummary> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(adminRepositoryProvider);
    final teacher = await repo.fetchTeacher(widget.teacherId);
    final classes = await repo.fetchClassesForTeacher(widget.teacherId);
    final studentsPage = await repo.fetchStudents(teacherId: widget.teacherId);
    setState(() {
      _teacher = teacher;
      _classes = classes;
      _students = studentsPage.items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_teacher == null) {
      return const Center(child: Text('Öğretmen bulunamadı.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text(_teacher!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(_teacher!.email, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('${_classes.length} sınıf · ${_students.length} öğrenci (ilk sayfa)'),
          const SizedBox(height: 24),
          const Text('Sınıflar', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._classes.map(
            (c) => ListTile(
              title: Text(c.name),
              subtitle: Text('Seviye: ${c.gradeLevel ?? '-'} · ${c.studentCount} öğrenci'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Öğrenciler', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._students.map(
            (s) => ListTile(
              title: Text(s.name),
              subtitle: Text('Sınıf: ${s.classId} · Veli: ${s.parentCount}'),
            ),
          ),
        ],
      ),
    );
  }
}
