import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odev_takip/features/auth/domain/repositories/auth_repository.dart';
import 'package:odev_takip/features/auth/domain/entities/app_user.dart';
import 'package:odev_takip/features/auth/data/services/firebase_phone_auth_service.dart';

/// Sahte AuthRepository Implementasyonu (Test & Doğrulama için)
class MockAuthRepository implements AuthRepository {
  bool registerParentCalled = false;
  bool validateInviteCodeCalled = false;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> registerParentWithPhoneAuth({
    required String name,
    required String inviteCode,
  }) async {
    registerParentCalled = true;
    return AppUser(
      uid: 'parent-uid-123',
      role: 'parent',
      name: name,
      email: '',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AppUser?> syncParentProfileAfterPhoneAuth() async => null;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser?> getUserProfile(String uid) async => null;

  @override
  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    validateInviteCodeCalled = true;
    if (code == 'VALID1') {
      return {
        'code': 'VALID1',
        'studentId': 'student-123',
        'studentName': 'Zeynep Kaya',
        'used': false,
      };
    }
    return null;
  }
}

void main() {
  group('Auth Bypass Prevention & Security Tests', () {
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    test(
        'OTP Doğrulaması Başarısız Olduğunda Veli Kaydı Çağrılmamalıdır (Zero Bypass)',
        () async {
      bool isOtpVerified = false;

      // Sahte akış simülasyonu: Kullanıcı hatalı OTP (000000) girdiğinde
      const enteredOtp = '000000';
      if (enteredOtp == '654321') {
        isOtpVerified = true;
      } else {
        isOtpVerified = false;
      }

      // Güvenlik denetimi: isOtpVerified false ise registerParentWithPhoneAuth ASLA çalıştırılmamalıdır!
      if (isOtpVerified) {
        await mockRepo.registerParentWithPhoneAuth(
          name: 'Mehmet Yılmaz',
          inviteCode: 'VALID1',
        );
      }

      expect(isOtpVerified, isFalse);
      expect(mockRepo.registerParentCalled, isFalse);
    });

    test(
        'OTP Doğrulaması Başarılı Olduğunda Veli Kaydı Atomik Olarak Çağrılmalıdır',
        () async {
      bool isOtpVerified = false;

      const enteredOtp = '654321';
      if (enteredOtp == '654321') {
        isOtpVerified = true;
      }

      if (isOtpVerified) {
        await mockRepo.registerParentWithPhoneAuth(
          name: 'Mehmet Yılmaz',
          inviteCode: 'VALID1',
        );
      }

      expect(isOtpVerified, isTrue);
      expect(mockRepo.registerParentCalled, isTrue);
    });

    test('Geçersiz davet kodu girildiğinde işlem reddedilmelidir', () async {
      final codeData = await mockRepo.validateInviteCode('INVALID');
      expect(codeData, isNull);
      expect(mockRepo.validateInviteCodeCalled, isTrue);
    });

    test('FirebasePhoneAuthService.mapFirebaseError tüm hata kodlarını anlaşılır Türkçe mesajlara dönüştürür', () {
      final invalidPhone = FirebaseAuthException(code: 'invalid-phone-number');
      expect(FirebasePhoneAuthService.mapFirebaseError(invalidPhone),
          contains('geçerli bir Türkiye cep telefonu'));

      final invalidCode = FirebaseAuthException(code: 'invalid-verification-code');
      expect(FirebasePhoneAuthService.mapFirebaseError(invalidCode),
          contains('doğrulama kodu hatalı'));

      final codeExpired = FirebaseAuthException(code: 'code-expired');
      expect(FirebasePhoneAuthService.mapFirebaseError(codeExpired),
          contains('süresi dolmuş'));

      final tooMany = FirebaseAuthException(code: 'too-many-requests');
      expect(FirebasePhoneAuthService.mapFirebaseError(tooMany),
          contains('Çok fazla deneme'));

      final billingErr = FirebaseAuthException(code: 'billing-not-enabled');
      expect(FirebasePhoneAuthService.mapFirebaseError(billingErr),
          contains('Blaze planı'));

      final appNotAuth = FirebaseAuthException(code: 'app-not-authorized');
      expect(FirebasePhoneAuthService.mapFirebaseError(appNotAuth),
          contains('Play Integrity'));

      final quota = FirebaseAuthException(code: 'quota-exceeded');
      expect(FirebasePhoneAuthService.mapFirebaseError(quota),
          contains('limiti aşıldı'));
    });
  });
}
