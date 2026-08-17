import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/features/classes/domain/entities/class_entity.dart';
import 'package:odev_takip/features/students/domain/entities/student_entity.dart';

void main() {
  group('ClassEntity Tests', () {
    test('ClassEntity kopyalama (copyWith) ve eşitlik testi', () {
      final entity1 = ClassEntity(
        id: 'class_1',
        teacherId: 'teacher_1',
        name: '8-A',
        gradeLevel: 8,
        createdAt: DateTime(2026, 7, 25),
      );

      final entity2 = entity1.copyWith(studentCount: 15);

      expect(entity1.id, entity2.id);
      expect(entity1.name, entity2.name);
      expect(entity2.studentCount, 15);
      expect(entity1 == entity2, true);
    });
  });

  group('StudentEntity Tests', () {
    test('StudentEntity veli durumu testi', () {
      final studentWithoutParent = StudentEntity(
        id: 'student_1',
        classId: 'class_1',
        teacherId: 'teacher_1',
        name: 'Ahmet Yılmaz',
        schoolNumber: '104',
        createdAt: DateTime.now(),
      );

      expect(studentWithoutParent.hasParent, false);

      final studentWithParent = studentWithoutParent.copyWith(
        parentIds: ['parent_uid_123'],
      );

      expect(studentWithParent.hasParent, true);
      expect(studentWithParent.parentIds.length, 1);
    });
  });
}
