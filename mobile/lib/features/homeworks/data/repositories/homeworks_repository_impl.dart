import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
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
    if (teacherId.isEmpty) return Stream.value([]);
    return _homeworksRef
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HomeworkModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<HomeworkEntity>> getClassHomeworks(String classId) {
    if (classId.isEmpty) return Stream.value([]);
    return _homeworksRef
        .where('classId', isEqualTo: classId)
        .orderBy('dueDate', descending: true)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HomeworkModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<HomeworkAssignmentEntity>> getHomeworkAssignments(
      String homeworkId) {
    if (homeworkId.isEmpty) return Stream.value([]);
    return _assignmentsRef
        .where('homeworkId', isEqualTo: homeworkId)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HomeworkAssignmentModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<HomeworkAssignmentEntity>> getStudentAssignments(
      String studentId) {
    if (studentId.isEmpty) return Stream.value([]);
    return _assignmentsRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('updatedAt', descending: true)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HomeworkAssignmentModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<HomeworkEntity?> getHomeworkById(String homeworkId) async {
    if (homeworkId.isEmpty) return null;
    final doc = await _homeworksRef.doc(homeworkId).get();
    if (!doc.exists) return null;
    return HomeworkModel.fromFirestore(doc);
  }

  @override
  Future<Map<String, HomeworkEntity>> getHomeworksByIds(
      List<String> homeworkIds) async {
    final unique = homeworkIds.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return {};

    // Tekil get: veli list sorgusu (whereIn) rules ile kırılmasın;
    // yetkisiz/eksik dokümanlar atlanır.
    final result = <String, HomeworkEntity>{};
    await Future.wait(unique.map((id) async {
      try {
        final doc = await _homeworksRef.doc(id).get();
        if (doc.exists) {
          result[id] = HomeworkModel.fromFirestore(doc);
        }
      } catch (_) {
        // permission-denied veya ağ — kart başlıksız kalabilir
      }
    }));
    return result;
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
      studentIds: List<String>.from(studentIds),
      createdAt: homework.createdAt,
    );

    final docRef = await _homeworksRef.add(model.toFirestore());
    final homeworkId = docRef.id;

    for (var i = 0; i < studentIds.length; i += 400) {
      final end =
          i + 400 > studentIds.length ? studentIds.length : i + 400;
      final chunk = studentIds.sublist(i, end);
      final batch = _firestore.batch();
      for (final studentId in chunk) {
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
    }
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
    final assignments =
        await _assignmentsRef.where('homeworkId', isEqualTo: homeworkId).get();
    for (var i = 0; i < assignments.docs.length; i += 400) {
      final end = i + 400 > assignments.docs.length
          ? assignments.docs.length
          : i + 400;
      final batch = _firestore.batch();
      for (final doc in assignments.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _homeworksRef.doc(homeworkId).delete();
  }
}
