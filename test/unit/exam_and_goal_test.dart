import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/features/exams/domain/entities/exam_result_entity.dart';
import 'package:odev_takip/features/goals/domain/entities/goal_entity.dart';

void main() {
  group('SubjectScore & ExamResultEntity Tests', () {
    test(
        'SubjectScore net hesabı otomatik doğru yapılır (16 D, 4 Y = 15.0 Net)',
        () {
      const score = SubjectScore(correct: 16, wrong: 4, blank: 0);
      expect(score.net, 15.0);
      expect(score.totalQuestions, 20);
    });

    test('ExamResultEntity ders skoru haritası erişimi', () {
      final exam = ExamResultEntity(
        id: 'exam_1',
        studentId: 'student_1',
        classId: 'class_1',
        teacherId: 'teacher_1',
        examName: 'Özdebir Deneme 1',
        examDate: DateTime(2026, 7, 25),
        scores: const {
          'Matematik': SubjectScore(correct: 20, wrong: 0, blank: 0),
          'Türkçe': SubjectScore(correct: 16, wrong: 4, blank: 0),
        },
        totalNet: 35.0,
        totalScore: 450.0,
        createdAt: DateTime(2026, 7, 25),
      );

      expect(exam.scores['Matematik']?.net, 20.0);
      expect(exam.scores['Türkçe']?.net, 15.0);
      expect(exam.totalNet, 35.0);
    });
  });

  group('GoalEntity Tests', () {
    test(
        'Hedef kalan değer (remainingValue) ve yüzde (progressPercentage) doğru hesaplanır',
        () {
      final goal = GoalEntity(
        id: 'goal_1',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        targetValue: 450.0,
        currentValue: 360.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      expect(goal.remainingValue, 90.0);
      expect(goal.progressPercentage, 80.0);
    });
  });
}
