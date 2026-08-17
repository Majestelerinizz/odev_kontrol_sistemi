class AdminUser {
  const AdminUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.isActive = true,
    this.createdAt,
  });

  final String uid;
  final String role;
  final String name;
  final String email;
  final bool isActive;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
}

class TeacherSummary {
  const TeacherSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.isActive,
    required this.createdAt,
    this.classCount = 0,
    this.studentCount = 0,
  });

  final String uid;
  final String name;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final int classCount;
  final int studentCount;
}

class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.classId,
    this.schoolNumber,
    this.parentCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String teacherId;
  final String classId;
  final String? schoolNumber;
  final int parentCount;
  final DateTime? createdAt;
}

class ClassSummary {
  const ClassSummary({
    required this.id,
    required this.name,
    required this.teacherId,
    this.gradeLevel,
    this.studentCount = 0,
  });

  final String id;
  final String name;
  final String teacherId;
  final String? gradeLevel;
  final int studentCount;
}

class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
  });

  final String type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
}

class DashboardStats {
  const DashboardStats({
    this.teacherCount = 0,
    this.parentCount = 0,
    this.studentCount = 0,
    this.classCount = 0,
    this.recentTeachers = 0,
  });

  final int teacherCount;
  final int parentCount;
  final int studentCount;
  final int classCount;
  final int recentTeachers;
}

enum BroadcastAudience {
  allTeachers('all_teachers', 'Tüm öğretmenler'),
  allParents('all_parents', 'Tüm veliler'),
  allUsers('all_users', 'Tüm kullanıcılar'),
  parentsOfTeacher('parents_of_teacher', 'Seçili öğretmenin velileri'),
  teacherAndParentsOfTeacher(
    'teacher_and_parents_of_teacher',
    'Öğretmen + velileri',
  );

  const BroadcastAudience(this.value, this.label);
  final String value;
  final String label;

  bool get requiresTeacher =>
      this == parentsOfTeacher || this == teacherAndParentsOfTeacher;

  static BroadcastAudience? fromValue(String value) {
    for (final item in BroadcastAudience.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}
