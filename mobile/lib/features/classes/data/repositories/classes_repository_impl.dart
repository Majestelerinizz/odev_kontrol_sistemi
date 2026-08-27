import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/class_model.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/repositories/classes_repository.dart';
import '../../../students/data/models/invite_code_model.dart';

class ClassesRepositoryImpl implements ClassesRepository {
  ClassesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _classesRef =>
      _firestore.collection(AppConstants.colClasses);
  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection(AppConstants.colStudents);
  CollectionReference<Map<String, dynamic>> get _inviteCodesRef =>
      _firestore.collection(AppConstants.colInviteCodes);

  @override
  Stream<List<ClassEntity>> getTeacherClasses(String teacherId) {
    if (teacherId.isEmpty) return Stream.value([]);
    return _classesRef
        .where('teacherId', isEqualTo: teacherId)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  @override
  Stream<ClassEntity?> getClassStream(String classId) {
    if (classId.isEmpty) return Stream.value(null);
    return _classesRef.doc(classId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClassModel.fromFirestore(doc);
    });
  }

  @override
  Future<String> addClass(ClassEntity classEntity) async {
    final model = ClassModel.fromEntity(classEntity);
    final docRef = await _classesRef.add(model.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateClass(ClassEntity classEntity) async {
    final model = ClassModel.fromEntity(classEntity);
    await _classesRef.doc(classEntity.id).update(model.toFirestore());
  }

  @override
  Future<void> deleteClass(String classId) async {
    final classDoc = await _classesRef.doc(classId).get();
    final inviteCode = classDoc.data()?['inviteCode'] as String?;
    if (inviteCode != null && inviteCode.isNotEmpty) {
      await _inviteCodesRef.doc(inviteCode).set(
        {'revoked': true},
        SetOptions(merge: true),
      );
    }
    await _classesRef.doc(classId).delete();
  }

  @override
  Future<InviteCodeModel> generateClassInviteCode({
    required String classId,
    required String teacherId,
  }) async {
    final classDoc = await _classesRef.doc(classId).get();
    if (!classDoc.exists) {
      throw Exception('Sınıf bulunamadı.');
    }
    final classData = classDoc.data()!;
    if (classData['teacherId'] != teacherId) {
      throw Exception('Bu sınıf için yetkiniz yok.');
    }

    final className = classData['name'] as String? ?? '';
    final oldCode = classData['inviteCode'] as String?;
    if (oldCode != null && oldCode.isNotEmpty) {
      await _inviteCodesRef.doc(oldCode).set(
        {'revoked': true},
        SetOptions(merge: true),
      );
    }

    final students = await _loadStudentOptions(classId);
    final code = _generateRandomCode();
    final now = DateTime.now();

    final invite = InviteCodeModel(
      code: code,
      type: 'class',
      classId: classId,
      className: className,
      students: students,
      teacherId: teacherId,
      createdAt: now,
    );

    final batch = _firestore.batch();
    batch.set(_inviteCodesRef.doc(code), invite.toFirestore());
    batch.update(_classesRef.doc(classId), {'inviteCode': code});
    await batch.commit();

    return invite;
  }

  @override
  Future<InviteCodeModel?> getActiveClassInviteCode(String classId) async {
    try {
      final classDoc = await _classesRef.doc(classId).get();
      if (!classDoc.exists) return null;
      final code = classDoc.data()?['inviteCode'] as String?;
      if (code == null || code.isEmpty) return null;

      final inviteDoc = await _inviteCodesRef.doc(code).get();
      if (!inviteDoc.exists) return null;

      final invite = InviteCodeModel.fromFirestore(inviteDoc);
      if (!invite.isValid) return null;

      // Öğrenci listesini güncel tut
      await refreshClassInviteRoster(classId);
      final refreshed = await _inviteCodesRef.doc(code).get();
      return InviteCodeModel.fromFirestore(refreshed);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> refreshClassInviteRoster(String classId) async {
    final classDoc = await _classesRef.doc(classId).get();
    if (!classDoc.exists) return;
    final code = classDoc.data()?['inviteCode'] as String?;
    if (code == null || code.isEmpty) return;

    final students = await _loadStudentOptions(classId);
    final className = classDoc.data()?['name'] as String? ?? '';
    await _inviteCodesRef.doc(code).set(
      {
        'students': students.map((s) => s.toMap()).toList(),
        'className': className,
      },
      SetOptions(merge: true),
    );
  }

  Future<List<InviteStudentOption>> _loadStudentOptions(String classId) async {
    final snapshot = await _studentsRef
        .where('classId', isEqualTo: classId)
        .limit(AppConstants.pageSize * 5)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      return InviteStudentOption(
        id: doc.id,
        name: data['name'] as String? ?? '',
        schoolNumber: data['schoolNumber'] as String?,
      );
    }).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomPart =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'OT-$randomPart';
  }
}
