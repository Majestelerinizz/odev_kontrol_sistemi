import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants.dart';
import '../../core/models.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Süper kullanıcı (admin) girişi — yalnızca role=admin.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AdminConstants.colUsers);

  Stream<AdminUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _readAdminProfile(firebaseUser.uid);
    });
  }

  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _readAdminProfile(credential.user!.uid);
      if (user == null) {
        await _auth.signOut();
        throw const AuthException(
          'Bu hesap yönetici paneline erişim yetkisine sahip değil '
          '(admin rolü yok veya hesap pasif).',
        );
      }
      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    }
  }

  Future<AdminUser?> _readAdminProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    final role = data['role'] as String? ?? '';
    if (role != AdminConstants.roleAdmin) return null;

    final isActive = data['isActive'] as bool? ?? true;
    if (!isActive) return null;

    return AdminUser(
      uid: uid,
      role: role,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isActive: isActive,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _mapCode(String code) {
    return switch (code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'E-posta veya şifre hatalı.',
      'invalid-email' => 'Geçersiz e-posta adresi.',
      'user-disabled' => 'Hesabınız devre dışı bırakılmış.',
      'network-request-failed' => 'İnternet bağlantısı kurulamadı.',
      'too-many-requests' => 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.',
      _ => 'Giriş başarısız. Lütfen tekrar deneyin.',
    };
  }
}
