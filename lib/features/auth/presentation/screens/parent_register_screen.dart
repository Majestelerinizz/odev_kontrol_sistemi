import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_providers.dart';
import '../providers/phone_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/step_progress_indicator.dart';
import '../../../../core/utils/phone_number_helper.dart';
import '../../../../core/extensions/extensions.dart';

/// Parolasız Veli Kayıt & Giriş Ekranı — 3 Adımlı Güvenli Wizard Yapısı
/// 1. Davet Kodu Doğrulama -> 2. Telefon Numarası -> 3. SMS OTP Doğrulama & Atomik Firestore Kaydı
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
  String? _normalizedPhone;

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

    final rawPhone = _phoneController.text.trim();
    if (!PhoneNumberHelper.isValidTurkishMobile(rawPhone) &&
        !PhoneNumberHelper.isValidE164(rawPhone)) {
      context.showSnackBar(
        'Lütfen 05XX XXX XX XX formatında geçerli bir cep telefonu numarası giriniz.',
        isError: true,
      );
      return;
    }

    _normalizedPhone = PhoneNumberHelper.normalizeToE164(rawPhone);

    final success = await ref
        .read(phoneAuthNotifierProvider.notifier)
        .sendCode(_normalizedPhone!);

    if (!mounted) return;

    final phoneState = ref.read(phoneAuthNotifierProvider);
    // Android Otomatik Doğrulama (verificationCompleted): Play Services SMS'i
    // kendisi okuyup oturumu açmış olabilir. Yine 3. adıma geçeriz, ancak orada
    // kod alanı yerine "otomatik doğrulandı" bildirimi gösterilir.
    if (success ||
        phoneState.authState is PhoneAuthCodeSent ||
        phoneState.authState is PhoneAuthSignedIn) {
      setState(() => _currentStep = 2);
    } else if (phoneState.authState is PhoneAuthError) {
      final errorMsg = (phoneState.authState as PhoneAuthError).userMessage;
      context.showSnackBar(errorMsg, isError: true);
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

  // ── Adım 3: SMS Kodunu Doğrula ve Atomik Olarak Veli Profilini Kaydet ────
  Future<void> _verifyAndRegister() async {
    context.unfocus();
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }
    if (_validatedCode == null) {
      context.showSnackBar('Davet kodu geçersiz. Lütfen ilk adıma dönünüz.',
          isError: true);
      setState(() => _currentStep = 0);
      return;
    }

    final otpCode = _otpController.text.trim();

    // 1. Firebase Phone Auth ile OTP kodunu doğrula.
    // Android otomatik doğrulamasında oturum Firebase tarafından zaten açılmıştır
    // ve girilecek bir kod yoktur; bu durumda doğrulama adımı atlanır.
    final bool isAutoVerified =
        ref.read(phoneAuthNotifierProvider).authState is PhoneAuthSignedIn;

    final isVerified = isAutoVerified
        ? true
        : await ref
            .read(phoneAuthNotifierProvider.notifier)
            .verifyCode(otpCode);

    if (!mounted) return;

    // KRİTİK GÜVENLİK KURALI: OTP doğrulaması başarısızsa işlem kesinlikle durur!
    if (!isVerified) {
      final phoneState = ref.read(phoneAuthNotifierProvider);
      final errorMsg = phoneState.authState is PhoneAuthError
          ? (phoneState.authState as PhoneAuthError).userMessage
          : 'Girdiğiniz SMS doğrulama kodu geçersiz veya süresi dolmuş.';
      context.showSnackBar(errorMsg, isError: true);
      return;
    }

    // 2. Doğrulanmış Firebase kullanıcısını denetle
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      context.showSnackBar('Oturum doğrulanamadı. Lütfen tekrar deneyin.',
          isError: true);
      return;
    }

    // Telefon numarası eşleşme kontrolü (Yetkisiz kimlik aktarımı engeli)
    if (_normalizedPhone != null &&
        currentUser.phoneNumber != null &&
        currentUser.phoneNumber != _normalizedPhone) {
      context.showSnackBar(
        'Doğrulanan telefon numarası ile kayıt yapılan numara eşleşmiyor.',
        isError: true,
      );
      return;
    }

    // 3. Atomik olarak Firestore'da veli profili oluştur, davet kodunu tüket ve öğrenciye bağla
    final registerSuccess =
        await ref.read(parentAuthProvider.notifier).registerParentWithPhoneAuth(
              name: _nameController.text.trim(),
              inviteCode: _validatedCode!,
            );

    if (!mounted) return;

    if (registerSuccess) {
      context.showSnackBar('✅ Başarıyla doğrulandı ve kaydınız tamamlandı!');
      context.go('/parent/home');
    } else {
      final error = ref.read(parentAuthProvider).errorMessage;
      if (error != null) context.showSnackBar(error, isError: true);
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
                stepTitles: const [
                  'Davet Kodu',
                  'Veli Bilgisi',
                  'SMS Doğrulama'
                ],
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
                    Text('Zaten kayıtlı mısınız? ',
                        style: AppTextStyles.bodySmall),
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
          'Öğretmeninizin öğrenciniz için oluşturduğu özel davet kodunu girin.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: AppStrings.inviteCode,
          hint: 'Örn: OT-4VHAYB veya 4VHAYB',
          controller: _codeController,
          prefixIcon:
              const Icon(Icons.vpn_key_rounded, color: AppColors.textSecondary),
          textCapitalization: TextCapitalization.characters,
          maxLength: 12,
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
                border: Border.all(
                    color: AppColors.parentPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.parentPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Öğrenci: $_studentName',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.parentPrimary),
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
            'SMS doğrulama kodu alacağınız Türkiye cep telefon numaranızı girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Adınız Soyadınız',
            hint: 'Örn: Ahmet Yılmaz',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textSecondary),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Lütfen adınızı giriniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Telefon Numarası',
            hint: '0531 563 5049',
            controller: _phoneController,
            prefixIcon: const Icon(Icons.phone_android_rounded,
                color: AppColors.textSecondary),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendSmsOtp(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Lütfen telefon numaranızı giriniz.';
              }
              if (!PhoneNumberHelper.isValidTurkishMobile(v) &&
                  !PhoneNumberHelper.isValidE164(v)) {
                return '05XX XXX XX XX formatında geçerli bir cep telefonu giriniz.';
              }
              return null;
            },
          ),

          if (phoneState.authState is PhoneAuthError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (phoneState.authState as PhoneAuthError).userMessage,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final isVerifying =
        authState.isLoading || phoneState.authState is PhoneAuthVerifying;

    final maskedNumber = _normalizedPhone != null
        ? PhoneNumberHelper.maskPhoneNumber(_normalizedPhone!)
        : PhoneNumberHelper.maskPhoneNumber(_phoneController.text);

    // Android'de Play Services SMS'i otomatik okuyup oturumu açmış olabilir.
    // Bu durumda girilecek bir kod yoktur; kod alanı ağaçtan tamamen çıkarılır,
    // aksi halde boş alanın validator'ı formu kalıcı olarak kilitler.
    final isAutoVerified = phoneState.authState is PhoneAuthSignedIn;

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAutoVerified ? '3. Telefon Doğrulandı' : '3. SMS Doğrulama Kodu',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            isAutoVerified
                ? '$maskedNumber numarası cihazınız tarafından otomatik olarak doğrulandı. Kaydı tamamlayabilirsiniz.'
                : '$maskedNumber numarasına gönderilen 6 haneli doğrulama kodunu girin.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (isAutoVerified) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SMS kodu otomatik algılandı, doğrulama tamamlandı.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            AppTextField(
              label: '6 Haneli SMS Kodu',
              hint: '______',
              controller: _otpController,
              prefixIcon: const Icon(Icons.mark_chat_unread_rounded,
                  color: AppColors.textSecondary),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onFieldSubmitted: (_) => _verifyAndRegister(),
              validator: (v) {
                if (v == null || v.trim().length != 6) {
                  return 'Lütfen 6 haneli doğrulama kodunu eksiksiz giriniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Otomatik doğrulandıysa tekrar SMS istemek anlamsızdır ve
              // gereksiz Blaze SMS ücreti çıkarır.
              if (isAutoVerified)
                const SizedBox.shrink()
              else if (phoneState.cooldownSeconds > 0)
                Text(
                  'Tekrar kod iste: ${phoneState.cooldownSeconds}s',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                )
              else
                TextButton(
                  onPressed: () =>
                      ref.read(phoneAuthNotifierProvider.notifier).resendCode(),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Tekrar SMS Gönder',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.parentPrimary,
                          fontWeight: FontWeight.bold)),
                ),
              TextButton(
                onPressed: () {
                  ref.read(phoneAuthNotifierProvider.notifier).reset();
                  setState(() => _currentStep = 1);
                },
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Numarayı Değiştir',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
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
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  label: 'Doğrula & Kaydı Tamamla 🚀',
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
