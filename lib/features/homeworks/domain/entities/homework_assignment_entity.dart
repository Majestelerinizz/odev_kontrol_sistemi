import 'package:flutter/foundation.dart';

/// Öğrenciye atanan ödev durumu entity'si (`homework_assignments`).
@immutable
class HomeworkAssignmentEntity {
  const HomeworkAssignmentEntity({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.classId,
    required this.teacherId,
    this.status = 'pending', // 'pending' | 'completed' | 'missed' | 'overdue'
    this.completedAt,
    this.teacherNote,
    required this.updatedAt,
  });

  final String id;
  final String homeworkId;
  final String studentId;
  final String classId;
  final String teacherId;
  final String status;
  final DateTime? completedAt;
  final String? teacherNote;
  final DateTime updatedAt;

  bool get isCompleted => status == 'completed';
  bool get isMissed => status == 'missed';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';

  HomeworkAssignmentEntity copyWith({
    String? id,
    String? homeworkId,
    String? studentId,
    String? classId,
    String? teacherId,
    String? status,
    DateTime? completedAt,
    String? teacherNote,
    DateTime? updatedAt,
  }) {
    return HomeworkAssignmentEntity(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      teacherNote: teacherNote ?? this.teacherNote,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkAssignmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
