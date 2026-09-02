import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/utils/phone_utils.dart';

/// Firebase Phone Auth OTP sonucu.
class PhoneOtpSession {
  const PhoneOtpSession({
    required this.verificationId,
    this.resendToken,
    this.autoVerified = false,
  });

  final String verificationId;
  final int? resendToken;
  final bool autoVerified;
}

/// Firebase Phone Auth ile SMS OTP gönderimi ve doğrulama.
class SmsService {
  SmsService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static PhoneOtpSession? _session;
  static bool _recaptchaReady = false;
  static Completer<void>? _recaptchaInit;

  static PhoneOtpSession? get currentSession => _session;

  /// reCAPTCHA Enterprise yapılandırmasını önden yükler (Android/iOS).
  /// Console anahtarları yoksa sessizce geçer; SDK akış içinde yeniden dener.
  static Future<void> ensureRecaptchaReady() async {
    if (kIsWeb || _recaptchaReady) return;
    if (_recaptchaInit != null) return _recaptchaInit!.future;

    final init = Completer<void>();
    _recaptchaInit = init;
    try {
      await _auth.initializeRecaptchaConfig();
      _recaptchaReady = true;
    } catch (e) {
      debugPrint('reCAPTCHA config yüklenemedi: $e');
    } finally {
      if (!init.isCompleted) init.complete();
      _recaptchaInit = null;
    }
  }

  /// OTP SMS gönderir; [verificationId] oturumda saklanır.
  /// Android otomatik SMS okumasında [PhoneOtpSession.autoVerified] true döner.
  static Future<PhoneOtpSession> sendOtp(
    String phoneE164, {
    bool resend = false,
  }) async {
    await ensureRecaptchaReady();

    final completer = Completer<PhoneOtpSession>();
    final forceResend = resend ? _session?.resendToken : null;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResend,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          final session = PhoneOtpSession(
            verificationId: _session?.verificationId ?? '',
            resendToken: _session?.resendToken,
            autoVerified: true,
          );
          _session = session;
          if (!completer.isCompleted) completer.complete(session);
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(_mapError(e));
          }
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(_mapError(e));
        }
      },
      codeSent: (verificationId, resendToken) {
        final session = PhoneOtpSession(
          verificationId: verificationId,
          resendToken: resendToken,
        );
        _session = session;
        if (!completer.isCompleted) completer.complete(session);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (_session == null || _session!.verificationId != verificationId) {
          _session = PhoneOtpSession(
            verificationId: verificationId,
            resendToken: _session?.resendToken,
          );
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        throw const AuthException(
          'SMS gönderimi zaman aşımına uğradı. Bağlantınızı kontrol edip tekrar deneyin.',
        );
      },
    );
  }

  /// OTP kodunu doğrular ve Firebase Auth kullanıcısını döner.
  static Future<User> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final current = _auth.currentUser;
    if (_session?.autoVerified == true && current != null) {
      _session = null;
      return current;
    }

    final vid = verificationId ?? _session?.verificationId;
    if (vid == null || vid.isEmpty) {
      if (current != null) {
        _session = null;
        return current;
      }
      throw const AuthException(
        'Doğrulama oturumu bulunamadı. Lütfen kodu yeniden isteyin.',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthException('Oturum açılamadı.');
      }
      _session = null;
      return user;
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Aynı numaraya OTP yeniden gönderir (Android'de forceResendingToken kullanır).
  static Future<PhoneOtpSession> resendOtp(String phoneE164) async {
    return sendOtp(phoneE164, resend: true);
  }

  static void clearSession() => _session = null;

  static String formatE164FromNational(String nationalDigits) {
    return PhoneUtils.toE164(nationalDigits);
  }

  static AuthException _mapError(Object e) {
    if (e is AuthException) return e;
    if (e is TimeoutException) {
      return const AuthException(
        'SMS gönderimi zaman aşımına uğradı. Tekrar deneyin.',
      );
    }
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-verification-code' =>
          const AuthException('Doğrulama kodu hatalı.'),
        'session-expired' =>
          const AuthException('Kodun süresi doldu. Yeni kod isteyin.'),
        'invalid-phone-number' =>
          const AuthException('Geçersiz telefon numarası.'),
        'too-many-requests' =>
          const AuthException('Çok fazla deneme. Lütfen sonra tekrar deneyin.'),
        'quota-exceeded' =>
          const AuthException('SMS kotası aşıldı. Daha sonra deneyin.'),
        'network-request-failed' =>
          const AuthException('İnternet bağlantısı kurulamadı.'),
        'operation-not-allowed' =>
          const AuthException(
            'Telefon ile giriş Firebase Console\'da açık değil.',
          ),
        'billing-not-enabled' =>
          const AuthException(
            'SMS gönderimi için Blaze faturalandırma planı gerekir.',
          ),
        'missing-client-identifier' ||
        'missing-or-invalid-nonce' ||
        'invalid-app-credential' ||
        'app-not-authorized' =>
          const AuthException(
            'Uygulama doğrulanamadı. Paket adı, SHA-1/SHA-256 ve reCAPTCHA anahtarlarını kontrol edin.',
          ),
        'captcha-check-failed' ||
        'recaptcha-not-enabled' ||
        'missing-recaptcha-token' =>
          const AuthException(
            'reCAPTCHA doğrulaması başarısız. Firebase Authentication ayarlarındaki anahtarları kontrol edin.',
          ),
        'web-context-cancelled' =>
          const AuthException('Doğrulama iptal edildi. Tekrar deneyin.'),
        'play-integrity-check-failed' ||
        'integrity-check-failed' =>
          const AuthException(
            'Play Integrity doğrulaması başarısız. SHA parmak izlerini Firebase\'e ekleyin.',
          ),
        _ => AuthException('SMS doğrulama başarısız (${e.code}).'),
      };
    }
    return AuthException(e.toString());
  }
}
