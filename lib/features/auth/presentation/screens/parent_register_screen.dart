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

/// Veli kayıt ekranı — 3 Adımlı Multi-step Wizard Yapısı
class ParentRegisterScreen extends ConsumerStatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  ConsumerState<ParentRegisterScreen> createState() =>
      _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends ConsumerState<ParentRegisterScreen> {
  int _currentStep = 0;

  // Step 0: Davet kodu
  final _codeController = TextEditingController();

  // Step 1: Kişisel Bilgiler
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 2: Güvenlik
  final _step2FormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _termsAccepted = false;

  String? _validatedCode;
  String? _studentName;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    context.unfocus();
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      context.showSnackBar(AppStrings.errorInviteCodeRequired, isError: true);
      return;
    }

    final notifier = ref.read(parentAuthProvider.notifier);
    final isValid = await notifier.validateInviteCode(code);

    if (!mounted) return;
    if (isValid) {
      _validatedCode = code;
      final data = notifier.inviteCodeData;
      _studentName = data?['studentName'] as String?;
      setState(() => _currentStep = 1);
    } else {
      final error = ref.read(parentAuthProvider).errorMessage;
      if (error != null) context.showSnackBar(error, isError: true);
    }
  }

  void _nextStep() {
    context.unfocus();
    if (_currentStep == 1) {
      if (!_step1FormKey.currentState!.validate()) return;
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

  Future<void> _register() async {
    context.unfocus();
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }

    await ref.read(parentAuthProvider.notifier).registerParent(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          inviteCode: _validatedCode!,
        );

    if (!mounted) return;
    final state = ref.read(parentAuthProvider);
    if (state.isSuccess) {
      context.go('/parent/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Veli Kaydı',
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
                  'Davet Kodu',
                  'Kişisel Bilgiler',
                  'Güvenlik & Onay'
                ],
                primaryColor: AppColors.parentPrimary,
              ),
              const SizedBox(height: 28),

              // ── Adım İçeriği ─────────────────────────────────────────────
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
                        color: AppColors.parentPrimary,
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
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Adım 1: Davet Kodu Doğrulama ─────────────────────────────────────────
  Widget _buildStep0() {
    final authState = ref.watch(parentAuthProvider);

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öğrenci Davet Kodu',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 6),
        Text(
          'Öğretmeninizden aldığınız 6 haneli davet kodunu (ör: OT-123456) girin.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: AppStrings.inviteCode,
          hint: 'OT-XXXXXX',
          controller: _codeController,
          prefixIcon: const Icon(Icons.qr_code_rounded,
              color: AppColors.textSecondary),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Kodu Doğrula ➔',
          onPressed: _validateCode,
          isLoading: authState.isLoading,
          backgroundColor: AppColors.parentPrimary,
        ),
      ],
    );
  }

  // ── Adım 2: Veli Kişisel Bilgileri ────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eşleşen Öğrenci Kartı
          if (_studentName != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.parentSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.parentPrimary.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.parentPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.child_care_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eşleşen Öğrenci',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.parentPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _studentName!,
                          style: AppTextStyles.h4,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.parentPrimary, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Veli Bilgileri',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            'Kendi Ad Soyad ve e-posta adresinizi girin.',
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
            hint: 'ornek@email.com',
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
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '← Kod Değiştir',
                  onPressed: _prevStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Devam Et ➔',
                  onPressed: _nextStep,
                  backgroundColor: AppColors.parentPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Adım 3: Güvenlik & Kaydı Tamamlama ───────────────────────────────────
  Widget _buildStep2() {
    final authState = ref.watch(parentAuthProvider);

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Güvenlik & Onay',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            'Şifrenizi belirleyin ve kaydı tamamlayın.',
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
          const SizedBox(height: 20),

          // Kullanım şartları
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                activeColor: AppColors.parentPrimary,
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
                          color: AppColors.parentPrimary,
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
                          color: AppColors.parentPrimary,
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
                  label: '← Geri',
                  onPressed: _prevStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Hesabı Oluştur 🚀',
                  onPressed: _register,
                  isLoading: authState.isLoading,
                  backgroundColor: AppColors.parentPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
