import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_result_model.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../../domain/repositories/exams_repository.dart';

class ExamsRepositoryImpl implements ExamsRepository {
  ExamsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _examsRef =>
      _firestore.collection('exam_results');

  @override
  Stream<List<ExamResultEntity>> getStudentExams(String studentId) {
    return _examsRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamResultModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.examDate.compareTo(a.examDate));
      return list;
    });
  }

  @override
  Stream<List<ExamResultEntity>> getClassExams(String classId) {
    return _examsRef
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamResultModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.examDate.compareTo(a.examDate));
      return list;
    });
  }

  @override
  Future<String> addExamResult(ExamResultEntity examResult) async {
    final model = ExamResultModel(
      id: '',
      studentId: examResult.studentId,
      classId: examResult.classId,
      teacherId: examResult.teacherId,
      examName: examResult.examName,
      examDate: examResult.examDate,
      publisher: examResult.publisher,
      scores: examResult.scores,
      totalNet: examResult.totalNet,
      totalScore: examResult.totalScore,
      createdAt: examResult.createdAt,
    );

    final docRef = await _examsRef.add(model.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> deleteExamResult(String examId) async {
    await _examsRef.doc(examId).delete();
  }
}
