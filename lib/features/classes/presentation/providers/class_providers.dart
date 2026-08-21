import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/classes_repository_impl.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/repositories/classes_repository.dart';

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepositoryImpl();
});

/// Giriş yapmış öğretmenin tüm sınıflarının canlı akışı
final teacherClassesStreamProvider = StreamProvider<List<ClassEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isTeacher) {
    return Stream.value([]);
  }
  return ref.watch(classesRepositoryProvider).getTeacherClasses(user.uid);
});

/// Tek bir sınıfın detay akışı
final classStreamProvider =
    StreamProvider.family<ClassEntity?, String>((ref, classId) {
  if (classId.isEmpty) return Stream.value(null);
  return ref.watch(classesRepositoryProvider).getClassStream(classId);
});

/// Sınıf Ekleme / Silme İşlemleri Notifier'ı
class ClassNotifier extends StateNotifier<AsyncValue<void>> {
  ClassNotifier(this._repo) : super(const AsyncValue.data(null));

  final ClassesRepository _repo;

  Future<bool> createClass({
    required String teacherId,
    required String name,
    required int gradeLevel,
    String? schoolName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newClass = ClassEntity(
        id: '',
        teacherId: teacherId,
        name: name,
        gradeLevel: gradeLevel,
        schoolName: schoolName,
        createdAt: DateTime.now(),
      );
      await _repo.addClass(newClass);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteClass(String classId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteClass(classId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final classNotifierProvider =
    StateNotifierProvider<ClassNotifier, AsyncValue<void>>((ref) {
  return ClassNotifier(ref.watch(classesRepositoryProvider));
});
