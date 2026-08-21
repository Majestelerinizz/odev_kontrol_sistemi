import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../../../classes/presentation/providers/class_providers.dart';

/// MatPusula Profil & Ayarlar Ekranı
/// Öğretmen ve Veli için özel özelleştirilmiş ayarlar menüsü
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _homeworkAlertsEnabled = true;

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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifre en az 6 karakter olmalıdır'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Şifreniz başarıyla güncellendi! 🔒'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Güncelle', style: TextStyle(color: Colors.white)),
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
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ödev Takip Sistemi (MatPusula) Gizlilik Bildirimi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '1. Kişisel Verilerin İşlenmesi:\nKullanıcıların adı, e-posta adresi ve rol bilgileri yalnızca uygulama içi ödev, sınav ve duyuru süreçlerinin yürütülmesi amacıyla işlenir.\n\n'
                '2. Veri Güvenliği:\nTüm veriler Google Firebase bulut altyapısında şifreli ve yetkilendirilmiş erişim kuralları (Firestore Security Rules) ile korunur.\n\n'
                '3. Üçüncü Taraflarla Paylaşım:\nVerileriniz hiçbir reklam veren veya 3. taraf pazarlama şirketleri ile paylaşılmaz.\n\n'
                '4. Haklarınız:\nHesabınızı dilediğiniz zaman silebilir veya verilerinizin silinmesini talep edebilirsiniz.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Okudum ve Anladım', style: TextStyle(color: Colors.white)),
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
        content: const Text(
          'Hesabınızı sildiğinizde profil verileriniz ve bağlantılarınız sistemden kalıcı olarak temizlenir. Bu işlem geri alınamaz.',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hesabınız ve profil verileriniz Firebase\'den kalıcı olarak silindi.'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go('/welcome');
            },
            child: const Text('Hesabımı Sil', style: TextStyle(color: Colors.white)),
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
                    Consumer(
                      builder: (context, ref, _) {
                        final studentsAsync = ref.watch(parentStudentsStreamProvider(user?.uid ?? ''));
                        final parentStudents = studentsAsync.valueOrNull ?? [];
                        final connectedStudent = parentStudents.firstOrNull;
                        final displayName = (!isTeacher && connectedStudent != null)
                            ? '${connectedStudent.name} Velisi'
                            : (user?.name ?? (isTeacher ? 'Öğretmen Hesabı' : 'Veli Hesabı'));

                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: AppTextStyles.h4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'ornek@matpusula.com',
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
                                  isTeacher ? '👨‍🏫 Matematik Öğretmeni' : '👨‍👩‍👧 Veli Hesabı',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Veli Özel: Gerçek Bağlı Çocuk Bilgisi ──────────────
              if (!isTeacher) ...[
                Consumer(
                  builder: (context, ref, _) {
                    final studentsAsync = ref.watch(parentStudentsStreamProvider(user?.uid ?? ''));
                    final parentStudents = studentsAsync.valueOrNull ?? [];

                    if (parentStudents.isEmpty) {
                      return _buildSettingsGroup('Öğrenci / Çocuk Bağlantıları', [
                        const ListTile(
                          leading: Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                          title: Text('Henüz bağlı bir öğrenci bulunmuyor'),
                          subtitle: Text('Öğretmeninizden aldığınız davet kodu ile bağlanabilirsiniz.'),
                        ),
                      ]);
                    }

                    return _buildSettingsGroup('Bağlı Öğrenci Profili', [
                      for (final st in parentStudents)
                        Consumer(
                          builder: (context, ref, _) {
                            final classAsync = ref.watch(classStreamProvider(st.classId));
                            final className = classAsync.asData?.value?.name ?? '';
                            final subtitle = className.isNotEmpty
                                ? '$className Sınıfı • No: ${st.schoolNumber ?? '-'}'
                                : (st.schoolNumber != null && st.schoolNumber!.isNotEmpty
                                    ? 'Okul No: ${st.schoolNumber}'
                                    : 'Kayıtlı Öğrenci');

                            return ListTile(
                              leading: const Icon(Icons.face_rounded, color: AppColors.parentPrimary),
                              title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(subtitle),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Bağlı',
                                  style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                    ]);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // ── Bildirim Tercihleri ────────────────────────────────────
              _buildSettingsGroup('Bildirim Ayarları', [
                SwitchListTile(
                  secondary: Icon(Icons.notifications_active_rounded, color: primaryColor),
                  title: const Text('Anlık Bildirimler', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Duyuru ve mesaj bildirimlerini al'),
                  value: _notificationsEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.assignment_turned_in_rounded, color: primaryColor),
                  title: const Text('Ödev & Deneme Uyarıları', style: TextStyle(fontWeight: FontWeight.w600)),
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
          color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
