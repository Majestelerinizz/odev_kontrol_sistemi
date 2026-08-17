import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/matpusula_logo.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/services/sms_service.dart';

/// MatPusula Yenilenmiş Giriş Ekranı
/// - Öğretmen: Kullanıcı Adı / E-posta + Şifre
/// - Veli: 2 Adımlı Şifresiz Giriş (Telefon Numarası -> Kodu Gönder -> Doğrulama Kodu -> Giriş/Kayıt Yap)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _teacherFormKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>();

  // Öğretmen alanları
  final _teacherIdentityController = TextEditingController();
  final _teacherPasswordController = TextEditingController();

  // Veli alanları (ŞİFRESİZ TELEFON & SMS KODU)
  final _parentPhoneController = TextEditingController(text: '0531 563 5049');
  final _parentOtpController = TextEditingController(text: '123456');

  bool _isTeacherRole = true; // true = Öğretmen, false = Veli
  bool _isSmsSent = false;
  bool _isSendingSms = false;

  @override
  void dispose() {
    _teacherIdentityController.dispose();
    _teacherPasswordController.dispose();
    _parentPhoneController.dispose();
    _parentOtpController.dispose();
    super.dispose();
  }

  // ── Öğretmen Girişi ──────────────────────────────────────────────────────
  Future<void> _submitTeacherLogin() async {
    context.unfocus();
    if (!_teacherFormKey.currentState!.validate()) return;

    final input = _teacherIdentityController.text.trim();
    final password = _teacherPasswordController.text;

    await ref.read(teacherAuthProvider.notifier).signIn(
          email: input,
          password: password,
        );

    if (!mounted) return;
    final state = ref.read(teacherAuthProvider);
    if (state.isSuccess) {
      context.go('/teacher/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
      ref.read(teacherAuthProvider.notifier).clearError();
    }
  }

  // ── Veli SMS Kodu Gönder ──────────────────────────────────────────────────
  Future<void> _sendParentSms() async {
    context.unfocus();
    final phone = _parentPhoneController.text.trim();
    if (phone.length < 10) {
      context.showSnackBar('Lütfen geçerli bir telefon numarası giriniz.', isError: true);
      return;
    }

    setState(() => _isSendingSms = true);
    final res = await SmsService.sendOtp(phone);
    if (!mounted) return;
    setState(() => _isSendingSms = false);

    if (res['success'] == true) {
      setState(() => _isSmsSent = true);
      context.showSnackBar('✅ SMS doğrulama kodu gönderildi. (Sabit Test Kodu: 123456)');
    } else {
      context.showSnackBar(res['message'] ?? 'SMS gönderilemedi.', isError: true);
    }
  }

  // ── Veli Telefon & OTP Doğrulama ile Şifresiz Giriş / Kayıt ─────────────
  Future<void> _submitParentLogin() async {
    context.unfocus();
    if (!_parentFormKey.currentState!.validate()) return;

    final phone = _parentPhoneController.text.trim();
    final otpCode = _parentOtpController.text.trim();

    if (!_isSmsSent) {
      await _sendParentSms();
      return;
    }

    final isValidOtp = await SmsService.verifyOtp(phone, otpCode);
    if (!mounted) return;

    if (!isValidOtp) {
      context.showSnackBar('Hatalı doğrulama kodu! Lütfen 123456 kodunu giriniz.', isError: true);
      return;
    }

    // Telefon ile şifresiz giriş veya kayıt yap (tek adımda tamamlar)
    await ref.read(parentAuthProvider.notifier).signInWithPhone(phone: phone);

    if (!mounted) return;
    final state = ref.read(parentAuthProvider);
    if (state.isSuccess) {
      context.showSnackBar('✅ Veli girişi başarılı!');
      context.go('/parent/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
      ref.read(parentAuthProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherAuthProvider);
    final parentState = ref.watch(parentAuthProvider);
    final isLoading = teacherState.isLoading || parentState.isLoading;

    final activeColor =
        _isTeacherRole ? AppColors.teacherPrimary : AppColors.parentPrimary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pagePadding * 1.2,
            vertical: AppSizes.pagePadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── MatPusula Logo & Header ─────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    const MatPusulaLogo(size: 84),
                    const SizedBox(height: 12),
                    Text(
                      'MatPusula',
                      style: AppTextStyles.h1.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Geleceğini Matematikle Şekillendir',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Kullanıcı Türü Seçimi (Öğretmen / Veli) ───────────────────
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleTabButton(
                        title: 'Öğretmen',
                        icon: Icons.school_rounded,
                        isSelected: _isTeacherRole,
                        activeColor: AppColors.teacherPrimary,
                        onTap: () {
                          setState(() => _isTeacherRole = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _RoleTabButton(
                        title: 'Veli',
                        icon: Icons.family_restroom_rounded,
                        isSelected: !_isTeacherRole,
                        activeColor: AppColors.parentPrimary,
                        onTap: () {
                          setState(() => _isTeacherRole = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tab İçerikleri ─────────────────────────────────────────────
              if (_isTeacherRole)
                _buildTeacherLoginForm(isLoading)
              else
                _buildParentPhoneLoginForm(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  // ── Öğretmen Giriş Formu (Kullanıcı Adı & Şifre) ──────────────────────────
  Widget _buildTeacherLoginForm(bool isLoading) {
    return Form(
      key: _teacherFormKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Kullanıcı Adı veya E-posta',
            hint: 'ahmet@okul.com / ahmet123',
            controller: _teacherIdentityController,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.teacherPrimary),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Kullanıcı adı veya e-posta giriniz';
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: 'Şifre',
            hint: 'Şifrenizi girin',
            controller: _teacherPasswordController,
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.teacherPrimary),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitTeacherLogin(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Lütfen şifrenizi girin';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'Şifremi Unuttum?',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.teacherPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Öğretmen Girişi Yap 🚀',
            onPressed: _submitTeacherLogin,
            isLoading: isLoading,
            backgroundColor: AppColors.teacherPrimary,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hesabınız yok mu? ', style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () => context.push('/register/teacher'),
                child: Text(
                  'Öğretmen Kaydı Oluştur',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.teacherPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Veli ŞİFRESİZ Telefon & SMS Kodu Giriş/Kayıt Formu ────────────────────
  Widget _buildParentPhoneLoginForm(bool isLoading) {
    return Form(
      key: _parentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.parentSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.parentPrimary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Şifreye gerek yok! Numaranızı girip doğrulama kodu isteyin.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Telefon Numarası Alanı
          AppTextField(
            label: 'Telefon Numarası',
            hint: '0531 563 5049',
            controller: _parentPhoneController,
            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.parentPrimary),
            keyboardType: TextInputType.phone,
            textInputAction: _isSmsSent ? TextInputAction.next : TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().length < 10) return 'Geçerli bir telefon numarası giriniz';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 2. Eğer SMS Kodu Gönderildi ise: Doğrulama Kodu Alanı Görünür
          if (_isSmsSent) ...[
            AppTextField(
              label: 'SMS Doğrulama Kodu',
              hint: '123456',
              controller: _parentOtpController,
              prefixIcon: const Icon(Icons.mark_chat_unread_rounded, color: AppColors.parentPrimary),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitParentLogin(),
              validator: (v) {
                if (v == null || v.trim().length < 6) return '6 haneli doğrulama kodunu giriniz';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.parentSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.parentPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sabit Test Kodu: Tüm telefonlar için geçerli doğrulama kodu: 123456',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Doğrula & Giriş/Kayıt Yap Butonu
            PrimaryButton(
              label: 'Doğrula & Giriş Yap 🚀',
              onPressed: _submitParentLogin,
              isLoading: isLoading,
              backgroundColor: AppColors.parentPrimary,
            ),
          ] else ...[
            const SizedBox(height: 8),
            // Kodu Gönder / SMS İste Butonu
            PrimaryButton(
              label: 'Doğrulama Kodu Gönder 📩',
              onPressed: _sendParentSms,
              isLoading: _isSendingSms,
              backgroundColor: AppColors.parentPrimary,
            ),
          ],

          const SizedBox(height: 24),

          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('İlk defa davet koduyla mı geliyorsunuz? ', style: AppTextStyles.bodySmall),
                TextButton(
                  onPressed: () => context.push('/register/parent'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Davet Kodu Eşleştir',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.parentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kullanıcı Türü Seçim Butonu Component
class _RoleTabButton extends StatelessWidget {
  const _RoleTabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
