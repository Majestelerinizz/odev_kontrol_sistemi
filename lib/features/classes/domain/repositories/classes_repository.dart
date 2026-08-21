import '../entities/class_entity.dart';

abstract class ClassesRepository {
  /// Öğretmenin tüm sınıflarının canlı akışı
  Stream<List<ClassEntity>> getTeacherClasses(String teacherId);

  /// Yeni sınıf ekleme
  Future<String> addClass(ClassEntity classEntity);

  /// Sınıf güncelleme
  Future<void> updateClass(ClassEntity classEntity);

  /// Tek bir sınıfın canlı akışı
  Stream<ClassEntity?> getClassStream(String classId);

  /// Sınıf silme
  Future<void> deleteClass(String classId);
}
