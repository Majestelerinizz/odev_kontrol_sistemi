import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Giriş yaptıktan sonra gösterilecek Bildirim İzin Diyaloğu
class NotificationPermissionDialog extends ConsumerWidget {
  const NotificationPermissionDialog({super.key});

  static bool _hasPrompted = false;

  /// Giriş sonrası yalnızca 1 defa gösterilecek diyalog çağrısı
  static Future<void> showIfFirstTime(BuildContext context) async {
    if (_hasPrompted) return;
    _hasPrompted = true;

    await Future.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NotificationPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teacherPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.teacherPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bildirim İzni 🔔',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: const Text(
        'Ödev güncellemeleri, deneme sınavı sonuçları ve anlık mesajlar hakkında hemen bilgi sahibi olmak için anlık bildirimlere izin verin.',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Daha Sonra', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teacherPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            Navigator.pop(context);
            final uid = ref.read(authStateProvider).valueOrNull?.uid;
            if (uid != null) {
              final granted = await FcmService.requestPermissionAndSaveToken(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    granted
                        ? 'Bildirim izni verildi ve cihaz kaydedildi.'
                        : 'Bildirim izni verilmedi.',
                  ),
                  backgroundColor: granted ? AppColors.success : AppColors.warning,
                ),
              );
            }
          },
          child: const Text('İzin Ver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
