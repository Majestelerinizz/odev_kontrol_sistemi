import 'package:flutter/foundation.dart';

/// Ders bazlı sınav skoru (Doğru, Yanlış, Boş ve Net)
@immutable
class SubjectScore {
  const SubjectScore({
    required this.correct,
    required this.wrong,
    required this.blank,
    double? net,
  }) : net = net ?? (correct - (wrong / 4.0));

  final int correct;
  final int wrong;
  final int blank;
  final double net;

  int get totalQuestions => correct + wrong + blank;

  SubjectScore copyWith({
    int? correct,
    int? wrong,
    int? blank,
    double? net,
  }) {
    return SubjectScore(
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      blank: blank ?? this.blank,
      net: net ?? this.net,
    );
  }
}

/// Deneme Sınavı Sonuç Domain Entity'si
@immutable
class ExamResultEntity {
  const ExamResultEntity({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.teacherId,
    required this.examName,
    required this.examDate,
    this.publisher,
    required this.scores,
    required this.totalNet,
    this.totalScore = 0.0,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String classId;
  final String teacherId;
  final String examName;
  final DateTime examDate;
  final String? publisher;
  final Map<String, SubjectScore> scores; // Ders adı -> Skor
  final double totalNet;
  final double totalScore;
  final DateTime createdAt;

  ExamResultEntity copyWith({
    String? id,
    String? studentId,
    String? classId,
    String? teacherId,
    String? examName,
    DateTime? examDate,
    String? publisher,
    Map<String, SubjectScore>? scores,
    double? totalNet,
    double? totalScore,
    DateTime? createdAt,
  }) {
    return ExamResultEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      examName: examName ?? this.examName,
      examDate: examDate ?? this.examDate,
      publisher: publisher ?? this.publisher,
      scores: scores ?? this.scores,
      totalNet: totalNet ?? this.totalNet,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamResultEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
