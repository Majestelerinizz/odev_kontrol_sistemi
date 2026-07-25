import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/invite_code_model.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/students_repository.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  StudentsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');
  CollectionReference<Map<String, dynamic>> get _classesRef =>
      _firestore.collection('classes');
  CollectionReference<Map<String, dynamic>> get _inviteCodesRef =>
      _firestore.collection('invite_codes');

  @override
  Stream<List<StudentEntity>> getClassStudents(String classId) {
    return _studentsRef
        .where('classId', isEqualTo: classId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<StudentEntity?> getStudentStream(String studentId) {
    return _studentsRef.doc(studentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StudentModel.fromFirestore(doc);
    });
  }

  @override
  Future<String> addStudent(StudentEntity student) async {
    final model = StudentModel(
      id: '',
      classId: student.classId,
      teacherId: student.teacherId,
      name: student.name,
      schoolNumber: student.schoolNumber,
      phone: student.phone,
      parentIds: student.parentIds,
      targetScore: student.targetScore,
      teacherNote: student.teacherNote,
      createdAt: student.createdAt,
    );

    final docRef = await _studentsRef.add(model.toFirestore());

    // Sınıfın öğrenci sayısını artır
    await _classesRef.doc(student.classId).update({
      'studentCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  @override
  Future<void> updateStudent(StudentEntity student) async {
    final model = StudentModel(
      id: student.id,
      classId: student.classId,
      teacherId: student.teacherId,
      name: student.name,
      schoolNumber: student.schoolNumber,
      phone: student.phone,
      parentIds: student.parentIds,
      targetScore: student.targetScore,
      teacherNote: student.teacherNote,
      createdAt: student.createdAt,
    );

    await _studentsRef.doc(student.id).update(model.toFirestore());
  }

  @override
  Future<void> deleteStudent(String studentId, String classId) async {
    await _studentsRef.doc(studentId).delete();

    // Sınıfın öğrenci sayısını azalt
    await _classesRef.doc(classId).update({
      'studentCount': FieldValue.increment(-1),
    });
  }

  @override
  Future<InviteCodeModel> generateInviteCode({
    required String studentId,
    required String teacherId,
  }) async {
    // 6 haneli rastgele kod üret: Örn 'OT-A7K9M2'
    final code = _generateRandomCode();
    final expiresAt = DateTime.now().add(const Duration(days: 14)); // 14 gün geçerli

    final inviteModel = InviteCodeModel(
      code: code,
      studentId: studentId,
      teacherId: teacherId,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );

    await _inviteCodesRef.doc(code).set(inviteModel.toFirestore());
    return inviteModel;
  }

  @override
  Future<InviteCodeModel?> getActiveInviteCode(String studentId) async {
    final query = await _inviteCodesRef
        .where('studentId', isEqualTo: studentId)
        .where('used', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final model = InviteCodeModel.fromFirestore(query.docs.first);
    return model.isExpired ? null : model;
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomPart =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'OT-$randomPart';
  }
}
