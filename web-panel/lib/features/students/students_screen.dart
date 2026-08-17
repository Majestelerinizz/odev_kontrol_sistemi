import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../core/responsive.dart';
import '../data/admin_providers.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _items = <StudentSummary>[];
  PaginationCursor? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  String? _selectedTeacherId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _items.clear();
        _cursor = null;
        _hasMore = true;
      }
    });

    final repo = ref.read(adminRepositoryProvider);
    final page = await repo.fetchStudents(
      teacherId: _selectedTeacherId,
      cursor: _cursor,
    );

    setState(() {
      _items.addAll(page.items);
      _cursor = PaginationCursor(lastDocument: page.lastDocument);
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  List<StudentSummary> get _filtered {
    if (_search.trim().isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.schoolNumber?.contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersPickerProvider);
    final isMobile = layoutModeForWidth(MediaQuery.sizeOf(context).width) ==
        AdminLayoutMode.mobile;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Ara (ad veya okul no)',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          teachersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (teachers) => DropdownButtonFormField<String?>(
              initialValue: _selectedTeacherId,
              decoration: const InputDecoration(labelText: 'Öğretmene göre filtre'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tümü')),
                ...teachers.map(
                  (t) => DropdownMenuItem(value: t.uid, child: Text(t.name)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedTeacherId = value);
                _load(reset: true);
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isMobile ? _mobileList() : _table(),
          ),
          if (_hasMore)
            Center(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  : OutlinedButton(
                      onPressed: _load,
                      child: const Text('Daha fazla yükle'),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _mobileList() {
    final items = _filtered;
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = items[i];
        return Card(
          child: ListTile(
            title: Text(s.name),
            subtitle: Text('Öğretmen: ${s.teacherId}\nSınıf: ${s.classId}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _table() {
    final items = _filtered;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Ad')),
          DataColumn(label: Text('Okul No')),
          DataColumn(label: Text('Sınıf')),
          DataColumn(label: Text('Öğretmen ID')),
          DataColumn(label: Text('Veli')),
        ],
        rows: [
          for (final s in items)
            DataRow(
              cells: [
                DataCell(Text(s.name)),
                DataCell(Text(s.schoolNumber ?? '-')),
                DataCell(Text(s.classId)),
                DataCell(Text(s.teacherId)),
                DataCell(Text('${s.parentCount}')),
              ],
            ),
        ],
      ),
    );
  }
}
