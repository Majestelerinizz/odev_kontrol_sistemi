import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/students_repository_impl.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/students_repository.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepositoryImpl();
});

/// Sınıfa göre öğrencilerin canlı akışı
/// Family parametresi: (classId, teacherId) record
final classStudentsStreamProvider = StreamProvider.family<List<StudentEntity>,
    ({String classId, String teacherId})>((ref, params) {
  final teacherId = params.teacherId.isNotEmpty
      ? params.teacherId
      : (FirebaseAuth.instance.currentUser?.uid ?? '');
  if (teacherId.isEmpty) {
    return Stream.value(const <StudentEntity>[]);
  }
  return ref
      .watch(studentsRepositoryProvider)
      .getClassStudents(params.classId, teacherId: teacherId);
});

/// Tek öğrenci akışı
final studentStreamProvider =
    StreamProvider.family<StudentEntity?, String>((ref, studentId) {
  return ref.watch(studentsRepositoryProvider).getStudentStream(studentId);
});

/// Veliye bağlı öğrencilerin canlı akışı
final parentStudentsStreamProvider =
    StreamProvider.family<List<StudentEntity>, String>((ref, parentUid) {
  if (parentUid.isEmpty) return Stream.value(const <StudentEntity>[]);
  return ref.watch(studentsRepositoryProvider).getParentStudents(parentUid);
});

/// Öğrenci ekleme/silme Notifier'ı
class StudentNotifier extends StateNotifier<AsyncValue<void>> {
  StudentNotifier(this._repo) : super(const AsyncValue.data(null));

  final StudentsRepository _repo;

  Future<bool> addStudent({
    required String classId,
    required String teacherId,
    required String name,
    String? schoolNumber,
    String? phone,
    double targetScore = 500.0,
    String? teacherNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      final student = StudentEntity(
        id: '',
        classId: classId,
        teacherId: teacherId,
        name: name,
        schoolNumber: schoolNumber,
        phone: phone,
        targetScore: targetScore,
        teacherNote: teacherNote,
        createdAt: DateTime.now(),
      );
      await _repo.addStudent(student);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId, String classId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteStudent(studentId, classId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final studentNotifierProvider =
    StateNotifierProvider<StudentNotifier, AsyncValue<void>>((ref) {
  return StudentNotifier(ref.watch(studentsRepositoryProvider));
});
