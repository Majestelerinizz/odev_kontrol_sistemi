import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/homework_assignment_entity.dart';

/// Firestore entegre HomeworkAssignmentModel
class HomeworkAssignmentModel extends HomeworkAssignmentEntity {
  const HomeworkAssignmentModel({
    required super.id,
    required super.homeworkId,
    required super.studentId,
    required super.classId,
    required super.teacherId,
    super.status,
    super.completedAt,
    super.teacherNote,
    required super.updatedAt,
  });

  factory HomeworkAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HomeworkAssignmentModel(
      id: doc.id,
      homeworkId: data['homeworkId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      teacherNote: data['teacherNote'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeworkId': homeworkId,
      'studentId': studentId,
      'classId': classId,
      'teacherId': teacherId,
      'status': status,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'teacherNote': teacherNote,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
