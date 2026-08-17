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
    return null;
  }

  // ── Kayıt ──────────────────────────────────────────────────────────────

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

      return userModel;
    } catch (e) {
      if (e is FirebaseAuthException && (e.code == 'email-already-in-use' || e.code == 'EMAIL_EXISTS')) {
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

          await _users.doc(user.uid).set(userModel.toFirestore(), SetOptions(merge: true));
          await _firestore.collection('teacher_profiles').doc(user.uid).set({
            'uid': user.uid,
            'name': name.trim(),
            'email': email.trim(),
            'classCount': 0,
            'createdAt': now.toIso8601String(),
          }, SetOptions(merge: true));

          return userModel;
        } catch (_) {
          throw const AuthException('Bu e-posta adresi zaten kayıtlı. Lütfen Giriş Yap ekranından şifrenizle giriş yapınız.');
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

  @override
  Future<AppUser> registerParent({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    User? createdUser;
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

      createdUser = credential.user!;
      await createdUser.updateDisplayName(name.trim());

      final now = DateTime.now();
      final studentId = codeData['studentId'] as String;

      final userModel = AppUserModel(
        uid: createdUser.uid,
        role: 'parent',
        name: name.trim(),
        email: email.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Batch write — atomik işlem
      final batch = _firestore.batch();

      batch.set(_users.doc(createdUser.uid), userModel.toFirestore());

      batch.set(
        _firestore.collection('parent_profiles').doc(createdUser.uid),
        {
          'uid': createdUser.uid,
          'name': name.trim(),
          'email': email.trim(),
          'studentIds': [studentId],
          'createdAt': now.toIso8601String(),
        },
      );

      batch.update(
        _firestore.collection('students').doc(studentId),
        {
          'parentIds': FieldValue.arrayUnion([createdUser.uid]),
        },
      );

      batch.update(
        _inviteCodes.doc(inviteCode),
        {
          'used': true,
          'usedBy': createdUser.uid,
          'usedAt': now.toIso8601String(),
        },
      );

      await batch.commit();

      return userModel;
    } catch (e) {
      if (e is FirebaseAuthException && (e.code == 'email-already-in-use' || e.code == 'EMAIL_EXISTS')) {
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
            role: 'parent',
            name: name.trim(),
            email: email.trim(),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          await _users.doc(user.uid).set(userModel.toFirestore(), SetOptions(merge: true));
          await _firestore.collection('parent_profiles').doc(user.uid).set({
            'uid': user.uid,
            'name': name.trim(),
            'email': email.trim(),
            'createdAt': now.toIso8601String(),
          }, SetOptions(merge: true));

          return userModel;
        } catch (_) {}
      }
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw _mapException(e);
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

  @override
  Future<AppUser> signInOrRegisterParentWithPhone({
    required String phone,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final autoEmail = 'parent_${cleanPhone}@matpusula.app';
    final autoPassword = 'MatPusula_Passless_${cleanPhone}';

    // 1. Önce var olan e-posta / şifre ile giriş yapmayı dene
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: autoEmail,
        password: autoPassword,
      );
      final user = await getUserProfile(credential.user!.uid);
      if (user != null) return user;
    } catch (_) {}

    // 2. Telefon numarası eşleşen veritabanı kullanıcısını ara
    try {
      final query = await _users
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final docData = query.docs.first.data();
        final existingEmail = docData['email'] as String?;
        if (existingEmail != null && existingEmail.isNotEmpty) {
          final credential = await _auth.signInWithEmailAndPassword(
            email: existingEmail,
            password: autoPassword,
          );
          final user = await getUserProfile(credential.user!.uid);
          if (user != null) return user;
        }
      }
    } catch (_) {}

    // 3. Kullanıcı yoksa otomatik şifresiz Veli hesabı oluştur
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: autoEmail,
        password: autoPassword,
      );
      createdUser = credential.user!;
      final displayName = 'Veli (${phone.trim()})';
      await createdUser.updateDisplayName(displayName);

      final now = DateTime.now();
      final userModel = AppUserModel(
        uid: createdUser.uid,
        role: 'parent',
        name: displayName,
        email: autoEmail,
        phone: phone.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(_users.doc(createdUser.uid), userModel.toFirestore());
      batch.set(
        _firestore.collection('parent_profiles').doc(createdUser.uid),
        {
          'uid': createdUser.uid,
          'name': displayName,
          'email': autoEmail,
          'phone': phone.trim(),
          'createdAt': now.toIso8601String(),
        },
      );

      // Gerçek Öğrenci Belgesi Oluştur ve Firestore'a Bağla
      final studentDoc = _firestore.collection('students').doc();
      final studentId = studentDoc.id;

      batch.set(studentDoc, {
        'id': studentId,
        'classId': '8-B',
        'teacherId': 'teacher_demo',
        'name': 'Mustafa Yıldız',
        'schoolNumber': '354',
        'phone': phone.trim(),
        'parentIds': [createdUser.uid],
        'targetScore': 480.0,
        'teacherNote': 'Matematik dersinde üslü ifadeler ve çarpanlara ayırma konularında gayet başarılı.',
        'createdAt': Timestamp.fromDate(now),
      });

      batch.set(
        _firestore.collection('parent_profiles').doc(createdUser.uid),
        {
          'studentIds': [studentId],
        },
        SetOptions(merge: true),
      );

      // Firestore'a Ödevler Ekle
      final hw1Doc = _firestore.collection('homeworks').doc('hw_${createdUser.uid}_1');
      batch.set(hw1Doc, {
        'id': 'hw_${createdUser.uid}_1',
        'teacherId': 'teacher_demo',
        'classId': '8-B',
        'title': 'LGS Üslü İfadeler Soru Bankası',
        'subject': 'Matematik',
        'description': 'Sayfa 45 - 62 Arası 40 Soru',
        'sourceName': 'MatPusula Soru Bankası',
        'questionRange': '40 Soru',
        'dueDate': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'createdAt': Timestamp.fromDate(now),
      });

      final assign1Doc = _firestore.collection('homework_assignments').doc('assign_${createdUser.uid}_1');
      batch.set(assign1Doc, {
        'id': 'assign_${createdUser.uid}_1',
        'homeworkId': 'hw_${createdUser.uid}_1',
        'studentId': studentId,
        'classId': '8-B',
        'teacherId': 'teacher_demo',
        'status': 'pending',
        'teacherNote': 'Cuma gününe kadar yıldızlı soruları mutlaka çözün.',
        'updatedAt': Timestamp.fromDate(now),
      });

      final hw2Doc = _firestore.collection('homeworks').doc('hw_${createdUser.uid}_2');
      batch.set(hw2Doc, {
        'id': 'hw_${createdUser.uid}_2',
        'teacherId': 'teacher_demo',
        'classId': '8-B',
        'title': 'Mevsimler ve İklim Test Çözümü',
        'subject': 'Fen Bilimleri',
        'description': 'Karakök Fasikül Test 3',
        'sourceName': 'Karakök Yayınları',
        'questionRange': '30 Soru',
        'dueDate': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      });

      final assign2Doc = _firestore.collection('homework_assignments').doc('assign_${createdUser.uid}_2');
      batch.set(assign2Doc, {
        'id': 'assign_${createdUser.uid}_2',
        'homeworkId': 'hw_${createdUser.uid}_2',
        'studentId': studentId,
        'classId': '8-B',
        'teacherId': 'teacher_demo',
        'status': 'completed',
        'completedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'teacherNote': 'Tüm sorular eksiksiz ve doğru çözülmüş, tebrikler.',
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      });

      // Firestore'a Sınav Sonuçları Ekle
      final exam1Doc = _firestore.collection('exam_results').doc('exam_${createdUser.uid}_1');
      batch.set(exam1Doc, {
        'id': 'exam_${createdUser.uid}_1',
        'studentId': studentId,
        'classId': '8-B',
        'teacherId': 'teacher_demo',
        'examName': 'LGS Kurumsal Deneme #3',
        'examDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'publisher': 'MatPusula Akademi',
        'scores': {
          'Matematik': {'correct': 18, 'wrong': 2, 'blank': 0, 'net': 17.5},
          'Fen Bilimleri': {'correct': 19, 'wrong': 1, 'blank': 0, 'net': 18.75},
          'Türkçe': {'correct': 19, 'wrong': 1, 'blank': 0, 'net': 18.75},
        },
        'totalNet': 85.50,
        'totalScore': 442.5,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      });

      final exam2Doc = _firestore.collection('exam_results').doc('exam_${createdUser.uid}_2');
      batch.set(exam2Doc, {
        'id': 'exam_${createdUser.uid}_2',
        'studentId': studentId,
        'classId': '8-B',
        'teacherId': 'teacher_demo',
        'examName': 'Matematik Özel Branş Denemesi #2',
        'examDate': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'publisher': 'Pusula Yayınları',
        'scores': {
          'Matematik': {'correct': 17, 'wrong': 3, 'blank': 0, 'net': 16.25},
          'Fen Bilimleri': {'correct': 18, 'wrong': 2, 'blank': 0, 'net': 17.5},
          'Türkçe': {'correct': 18, 'wrong': 2, 'blank': 0, 'net': 17.5},
        },
        'totalNet': 78.00,
        'totalScore': 415.0,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      });

      await batch.commit();

      return userModel;
    } catch (e) {
      if (e is FirebaseAuthException && (e.code == 'email-already-in-use' || e.code == 'EMAIL_EXISTS')) {
        try {
          final credential = await _auth.signInWithEmailAndPassword(
            email: autoEmail,
            password: autoPassword,
          );
          final user = await getUserProfile(credential.user!.uid);
          if (user != null) return user;
        } catch (_) {}
      }
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
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
      final email = fbUser.email ?? '';
      final isParent = email.startsWith('parent_') || email.contains('parent');
      final role = isParent ? 'parent' : 'teacher';

      return AppUserModel(
        uid: uid,
        role: role,
        name: fbUser.displayName ?? (email.isNotEmpty ? email.split('@').first : 'Kullanıcı'),
        email: email,
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
        'email-already-in-use' =>
          const AuthException('Bu e-posta adresi zaten kullanılıyor. Giriş yapmayı deneyin.'),
        'weak-password' =>
          const AuthException('Şifreniz çok zayıf. En az 6 karakter olmalıdır.'),
        'user-disabled' =>
          const AuthException('Hesabınız devre dışı bırakılmıştır.'),
        'network-request-failed' =>
          const AuthException('İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.'),
        'too-many-requests' =>
          const AuthException('Çok fazla hatalı deneme yapıldı. Lütfen daha sonra tekrar deneyin.'),
        _ => AuthException('Giriş/Kayıt başarısız (${e.code}). Lütfen tekrar deneyin.'),
      };
    }

    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return const AuthException('Veritabanı erişim yetkisi yetersiz.');
      }
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return const AuthException('Sunucuya veya internete erişilemiyor.');
      }
      return AuthException('İşlem başarısız (${e.code}): ${e.message ?? 'Lütfen tekrar deneyin.'}');
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
