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
/// Web ve Mobil (Android/iOS) platformlarında Google SMS Gateway OTP gönderimini yönetir.
class FirebasePhoneAuthService {
  final FirebaseAuth _auth;
  ConfirmationResult? _webConfirmationResult;

  FirebasePhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// SMS Doğrulama Kodu Gönder (Web için signInWithPhoneNumber, Mobil için verifyPhoneNumber)
  Future<void> sendVerificationCode({
    required String rawPhone,
    int? forceResendingToken,
    required void Function(PhoneAuthState state) onStateChanged,
  }) async {
    final e164Phone = PhoneNumberHelper.normalizeToE164(rawPhone);
    final maskedPhone = PhoneNumberHelper.maskPhoneNumber(e164Phone);

    onStateChanged(const PhoneAuthSending());

    try {
      // Türkçe SMS yerelleştirmesi
      await _auth.setLanguageCode('tr');

      if (kIsWeb) {
        // ── FLUTTER WEB (reCAPTCHA + Google SMS Gateway) ───────────────────
        _webConfirmationResult = await _auth.signInWithPhoneNumber(e164Phone);
        onStateChanged(PhoneAuthCodeSent(
          verificationId: _webConfirmationResult!.verificationId,
          resendToken: null,
          maskedPhone: maskedPhone,
        ));
      } else {
        // ── MOBİL (Android Play Integrity + iOS APNs) ──────────────────────
        await _auth.verifyPhoneNumber(
          phoneNumber: e164Phone,
          timeout: const Duration(seconds: 60),
          forceResendingToken: forceResendingToken,
          verificationCompleted: (PhoneAuthCredential credential) async {
            try {
              onStateChanged(const PhoneAuthVerifying());
              final userCredential = await _auth.signInWithCredential(credential);
              if (userCredential.user != null) {
                final token = await userCredential.user!.getIdToken();
                onStateChanged(PhoneAuthSignedIn(user: userCredential.user!, idToken: token));
              }
            } catch (e) {
              onStateChanged(PhoneAuthError(userMessage: _mapFirebaseError(e)));
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            onStateChanged(PhoneAuthError(
              userMessage: _mapFirebaseError(e),
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
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      onStateChanged(PhoneAuthError(userMessage: _mapFirebaseError(e)));
    }
  }

  /// Kullanıcının girdiği 6 haneli OTP kodunu doğrula
  Future<UserCredential> verifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final cleanCode = smsCode.trim();
    if (cleanCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
      throw const FormatException('Doğrulama kodu 6 haneli rakamlardan oluşmalıdır.');
    }

    if (kIsWeb && _webConfirmationResult != null) {
      // Web doğrulama
      return await _webConfirmationResult!.confirm(cleanCode);
    } else {
      // Mobil doğrulama
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: cleanCode,
      );
      return await _auth.signInWithCredential(credential);
    }
  }

  /// Firebase Hata Kodlarını Kullanıcı Dostu Türkçe Mesajlara Dönüştürür
  static String _mapFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
        case 'auth/invalid-phone-number':
          return 'Girilen telefon numarası geçersiz. Lütfen kontrol ediniz.';
        case 'invalid-verification-code':
        case 'auth/invalid-verification-code':
          return 'Girdiğiniz 6 haneli doğrulama kodu hatalı.';
        case 'session-expired':
        case 'auth/code-expired':
          return 'Doğrulama kodunun süresi doldu. Lütfen tekrar kod isteyiniz.';
        case 'too-many-requests':
        case 'auth/too-many-requests':
        case 'auth/quota-exceeded':
          return 'Çok fazla doğrulama isteği gönderildi. Lütfen biraz bekleyip tekrar deneyin.';
        case 'captcha-check-failed':
        case 'auth/captcha-check-failed':
          return 'Güvenlik doğrulaması (reCAPTCHA) başarısız oldu. Lütfen tekrar deneyin.';
        case 'network-request-failed':
          return 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.';
        default:
          return error.message ?? 'Telefon doğrulaması sırasında bir hata oluştu.';
      }
    }
    return 'Beklenmeyen bir hata oluştu: ${error.toString()}';
  }
}
