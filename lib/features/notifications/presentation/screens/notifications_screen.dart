import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleNotifications = [
      {
        'title': 'LGS Kurumsal Deneme #3 Açıklandı!',
        'subtitle':
            'Toplam 85.50 Net ile öğrenciniz sınıfta 2. sırada yer aldı.',
        'time': '10 dk önce',
        'icon': Icons.stars_rounded,
        'color': AppColors.parentPrimary,
      },
      {
        'title': 'Yeni Ödev Atandı: Çarpanlar ve Katlar',
        'subtitle': 'Teslim tarihi: Yarın 17:00. Lütfen kontrol ediniz.',
        'time': '2 saat önce',
        'icon': Icons.assignment_rounded,
        'color': AppColors.accent,
      },
      {
        'title': 'Öğretmen Değerlendirme Notu',
        'subtitle':
            'Matematik dersindeki özverili çalışması için teşekkür ederiz.',
        'time': ' Dün',
        'icon': Icons.sticky_note_2_rounded,
        'color': AppColors.success,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyuru & Bildirimler'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        itemCount: sampleNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = sampleNotifications[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item['time'] as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subtitle'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
