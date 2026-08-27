/// Uygulama genelinde kullanılan sabitler
class AppConstants {
  AppConstants._();

  // ── Firebase koleksiyon adları ────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colTeacherProfiles = 'teacher_profiles';
  static const String colParentProfiles = 'parent_profiles';
  static const String colClasses = 'classes';
  static const String colStudents = 'students';
  static const String colInviteCodes = 'invite_codes';
  static const String colHomeworks = 'homeworks';
  static const String colHomeworkAssignments = 'homework_assignments';
  static const String colExamResults = 'exam_results';
  static const String colSubjectProgress = 'subject_progress';
  static const String colGoals = 'goals';
  static const String colMessages = 'messages';
  static const String colNotifications = 'notifications';
  static const String colAdminBroadcasts = 'admin_broadcasts';

  // ── Kullanıcı rolleri ─────────────────────────────────────────────────────
  static const String roleTeacher = 'teacher';
  static const String roleParent = 'parent';
  static const String roleAdmin = 'admin';

  // ── Ödev durumları ────────────────────────────────────────────────────────
  static const String hwPending = 'pending';
  static const String hwCompleted = 'completed';
  static const String hwMissed = 'missed';
  static const String hwOverdue = 'overdue';

  // ── Konu durumları ────────────────────────────────────────────────────────
  static const String topicCompleted = 'completed';
  static const String topicImprove = 'improve';
  static const String topicMissing = 'missing';

  // ── Hedef türleri ─────────────────────────────────────────────────────────
  static const String goalScore = 'score';
  static const String goalNet = 'net';
  static const String goalHomeworkCount = 'homework_count';

  // ── Mesaj türleri ─────────────────────────────────────────────────────────
  static const String msgIndividual = 'individual';
  static const String msgBulk = 'bulk';

  // ── Bildirim türleri ──────────────────────────────────────────────────────
  static const String notifHomework = 'homework';
  static const String notifExam = 'exam';
  static const String notifMessage = 'message';
  static const String notifSystem = 'system';

  // ── Dosya yükleme ─────────────────────────────────────────────────────────
  static const int maxFileSizeMb = 10;
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];

  // ── Net hesaplama ─────────────────────────────────────────────────────────
  static const double defaultWrongPenalty = 4.0;

  // ── Davet kodu ────────────────────────────────────────────────────────────
  /// Sınıf kodları süresiz; eski öğrenci kodları için yedek süre.
  static const int inviteCodeExpiryDays = 365;

  // ── Sayfalama ─────────────────────────────────────────────────────────────
  static const int pageSize = 20;

  // ── Uygulama bilgileri ────────────────────────────────────────────────────
  static const String supportEmail = 'destek@eduly.app';
  static const String privacyPolicyUrl = 'https://eduly-server.web.app/privacy.html';
  static const String termsUrl = 'https://eduly-server.web.app/terms.html';
  static const String storeSupportUrl = 'https://eduly-server.web.app/support.html';
}
