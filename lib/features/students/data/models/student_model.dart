import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/student_entity.dart';

/// Firestore entegre StudentModel
class StudentModel extends StudentEntity {
  const StudentModel({
    required super.id,
    required super.classId,
    required super.teacherId,
    required super.name,
    super.schoolNumber,
    super.phone,
    super.parentIds,
    super.targetScore,
    super.teacherNote,
    required super.createdAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawParents = data['parentIds'] as List<dynamic>? ?? [];
    return StudentModel(
      id: doc.id,
      classId: data['classId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      schoolNumber: data['schoolNumber'] as String?,
      phone: data['phone'] as String?,
      parentIds: rawParents.map((e) => e.toString()).toList(),
      targetScore: (data['targetScore'] as num?)?.toDouble() ?? 500.0,
      teacherNote: data['teacherNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'teacherId': teacherId,
      'name': name,
      'schoolNumber': schoolNumber,
      'phone': phone,
      'parentIds': parentIds,
      'targetScore': targetScore,
      'teacherNote': teacherNote,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
