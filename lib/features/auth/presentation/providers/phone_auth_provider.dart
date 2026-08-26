import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/phone_number_helper.dart';
import '../../data/services/firebase_phone_auth_service.dart';
import 'auth_providers.dart';

export '../../data/services/firebase_phone_auth_service.dart';

class PhoneAuthUiState {
  final PhoneAuthState authState;
  final int cooldownSeconds;
  final bool canResend;
  final String? currentPhone;

  const PhoneAuthUiState({
    this.authState = const PhoneAuthIdle(),
    this.cooldownSeconds = 0,
    this.canResend = false,
    this.currentPhone,
  });

  PhoneAuthUiState copyWith({
    PhoneAuthState? authState,
    int? cooldownSeconds,
    bool? canResend,
    String? currentPhone,
  }) {
    return PhoneAuthUiState(
      authState: authState ?? this.authState,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      canResend: canResend ?? this.canResend,
      currentPhone: currentPhone ?? this.currentPhone,
    );
  }
}

class PhoneAuthNotifier extends StateNotifier<PhoneAuthUiState> {
  final FirebasePhoneAuthService _phoneAuthService;
  final Ref _ref;
  Timer? _cooldownTimer;

  PhoneAuthNotifier(this._phoneAuthService, this._ref)
      : super(const PhoneAuthUiState());

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// 60 Saniyelik Tekrar Gönder Sayacı Başlat
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    state = state.copyWith(cooldownSeconds: 60, canResend: false);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.cooldownSeconds > 1) {
        state = state.copyWith(cooldownSeconds: state.cooldownSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0, canResend: true);
      }
    });
  }

  /// SMS Kodu Gönder (E.164 doğrulaması ile)
  Future<bool> sendCode(String phone) async {
    final clean = phone.trim();
    if (clean.isEmpty) {
      state = state.copyWith(
        authState: const PhoneAuthError(
            userMessage: 'Lütfen telefon numaranızı giriniz.'),
      );
      return false;
    }

    if (!PhoneNumberHelper.isValidTurkishMobile(clean) &&
        !PhoneNumberHelper.isValidE164(clean)) {
      state = state.copyWith(
        authState: const PhoneAuthError(
          userMessage:
              'Geçersiz telefon numarası. Lütfen 05XX XXX XX XX formatında 10 haneli geçerli cep numaranızı girin.',
        ),
      );
      return false;
    }

    String e164Phone;
    try {
      e164Phone = PhoneNumberHelper.normalizeToE164(clean);
    } catch (_) {
      state = state.copyWith(
        authState: const PhoneAuthError(
            userMessage: 'Telefon numarası formatı geçersiz.'),
      );
      return false;
    }

    state = state.copyWith(
      currentPhone: e164Phone,
      authState: const PhoneAuthSending(),
    );

    final completer = Completer<bool>();

    await _phoneAuthService.sendVerificationCode(
      rawPhone: e164Phone,
      onStateChanged: (newAuthState) {
        state = state.copyWith(authState: newAuthState);
        if (newAuthState is PhoneAuthCodeSent) {
          _startCooldownTimer();
          if (!completer.isCompleted) completer.complete(true);
        } else if (newAuthState is PhoneAuthSignedIn) {
          _handleSuccessfulAuth();
          if (!completer.isCompleted) completer.complete(true);
        } else if (newAuthState is PhoneAuthError) {
          if (!completer.isCompleted) completer.complete(false);
        }
      },
    );

    // Eğer timeout olursa veya senkron tamamlanmadıysa
    return completer.isCompleted
        ? await completer.future
        : (state.authState is PhoneAuthCodeSent);
  }

  /// Kodu Tekrar Gönder
  Future<void> resendCode() async {
    if (!state.canResend || state.currentPhone == null) return;

    final codeSentState = state.authState is PhoneAuthCodeSent
        ? state.authState as PhoneAuthCodeSent
        : null;

    state = state.copyWith(authState: const PhoneAuthSending());

    await _phoneAuthService.sendVerificationCode(
      rawPhone: state.currentPhone!,
      forceResendingToken: codeSentState?.resendToken,
      onStateChanged: (newAuthState) {
        state = state.copyWith(authState: newAuthState);
        if (newAuthState is PhoneAuthCodeSent) {
          _startCooldownTimer();
        } else if (newAuthState is PhoneAuthSignedIn) {
          _handleSuccessfulAuth();
        }
      },
    );
  }

  /// Kullanıcının girdiği 6 haneli OTP kodunu doğrula
  Future<bool> verifyCode(String code) async {
    if (state.authState is! PhoneAuthCodeSent) {
      state = state.copyWith(
        authState: const PhoneAuthError(
            userMessage: 'Lütfen önce doğrulama kodu isteyiniz.'),
      );
      return false;
    }
    final codeSent = state.authState as PhoneAuthCodeSent;

    final cleanCode = code.trim();
    if (cleanCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
      state = state.copyWith(
        authState: const PhoneAuthError(
            userMessage: 'Doğrulama kodu 6 haneli rakamlardan oluşmalıdır.'),
      );
      return false;
    }

    state = state.copyWith(authState: const PhoneAuthVerifying());

    try {
      final credential = await _phoneAuthService.verifyOtpCode(
        verificationId: codeSent.verificationId,
        smsCode: cleanCode,
      );

      if (credential.user != null) {
        final token = await credential.user!.getIdToken();
        state = state.copyWith(
          authState: PhoneAuthSignedIn(user: credential.user!, idToken: token),
        );
        await _handleSuccessfulAuth();
        return true;
      }
      state = state.copyWith(
        authState: const PhoneAuthError(
            userMessage: 'Doğrulama başarısız oldu. Kullanıcı oluşturulamadı.'),
      );
      return false;
    } catch (e) {
      final String message;
      if (e is FormatException) {
        message = e.message;
      } else {
        message = FirebasePhoneAuthService.mapFirebaseError(e);
      }
      state = state.copyWith(
        authState: PhoneAuthError(userMessage: message),
      );
      return false;
    }
  }

  /// Başarılı Giriş Sonrası Firestore ve Auth Durumunu Senkronize Et
  Future<void> _handleSuccessfulAuth() async {
    // Auth repository üzerinden profili tazele
    _ref.invalidate(authStateProvider);
    _ref.invalidate(currentUserProvider);
  }

  void reset() {
    _cooldownTimer?.cancel();
    state = const PhoneAuthUiState();
  }
}

final firebasePhoneAuthServiceProvider =
    Provider<FirebasePhoneAuthService>((ref) {
  return FirebasePhoneAuthService();
});

final phoneAuthNotifierProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthUiState>((ref) {
  final service = ref.watch(firebasePhoneAuthServiceProvider);
  return PhoneAuthNotifier(service, ref);
});
