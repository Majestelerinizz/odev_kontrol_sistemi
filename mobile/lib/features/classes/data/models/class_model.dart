import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/class_entity.dart';

/// Firestore ile entegre ClassModel
class ClassModel extends ClassEntity {
  const ClassModel({
    required super.id,
    required super.teacherId,
    required super.name,
    required super.gradeLevel,
    super.schoolName,
    super.academicYear,
    super.studentCount,
    super.inviteCode,
    required super.createdAt,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClassModel(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      gradeLevel: (data['gradeLevel'] as num?)?.toInt() ?? 8,
      schoolName: data['schoolName'] as String?,
      academicYear: data['academicYear'] as String? ?? '2026-2027',
      studentCount: (data['studentCount'] as num?)?.toInt() ?? 0,
      inviteCode: data['inviteCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'name': name,
      'gradeLevel': gradeLevel,
      'schoolName': schoolName,
      'academicYear': academicYear,
      'studentCount': studentCount,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ClassModel.fromEntity(ClassEntity entity) {
    return ClassModel(
      id: entity.id,
      teacherId: entity.teacherId,
      name: entity.name,
      gradeLevel: entity.gradeLevel,
      schoolName: entity.schoolName,
      academicYear: entity.academicYear,
      studentCount: entity.studentCount,
      inviteCode: entity.inviteCode,
      createdAt: entity.createdAt,
    );
  }
}
