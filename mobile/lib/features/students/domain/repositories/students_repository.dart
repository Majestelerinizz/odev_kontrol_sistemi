import '../entities/student_entity.dart';

abstract class StudentsRepository {
  /// Sınıftaki öğrencilerin canlı akışı
  Stream<List<StudentEntity>> getClassStudents(String classId,
      {required String teacherId});

  /// Tek bir öğrenci detay akışı
  Stream<StudentEntity?> getStudentStream(String studentId);

  /// Veliye bağlı öğrencilerin canlı akışı
  Stream<List<StudentEntity>> getParentStudents(String parentUid);

  /// Öğrenci ekleme (sınıfın studentCount değerini artırır)
  Future<String> addStudent(StudentEntity student);

  /// Öğrenci güncelleme
  Future<void> updateStudent(StudentEntity student);

  /// Öğrenci silme (sınıfın studentCount değerini azaltır)
  Future<void> deleteStudent(String studentId, String classId);
}
