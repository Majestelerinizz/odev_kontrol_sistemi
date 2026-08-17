import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

/// Admin read-only Firestore sorguları.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DashboardStats> fetchDashboardStats() async {
    final teachers = await _firestore
        .collection(AdminConstants.colUsers)
        .where('role', isEqualTo: AdminConstants.roleTeacher)
        .count()
        .get();
    final parents = await _firestore
        .collection(AdminConstants.colUsers)
        .where('role', isEqualTo: AdminConstants.roleParent)
        .count()
        .get();
    final students = await _firestore
        .collection(AdminConstants.colStudents)
        .count()
        .get();
    final classes = await _firestore
        .collection(AdminConstants.colClasses)
        .count()
        .get();

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentTeachersSnap = await _firestore
        .collection(AdminConstants.colUsers)
        .where('role', isEqualTo: AdminConstants.roleTeacher)
        .where('createdAt', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
        .count()
        .get();

    return DashboardStats(
      teacherCount: teachers.count ?? 0,
      parentCount: parents.count ?? 0,
      studentCount: students.count ?? 0,
      classCount: classes.count ?? 0,
      recentTeachers: recentTeachersSnap.count ?? 0,
    );
  }

  Future<PaginatedResult<TeacherSummary>> fetchTeachers({
    PaginationCursor? cursor,
    int limit = AdminConstants.pageSize,
  }) async {
    var query = _firestore
        .collection(AdminConstants.colUsers)
        .where('role', isEqualTo: AdminConstants.roleTeacher)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (cursor?.lastDocument != null) {
      query = query.startAfterDocument(cursor!.lastDocument!);
    }

    final snap = await query.get();
    final items = <TeacherSummary>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final uid = doc.id;
      final classCount = await _countForTeacher(
        AdminConstants.colClasses,
        uid,
      );
      final studentCount = await _countForTeacher(
        AdminConstants.colStudents,
        uid,
      );

      items.add(
        TeacherSummary(
          uid: uid,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          isActive: data['isActive'] as bool? ?? true,
          createdAt: _parseDate(data['createdAt']),
          classCount: classCount,
          studentCount: studentCount,
        ),
      );
    }

    return PaginatedResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<TeacherSummary?> fetchTeacher(String uid) async {
    final doc = await _firestore.collection(AdminConstants.colUsers).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    if (data['role'] != AdminConstants.roleTeacher) return null;

    return TeacherSummary(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseDate(data['createdAt']),
      classCount: await _countForTeacher(AdminConstants.colClasses, uid),
      studentCount: await _countForTeacher(AdminConstants.colStudents, uid),
    );
  }

  Future<List<ClassSummary>> fetchClassesForTeacher(String teacherId) async {
    final snap = await _firestore
        .collection(AdminConstants.colClasses)
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return ClassSummary(
        id: doc.id,
        name: data['name'] as String? ?? '',
        teacherId: teacherId,
        gradeLevel: data['gradeLevel']?.toString(),
        studentCount: data['studentCount'] as int? ?? 0,
      );
    }).toList();
  }

  Future<PaginatedResult<StudentSummary>> fetchStudents({
    String? teacherId,
    PaginationCursor? cursor,
    int limit = AdminConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(AdminConstants.colStudents);

    if (teacherId != null && teacherId.isNotEmpty) {
      query = query
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    query = query.limit(limit);
    if (cursor?.lastDocument != null) {
      query = query.startAfterDocument(cursor!.lastDocument!);
    }

    final snap = await query.get();
    final items = snap.docs.map((doc) {
      final data = doc.data();
      final parentIds = data['parentIds'] as List<dynamic>? ?? [];
      return StudentSummary(
        id: doc.id,
        name: data['name'] as String? ?? '',
        teacherId: data['teacherId'] as String? ?? '',
        classId: data['classId'] as String? ?? '',
        schoolNumber: data['schoolNumber'] as String?,
        parentCount: parentIds.length,
        createdAt: _parseDate(data['createdAt']),
      );
    }).toList();

    return PaginatedResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<ActivityItem>> fetchRecentActivity({
    int limit = AdminConstants.activityLimit,
  }) async {
    final perSource = (limit / 4).ceil().clamp(5, 15);
    final items = <ActivityItem>[];

    final teachers = await _firestore
        .collection(AdminConstants.colUsers)
        .where('role', isEqualTo: AdminConstants.roleTeacher)
        .orderBy('createdAt', descending: true)
        .limit(perSource)
        .get();
    for (final doc in teachers.docs) {
      final data = doc.data();
      items.add(
        ActivityItem(
          type: 'teacher',
          title: 'Yeni öğretmen: ${data['name'] ?? ''}',
          subtitle: data['email'] as String? ?? '',
          createdAt: _parseDate(data['createdAt']),
        ),
      );
    }

    final homeworks = await _firestore
        .collection(AdminConstants.colHomeworks)
        .orderBy('createdAt', descending: true)
        .limit(perSource)
        .get();
    for (final doc in homeworks.docs) {
      final data = doc.data();
      items.add(
        ActivityItem(
          type: 'homework',
          title: 'Ödev: ${data['title'] ?? ''}',
          subtitle: data['subject'] as String? ?? '',
          createdAt: _parseDate(data['createdAt']),
        ),
      );
    }

    final exams = await _firestore
        .collection(AdminConstants.colExamResults)
        .orderBy('createdAt', descending: true)
        .limit(perSource)
        .get();
    for (final doc in exams.docs) {
      final data = doc.data();
      items.add(
        ActivityItem(
          type: 'exam',
          title: 'Deneme: ${data['examName'] ?? ''}',
          subtitle: 'Net: ${data['totalNet'] ?? '-'}',
          createdAt: _parseDate(data['createdAt']),
        ),
      );
    }

    final messages = await _firestore
        .collection(AdminConstants.colMessages)
        .orderBy('createdAt', descending: true)
        .limit(perSource)
        .get();
    for (final doc in messages.docs) {
      final data = doc.data();
      items.add(
        ActivityItem(
          type: 'message',
          title: data['title'] as String? ?? 'Mesaj',
          subtitle: data['body'] as String? ?? '',
          createdAt: _parseDate(data['createdAt']),
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  Future<List<TeacherSummary>> fetchAllTeachersForPicker() async {
    final snap = await _firestore
        .collection(AdminConstants.colUsers)
        .where('role', isEqualTo: AdminConstants.roleTeacher)
        .get();

    final teachers = snap.docs.map((doc) {
      final data = doc.data();
      return TeacherSummary(
        uid: doc.id,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        isActive: data['isActive'] as bool? ?? true,
        createdAt: _parseDate(data['createdAt']),
      );
    }).toList();

    teachers.sort((a, b) => a.name.compareTo(b.name));
    return teachers;
  }

  Future<int> countBroadcastTargets({
    required String audience,
    String? teacherId,
  }) async {
    final uids = await _resolveTargetUids(audience: audience, teacherId: teacherId);
    return uids.length;
  }

  Future<Set<String>> _resolveTargetUids({
    required String audience,
    String? teacherId,
  }) async {
    final uids = <String>{};

    switch (audience) {
      case 'all_teachers':
        final snap = await _firestore
            .collection(AdminConstants.colUsers)
            .where('role', isEqualTo: AdminConstants.roleTeacher)
            .get();
        uids.addAll(snap.docs.map((d) => d.id));
      case 'all_parents':
        final snap = await _firestore
            .collection(AdminConstants.colUsers)
            .where('role', isEqualTo: AdminConstants.roleParent)
            .get();
        uids.addAll(snap.docs.map((d) => d.id));
      case 'all_users':
        final teachers = await _firestore
            .collection(AdminConstants.colUsers)
            .where('role', isEqualTo: AdminConstants.roleTeacher)
            .get();
        final parents = await _firestore
            .collection(AdminConstants.colUsers)
            .where('role', isEqualTo: AdminConstants.roleParent)
            .get();
        uids.addAll(teachers.docs.map((d) => d.id));
        uids.addAll(parents.docs.map((d) => d.id));
      case 'parents_of_teacher':
        if (teacherId == null) break;
        uids.addAll(await _parentIdsForTeacher(teacherId));
      case 'teacher_and_parents_of_teacher':
        if (teacherId == null) break;
        uids.add(teacherId);
        uids.addAll(await _parentIdsForTeacher(teacherId));
    }

    return uids;
  }

  Future<Set<String>> _parentIdsForTeacher(String teacherId) async {
    final snap = await _firestore
        .collection(AdminConstants.colStudents)
        .where('teacherId', isEqualTo: teacherId)
        .get();
    final parentIds = <String>{};
    for (final doc in snap.docs) {
      final ids = doc.data()['parentIds'] as List<dynamic>? ?? [];
      parentIds.addAll(ids.map((e) => e.toString()));
    }
    return parentIds;
  }

  Future<int> _countForTeacher(String collection, String teacherId) async {
    final result = await _firestore
        .collection(collection)
        .where('teacherId', isEqualTo: teacherId)
        .count()
        .get();
    return result.count ?? 0;
  }
}
