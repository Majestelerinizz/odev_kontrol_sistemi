import '../entities/exam_result_entity.dart';

abstract class ExamsRepository {
  /// Bir öğrenciye ait deneme sonuçlarının canlı akışı (Tarihe göre sıralı)
  Stream<List<ExamResultEntity>> getStudentExams(String studentId, {String? teacherId});

  /// Bir sınıfa ait tüm deneme sonuçlarının canlı akışı
  Stream<List<ExamResultEntity>> getClassExams(String classId, {required String teacherId});

  /// Yeni deneme sonucu kaydetme (ve öğrenci hedefindeki mevcut skoru güncelleme)
  Future<String> addExamResult(ExamResultEntity examResult);

  /// Deneme sonucu silme
  Future<void> deleteExamResult(String examId);
}
