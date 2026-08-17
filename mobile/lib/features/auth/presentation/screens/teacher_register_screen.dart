import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/step_progress_indicator.dart';
import '../../../../core/extensions/extensions.dart';

/// Öğretmen kayıt ekranı — 3 adımlı Wizard yapısı
class TeacherRegisterScreen extends ConsumerStatefulWidget {
  const TeacherRegisterScreen({super.key});

  @override
  ConsumerState<TeacherRegisterScreen> createState() =>
      _TeacherRegisterScreenState();
}

class _TeacherRegisterScreenState
    extends ConsumerState<TeacherRegisterScreen> {
  int _currentStep = 0;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _nextStep() {
    context.unfocus();
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_step2FormKey.currentState!.validate()) return;
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    context.unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }

    await ref.read(teacherAuthProvider.notifier).registerTeacher(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final authState = ref.read(teacherAuthProvider);
    if (authState.isSuccess) {
      context.go('/teacher/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hata mesajı göster
    ref.listen(teacherAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        context.showSnackBar(next.errorMessage!, isError: true);
        ref.read(teacherAuthProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: _prevStep,
        ),
        title: Text(
          'Öğretmen Kaydı',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Adım İlerleme Çubuğu ─────────────────────────────────────
              StepProgressIndicator(
                currentStep: _currentStep,
                totalSteps: 3,
                stepTitles: const [
                  'Kişisel Bilgiler',
                  'Güvenlik',
                  'Tamamlama'
                ],
                primaryColor: AppColors.teacherPrimary,
              ),
              const SizedBox(height: 28),

              // ── Adım İçerikleri (AnimatedSwitcher ile yumuşak geçiş) ──────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(),
              ),

              const SizedBox(height: 32),

              // ── Giriş bağlantısı ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Zaten hesabınız var mı? ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      AppStrings.login,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.teacherPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Adım 1: Kişisel Bilgiler ─────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kişisel Bilgileriniz',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            'Öğretmen hesabınız için Ad Soyad ve e-posta adresinizi girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.fullName,
            hint: 'Ad Soyad',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textSecondary),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.errorNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: AppStrings.email,
            hint: 'ornek@okul.com',
            controller: _emailController,
            prefixIcon: const Icon(Icons.email_outlined,
                color: AppColors.textSecondary),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.errorEmailRequired;
              }
              if (!v.trim().isValidEmail) {
                return AppStrings.errorEmailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Devam Et ➔',
            onPressed: _nextStep,
            backgroundColor: AppColors.teacherPrimary,
          ),
        ],
      ),
    );
  }

  // ── Adım 2: Güvenlik Bilgileri ───────────────────────────────────────────
  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Güvenlik & Şifre',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            'Hesabınız için güçlü bir şifre belirleyin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.password,
            hint: 'En az 8 karakter',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textSecondary),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return AppStrings.errorPasswordRequired;
              }
              if (!v.isValidPassword) {
                return AppStrings.errorPasswordMin;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: AppStrings.passwordConfirm,
            hint: 'Şifrenizi tekrar girin',
            controller: _passwordConfirmController,
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textSecondary),
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v != _passwordController.text) {
                return AppStrings.errorPasswordMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '← Geri',
                  onPressed: _prevStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Son Adıma Geç ➔',
                  onPressed: _nextStep,
                  backgroundColor: AppColors.teacherPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Adım 3: Tamamlama & Onay ─────────────────────────────────────────────
  Widget _buildStep3() {
    final authState = ref.watch(teacherAuthProvider);

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hesabınızı Tamamlayın',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 6),
        Text(
          'Bilgilerinizi gözden geçirin ve şartları onaylayın.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Özet Kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.teacherSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teacherPrimary.withAlpha(51)),
          ),
          child: Column(
            children: [
              _buildSummaryRow(Icons.person_rounded, 'Ad Soyad', _nameController.text),
              const Divider(height: 16),
              _buildSummaryRow(Icons.email_rounded, 'E-posta', _emailController.text),
              const Divider(height: 16),
              _buildSummaryRow(Icons.badge_rounded, 'Hesap Türü', 'Öğretmen'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Kullanım şartları onay kutusu
        Row(
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
              activeColor: AppColors.teacherPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Wrap(
                children: [
                  Text(
                    'Okudum, kabul ediyorum: ',
                    style: AppTextStyles.bodySmall,
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      AppStrings.termsOfService,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.teacherPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ' ve ',
                    style: AppTextStyles.bodySmall,
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      AppStrings.privacyPolicy,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.teacherPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: '← Düzelt',
                onPressed: _prevStep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Kaydol ve Başla 🚀',
                onPressed: _submit,
                isLoading: authState.isLoading,
                backgroundColor: AppColors.teacherPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.teacherPrimary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
