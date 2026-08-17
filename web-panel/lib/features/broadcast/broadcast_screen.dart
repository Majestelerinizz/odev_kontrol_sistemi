import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../data/admin_providers.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  BroadcastAudience _audience = BroadcastAudience.allTeachers;
  String? _teacherId;
  int? _estimatedTargets;
  bool _loadingEstimate = false;
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    setState(() => _loadingEstimate = true);
    try {
      final count = await ref.read(broadcastServiceProvider).estimateTargets(
            audience: _audience,
            teacherId: _teacherId,
            repository: ref.read(adminRepositoryProvider),
          );
      setState(() => _estimatedTargets = count);
    } finally {
      setState(() => _loadingEstimate = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience.requiresTeacher &&
        (_teacherId == null || _teacherId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu hedef için öğretmen seçin.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Toplu bildirim gönder'),
        content: Text(
          '“${_titleController.text.trim()}” başlıklı bildirim '
          '${_estimatedTargets ?? '?'} kullanıcıya gönderilecek. Onaylıyor musunuz?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    try {
      final result = await ref.read(broadcastServiceProvider).sendBroadcast(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            audience: _audience,
            teacherId: _teacherId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gönderildi: ${result['sentCount'] ?? 0} cihaz, '
            '${result['targetUserCount'] ?? 0} kullanıcı',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gönderilemedi: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersPickerProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Toplu push bildirimi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bildirimler Cloud Functions üzerinden FCM ile iletilir.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Başlık gerekli.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  maxLength: 240,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mesaj'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Mesaj gerekli.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BroadcastAudience>(
                  initialValue: _audience,
                  decoration: const InputDecoration(labelText: 'Hedef kitle'),
                  items: [
                    for (final a in BroadcastAudience.values)
                      DropdownMenuItem(value: a, child: Text(a.label)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _audience = v;
                      _estimatedTargets = null;
                      if (!v.requiresTeacher) _teacherId = null;
                    });
                  },
                ),
                if (_audience.requiresTeacher) ...[
                  const SizedBox(height: 12),
                  teachersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Öğretmen listesi yüklenemedi'),
                    data: (teachers) => DropdownButtonFormField<String>(
                      initialValue: _teacherId,
                      decoration: const InputDecoration(labelText: 'Öğretmen'),
                      items: [
                        for (final t in teachers)
                          DropdownMenuItem(value: t.uid, child: Text(t.name)),
                      ],
                      onChanged: (v) => setState(() {
                        _teacherId = v;
                        _estimatedTargets = null;
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadingEstimate ? null : _estimate,
                      icon: _loadingEstimate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.groups_outlined),
                      label: Text(
                        _estimatedTargets == null
                            ? 'Hedef sayısını hesapla'
                            : '~$_estimatedTargets kullanıcı',
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Gönder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
