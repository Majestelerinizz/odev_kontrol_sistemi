/// Firestore koleksiyon adları ve sabitler.
class AdminConstants {
  AdminConstants._();

  static const String colUsers = 'users';
  static const String colTeacherProfiles = 'teacher_profiles';
  static const String colClasses = 'classes';
  static const String colStudents = 'students';
  static const String colHomeworks = 'homeworks';
  static const String colExamResults = 'exam_results';
  static const String colMessages = 'messages';
  static const String colAdminBroadcasts = 'admin_broadcasts';

  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleParent = 'parent';

  static const int pageSize = 25;
  static const int activityLimit = 50;
}
