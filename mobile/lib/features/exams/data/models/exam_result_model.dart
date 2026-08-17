import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/exam_result_entity.dart';

/// Firestore ile entegre ExamResultModel
class ExamResultModel extends ExamResultEntity {
  const ExamResultModel({
    required super.id,
    required super.studentId,
    required super.classId,
    required super.teacherId,
    required super.examName,
    required super.examDate,
    super.publisher,
    required super.scores,
    required super.totalNet,
    super.totalScore,
    required super.createdAt,
  });

  factory ExamResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawScores = data['scores'] as Map<String, dynamic>? ?? {};

    final scoresMap = <String, SubjectScore>{};
    rawScores.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        scoresMap[key] = SubjectScore(
          correct: (val['correct'] as num?)?.toInt() ?? 0,
          wrong: (val['wrong'] as num?)?.toInt() ?? 0,
          blank: (val['blank'] as num?)?.toInt() ?? 0,
          net: (val['net'] as num?)?.toDouble() ?? 0.0,
        );
      }
    });

    return ExamResultModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      examName: data['examName'] as String? ?? '',
      examDate: (data['examDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publisher: data['publisher'] as String?,
      scores: scoresMap,
      totalNet: (data['totalNet'] as num?)?.toDouble() ?? 0.0,
      totalScore: (data['totalScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final serializedScores = <String, dynamic>{};
    scores.forEach((key, val) {
      serializedScores[key] = {
        'correct': val.correct,
        'wrong': val.wrong,
        'blank': val.blank,
        'net': val.net,
      };
    });

    return {
      'studentId': studentId,
      'classId': classId,
      'teacherId': teacherId,
      'examName': examName,
      'examDate': Timestamp.fromDate(examDate),
      'publisher': publisher,
      'scores': serializedScores,
      'totalNet': totalNet,
      'totalScore': totalScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
