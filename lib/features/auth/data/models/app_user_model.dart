import '../../domain/entities/app_user.dart';

/// AppUser Firestore modeli.
/// JSON serializasyon ve Firestore dönüşümlerini yönetir.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.role,
    required super.name,
    required super.email,
    super.phone,
    super.photoUrl,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppUserModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return AppUserModel(
      uid: uid,
      role: data['role'] as String? ?? 'teacher',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    // Firestore Timestamp
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  factory AppUserModel.fromEntity(AppUser user) {
    return AppUserModel(
      uid: user.uid,
      role: user.role,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photoUrl,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
