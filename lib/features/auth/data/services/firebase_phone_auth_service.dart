// ═══════════════════════════════════════════════════════════════
// lib/features/auth/data/services/firebase_phone_auth_service.dart
//
// Firebase Native Phone Authentication Servisi (Single Source of Truth)
// Android Play Integrity / iOS APNs / Web reCAPTCHA & SMS OTP
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/phone_number_helper.dart';

/// Firebase Telefon Kimlik Doğrulama Durum Modeli
sealed class PhoneAuthState {
  const PhoneAuthState();
}

class PhoneAuthIdle extends PhoneAuthState {
  const PhoneAuthIdle();
}

class PhoneAuthSending extends PhoneAuthState {
  const PhoneAuthSending();
}

class PhoneAuthCodeSent extends PhoneAuthState {
  final String verificationId;
  final int? resendToken;
  final String maskedPhone;

  const PhoneAuthCodeSent({
    required this.verificationId,
    this.resendToken,
    required this.maskedPhone,
  });
}

class PhoneAuthVerifying extends PhoneAuthState {
  const PhoneAuthVerifying();
}

class PhoneAuthSignedIn extends PhoneAuthState {
  final User user;
  final String? idToken;

  const PhoneAuthSignedIn({
    required this.user,
    this.idToken,
  });
}

class PhoneAuthError extends PhoneAuthState {
  final String userMessage;
  final String? errorCode;

  const PhoneAuthError({
    required this.userMessage,
    this.errorCode,
  });
}

/// Firebase Native Phone Authentication Servisi
class FirebasePhoneAuthService {
  final FirebaseAuth _auth;
  ConfirmationResult? _webConfirmationResult;

  FirebasePhoneAuthService({
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  /// SMS Doğrulama Kodu Gönder
  Future<void> sendVerificationCode({
    required String rawPhone,
    int? forceResendingToken,
    required void Function(PhoneAuthState state) onStateChanged,
  }) async {
    final e164Phone = PhoneNumberHelper.normalizeToE164(rawPhone);
    final maskedPhone = PhoneNumberHelper.maskPhoneNumber(e164Phone);

    onStateChanged(const PhoneAuthSending());

    try {
      await _auth.setLanguageCode('tr');

      if (kIsWeb) {
        // FLUTTER WEB: signInWithPhoneNumber
        _webConfirmationResult = await _auth.signInWithPhoneNumber(e164Phone);
        onStateChanged(PhoneAuthCodeSent(
          verificationId: _webConfirmationResult!.verificationId,
          resendToken: null,
          maskedPhone: maskedPhone,
        ));
      } else {
        // MOBİL (Android / iOS)
        await _auth.verifyPhoneNumber(
          phoneNumber: e164Phone,
          timeout: const Duration(seconds: 60),
          forceResendingToken: forceResendingToken,
          verificationCompleted: (PhoneAuthCredential credential) async {
            try {
              onStateChanged(const PhoneAuthVerifying());
              final userCredential =
                  await _auth.signInWithCredential(credential);
              if (userCredential.user != null) {
                final token = await userCredential.user!.getIdToken();
                onStateChanged(PhoneAuthSignedIn(
                  user: userCredential.user!,
                  idToken: token,
                ));
              }
            } catch (e) {
              onStateChanged(PhoneAuthError(
                userMessage: mapFirebaseError(e),
                errorCode: e is FirebaseAuthException ? e.code : null,
              ));
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            onStateChanged(PhoneAuthError(
              userMessage: mapFirebaseError(e),
              errorCode: e.code,
            ));
          },
          codeSent: (String verificationId, int? resendToken) {
            onStateChanged(PhoneAuthCodeSent(
              verificationId: verificationId,
              resendToken: resendToken,
              maskedPhone: maskedPhone,
            ));
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Android otomatik okuma zaman aşımı
          },
        );
      }
    } catch (e) {
      onStateChanged(PhoneAuthError(
        userMessage: mapFirebaseError(e),
        errorCode: e is FirebaseAuthException ? e.code : null,
      ));
    }
  }

  /// Kullanıcının girdiği 6 haneli OTP kodunu doğrula
  Future<UserCredential> verifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final cleanCode = smsCode.trim();
    if (cleanCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
      throw const FormatException(
          'Doğrulama kodu 6 haneli rakamlardan oluşmalıdır.');
    }

    if (kIsWeb && _webConfirmationResult != null) {
      return await _webConfirmationResult!.confirm(cleanCode);
    } else {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: cleanCode,
      );
      return await _auth.signInWithCredential(credential);
    }
  }

  /// Aktif oturumun Firebase ID Token'ını alır
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Firebase Hata Kodlarını Güvenli ve Açıklayıcı Türkçe Mesajlara Dönüştürür
  static String mapFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
        case 'auth/invalid-phone-number':
          return 'Girilen telefon numarası geçersiz. Lütfen 05XX XXX XX XX formatında geçerli bir Türkiye cep telefonu giriniz.';
        case 'invalid-verification-code':
        case 'auth/invalid-verification-code':
          return 'Girdiğiniz 6 haneli SMS doğrulama kodu hatalı.';
        case 'session-expired':
        case 'auth/session-expired':
        case 'code-expired':
        case 'auth/code-expired':
          return 'Doğrulama kodunun geçerlilik süresi dolmuş. Lütfen yeni bir kod isteyiniz.';
        case 'too-many-requests':
        case 'auth/too-many-requests':
          return 'Çok fazla deneme yapıldı. Güvenliğiniz için lütfen biraz bekleyip tekrar deneyin.';
        case 'quota-exceeded':
        case 'auth/quota-exceeded':
          return 'SMS gönderim limiti aşıldı. Lütfen daha sonra tekrar deneyiniz.';
        case 'operation-not-allowed':
        case 'auth/operation-not-allowed':
          return 'Firebase Console üzerinde Telefon Doğrulama (Phone Provider) etkinleştirilmemiş.';
        case 'app-not-authorized':
        case 'auth/app-not-authorized':
          return 'Uygulama Firebase ile yetkilendirilemedi. SHA-1/SHA-256 fingerprint veya Play Integrity ayarlarını kontrol ediniz.';
        case 'billing-not-enabled':
        case 'auth/billing-not-enabled':
          return 'SMS doğrulama hizmeti için Firebase faturalandırması (Blaze planı) etkinleştirilmelidir.';
        case 'captcha-check-failed':
        case 'auth/captcha-check-failed':
          return 'Güvenlik doğrulaması (reCAPTCHA) başarısız oldu. Lütfen tekrar deneyin.';
        case 'network-request-failed':
        case 'auth/network-request-failed':
          return 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.';
        case 'user-disabled':
        case 'auth/user-disabled':
          return 'Bu kullanıcı hesabı devre dışı bırakılmıştır.';
        default:
          return error.message ??
              'Telefon doğrulaması sırasında bir hata oluştu.';
      }
    }
    return 'Beklenmeyen bir hata oluştu: ${error.toString()}';
  }
}
