import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';
import '../services/backend_auth_service.dart';

/// AuthRepository'nin Firebase implementasyonu.
class AuthRepositoryImpl implements AuthRepository {
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ?? FirebaseFirestore.instance;

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
    return null;
  }

  // ── Öğretmen Kaydı ──────────────────────────────────────────────────────

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

      // Firestore'a kaydet
      await _users.doc(createdUser.uid).set(userModel.toFirestore());

      // Öğretmen profili oluştur
      await _firestore.collection('teacher_profiles').doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'name': name.trim(),
        'email': email.trim(),
        'classCount': 0,
        'createdAt': now.toIso8601String(),
      });

      // Backend PostgreSQL ile Firebase ID Token üzerinden oturum doğrula ve eşitle
      try {
        final idToken = await createdUser.getIdToken();
        if (idToken != null) {
          await BackendAuthService.instance.verifySession(
            idToken: idToken,
            name: name.trim(),
            role: 'teacher',
          );
        }
      } catch (_) {}

      return userModel;
    } catch (e) {
      if (e is FirebaseAuthException &&
          (e.code == 'email-already-in-use' || e.code == 'EMAIL_EXISTS')) {
        try {
          final credential = await _auth.signInWithEmailAndPassword(
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

          await _users
              .doc(user.uid)
              .set(userModel.toFirestore(), SetOptions(merge: true));
          await _firestore.collection('teacher_profiles').doc(user.uid).set({
            'uid': user.uid,
            'name': name.trim(),
            'email': email.trim(),
            'classCount': 0,
            'createdAt': now.toIso8601String(),
          }, SetOptions(merge: true));

          return userModel;
        } catch (_) {
          throw const AuthException(
              'Bu e-posta adresi zaten kayıtlı. Lütfen Giriş Yap ekranından şifrenizle giriş yapınız.');
        }
      }
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw _mapException(e);
    }
  }

  // ── Veli Kaydı (Doğrulanmış Firebase Phone Auth UID + Davet Kodu) ────────

  @override
  Future<AppUser> registerParentWithPhoneAuth({
    required String name,
    required String inviteCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
          'Telefon doğrulaması bulunamadı. Lütfen önce SMS kodunu doğrulayınız.');
    }

    final phone = user.phoneNumber;
    if (phone == null || phone.isEmpty) {
      throw const AuthException('Doğrulanmış telefon numarası bilgisi eksik.');
    }

    final trimmedName = name.trim();
    final cleanCode = inviteCode.trim().toUpperCase();
    final now = DateTime.now();

    try {
      // Display name güncelle
      await user.updateDisplayName(trimmedName);

      // Firestore Transaction ile Davet Kodu Doğrulama & Tüketme ve Profil Oluşturma (Atomik)
      final userModel =
          await _firestore.runTransaction<AppUser>((transaction) async {
        var targetCode = cleanCode;
        var codeRef = _inviteCodes.doc(targetCode);
        var codeSnapshot = await transaction.get(codeRef);

        if (!codeSnapshot.exists && !targetCode.startsWith('OT-')) {
          targetCode = 'OT-$targetCode';
          codeRef = _inviteCodes.doc(targetCode);
          codeSnapshot = await transaction.get(codeRef);
        }

        if (!codeSnapshot.exists || codeSnapshot.data() == null) {
          throw const AuthException('Geçersiz davet kodu.');
        }


        final codeData = codeSnapshot.data()!;
        final bool isUsed = codeData['used'] as bool? ?? false;
        if (isUsed) {
          throw const AuthException('Bu davet kodu daha önce kullanılmış.');
        }

        final expiresAt = codeData['expiresAt'];
        if (expiresAt != null) {
          DateTime expiry;
          if (expiresAt is String) {
            expiry = DateTime.parse(expiresAt);
          } else {
            expiry = (expiresAt as Timestamp).toDate();
          }
          if (now.isAfter(expiry)) {
            throw const AuthException(
                'Bu davet kodunun kullanım süresi dolmuş.');
          }
        }

        final studentId = codeData['studentId'] as String?;
        if (studentId == null || studentId.isEmpty) {
          throw const AuthException(
              'Davet kodu ile ilişkili öğrenci bulunamadı.');
        }

        final studentRef = _firestore.collection('students').doc(studentId);
        final studentSnapshot = await transaction.get(studentRef);
        if (!studentSnapshot.exists) {
          throw const AuthException('Öğrenci kaydı bulunamadı.');
        }

        final userRef = _users.doc(user.uid);
        final parentProfileRef =
            _firestore.collection('parent_profiles').doc(user.uid);

        final newAppUser = AppUserModel(
          uid: user.uid,
          role: 'parent',
          name: trimmedName,
          email: user.email ?? '',
          phone: phone,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        // 1. users koleksiyonuna ekle
        transaction.set(
            userRef, newAppUser.toFirestore(), SetOptions(merge: true));

        // 2. parent_profiles koleksiyonuna ekle
        transaction.set(
          parentProfileRef,
          {
            'uid': user.uid,
            'name': trimmedName,
            'phone': phone,
            'email': user.email ?? '',
            'studentIds': FieldValue.arrayUnion([studentId]),
            'updatedAt': now.toIso8601String(),
            'createdAt': now.toIso8601String(),
          },
          SetOptions(merge: true),
        );

        // 3. Öğrenciye veli UID'sini bağla
        transaction.update(studentRef, {
          'parentIds': FieldValue.arrayUnion([user.uid]),
        });

        // 4. Davet kodunu tüket
        transaction.update(codeRef, {
          'used': true,
          'usedBy': user.uid,
          'usedAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        return newAppUser;
      });

      // Backend PostgreSQL ile Firebase ID Token üzerinden oturum doğrula ve eşitle
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          await BackendAuthService.instance.verifySession(
            idToken: idToken,
            name: trimmedName,
            role: 'parent',
          );
        }
      } catch (e) {
        // Backend sync uyarısı loglanır, akışı durdurmaz
      }

      return userModel;
    } catch (e) {
      throw _mapException(e);
    }
  }

  // ── Veli Phone Auth Girişi Sonrası Profil Senkronizasyonu ─────────────────

  @override
  Future<AppUser?> syncParentProfileAfterPhoneAuth() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final phone = user.phoneNumber;
    final now = DateTime.now();

    try {
      AppUser? resolvedUser;
      final userDoc = await _users.doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        resolvedUser = AppUserModel.fromFirestore(userDoc.data()!, user.uid);
      } else {
        // Eğer Firestore'da profil henüz yoksa, temel veli profilini oluştur
        final displayName =
            user.displayName ?? (phone != null ? 'Veli ($phone)' : 'Veli');
        final newAppUser = AppUserModel(
          uid: user.uid,
          role: 'parent',
          name: displayName,
          email: user.email ?? '',
          phone: phone,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final batch = _firestore.batch();
        batch.set(_users.doc(user.uid), newAppUser.toFirestore());
        batch.set(
          _firestore.collection('parent_profiles').doc(user.uid),
          {
            'uid': user.uid,
            'name': displayName,
            'phone': phone,
            'studentIds': [],
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        );

        // Telefon numarası eşleşen öğrenci varsa otomatik ilişkilendir
        if (phone != null && phone.isNotEmpty) {
          final studentQuery = await _firestore
              .collection('students')
              .where('phone', isEqualTo: phone)
              .get();

          for (final sDoc in studentQuery.docs) {
            batch.update(sDoc.reference, {
              'parentIds': FieldValue.arrayUnion([user.uid]),
            });
          }
        }

        await batch.commit();
        resolvedUser = newAppUser;
      }

      // Backend PostgreSQL ile Firebase ID Token üzerinden oturum doğrula ve eşitle
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          await BackendAuthService.instance.verifySession(
            idToken: idToken,
            name: resolvedUser.name,
            role: 'parent',
          );
        }
      } catch (e) {
        // Backend sync uyarısı loglanır
      }

      return resolvedUser;
    } catch (e) {
      throw _mapException(e);
    }
  }

  // ── Öğretmen E-posta/Şifre ile Giriş ────────────────────────────────────

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      String targetEmail = email.trim();

      if (!targetEmail.contains('@')) {
        final query = await _users.where('phone', isEqualTo: targetEmail).get();
        if (query.docs.isNotEmpty) {
          targetEmail = query.docs.first.data()['email'] ?? targetEmail;
        } else {
          final nameQuery =
              await _users.where('name', isEqualTo: targetEmail).get();
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
      if (user == null) {
        throw const AuthException('Kullanıcı profili bulunamadı.');
      }

      // Backend PostgreSQL ile Firebase ID Token üzerinden oturum doğrula ve eşitle
      try {
        final idToken = await _auth.currentUser?.getIdToken();
        if (idToken != null) {
          await BackendAuthService.instance.verifySession(
            idToken: idToken,
            name: user.name,
            role: user.role,
          );
        }
      } catch (_) {}

      return user;
    } catch (e) {
      throw _mapException(e);
    }
  }

  // ── Çıkış ──────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Kalıcı Hesap Silme ──────────────────────────────────────────────────

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    try {
      // 1. Firestore veritabanından kullanıcı belgelerini sil
      await _users.doc(uid).delete();
      await _firestore.collection('teacher_profiles').doc(uid).delete();
      await _firestore.collection('parent_profiles').doc(uid).delete();

      // 2. Firebase Auth üzerinden hesabı kalıcı olarak sil
      await user.delete();

      // 3. Oturumu sonlandır
      await _auth.signOut();
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (_) {}
      throw _mapException(e);
    }
  }

  // ── Şifre sıfırlama ────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _mapException(e);
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
      final phone = fbUser.phoneNumber;
      final role = (phone != null && phone.isNotEmpty) ? 'parent' : 'teacher';

      return AppUserModel(
        uid: uid,
        role: role,
        name: fbUser.displayName ??
            (phone != null ? 'Veli ($phone)' : 'Kullanıcı'),
        email: fbUser.email ?? '',
        phone: phone,
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
    try {
      final cleanCode = code.trim().toUpperCase();
      if (cleanCode.isEmpty) return null;

      var doc = await _inviteCodes.doc(cleanCode).get();
      if (!doc.exists && !cleanCode.startsWith('OT-')) {
        doc = await _inviteCodes.doc('OT-$cleanCode').get();
      }

      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final used = data['used'] as bool? ?? false;
      if (used) {
        throw const AuthException('Bu davet kodu daha önce kullanılmış.');
      }

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
    } catch (e) {
      if (e is AuthException) rethrow;
      throw _mapException(e);
    }
  }


  // ── Genel Hata Dönüştürücü ──────────────────────────────────────────────

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
        'email-already-in-use' => const AuthException(
            'Bu e-posta adresi zaten kullanılıyor. Giriş yapmayı deneyin.'),
        'invalid-phone-number' =>
          const AuthException('Geçersiz telefon numarası girdiniz.'),
        'invalid-verification-code' =>
          const AuthException('Girdiğiniz SMS doğrulama kodu hatalı.'),
        'session-expired' || 'code-expired' => const AuthException(
            'Doğrulama kodunun süresi dolmuş. Lütfen tekrar kod isteyiniz.'),
        'weak-password' => const AuthException(
            'Şifreniz çok zayıf. En az 6 karakter olmalıdır.'),
        'user-disabled' =>
          const AuthException('Hesabınız devre dışı bırakılmıştır.'),
        'network-request-failed' => const AuthException(
            'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.'),
        'too-many-requests' => const AuthException(
            'Çok fazla hatalı deneme yapıldı. Lütfen daha sonra tekrar deneyin.'),
        _ => AuthException(
            'İşlem başarısız (${e.code}): ${e.message ?? 'Lütfen tekrar deneyin.'}'),
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
          'İşlem başarısız (${e.code}): ${e.message ?? 'Lütfen tekrar deneyin.'}');
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
