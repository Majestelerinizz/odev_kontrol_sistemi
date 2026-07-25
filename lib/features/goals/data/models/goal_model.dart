import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/goal_entity.dart';

/// Firestore ile entegre GoalModel
class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.studentId,
    required super.teacherId,
    super.type,
    required super.targetValue,
    super.currentValue,
    required super.startDate,
    required super.endDate,
    super.isActive,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GoalModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      type: data['type'] as String? ?? 'score',
      targetValue: (data['targetValue'] as num?)?.toDouble() ?? 500.0,
      currentValue: (data['currentValue'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'teacherId': teacherId,
      'type': type,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
    };
  }
}
