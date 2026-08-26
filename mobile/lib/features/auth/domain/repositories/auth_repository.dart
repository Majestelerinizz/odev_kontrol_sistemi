import '../../domain/entities/app_user.dart';

/// Auth işlemleri için soyut repository arayüzü.
/// Implementasyon `auth_repository_impl.dart` içinde yapılır.
abstract class AuthRepository {
  /// Oturum durumu akışı
  Stream<AppUser?> get authStateChanges;

  /// Mevcut oturum açmış kullanıcı (son bilinen profil; stream ile güncellenir)
  AppUser? get currentUser;

  /// Öğretmen kaydı
  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
  });

  /// Veli kaydı (davet koduyla)
  Future<AppUser> registerParent({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  });

  /// E-posta/şifre ile giriş.
  /// [expectedRole] verilirse profil rolü eşleşmezse oturum kapatılır.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? expectedRole,
  });

  /// Çıkış
  Future<void> signOut();

  /// Hesabı hem Firebase Auth hem Firestore'dan kalıcı olarak sil
  Future<void> deleteAccount();

  /// Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email);

  /// Kullanıcı profilini Firestore'dan getir
  Future<AppUser?> getUserProfile(String uid);

  /// Davet kodunu doğrula
  Future<Map<String, dynamic>?> validateInviteCode(String code);
}
