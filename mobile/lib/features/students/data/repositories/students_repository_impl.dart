import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/students_repository.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  StudentsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection(AppConstants.colStudents);
  CollectionReference<Map<String, dynamic>> get _classesRef =>
      _firestore.collection(AppConstants.colClasses);
  CollectionReference<Map<String, dynamic>> get _inviteCodesRef =>
      _firestore.collection(AppConstants.colInviteCodes);

  @override
  Stream<List<StudentEntity>> getClassStudents(String classId,
      {required String teacherId}) {
    if (classId.isEmpty) return Stream.value([]);

    Query<Map<String, dynamic>> query =
        _studentsRef.where('classId', isEqualTo: classId);
    if (teacherId.isNotEmpty) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }

    return query.limit(AppConstants.pageSize).snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  @override
  Stream<StudentEntity?> getStudentStream(String studentId) {
    if (studentId.isEmpty) return Stream.value(null);
    return _studentsRef.doc(studentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StudentModel.fromFirestore(doc);
    });
  }

  @override
  Stream<List<StudentEntity>> getParentStudents(String parentUid) {
    if (parentUid.isEmpty) return Stream.value([]);
    return _studentsRef
        .where('parentIds', arrayContains: parentUid)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList();
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

    await _classesRef.doc(student.classId).update({
      'studentCount': FieldValue.increment(1),
    });

    await _syncClassInviteRoster(student.classId);
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
    await _syncClassInviteRoster(student.classId);
  }

  @override
  Future<void> deleteStudent(String studentId, String classId) async {
    await _studentsRef.doc(studentId).delete();

    await _classesRef.doc(classId).update({
      'studentCount': FieldValue.increment(-1),
    });

    await _syncClassInviteRoster(classId);
  }

  Future<void> _syncClassInviteRoster(String classId) async {
    try {
      final classDoc = await _classesRef.doc(classId).get();
      final code = classDoc.data()?['inviteCode'] as String?;
      if (code == null || code.isEmpty) return;

      final snapshot = await _studentsRef
          .where('classId', isEqualTo: classId)
          .limit(AppConstants.pageSize * 5)
          .get();

      final students = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? '',
          if (data['schoolNumber'] != null)
            'schoolNumber': data['schoolNumber'],
        };
      }).toList();

      students.sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

      await _inviteCodesRef.doc(code).set(
        {'students': students},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Davet kodu yoksa veya yetki yoksa sessizce geç
    }
  }
}
