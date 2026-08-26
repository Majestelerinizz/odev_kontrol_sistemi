import 'package:flutter/foundation.dart';

/// Uygulama kullanıcı entity'si.
/// Tüm Auth ve kullanıcı bilgilerini temsil eder.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String role; // 'teacher' | 'parent'
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTeacher => role == 'teacher';
  bool get isParent => role == 'parent';

  AppUser copyWith({
    String? uid,
    String? role,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'AppUser(uid: $uid, role: $role, name: $name)';
}
