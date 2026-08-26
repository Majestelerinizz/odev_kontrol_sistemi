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

/// Veli kaydı: 1) Davet kodu 2) Ad + e-posta + şifre.
class ParentRegisterScreen extends ConsumerStatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  ConsumerState<ParentRegisterScreen> createState() =>
      _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends ConsumerState<ParentRegisterScreen> {
  int _currentStep = 0;

  final _codeController = TextEditingController();
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = true;

  String? _validatedCode;
  String? _studentName;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  void _prevStep() {
    context.unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submitRegister() async {
    context.unfocus();
    if (!_step1FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }
    if (_validatedCode == null) {
      context.showSnackBar(AppStrings.errorInviteCodeRequired, isError: true);
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
      context.showSnackBar('Kayıt tamamlandı.');
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
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
              StepProgressIndicator(
                currentStep: _currentStep,
                totalSteps: 2,
                stepTitles: const ['Davet Kodu', 'Hesap Bilgileri'],
                primaryColor: AppColors.parentPrimary,
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0 ? _buildStep0() : _buildStep1(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Zaten kayıtlı mısınız? '),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      'Giriş Yap',
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

  Widget _buildStep0() {
    final authState = ref.watch(parentAuthProvider);

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Öğrenci Davet Kodu', style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text(
          'Öğretmeninizden aldığınız davet kodunu girin.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: AppStrings.inviteCode,
          hint: 'OT-XXXXXX',
          controller: _codeController,
          prefixIcon:
              const Icon(Icons.qr_code_rounded, color: AppColors.textSecondary),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Kodu Doğrula',
          onPressed: _validateCode,
          isLoading: authState.isLoading,
          backgroundColor: AppColors.parentPrimary,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final authState = ref.watch(parentAuthProvider);

    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_studentName != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.parentSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.parentPrimary.withValues(alpha: 0.3),
                ),
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
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
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
                        Text(_studentName!, style: AppTextStyles.h4),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.parentPrimary,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('2. Hesap Bilgileri', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'E-posta ve şifrenizle giriş yapabileceksiniz.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.fullName,
            hint: 'Ad Soyad',
            controller: _nameController,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
            ),
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
            label: 'E-posta',
            hint: 'ornek@mail.com',
            controller: _emailController,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty || !v.contains('@')) {
                return 'Geçerli bir e-posta giriniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: 'Şifre',
            hint: 'En az 6 karakter',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? true),
                activeColor: AppColors.parentPrimary,
              ),
              Expanded(
                child: Text(
                  'Kullanım şartlarını ve KVKK gizlilik politikalarını onaylıyorum.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Geri',
                  onPressed: _prevStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Kaydı Tamamla',
                  onPressed: _submitRegister,
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
