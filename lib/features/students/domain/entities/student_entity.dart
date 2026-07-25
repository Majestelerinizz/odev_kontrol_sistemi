import 'package:flutter/foundation.dart';

/// Öğrenci domain entity'si.
@immutable
class StudentEntity {
  const StudentEntity({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.name,
    this.schoolNumber,
    this.phone,
    this.parentIds = const [],
    this.targetScore = 500,
    this.teacherNote,
    required this.createdAt,
  });

  final String id;
  final String classId;
  final String teacherId;
  final String name;
  final String? schoolNumber;
  final String? phone;
  final List<String> parentIds;
  final double targetScore;
  final String? teacherNote;
  final DateTime createdAt;

  bool get hasParent => parentIds.isNotEmpty;

  StudentEntity copyWith({
    String? id,
    String? classId,
    String? teacherId,
    String? name,
    String? schoolNumber,
    String? phone,
    List<String>? parentIds,
    double? targetScore,
    String? teacherNote,
    DateTime? createdAt,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      schoolNumber: schoolNumber ?? this.schoolNumber,
      phone: phone ?? this.phone,
      parentIds: parentIds ?? this.parentIds,
      targetScore: targetScore ?? this.targetScore,
      teacherNote: teacherNote ?? this.teacherNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
