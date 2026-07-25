import 'package:cloud_firestore/cloud_firestore.dart';

/// Veli davet kodu modeli (`invite_codes` koleksiyonu)
class InviteCodeModel {
  const InviteCodeModel({
    required this.code,
    required this.studentId,
    required this.teacherId,
    required this.expiresAt,
    this.used = false,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  final String code;
  final String studentId;
  final String teacherId;
  final DateTime expiresAt;
  final bool used;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !used && !isExpired;

  factory InviteCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InviteCodeModel(
      code: doc.id,
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      used: data['used'] as bool? ?? false,
      usedBy: data['usedBy'] as String?,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'teacherId': teacherId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'used': used,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
