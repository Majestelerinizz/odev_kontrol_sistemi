import '../entities/homework_entity.dart';
import '../entities/homework_assignment_entity.dart';

abstract class HomeworksRepository {
  /// Öğretmenin oluşturduğu ödevlerin canlı akışı
  Stream<List<HomeworkEntity>> getTeacherHomeworks(String teacherId);

  /// Sınıfa özel ödevlerin canlı akışı
  Stream<List<HomeworkEntity>> getClassHomeworks(String classId);

  /// Bir ödeve ait tüm öğrenci durumlarının canlı akışı (`homework_assignments`)
  Stream<List<HomeworkAssignmentEntity>> getHomeworkAssignments(String homeworkId);

  /// Bir öğrencinin tüm ödev atamalarının canlı akışı (Veli ekranı için)
  Stream<List<HomeworkAssignmentEntity>> getStudentAssignments(String studentId);

  /// Tek ödev detayını getirme
  Future<HomeworkEntity?> getHomeworkById(String homeworkId);

  /// Birden fazla ödevi batch getir (N+1 önleme)
  Future<Map<String, HomeworkEntity>> getHomeworksByIds(List<String> homeworkIds);

  /// Yeni ödev oluşturma ve sınıftaki öğrencilere atama
  Future<String> createHomework({
    required HomeworkEntity homework,
    required List<String> studentIds,
  });

  /// Öğrenci ödev durumunu güncelleme (Tamamlandı / Yapılmadı / Bekliyor)
  Future<void> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    String? teacherNote,
  });

  /// Ödev silme
  Future<void> deleteHomework(String homeworkId);
}
