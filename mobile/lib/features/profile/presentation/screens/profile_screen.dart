import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Eduly Profil & Ayarlar Ekranı
/// Öğretmen ve Veli için özel özelleştirilmiş ayarlar menüsü
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _homeworkAlertsEnabled = true;

  void _showAddChildDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppColors.parentPrimary),
            SizedBox(width: 8),
            Text('Yeni Öğrenci/Çocuk Ekle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Öğretmeninizden aldığınız 6 haneli davet kodunu girin:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Davet Kodu',
              hint: 'Örn: OT-A7K9M2',
              controller: codeController,
              prefixIcon: const Icon(Icons.key_rounded, color: AppColors.parentPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.parentPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (codeController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.showSnackBar('Davet kodu başarıyla doğrulandı ve öğrenci eklendi! 🎉');
            },
            child: Text('Ekle', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppColors.teacherPrimary),
            SizedBox(width: 8),
            Text('Şifre Değiştir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Mevcut Şifre',
              hint: 'Mevcut şifreniz',
              controller: oldPassController,
              isPassword: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Yeni Şifre',
              hint: 'En az 8 karakter',
              controller: newPassController,
              isPassword: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teacherPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (newPassController.text.length < 6) {
                context.showSnackBar('Şifre en az 6 karakter olmalıdır', isError: true);
                return;
              }
              Navigator.pop(ctx);
              context.showSnackBar('Şifreniz başarıyla güncellendi! 🔒');
            },
            child: Text('Güncelle', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: AppColors.info),
            SizedBox(width: 8),
            Text('Gizlilik Politikası & KVKK'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Eduly Gizlilik Bildirimi',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '1. Kişisel Verilerin İşlenmesi:\nKullanıcıların adı, e-posta adresi ve rol bilgileri yalnızca uygulama içi ödev, sınav ve duyuru süreçlerinin yürütülmesi amacıyla işlenir.\n\n'
                '2. Veri Güvenliği:\nTüm veriler Google Firebase bulut altyapısında şifreli ve yetkilendirilmiş erişim kuralları (Firestore Security Rules) ile korunur.\n\n'
                '3. Üçüncü Taraflarla Paylaşım:\nVerileriniz hiçbir reklam veren veya 3. taraf pazarlama şirketleri ile paylaşılmaz.\n\n'
                '4. Haklarınız:\nHesabınızı dilediğiniz zaman silebilir veya verilerinizin silinmesini talep edebilirsiniz.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(AppConstants.privacyPolicyUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Tam metin'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Okudum ve Anladım', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hesabı Sil?'),
          ],
        ),
        content: Text(
          'Hesabınızı sildiğinizde profil verileriniz ve bağlantılarınız sistemden kalıcı olarak temizlenir. Bu işlem geri alınamaz.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).deleteAccount();
              if (!mounted) return;
              context.showSnackBar('Hesabınız ve profil verileriniz Firebase\'den kalıcı olarak silindi.');
              context.go('/welcome');
            },
            child: Text('Hesabımı Sil', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isTeacher = user?.isTeacher ?? true;
    final primaryColor =
        isTeacher ? AppColors.teacherPrimary : AppColors.parentPrimary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profil & Ayarlar',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            children: [
              // ── Kullanıcı Profil Kartı ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: primaryColor.withAlpha(30),
                      child: Icon(
                        isTeacher
                            ? Icons.school_rounded
                            : Icons.family_restroom_rounded,
                        color: primaryColor,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? (isTeacher ? 'Öğretmen Hesabı' : 'Veli Hesabı'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'ornek@eduly.com',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isTeacher ? '👨‍🏫 Öğretmen Hesabı' : '👨‍👩‍👧 Veli Hesabı',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Veli Özel: Çocuk Bağlantısı ve Yeni Çocuk Ekleme ────────
              if (!isTeacher) ...[
                _buildSettingsGroup('Öğrenci / Çocuk Bağlantıları', [
                  ListTile(
                    leading: const Icon(Icons.face_rounded, color: AppColors.parentPrimary),
                    title: Text('Ahmet Yılmaz',
                        style: AppTextStyles.h4),
                    subtitle: const Text('8A Sınıfı • No: 456'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bağlı',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.parentPrimary),
                    title: Text(
                      'Yeni Çocuk / Öğrenci Ekle',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.parentPrimary),
                    ),
                    subtitle: const Text('Öğretmenden alınan davet kodu ile ekle'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.parentPrimary),
                    onTap: _showAddChildDialog,
                  ),
                ]),
                const SizedBox(height: 20),
              ],

              // ── Bildirim Tercihleri ────────────────────────────────────
              _buildSettingsGroup('Bildirim Ayarları', [
                SwitchListTile(
                  secondary: Icon(Icons.notifications_active_rounded, color: primaryColor),
                  title: Text('Anlık Bildirimler',
                      style: AppTextStyles.labelLarge),
                  subtitle: const Text('Duyuru ve mesaj bildirimlerini al'),
                  value: _notificationsEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.assignment_turned_in_rounded, color: primaryColor),
                  title: Text('Ödev & Deneme Uyarıları',
                      style: AppTextStyles.labelLarge),
                  subtitle: const Text('Yaklaşan ödev ve deneme hatırlatmaları'),
                  value: _homeworkAlertsEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) => setState(() => _homeworkAlertsEnabled = val),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Güvenlik & Hesap Ayarları ──────────────────────────────
              _buildSettingsGroup('Güvenlik & Hesap', [
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Şifre Değiştir',
                  subtitle: 'Hesap şifrenizi güncelleyin',
                  onTap: _showChangePasswordDialog,
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Gizlilik Politikası & KVKK',
                  subtitle: 'Veri gizliliği ve kullanım şartları',
                  onTap: _showPrivacyPolicyDialog,
                ),
                _buildSettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Hesabımı Sil',
                  subtitle: 'Tüm kişisel verilerinizi kalıcı olarak silin',
                  onTap: _showDeleteAccountDialog,
                ),
              ]),
              const SizedBox(height: 32),

              // ── Çıkış Yap Butonu ──────────────────────────────────────
              SecondaryButton(
                label: 'Güvenli Çıkış Yap',
                icon: Icons.logout_rounded,
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (!context.mounted) return;
                  context.go('/welcome');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
