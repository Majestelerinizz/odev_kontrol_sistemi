import '../entities/class_entity.dart';
import '../../../students/data/models/invite_code_model.dart';

abstract class ClassesRepository {
  /// Öğretmenin tüm sınıflarının canlı akışı
  Stream<List<ClassEntity>> getTeacherClasses(String teacherId);

  /// Tek sınıf akışı
  Stream<ClassEntity?> getClassStream(String classId);

  /// Yeni sınıf ekleme
  Future<String> addClass(ClassEntity classEntity);

  /// Sınıf güncelleme
  Future<void> updateClass(ClassEntity classEntity);

  /// Sınıf silme
  Future<void> deleteClass(String classId);

  /// Sınıf için tek davet kodu üret / yenile (çoklu kullanım)
  Future<InviteCodeModel> generateClassInviteCode({
    required String classId,
    required String teacherId,
  });

  /// Sınıfın aktif davet kodunu getir (yoksa null)
  Future<InviteCodeModel?> getActiveClassInviteCode(String classId);

  /// Davet kodundaki öğrenci listesini güncelle
  Future<void> refreshClassInviteRoster(String classId);
}
