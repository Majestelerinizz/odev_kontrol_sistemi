import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

/// AuthRepository'nin Firebase implementasyonu.
class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  // ── Koleksiyon referansları ─────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('invite_codes');

  // ── Auth state akışı ────────────────────────────────────────────────────

  @override
  Stream<AppUser?> get authStateChanges {
    try {
      return _auth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        return getUserProfile(firebaseUser.uid);
      });
    } catch (e) {
      return Stream.value(null);
    }
  }

  @override
  AppUser? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    // Senkron versiyon — sadece uid döner; tam profil için getUserProfile kullanın
    return null;
  }

  // ── Kayıt ──────────────────────────────────────────────────────────────

  @override
  Future<AppUser> registerTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name.trim());

      final now = DateTime.now();
      final userModel = AppUserModel(
        uid: user.uid,
        role: 'teacher',
        name: name.trim(),
        email: email.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Firestore'a kaydet
      await _users.doc(user.uid).set(userModel.toFirestore());

      // Öğretmen profili oluştur
      await _firestore.collection('teacher_profiles').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'classCount': 0,
        'createdAt': now.toIso8601String(),
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AppUser> registerParent({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    try {
      // Davet kodunu doğrula
      final codeData = await validateInviteCode(inviteCode);
      if (codeData == null) {
        throw const AuthException('Geçersiz davet kodu.');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name.trim());

      final now = DateTime.now();
      final studentId = codeData['studentId'] as String;

      final userModel = AppUserModel(
        uid: user.uid,
        role: 'parent',
        name: name.trim(),
        email: email.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Batch write — atomik işlem
      final batch = _firestore.batch();

      // users koleksiyonu
      batch.set(_users.doc(user.uid), userModel.toFirestore());

      // parent_profiles koleksiyonu
      batch.set(
        _firestore.collection('parent_profiles').doc(user.uid),
        {
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'studentIds': [studentId],
          'createdAt': now.toIso8601String(),
        },
      );

      // Öğrenci kaydında parentIds güncelle
      batch.update(
        _firestore.collection('students').doc(studentId),
        {
          'parentIds': FieldValue.arrayUnion([user.uid]),
        },
      );

      // Davet kodunu kullanıldı olarak işaretle
      batch.update(
        _inviteCodes.doc(inviteCode),
        {
          'used': true,
          'usedBy': user.uid,
          'usedAt': now.toIso8601String(),
        },
      );

      await batch.commit();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ── Giriş ──────────────────────────────────────────────────────────────

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      String targetEmail = email.trim();

      // E-posta formatında değilse (telefon numarası veya kullanıcı adı ise) Firestore'dan e-postayı bul
      if (!targetEmail.contains('@')) {
        final query = await _users
            .where('phone', isEqualTo: targetEmail)
            .get();
        if (query.docs.isNotEmpty) {
          targetEmail = query.docs.first.data()['email'] ?? targetEmail;
        } else {
          final nameQuery = await _users
              .where('name', isEqualTo: targetEmail)
              .get();
          if (nameQuery.docs.isNotEmpty) {
            targetEmail = nameQuery.docs.first.data()['email'] ?? targetEmail;
          }
        }
      }

      await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );

      final user = await getUserProfile(_auth.currentUser!.uid);
      if (user == null) throw const AuthException('Kullanıcı profili bulunamadı.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ── Çıkış ──────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Şifre sıfırlama ────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ── Profil getir ────────────────────────────────────────────────────────

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUserModel.fromFirestore(doc.data()!, uid);
      }
    } catch (_) {}

    final fbUser = _auth.currentUser;
    if (fbUser != null && fbUser.uid == uid) {
      return AppUserModel(
        uid: uid,
        role: 'teacher',
        name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Kullanıcı',
        email: fbUser.email ?? '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  // ── Davet kodu doğrulama ────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    final doc = await _inviteCodes.doc(code).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    final used = data['used'] as bool? ?? false;
    if (used) throw const AuthException('Bu davet kodu daha önce kullanılmış.');

    final expiresAt = data['expiresAt'];
    if (expiresAt != null) {
      DateTime expiry;
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
  }

  // ── Firebase hata dönüştürücü ───────────────────────────────────────────

  AuthException _mapAuthException(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' ||
      'invalid-email' =>
        const AuthException('E-posta veya şifre hatalı.'),
      'email-already-in-use' =>
        const AuthException('Bu e-posta adresi zaten kullanılıyor.'),
      'weak-password' => const AuthException('Şifreniz çok zayıf.'),
      'user-disabled' =>
        const AuthException('Hesabınız devre dışı bırakılmıştır.'),
      'network-request-failed' =>
        const AuthException('İnternet bağlantısı kurulamadı.'),
      _ => AuthException('Giriş yapılamadı (${e.code}). Lütfen bilgilerinizi kontrol edin.'),
    };
  }
}

/// Auth işlem hatası
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
