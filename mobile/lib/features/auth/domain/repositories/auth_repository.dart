import '../entities/app_user.dart';
import '../entities/teacher_auth_preview.dart';

/// Auth işlemleri için soyut repository arayüzü.
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
  });

  /// Veli kaydı — telefon ile doğrulanmış oturum sonrası profil tamamlama.
  Future<AppUser> registerParentWithPhone({
    required String name,
    required String phone,
    required String inviteCode,
    required String studentId,
  });

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? expectedRole,
  });

  /// E-posta için kayıtlı giriş yöntemlerini döner (boş = yeni hesap).
  Future<List<String>> fetchSignInMethodsForEmail(String email);

  /// Öğretmen giriş/kayıt önizlemesi (isim + rol).
  Future<TeacherAuthPreview> getTeacherAuthPreview(String email);

  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> sendPasswordResetEmail(String email);
  Future<AppUser?> getUserProfile(String uid);
  Future<Map<String, dynamic>?> validateInviteCode(String code);
}
