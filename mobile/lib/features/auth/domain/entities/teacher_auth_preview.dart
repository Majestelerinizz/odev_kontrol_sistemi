/// Öğretmen e-posta önizleme sonucu (giriş / kayıt ayrımı için).
class TeacherAuthPreview {
  const TeacherAuthPreview({
    required this.exists,
    this.name,
    this.role,
  });

  final bool exists;
  final String? name;
  final String? role;

  bool get isTeacher => role == 'teacher';
  bool get isParent => role == 'parent';
}
