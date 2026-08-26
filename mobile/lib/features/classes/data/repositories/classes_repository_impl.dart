import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/class_model.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/repositories/classes_repository.dart';

class ClassesRepositoryImpl implements ClassesRepository {
  ClassesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _classesRef =>
      _firestore.collection('classes');

  @override
  Stream<List<ClassEntity>> getTeacherClasses(String teacherId) {
    if (teacherId.isEmpty) return Stream.value([]);
    return _classesRef
        .where('teacherId', isEqualTo: teacherId)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ClassModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
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
    await _classesRef.doc(classId).delete();
  }
}
