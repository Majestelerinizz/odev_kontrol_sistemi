import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

/// AuthRepository'nin Firebase implementasyonu.
class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;
  AppUser? _cachedUser;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('invite_codes');

  @override
  Stream<AppUser?> get authStateChanges {
    try {
      return _auth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) {
          _cachedUser = null;
          return null;
        }
        // Kayıt/giriş az önce profili yazdıysa stream yarışını önle
        if (_cachedUser?.uid == firebaseUser.uid) {
          return _cachedUser;
        }
        try {
          final profile = await getUserProfile(firebaseUser.uid);
          _cachedUser = profile;
          return profile;
        } on AuthException {
          _cachedUser = null;
          return null;
        } catch (_) {
          _cachedUser = null;
          return null;
        }
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user!;
      await createdUser.updateDisplayName(name.trim());

      final now = DateTime.now();
      final userModel = AppUserModel(
        uid: createdUser.uid,
        role: 'teacher',
        name: name.trim(),
        email: email.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _users.doc(createdUser.uid).set(userModel.toFirestore());

      await _firestore.collection('teacher_profiles').doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'name': name.trim(),
        'email': email.trim(),
        'classCount': 0,
        'createdAt': now.toIso8601String(),
      });

      _cachedUser = userModel;
      return userModel;
    } catch (e) {
      if (e is FirebaseAuthException &&
          (e.code == 'email-already-in-use' || e.code == 'EMAIL_EXISTS')) {
        throw const AuthException(
          'Bu e-posta adresi zaten kayıtlı. Lütfen Giriş Yap ekranından şifrenizle giriş yapınız.',
        );
      }
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw _mapException(e);
    }
  }

  @override
  Future<AppUser> registerParent({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
    required String studentId,
  }) async {
    User? createdUser;
    try {
      final codeData = await validateInviteCode(inviteCode);
      if (codeData == null) {
        throw const AuthException('Geçersiz davet kodu.');
      }

      final resolvedStudentId = _resolveStudentId(codeData, studentId);
      final now = DateTime.now();

      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        createdUser = credential.user!;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use' || e.code == 'EMAIL_EXISTS') {
          return _linkInviteToExistingParent(
            name: name,
            email: email,
            password: password,
            inviteCode: inviteCode,
            studentId: resolvedStudentId,
            inviteType: codeData['type'] as String? ?? 'student',
            now: now,
          );
        }
        rethrow;
      }

      await createdUser.updateDisplayName(name.trim());

      final userModel = AppUserModel(
        uid: createdUser.uid,
        role: 'parent',
        name: name.trim(),
        email: email.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _commitParentInviteBinding(
        uid: createdUser.uid,
        userModel: userModel,
        name: name.trim(),
        email: email.trim(),
        studentId: resolvedStudentId,
        inviteCode: inviteCode,
        inviteType: codeData['type'] as String? ?? 'student',
        now: now,
        mergeUser: false,
      );

      _cachedUser = userModel;
      return userModel;
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw _mapException(e);
    }
  }

  String _resolveStudentId(Map<String, dynamic> codeData, String studentId) {
    final type = codeData['type'] as String? ??
        (codeData['classId'] != null ? 'class' : 'student');

    if (type == 'class') {
      if (studentId.isEmpty) {
        throw const AuthException('Lütfen çocuğunuzu listeden seçin.');
      }
      final students = codeData['students'] as List<dynamic>? ?? [];
      final ids = students
          .whereType<Map>()
          .map((e) => e['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!ids.contains(studentId)) {
        throw const AuthException(
          'Seçilen öğrenci bu sınıf davet koduna ait değil.',
        );
      }
      return studentId;
    }

    final legacyId = codeData['studentId'] as String?;
    if (legacyId == null || legacyId.isEmpty) {
      throw const AuthException('Geçersiz davet kodu.');
    }
    return legacyId;
  }

  Future<AppUser> _linkInviteToExistingParent({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
    required String studentId,
    required String inviteType,
    required DateTime now,
  }) async {
    late final User user;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user!;
    } catch (_) {
      throw const AuthException(
        'Bu e-posta zaten kayıtlı. Şifreniz doğruysa tekrar deneyin; '
        'değilse Giriş Yap ekranından giriş yapın veya şifre sıfırlayın.',
      );
    }

    final existing = await getUserProfile(user.uid);
    if (existing != null && existing.role != 'parent') {
      await _auth.signOut();
      _cachedUser = null;
      throw const AuthException(
        'Bu e-posta bir veli hesabı değil. Doğru hesapla giriş yapın.',
      );
    }

    await user.updateDisplayName(name.trim());

    final userModel = AppUserModel(
      uid: user.uid,
      role: 'parent',
      name: name.trim(),
      email: email.trim(),
      isActive: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _commitParentInviteBinding(
      uid: user.uid,
      userModel: userModel,
      name: name.trim(),
      email: email.trim(),
      studentId: studentId,
      inviteCode: inviteCode,
      inviteType: inviteType,
      now: now,
      mergeUser: true,
    );

    _cachedUser = userModel;
    return userModel;
  }

  Future<void> _commitParentInviteBinding({
    required String uid,
    required AppUserModel userModel,
    required String name,
    required String email,
    required String studentId,
    required String inviteCode,
    required String inviteType,
    required DateTime now,
    required bool mergeUser,
  }) async {
    final batch = _firestore.batch();

    if (mergeUser) {
      batch.set(
        _users.doc(uid),
        userModel.toFirestore(),
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection('parent_profiles').doc(uid),
        {
          'uid': uid,
          'name': name,
          'email': email,
          'studentIds': FieldValue.arrayUnion([studentId]),
          'updatedAt': now.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } else {
      batch.set(_users.doc(uid), userModel.toFirestore());
      batch.set(
        _firestore.collection('parent_profiles').doc(uid),
        {
          'uid': uid,
          'name': name,
          'email': email,
          'studentIds': [studentId],
          'createdAt': now.toIso8601String(),
        },
      );
    }

    batch.update(
      _firestore.collection('students').doc(studentId),
      {
        'parentIds': FieldValue.arrayUnion([uid]),
      },
    );

    // Sınıf kodları yeniden kullanılabilir; yalnızca eski öğrenci kodlarını işaretle
    if (inviteType != 'class') {
      batch.update(
        _inviteCodes.doc(inviteCode),
        {
          'used': true,
          'usedBy': uid,
          'usedAt': now.toIso8601String(),
        },
      );
    }

    await batch.commit();
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? expectedRole,
  }) async {
    try {
      final targetEmail = email.trim();
      if (!targetEmail.contains('@')) {
        throw const AuthException(
          'Lütfen geçerli bir e-posta adresi giriniz.',
        );
      }

      await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );

      final user = await getUserProfile(_auth.currentUser!.uid);
      if (user == null) {
        await _auth.signOut();
        throw const AuthException('Kullanıcı profili bulunamadı.');
      }

      if (expectedRole != null && user.role != expectedRole) {
        await _auth.signOut();
        _cachedUser = null;
        final label = expectedRole == 'teacher' ? 'öğretmen' : 'veli';
        throw AuthException(
          'Bu hesap $label girişi için uygun değil. Doğru rol sekmesini seçin.',
        );
      }

      if (user.isActive == false) {
        await _auth.signOut();
        _cachedUser = null;
        throw const AuthException('Hesabınız pasif durumda.');
      }

      _cachedUser = user;
      return user;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    try {
      await _users.doc(uid).delete();
      await _firestore.collection('teacher_profiles').doc(uid).delete();
      await _firestore.collection('parent_profiles').doc(uid).delete();
      await user.delete();
      _cachedUser = null;
      await _auth.signOut();
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (_) {}
      _cachedUser = null;
      throw _mapException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUserModel.fromFirestore(doc.data()!, uid);
      }
    } on FirebaseException catch (e) {
      // Sessiz yutma: permission-denied profili null gösterip welcome'a atıyordu
      if (e.code == 'permission-denied') {
        throw const AuthException(
          'Veritabanı erişim yetkisi yetersiz. Firestore kuralları deploy edilmiş mi?',
        );
      }
      rethrow;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    try {
      final doc = await _inviteCodes.doc(code.trim().toUpperCase()).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = Map<String, dynamic>.from(doc.data()!);
      data['code'] = doc.id;

      final type = data['type'] as String? ??
          (data['classId'] != null ? 'class' : 'student');
      data['type'] = type;

      final revoked = data['revoked'] as bool? ?? false;
      if (revoked) {
        throw const AuthException('Bu davet kodu iptal edilmiş.');
      }

      if (type != 'class') {
        final used = data['used'] as bool? ?? false;
        if (used) {
          throw const AuthException('Bu davet kodu daha önce kullanılmış.');
        }
      }

      final expiresAt = data['expiresAt'];
      if (expiresAt != null) {
        final DateTime expiry;
        if (expiresAt is String) {
          expiry = DateTime.parse(expiresAt);
        } else {
          expiry = (expiresAt as Timestamp).toDate();
        }
        if (DateTime.now().isAfter(expiry)) {
          throw const AuthException('Bu davet kodunun süresi dolmuş.');
        }
      }

      return data;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw _mapException(e);
    }
  }

  Exception _mapException(Object e) {
    if (e is AuthException) return e;

    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          const AuthException('E-posta veya şifre hatalı.'),
        'invalid-email' =>
          const AuthException('Geçersiz e-posta adresi biçimi.'),
        'email-already-in-use' =>
          const AuthException(
            'Bu e-posta adresi zaten kullanılıyor. Giriş yapmayı deneyin.',
          ),
        'weak-password' =>
          const AuthException(
            'Şifreniz çok zayıf. En az 6 karakter olmalıdır.',
          ),
        'user-disabled' =>
          const AuthException('Hesabınız devre dışı bırakılmıştır.'),
        'network-request-failed' =>
          const AuthException(
            'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.',
          ),
        'too-many-requests' =>
          const AuthException(
            'Çok fazla hatalı deneme yapıldı. Lütfen daha sonra tekrar deneyin.',
          ),
        _ => AuthException(
            'Giriş/Kayıt başarısız (${e.code}). Lütfen tekrar deneyin.',
          ),
      };
    }

    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return const AuthException('Veritabanı erişim yetkisi yetersiz.');
      }
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return const AuthException('Sunucuya veya internete erişilemiyor.');
      }
      return AuthException(
        'İşlem başarısız (${e.code}): ${e.message ?? 'Lütfen tekrar deneyin.'}',
      );
    }

    return AuthException(e.toString().replaceAll('Exception: ', ''));
  }
}

/// Auth işlem hatası
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
