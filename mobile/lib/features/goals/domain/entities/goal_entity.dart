import 'package:flutter/foundation.dart';

/// Öğrenci Hedef Entity'si (`goals`)
@immutable
class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.type = 'score', // 'score' | 'net'
    required this.targetValue,
    this.currentValue = 0.0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String type;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  double get remainingValue => (targetValue - currentValue).clamp(0, double.infinity);
  double get progressPercentage =>
      targetValue > 0 ? ((currentValue / targetValue) * 100).clamp(0, 100) : 0;

  GoalEntity copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? type,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
