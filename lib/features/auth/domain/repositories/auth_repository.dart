import '../../domain/entities/app_user.dart';

/// Auth işlemleri için soyut repository arayüzü.
/// Implementasyon `auth_repository_impl.dart` içinde yapılır.
abstract class AuthRepository {
  /// Oturum durumu akışı
  Stream<AppUser?> get authStateChanges;

  /// Mevcut oturum açmış kullanıcı
  AppUser? get currentUser;

  /// Öğretmen kaydı (E-posta + Şifre)
  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
  });

  /// Veli kaydı (Firebase Phone Auth ile doğrulanmış oturum + Davet Kodu)
  /// Atomik olarak Firestore'da profil açar, davet kodunu tüketir ve öğrenciye bağlar.
  Future<AppUser> registerParentWithPhoneAuth({
    required String name,
    required String inviteCode,
  });

  /// E-posta/şifre ile giriş (Öğretmenler için)
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Veli Phone Auth oturumu sonrasında Firestore profilini getirir veya senkronize eder
  Future<AppUser?> syncParentProfileAfterPhoneAuth();

  /// Çıkış
  Future<void> signOut();

  /// Hesabı hem Firebase Auth hem Firestore'dan kalıcı olarak sil
  Future<void> deleteAccount();

  /// Şifre sıfırlama e-postası gönder (Öğretmenler için)
  Future<void> sendPasswordResetEmail(String email);

  /// Kullanıcı profilini Firestore'dan getir
  Future<AppUser?> getUserProfile(String uid);

  /// Davet kodunu doğrula
  Future<Map<String, dynamic>?> validateInviteCode(String code);
}
