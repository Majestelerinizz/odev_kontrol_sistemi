import '../entities/goal_entity.dart';

abstract class GoalsRepository {
  /// Öğrencinin aktif hedefinin canlı akışı
  Stream<GoalEntity?> getStudentGoal(String studentId);

  /// Hedef ekleme veya güncelleme
  Future<void> setGoal(GoalEntity goal);
}
