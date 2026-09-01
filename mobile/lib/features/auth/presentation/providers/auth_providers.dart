import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/teacher_auth_preview.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

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

// ── Davet linki ön doldurma ───────────────────────────────────────────────────

class InvitePrefill {
  const InvitePrefill({this.code, this.studentId});

  final String? code;
  final String? studentId;

  bool get hasCode => code != null && code!.isNotEmpty;
}

class InvitePrefillNotifier extends StateNotifier<InvitePrefill> {
  InvitePrefillNotifier() : super(const InvitePrefill());

  void setPrefill({String? code, String? studentId}) {
    state = InvitePrefill(
      code: code?.trim().toUpperCase(),
      studentId: studentId?.trim(),
    );
  }

  void clearCode() => state = InvitePrefill(studentId: state.studentId);
  void clear() => state = const InvitePrefill();
}

final invitePrefillProvider =
    StateNotifierProvider<InvitePrefillNotifier, InvitePrefill>((ref) {
  return InvitePrefillNotifier();
});

// ── Öğretmen Auth ─────────────────────────────────────────────────────────────

class TeacherAuthNotifier extends StateNotifier<AuthState> {
  TeacherAuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;
  TeacherAuthPreview? lastPreview;

  Future<TeacherAuthPreview?> checkEmail(String email) async {
    state = state.loading;
    try {
      final methods = await _repo.fetchSignInMethodsForEmail(email);
      final hasAuthAccount = methods.isNotEmpty;

      if (!hasAuthAccount) {
        lastPreview = const TeacherAuthPreview(exists: false);
        state = const AuthState();
        return lastPreview;
      }

      final preview = await _repo.getTeacherAuthPreview(email);
      lastPreview = preview;

      if (preview.isParent) {
        state = state.error(
          'Bu e-posta bir veli hesabına ait. Öğretmen olarak devam edemezsiniz.',
        );
        return null;
      }

      state = const AuthState();
      return preview.exists
          ? preview
          : TeacherAuthPreview(exists: true, name: preview.name);
    } on AuthException catch (e) {
      state = state.error(e.message);
      return null;
    } catch (_) {
      state = state.error('E-posta kontrol edilemedi.');
      return null;
    }
  }

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
      await _repo.signInWithEmailAndPassword(
        email: email,
        password: password,
        expectedRole: 'teacher',
      );
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
    lastPreview = null;
  }

  void clearError() => state = const AuthState();
}

final teacherAuthProvider =
    StateNotifierProvider<TeacherAuthNotifier, AuthState>((ref) {
  return TeacherAuthNotifier(ref.watch(authRepositoryProvider));
});

// ── Veli Auth ─────────────────────────────────────────────────────────────────

class ParentAuthNotifier extends StateNotifier<AuthState> {
  ParentAuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;
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

  Future<AppUser?> loadCurrentProfile(String uid) async {
    try {
      return await _repo.getUserProfile(uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> registerParentWithPhone({
    required String name,
    required String phone,
    required String inviteCode,
    required String studentId,
  }) async {
    state = state.loading;
    try {
      await _repo.registerParentWithPhone(
        name: name,
        phone: phone,
        inviteCode: inviteCode,
        studentId: studentId,
      );
      state = state.success;
    } on AuthException catch (e) {
      state = state.error(e.message);
    } catch (_) {
      state = state.error('Kayıt tamamlanamadı.');
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    inviteCodeData = null;
    state = const AuthState();
  }

  void clearError() => state = const AuthState();
  void clearInviteData() => inviteCodeData = null;
}

final parentAuthProvider =
    StateNotifierProvider<ParentAuthNotifier, AuthState>((ref) {
  return ParentAuthNotifier(ref.watch(authRepositoryProvider));
});

// ── Şifre sıfırlama ───────────────────────────────────────────────────────────

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
