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
import '../../../../core/extensions/extensions.dart';

/// Veli kayıt ekranı — 2 adım: davet kodu doğrulama + hesap oluşturma
class ParentRegisterScreen extends ConsumerStatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  ConsumerState<ParentRegisterScreen> createState() =>
      _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends ConsumerState<ParentRegisterScreen> {
  int _step = 0; // 0: davet kodu, 1: hesap bilgileri

  // Step 0
  final _codeController = TextEditingController();

  // Step 1
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
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
      setState(() => _step = 1);
    } else {
      final error = ref.read(parentAuthProvider).errorMessage;
      if (error != null) context.showSnackBar(error, isError: true);
    }
  }

  Future<void> _register() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;
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
    final authState = ref.watch(parentAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _buildStep0(authState)
                : _buildStep1(authState),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0(AuthState authState) {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.parentSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            color: AppColors.parentPrimary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text('Veli Hesabı', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text(
          'Öğretmeninizden aldığınız davet kodunu girin.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 32),

        // ── Adım göstergesi ────────────────────────────────────────────
        _StepIndicator(currentStep: 0, totalSteps: 2),
        const SizedBox(height: 32),

        AppTextField(
          label: AppStrings.inviteCode,
          hint: AppStrings.inviteCodeHint,
          controller: _codeController,
          prefixIcon: const Icon(Icons.vpn_key_outlined,
              color: AppColors.textSecondary),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _validateCode(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Davet kodunu öğretmeninizden SMS, WhatsApp veya e-posta ile alabilirsiniz.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
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

  Widget _buildStep1(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.parentSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.parentPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text('Hesap Bilgileriniz', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            _studentName != null
                ? '$_studentName için veli hesabı oluşturuluyor.'
                : 'Hesap bilgilerinizi girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),

          // ── Öğrenci önizleme ───────────────────────────────────────────
          if (_studentName != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.parentSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.parentPrimary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded,
                      color: AppColors.parentPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Öğrenci: $_studentName',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.parentPrimary),
                  ),
                ],
              ),
            ),

          // ── Adım göstergesi ────────────────────────────────────────────
          _StepIndicator(currentStep: 1, totalSteps: 2),
          const SizedBox(height: 32),

          AppTextField(
            label: AppStrings.fullName,
            hint: 'Ad Soyad',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textSecondary),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? AppStrings.errorNameRequired
                : null,
          ),
          const SizedBox(height: AppSizes.itemSpacing),

          AppTextField(
            label: AppStrings.email,
            hint: 'ornek@mail.com',
            controller: _emailController,
            prefixIcon: const Icon(Icons.email_outlined,
                color: AppColors.textSecondary),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return AppStrings.errorEmailRequired;
              if (!v.trim().isValidEmail) return AppStrings.errorEmailInvalid;
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),

          AppTextField(
            label: AppStrings.password,
            hint: 'En az 8 karakter',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textSecondary),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.errorPasswordRequired;
              if (!v.isValidPassword) return AppStrings.errorPasswordMin;
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
            validator: (v) => v != _passwordController.text
                ? AppStrings.errorPasswordMatch
                : null,
          ),
          const SizedBox(height: 20),

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
                child: Text(
                  'Kullanım koşullarını ve gizlilik politikasını kabul ediyorum.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            label: AppStrings.register,
            onPressed: _register,
            isLoading: authState.isLoading,
            backgroundColor: AppColors.parentPrimary,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Adım göstergesi
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.parentPrimary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
