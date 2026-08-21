import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/phone_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/step_progress_indicator.dart';
import '../../../../core/extensions/extensions.dart';

/// Parolasız Veli Kayıt & Giriş Ekranı — 3 Adımlı Şifresiz Wizard Yapısı
/// 1. Davet Kodu -> 2. Telefon Numarası -> 3. SMS Doğrulama Kodu -> Sonsuza Kadar Açık Giriş
class ParentRegisterScreen extends ConsumerStatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  ConsumerState<ParentRegisterScreen> createState() =>
      _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends ConsumerState<ParentRegisterScreen> {
  int _currentStep = 0;

  // Step 0: Davet Kodu
  final _codeController = TextEditingController();

  // Step 1: Ad Soyad & Telefon Numarası
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2: SMS Doğrulama Kodu
  final _step2FormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _termsAccepted = true;

  String? _validatedCode;
  String? _studentName;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Adım 1: Davet Kodu Doğrulama ─────────────────────────────────────────
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

  // ── Adım 2: Telefon Numarasına Firebase SMS Gönderme ─────────────────────
  Future<void> _sendSmsOtp() async {
    context.unfocus();
    if (!_step1FormKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    await ref.read(phoneAuthNotifierProvider.notifier).sendCode(phone);

    if (!mounted) return;
    setState(() => _currentStep = 2);
  }

  void _prevStep() {
    context.unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  // ── Adım 3: SMS Kodunu Doğrula ve Şifresiz Kalıcı Giriş Yap ─────────────
  Future<void> _verifyAndRegister() async {
    context.unfocus();
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }

    final phone = _phoneController.text.trim();
    final otpCode = _otpController.text.trim();

    // Firebase Phone Auth ile doğrula
    await ref.read(phoneAuthNotifierProvider.notifier).verifyCode(otpCode);

    final autoEmail = 'parent_${phone.replaceAll(RegExp(r'\D'), '')}@matpusula.app';
    final autoPassword = 'MatPusula_Passless_${phone.replaceAll(RegExp(r'\D'), '')}';

    await ref.read(parentAuthProvider.notifier).registerParent(
          name: _nameController.text.trim(),
          email: autoEmail,
          password: autoPassword,
          inviteCode: _validatedCode!,
        );

    if (!mounted) return;
    final state = ref.read(parentAuthProvider);
    if (state.isSuccess) {
      context.showSnackBar('✅ Başarıyla doğrulandı! Çıkış yapana kadar hesabınız açık kalacaktır.');
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
          'Veli Telefon Kaydı',
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
                totalSteps: 3,
                currentStep: _currentStep,
                primaryColor: AppColors.parentPrimary,
                stepTitles: const ['Davet Kodu', 'Veli Bilgisi', 'SMS Doğrulama'],
              ),
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),

              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Zaten kayıtlı mısınız? ', style: AppTextStyles.bodySmall),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Direkt Giriş Yap',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.parentPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
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

  // ── Adım 1: Davet Kodu ───────────────────────────────────────────────────
  Widget _buildStep0() {
    final authState = ref.watch(parentAuthProvider);

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Davet Kodunuzu Girin', style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text(
          'Öğretmeninizin öğrenciniz için oluşturduğu 6 haneli özel kodu girin.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: AppStrings.inviteCode,
          hint: 'Örn: AB12CD',
          controller: _codeController,
          prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.textSecondary),
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _validateCode(),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Kodu Doğrula →',
          onPressed: _validateCode,
          isLoading: authState.isLoading,
          backgroundColor: AppColors.parentPrimary,
        ),
      ],
    );
  }

  // ── Adım 2: Veli Ad Soyad & Telefon ──────────────────────────────────────
  Widget _buildStep1() {
    final phoneState = ref.watch(phoneAuthNotifierProvider);
    final isSending = phoneState.authState is PhoneAuthSending;

    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_studentName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.parentSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.parentPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Öğrenci: $_studentName',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.parentPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('2. Veli Bilgileri', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'SMS doğrulama kodu alacağınız telefon numaranızı girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Adınız Soyadınız',
            hint: 'Örn: Ahmet Yılmaz',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Lütfen adınızı giriniz.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Telefon Numarası',
            hint: '0531 563 5049',
            controller: _phoneController,
            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.textSecondary),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().length < 10) return 'Geçerli bir telefon numarası giriniz.';
              return null;
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '← Değiştir',
                  onPressed: _prevStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'SMS Kodu Gönder 📩',
                  onPressed: _sendSmsOtp,
                  isLoading: isSending,
                  backgroundColor: AppColors.parentPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Adım 3: SMS Kodu Doğrulama & Şifresiz Kalıcı Giriş ────────────────────
  Widget _buildStep2() {
    final authState = ref.watch(parentAuthProvider);
    final phoneState = ref.watch(phoneAuthNotifierProvider);
    final isVerifying = authState.isLoading || phoneState.authState is PhoneAuthVerifying;

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3. SMS Doğrulama Kodu', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            '${_phoneController.text} numarasına Firebase üzerinden gönderilen 6 haneli doğrulama kodunu girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: '6 Haneli SMS Kodu',
            hint: '123456',
            controller: _otpController,
            prefixIcon: const Icon(Icons.mark_chat_unread_rounded, color: AppColors.textSecondary),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().length < 6) return '6 haneli doğrulama kodunu giriniz.';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (phoneState.cooldownSeconds > 0)
                Text(
                  'Tekrar kod iste: ${phoneState.cooldownSeconds}s',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                )
              else
                TextButton(
                  onPressed: () => ref.read(phoneAuthNotifierProvider.notifier).resendCode(),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Tekrar SMS Gönder', style: TextStyle(fontSize: 12, color: AppColors.parentPrimary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? true),
                activeColor: AppColors.parentPrimary,
              ),
              const Expanded(
                child: Text(
                  'Kullanım şartlarını ve KVKK gizlilik politikalarını onaylıyorum.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  label: 'Doğrula & Giriş Yap 🚀',
                  onPressed: _verifyAndRegister,
                  isLoading: isVerifying,
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
