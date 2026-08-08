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
import '../../../../core/services/sms_service.dart';

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

  // Step 1: Ad Soyad & Telefon Numarası (Şifre Alanı YOKTUR!)
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '0531 563 5049');

  // Step 2: SMS Doğrulama Kodu
  final _step2FormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _termsAccepted = true;
  bool _isSendingSms = false;

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

  // ── Adım 2: Telefon Numarasına SMS Gönderme ─────────────────────────────
  Future<void> _sendSmsOtp() async {
    context.unfocus();
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() => _isSendingSms = true);
    final phone = _phoneController.text.trim();
    final res = await SmsService.sendOtp(phone);
    if (!mounted) return;
    setState(() => _isSendingSms = false);

    if (res['success'] == true) {
      context.showSnackBar(res['message'] ?? 'SMS doğrulama kodu gönderildi.');
      setState(() => _currentStep = 2);
    } else {
      context.showSnackBar(res['message'] ?? 'SMS gönderilemedi.', isError: true);
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

    final isValidOtp = await SmsService.verifyOtp(phone, otpCode);
    if (!mounted) return;

    if (!isValidOtp) {
      context.showSnackBar('Doğrulama kodu hatalı veya süresi dolmuş.', isError: true);
      return;
    }

    // Şifresiz arka plan hesabı: Telefon bazlı gizli hash şifre
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
              // ── İlerleme Adımları ─────────────────────────────────────────
              StepProgressIndicator(
                currentStep: _currentStep,
                totalSteps: 3,
                stepTitles: const [
                  'Davet Kodu',
                  'Telefon Numarası',
                  'SMS Doğrulama'
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Zaten kayıtlı mısınız? '),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      'Direkt Giriş Yap',
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

  // ── Adım 1: Davet Kodu ────────────────────────────────────────────────────
  Widget _buildStep0() {
    final authState = ref.watch(parentAuthProvider);

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Öğrenci Davet Kodu', style: AppTextStyles.h3),
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
          prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.textSecondary),
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

  // ── Adım 2: Ad Soyad & Telefon Numarası ────────────────────────────────────
  Widget _buildStep1() {
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
                border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.3)),
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
                    child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 24),
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
                  const Icon(Icons.check_circle_rounded, color: AppColors.parentPrimary, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text('2. Veli Bilgileri & Telefon', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Şifre gerekmez. Telefon numaranıza SMS kodu gönderilecektir.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.fullName,
            hint: 'Ad Soyad',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return AppStrings.errorNameRequired;
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
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
                  isLoading: _isSendingSms,
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

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3. SMS Doğrulama Kodu', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            '${_phoneController.text} numarasına gönderilen 6 haneli doğrulama kodunu girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'SMS Kodu',
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
                    'Test Modu: Tüm telefon numaraları için sabit doğrulama kodu: 123456',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.parentPrimary),
                  ),
                ),
              ],
            ),
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
