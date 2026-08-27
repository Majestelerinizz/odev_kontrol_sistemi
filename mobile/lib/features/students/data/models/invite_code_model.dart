import 'package:cloud_firestore/cloud_firestore.dart';

/// Davet kodundaki öğrenci özeti (veli seçimi için)
class InviteStudentOption {
  const InviteStudentOption({
    required this.id,
    required this.name,
    this.schoolNumber,
  });

  final String id;
  final String name;
  final String? schoolNumber;

  factory InviteStudentOption.fromMap(Map<String, dynamic> data) {
    return InviteStudentOption(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      schoolNumber: data['schoolNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (schoolNumber != null) 'schoolNumber': schoolNumber,
    };
  }
}

/// Veli davet kodu modeli (`invite_codes` koleksiyonu).
///
/// [type] `class` → sınıf kodu (çoklu kullanım); `student` → eski tek öğrenci kodu.
class InviteCodeModel {
  const InviteCodeModel({
    required this.code,
    required this.teacherId,
    required this.createdAt,
    this.type = 'class',
    this.classId,
    this.className,
    this.studentId,
    this.students = const [],
    this.expiresAt,
    this.used = false,
    this.revoked = false,
    this.usedBy,
    this.usedAt,
  });

  final String code;
  final String type;
  final String? classId;
  final String? className;
  final String? studentId;
  final List<InviteStudentOption> students;
  final String teacherId;
  final DateTime? expiresAt;
  final bool used;
  final bool revoked;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  bool get isClassInvite => type == 'class';
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid =>
      !revoked && !isExpired && (isClassInvite || !used);

  factory InviteCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawStudents = data['students'] as List<dynamic>? ?? [];
    return InviteCodeModel(
      code: doc.id,
      type: data['type'] as String? ??
          (data['classId'] != null ? 'class' : 'student'),
      classId: data['classId'] as String?,
      className: data['className'] as String?,
      studentId: data['studentId'] as String?,
      students: rawStudents
          .whereType<Map>()
          .map((e) => InviteStudentOption.fromMap(Map<String, dynamic>.from(e)))
          .where((s) => s.id.isNotEmpty)
          .toList(),
      teacherId: data['teacherId'] as String? ?? '',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      used: data['used'] as bool? ?? false,
      revoked: data['revoked'] as bool? ?? false,
      usedBy: data['usedBy'] as String?,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      if (classId != null) 'classId': classId,
      if (className != null) 'className': className,
      if (studentId != null) 'studentId': studentId,
      'students': students.map((s) => s.toMap()).toList(),
      'teacherId': teacherId,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'used': used,
      'revoked': revoked,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
