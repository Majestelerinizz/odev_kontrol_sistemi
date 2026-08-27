import 'package:flutter/foundation.dart';

/// Sınıf domain entity'si.
@immutable
class ClassEntity {
  const ClassEntity({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.gradeLevel,
    this.schoolName,
    this.academicYear = '2026-2027',
    this.studentCount = 0,
    this.inviteCode,
    required this.createdAt,
  });

  final String id;
  final String teacherId;
  final String name; // Örn: '8-A'
  final int gradeLevel; // Örn: 8
  final String? schoolName;
  final String academicYear;
  final int studentCount;
  /// Sınıf davet kodu (tüm veliler aynı kodu kullanır)
  final String? inviteCode;
  final DateTime createdAt;

  ClassEntity copyWith({
    String? id,
    String? teacherId,
    String? name,
    int? gradeLevel,
    String? schoolName,
    String? academicYear,
    int? studentCount,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    return ClassEntity(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      schoolName: schoolName ?? this.schoolName,
      academicYear: academicYear ?? this.academicYear,
      studentCount: studentCount ?? this.studentCount,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
