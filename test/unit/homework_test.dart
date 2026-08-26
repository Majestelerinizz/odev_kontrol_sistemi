import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/features/homeworks/domain/entities/homework_entity.dart';
import 'package:odev_takip/features/homeworks/domain/entities/homework_assignment_entity.dart';

void main() {
  group('HomeworkEntity Tests', () {
    test('Gecikme (isOverdue) kontrolü doğru çalışır', () {
      final pastDueDate = DateTime.now().subtract(const Duration(days: 1));
      final futureDueDate = DateTime.now().add(const Duration(days: 1));

      final overdueHomework = HomeworkEntity(
        id: 'hw_1',
        teacherId: 'teacher_1',
        classId: 'class_1',
        title: 'Matematik Test 1',
        subject: 'Matematik',
        dueDate: pastDueDate,
        createdAt: DateTime.now(),
      );

      final activeHomework = overdueHomework.copyWith(dueDate: futureDueDate);

      expect(overdueHomework.isOverdue, true);
      expect(activeHomework.isOverdue, false);
    });
  });

  group('HomeworkAssignmentEntity Tests', () {
    test('Durum yardımcıları (isCompleted, isPending, isMissed) doğru çalışır',
        () {
      final assignment = HomeworkAssignmentEntity(
        id: 'asg_1',
        homeworkId: 'hw_1',
        studentId: 'student_1',
        classId: 'class_1',
        teacherId: 'teacher_1',
        status: 'pending',
        updatedAt: DateTime.now(),
      );

      expect(assignment.isPending, true);
      expect(assignment.isCompleted, false);

      final completedAssignment = assignment.copyWith(status: 'completed');
      expect(completedAssignment.isCompleted, true);
      expect(completedAssignment.isPending, false);
    });
  });
}
