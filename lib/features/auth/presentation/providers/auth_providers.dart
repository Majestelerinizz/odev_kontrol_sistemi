import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// ── Auth state akışı ─────────────────────────────────────────────────────────

/// Mevcut oturum durumu stream'i.
/// null → giriş yok, AppUser → giriş var
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Mevcut oturum açmış kullanıcı (senkron erişim için)
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ── Auth işlem durumu ─────────────────────────────────────────────────────────

/// Auth ekranları için işlem durumu (giriş, kayıt, şifre sıfırlama)
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  AuthState get loading => const AuthState(isLoading: true);
  AuthState error(String message) => AuthState(errorMessage: message);
  AuthState get success => const AuthState(isSuccess: true);
}

// ── Öğretmen Auth Notifier ───────────────────────────────────────────────────

class TeacherAuthNotifier extends StateNotifier<AuthState> {
  TeacherAuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> registerTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.loading;
    try {
      await _repo.registerTeacher(name: name, email: email, password: password);
      state = state.success;
    } on AuthException catch (e) {
      state = state.error(e.message);
    } catch (_) {
      state = state.error('Beklenmeyen bir hata oluştu.');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.loading;
    try {
      await _repo.signInWithEmailAndPassword(email: email, password: password);
      state = state.success;
    } on AuthException catch (e) {
      state = state.error(e.message);
    } catch (_) {
      state = state.error('Beklenmeyen bir hata oluştu.');
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  void clearError() => state = const AuthState();
}

final teacherAuthProvider =
    StateNotifierProvider<TeacherAuthNotifier, AuthState>((ref) {
  return TeacherAuthNotifier(ref.watch(authRepositoryProvider));
});

// ── Veli Auth Notifier ───────────────────────────────────────────────────────

class ParentAuthNotifier extends StateNotifier<AuthState> {
  ParentAuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  /// Davet kodu önizleme bilgisi
  Map<String, dynamic>? inviteCodeData;

  Future<bool> validateInviteCode(String code) async {
    state = state.loading;
    try {
      final data = await _repo.validateInviteCode(code);
      if (data == null) {
        state = state.error('Geçersiz davet kodu.');
        return false;
      }
      inviteCodeData = data;
      state = const AuthState();
      return true;
    } on AuthException catch (e) {
      state = state.error(e.message);
      return false;
    } catch (_) {
      state = state.error('Davet kodu doğrulanamadı.');
      return false;
    }
  }

  /// Doğrulanmış Firebase Phone Auth oturumu ile veli profili oluşturur ve davet kodunu tüketir
  Future<bool> registerParentWithPhoneAuth({
    required String name,
    required String inviteCode,
  }) async {
    state = state.loading;
    try {
      await _repo.registerParentWithPhoneAuth(
        name: name,
        inviteCode: inviteCode,
      );
      state = state.success;
      return true;
    } on AuthException catch (e) {
      state = state.error(e.message);
      return false;
    } catch (_) {
      state =
          state.error('Veli kaydı oluşturulurken beklenmeyen bir hata oluştu.');
      return false;
    }
  }

  /// Telefon ile başarılı OTP doğrulaması sonrasında Firestore profilini eşitler
  Future<bool> syncParentProfile() async {
    state = state.loading;
    try {
      final user = await _repo.syncParentProfileAfterPhoneAuth();
      if (user != null) {
        state = state.success;
        return true;
      }
      state = state.error('Kullanıcı profili senkronize edilemedi.');
      return false;
    } on AuthException catch (e) {
      state = state.error(e.message);
      return false;
    } catch (_) {
      state =
          state.error('Giriş profili senkronize edilirken bir hata oluştu.');
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  void clearError() => state = const AuthState();
}

final parentAuthProvider =
    StateNotifierProvider<ParentAuthNotifier, AuthState>((ref) {
  return ParentAuthNotifier(ref.watch(authRepositoryProvider));
});

// ── Şifre sıfırlama notifier ─────────────────────────────────────────────────

class PasswordResetNotifier extends StateNotifier<AuthState> {
  PasswordResetNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> sendResetEmail(String email) async {
    state = state.loading;
    try {
      await _repo.sendPasswordResetEmail(email);
      state = state.success;
    } on AuthException catch (e) {
      state = state.error(e.message);
    } catch (_) {
      state = state.error('E-posta gönderilemedi.');
    }
  }
}

final passwordResetProvider =
    StateNotifierProvider<PasswordResetNotifier, AuthState>((ref) {
  return PasswordResetNotifier(ref.watch(authRepositoryProvider));
});
