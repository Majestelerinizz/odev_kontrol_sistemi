import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../providers/messages_providers.dart';
import '../../domain/entities/message_entity.dart';

/// Öğretmenin Gönderdiği Duyuru Geçmişi Ekranı
class TeacherMessagesHistoryScreen extends ConsumerWidget {
  const TeacherMessagesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(teacherMessagesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Duyuru & Veli Mesajları',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teacherPrimary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text('Yeni Duyuru',
            style: AppTextStyles.buttonMedium.copyWith(color: Colors.white)),
        onPressed: () => context.push('/teacher/messages/new'),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorState(
          message: 'Mesajlar yüklenirken bir sorun oluştu.',
          onRetry: () => ref.refresh(teacherMessagesStreamProvider),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Henüz Duyuru Göndermediniz',
              subtitle:
                  'Velilerinize toplu duyuru veya mesaj göndermek için aşağıdaki butona dokunun.',
              actionLabel: 'Duyuru Oluştur 🚀',
              action: () => context.push('/teacher/messages/new'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: messages.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.itemSpacing),
            itemBuilder: (context, index) {
              final message = messages[index];
              return _TeacherMessageCard(message: message);
            },
          );
        },
      ),
    );
  }
}

class _TeacherMessageCard extends StatelessWidget {
  final MessageEntity message;

  const _TeacherMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teacherPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.className ?? 'Tüm Veliler',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.teacherPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                message.createdAt.toTurkishDate(),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.title,
            style: AppTextStyles.h4.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            message.body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${message.parentIds.length} Veliye Ulaştı',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
