import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework_model.dart';
import '../models/homework_assignment_model.dart';
import '../../domain/entities/homework_entity.dart';
import '../../domain/entities/homework_assignment_entity.dart';
import '../../domain/repositories/homeworks_repository.dart';

class HomeworksRepositoryImpl implements HomeworksRepository {
  HomeworksRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _homeworksRef =>
      _firestore.collection('homeworks');
  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('homework_assignments');

  @override
  Stream<List<HomeworkEntity>> getTeacherHomeworks(String teacherId) {
    return _homeworksRef
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => HomeworkModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<HomeworkEntity>> getClassHomeworks(String classId) {
    return _homeworksRef
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => HomeworkModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return list;
    });
  }

  @override
  Stream<List<HomeworkAssignmentEntity>> getHomeworkAssignments(
      String homeworkId) {
    return _assignmentsRef
        .where('homeworkId', isEqualTo: homeworkId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HomeworkAssignmentModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<HomeworkAssignmentEntity>> getStudentAssignments(
      String studentId) {
    return _assignmentsRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => HomeworkAssignmentModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Future<HomeworkEntity?> getHomeworkById(String homeworkId) async {
    final doc = await _homeworksRef.doc(homeworkId).get();
    if (!doc.exists) return null;
    return HomeworkModel.fromFirestore(doc);
  }

  @override
  Future<String> createHomework({
    required HomeworkEntity homework,
    required List<String> studentIds,
  }) async {
    final model = HomeworkModel(
      id: '',
      teacherId: homework.teacherId,
      classId: homework.classId,
      title: homework.title,
      subject: homework.subject,
      description: homework.description,
      sourceName: homework.sourceName,
      questionRange: homework.questionRange,
      dueDate: homework.dueDate,
      attachmentUrls: homework.attachmentUrls,
      assignedToAll: homework.assignedToAll,
      createdAt: homework.createdAt,
    );

    // 1. Ödevi ekle
    final docRef = await _homeworksRef.add(model.toFirestore());
    final homeworkId = docRef.id;

    // 2. Her öğrenci için atomik batch ile homework_assignments oluştur
    final batch = _firestore.batch();
    for (final studentId in studentIds) {
      final assignmentRef = _assignmentsRef.doc();
      final assignmentModel = HomeworkAssignmentModel(
        id: assignmentRef.id,
        homeworkId: homeworkId,
        studentId: studentId,
        classId: homework.classId,
        teacherId: homework.teacherId,
        status: 'pending',
        updatedAt: DateTime.now(),
      );
      batch.set(assignmentRef, assignmentModel.toFirestore());
    }

    await batch.commit();
    return homeworkId;
  }

  @override
  Future<void> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    String? teacherNote,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (status == 'completed') {
      updates['completedAt'] = Timestamp.fromDate(DateTime.now());
    } else {
      updates['completedAt'] = null;
    }
    if (teacherNote != null) {
      updates['teacherNote'] = teacherNote;
    }

    await _assignmentsRef.doc(assignmentId).update(updates);
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    // 1. Ödevi sil
    await _homeworksRef.doc(homeworkId).delete();

    // 2. İlgili atamaları sil
    final assignments =
        await _assignmentsRef.where('homeworkId', isEqualTo: homeworkId).get();
    final batch = _firestore.batch();
    for (final doc in assignments.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
