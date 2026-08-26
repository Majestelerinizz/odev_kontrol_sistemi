import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../classes/presentation/providers/class_providers.dart';
import '../providers/messages_providers.dart';

/// Toplu Veli Mesajı ve Duyuru Oluşturma Ekranı
class TeacherNewMessageScreen extends ConsumerStatefulWidget {
  const TeacherNewMessageScreen({super.key});

  @override
  ConsumerState<TeacherNewMessageScreen> createState() =>
      _TeacherNewMessageScreenState();
}

class _TeacherNewMessageScreenState
    extends ConsumerState<TeacherNewMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      context.showSnackBar('Oturum açmış kullanıcı bulunamadı!', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final repo = ref.read(messagesRepositoryProvider);

      await repo.sendMessage(
        teacherId: currentUser.uid,
        teacherName: currentUser.name,
        classId: _selectedClassId,
        className: _selectedClassName,
        title: _titleController.text.trim(),
        body: _contentController.text.trim(),
      );

      if (!mounted) return;

      context.showSnackBar('Duyuru başarıyla velilere gönderildi! 📲');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Mesaj gönderilemedi: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Toplu Veli Mesajı',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veli Duyurusu & Mesaj',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sınıf seçerek tüm velilere anlık bildirim ve mesaj iletebilirsiniz.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Sınıf seçimi
                classesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Sınıflar yüklenemedi'),
                  data: (classes) {
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedClassId,
                      decoration: InputDecoration(
                        labelText: 'Hedef Sınıf',
                        prefixIcon: const Icon(Icons.class_rounded,
                            color: AppColors.teacherPrimary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm Sınıflarım & Veliler'),
                        ),
                        ...classes.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                          if (val != null) {
                            final match =
                                classes.firstWhere((c) => c.id == val);
                            _selectedClassName = match.name;
                          } else {
                            _selectedClassName = null;
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.itemSpacing),

                // Mesaj Başlığı
                AppTextField(
                  label: 'Mesaj Başlığı',
                  hint: 'Örn: Yarınki Veliler Toplantısı',
                  controller: _titleController,
                  prefixIcon: const Icon(Icons.title_rounded,
                      color: AppColors.textSecondary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Lütfen bir başlık girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.itemSpacing),

                // Mesaj İçeriği
                AppTextField(
                  label: 'Mesaj İçeriği',
                  hint: 'Duyuru detaylarını buraya yazın...',
                  controller: _contentController,
                  maxLines: 5,
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.textSecondary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Lütfen mesaj içeriğini yazın';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Gönder Butonu
                PrimaryButton(
                  label: 'Velilere Gönder 🚀',
                  onPressed: _sendMessage,
                  isLoading: _isSending,
                  backgroundColor: AppColors.teacherPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
