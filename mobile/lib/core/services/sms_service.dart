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
  });

  final String verificationId;
  final int? resendToken;
}

/// Firebase Phone Auth ile SMS OTP gönderimi ve doğrulama.
class SmsService {
  SmsService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static PhoneOtpSession? _session;

  static PhoneOtpSession? get currentSession => _session;

  /// OTP SMS gönderir; [verificationId] oturumda saklanır.
  static Future<PhoneOtpSession> sendOtp(String phoneE164) async {
    final completer = Completer<PhoneOtpSession>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android otomatik doğrulama — hemen giriş
        try {
          await _auth.signInWithCredential(credential);
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
        if (!completer.isCompleted) {
          completer.complete(session);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _session = PhoneOtpSession(verificationId: verificationId);
      },
    );

    return completer.future;
  }

  /// OTP kodunu doğrular ve Firebase Auth oturumu açar.
  static Future<UserCredential> verifyOtp({
    required String smsCode,
    String? verificationId,
  }) async {
    final vid = verificationId ?? _session?.verificationId;
    if (vid == null || vid.isEmpty) {
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
      _session = null;
      return result;
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Aynı numaraya OTP yeniden gönderir.
  static Future<PhoneOtpSession> resendOtp(String phoneE164) async {
    return sendOtp(phoneE164);
  }

  static void clearSession() => _session = null;

  static String formatE164FromNational(String nationalDigits) {
    return PhoneUtils.toE164(nationalDigits);
  }

  static AuthException _mapError(Object e) {
    if (e is AuthException) return e;
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
        _ => AuthException(
            'SMS doğrulama başarısız (${e.code}).',
          ),
      };
    }
    return AuthException(e.toString());
  }
}
