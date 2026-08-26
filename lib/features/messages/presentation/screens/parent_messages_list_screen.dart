import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../providers/messages_providers.dart';
import '../../domain/entities/message_entity.dart';

/// Veliler İçin Öğretmen Duyuru ve Mesaj Listesi Ekranı
class ParentMessagesListScreen extends ConsumerWidget {
  const ParentMessagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(parentMessagesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Öğretmen Duyuruları',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorState(
          message: 'Mesajlar yüklenirken bir sorun oluştu.',
          onRetry: () => ref.refresh(parentMessagesStreamProvider),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return const EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'Henüz Duyuru Yok',
              subtitle:
                  'Öğretmenleriniz tarafından henüz bir duyuru paylaşılmadı.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: messages.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.itemSpacing),
            itemBuilder: (context, index) {
              final message = messages[index];
              return _ParentMessageCard(message: message);
            },
          );
        },
      ),
    );
  }
}

class _ParentMessageCard extends StatelessWidget {
  final MessageEntity message;

  const _ParentMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst bilgi çubuğu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.parentPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.parentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.teacherName ?? 'Öğretmen',
                      style: AppTextStyles.h4.copyWith(fontSize: 15),
                    ),
                    Text(
                      message.className != null
                          ? '${message.className} Sınıfı Duyurusu'
                          : 'Genel Duyuru',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                message.createdAt.toTurkishDate(),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),

          // Başlık
          Text(
            message.title,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),

          // Gövde Metni
          Text(
            message.body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
