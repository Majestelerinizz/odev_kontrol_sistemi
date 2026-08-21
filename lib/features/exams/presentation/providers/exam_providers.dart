import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exams_repository_impl.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../../domain/repositories/exams_repository.dart';
import '../../../goals/data/repositories/goals_repository_impl.dart';
import '../../../goals/domain/entities/goal_entity.dart';
import '../../../goals/domain/repositories/goals_repository.dart';

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  return ExamsRepositoryImpl();
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepositoryImpl();
});

/// Bir öğrencinin tüm sınav sonuçlarının canlı akışı
final studentExamsStreamProvider =
    StreamProvider.family<List<ExamResultEntity>, String>((ref, studentId) {
  if (studentId.isEmpty) return Stream.value(const <ExamResultEntity>[]);
  return ref.watch(examsRepositoryProvider).getStudentExams(studentId);
});

/// Bir sınıfın tüm sınav sonuçlarının canlı akışı
/// Family parametresi: (classId, teacherId) record
final classExamsStreamProvider =
    StreamProvider.family<List<ExamResultEntity>, ({String classId, String teacherId})>((ref, params) {
  return ref.watch(examsRepositoryProvider).getClassExams(params.classId, teacherId: params.teacherId);
});

/// Öğrencinin aktif hedefinin canlı akışı
final studentGoalStreamProvider =
    StreamProvider.family<GoalEntity?, String>((ref, studentId) {
  return ref.watch(goalsRepositoryProvider).getStudentGoal(studentId);
});

/// Sınav Ekleme ve Silme Notifier'ı
class ExamNotifier extends StateNotifier<AsyncValue<void>> {
  ExamNotifier(this._examRepo, this._goalRepo)
      : super(const AsyncValue.data(null));

  final ExamsRepository _examRepo;
  final GoalsRepository _goalRepo;

  Future<bool> addExamResult({
    required String studentId,
    required String classId,
    required String teacherId,
    required String examName,
    required DateTime examDate,
    String? publisher,
    required Map<String, SubjectScore> scores,
    required double totalNet,
    double totalScore = 0.0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final exam = ExamResultEntity(
        id: '',
        studentId: studentId,
        classId: classId,
        teacherId: teacherId,
        examName: examName,
        examDate: examDate,
        publisher: publisher,
        scores: scores,
        totalNet: totalNet,
        totalScore: totalScore,
        createdAt: DateTime.now(),
      );

      await _examRepo.addExamResult(exam);

      // Öğrencinin hedefini güncelle
      final activeGoal = await _goalRepo.getStudentGoal(studentId).first;
      if (activeGoal != null) {
        final updatedGoal = activeGoal.copyWith(
          currentValue: activeGoal.type == 'score' ? totalScore : totalNet,
        );
        await _goalRepo.setGoal(updatedGoal);
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteExam(String examId) async {
    state = const AsyncValue.loading();
    try {
      await _examRepo.deleteExamResult(examId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final examNotifierProvider =
    StateNotifierProvider<ExamNotifier, AsyncValue<void>>((ref) {
  return ExamNotifier(
    ref.watch(examsRepositoryProvider),
    ref.watch(goalsRepositoryProvider),
  );
});
