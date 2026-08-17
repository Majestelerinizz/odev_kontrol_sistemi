/// Uygulama genelinde kullanılan metin sabitleri (Türkçe)
class AppStrings {
  AppStrings._();

  // ── Genel ─────────────────────────────────────────────────────────────────
  static const String appName = 'Ödev Takip';
  static const String ok = 'Tamam';
  static const String cancel = 'İptal';
  static const String save = 'Kaydet';
  static const String delete = 'Sil';
  static const String edit = 'Düzenle';
  static const String add = 'Ekle';
  static const String back = 'Geri';
  static const String yes = 'Evet';
  static const String no = 'Hayır';
  static const String loading = 'Yükleniyor...';
  static const String retry = 'Tekrar Dene';
  static const String close = 'Kapat';
  static const String confirm = 'Onayla';
  static const String search = 'Ara';
  static const String filter = 'Filtrele';
  static const String selectAll = 'Tümünü Seç';
  static const String done = 'Bitti';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = 'Giriş Yap';
  static const String logout = 'Çıkış Yap';
  static const String register = 'Kayıt Ol';
  static const String email = 'E-posta';
  static const String password = 'Şifre';
  static const String passwordConfirm = 'Şifre Tekrar';
  static const String fullName = 'Ad Soyad';
  static const String phone = 'Telefon';
  static const String forgotPassword = 'Şifremi Unuttum';
  static const String resetPassword = 'Şifre Sıfırla';
  static const String roleTeacher = 'Öğretmen';
  static const String roleParent = 'Veli';
  static const String inviteCode = 'Davet Kodu';
  static const String inviteCodeHint = 'Örnek: OT-8A-A7K9M2';
  static const String termsAccept = 'Kullanım koşullarını kabul ediyorum';
  static const String privacyPolicy = 'Gizlilik Politikası';
  static const String termsOfService = 'Kullanım Koşulları';
  static const String welcomeBack = 'Tekrar Hoş Geldiniz';
  static const String createAccount = 'Hesap Oluştur';
  static const String alreadyHaveAccount = 'Zaten hesabım var';
  static const String dontHaveAccount = 'Hesabınız yok mu?';

  // ── Rol seçimi ────────────────────────────────────────────────────────────
  static const String roleSelectionTitle = 'Rolünüzü Seçin';
  static const String roleSelectionSubtitle = 'Devam etmek için rolünüzü seçiniz';
  static const String teacherRoleDesc = 'Sınıflarınızı ve öğrencilerinizi yönetin';
  static const String parentRoleDesc = 'Çocuğunuzun gelişimini takip edin';

  // ── Sınıf ─────────────────────────────────────────────────────────────────
  static const String classes = 'Sınıflar';
  static const String addClass = 'Sınıf Ekle';
  static const String className = 'Sınıf Adı';
  static const String gradeLevel = 'Sınıf Seviyesi';
  static const String schoolName = 'Okul Adı';
  static const String academicYear = 'Öğretim Yılı';
  static const String studentCount = 'Öğrenci Sayısı';

  // ── Öğrenci ───────────────────────────────────────────────────────────────
  static const String students = 'Öğrenciler';
  static const String addStudent = 'Öğrenci Ekle';
  static const String studentName = 'Öğrenci Adı';
  static const String schoolNumber = 'Okul Numarası';
  static const String studentProfile = 'Öğrenci Profili';
  static const String noStudents = 'Henüz öğrenci eklenmedi';
  static const String generateInviteCode = 'Davet Kodu Oluştur';
  static const String targetScore = 'Hedef Puan';
  static const String teacherNote = 'Öğretmen Notu';

  // ── Ödev ──────────────────────────────────────────────────────────────────
  static const String homeworks = 'Ödevler';
  static const String addHomework = 'Ödev Ekle';
  static const String homeworkTitle = 'Ödev Başlığı';
  static const String subject = 'Ders';
  static const String sourceName = 'Kaynak / Test Adı';
  static const String questionRange = 'Soru Aralığı';
  static const String dueDate = 'Teslim Tarihi';
  static const String description = 'Açıklama';
  static const String assignToAll = 'Tüm Sınıfa Ata';
  static const String selectStudents = 'Öğrenci Seç';
  static const String addAttachment = 'Ek Dosya Ekle';
  static const String noHomeworks = 'Henüz ödev eklenmedi';

  // ── Ödev durumları ────────────────────────────────────────────────────────
  static const String statusPending = 'Bekliyor';
  static const String statusCompleted = 'Tamamlandı';
  static const String statusMissed = 'Yapılmadı';
  static const String statusOverdue = 'Gecikti';

  // ── Deneme ────────────────────────────────────────────────────────────────
  static const String exams = 'Denemeler';
  static const String addExam = 'Deneme Ekle';
  static const String examName = 'Deneme Adı';
  static const String examDate = 'Tarih';
  static const String publisher = 'Yayınevi';
  static const String correct = 'Doğru';
  static const String wrong = 'Yanlış';
  static const String blank = 'Boş';
  static const String net = 'Net';
  static const String totalNet = 'Toplam Net';
  static const String totalScore = 'Toplam Puan';

  // ── Konu analizi ──────────────────────────────────────────────────────────
  static const String analytics = 'Analizler';
  static const String subjectProgress = 'Konu İlerlemesi';
  static const String topicMap = 'Konu Haritası';
  static const String statusCompleteLabel = 'Tamamlandı';
  static const String statusImproveLabel = 'Geliştirilmeli';
  static const String statusMissingLabel = 'Eksik';

  // ── Hedef ─────────────────────────────────────────────────────────────────
  static const String goals = 'Hedefler';
  static const String addGoal = 'Hedef Belirle';
  static const String goalType = 'Hedef Türü';
  static const String targetValue = 'Hedef Değer';
  static const String currentValue = 'Mevcut Değer';
  static const String remaining = 'Kalan';
  static const String startDate = 'Başlangıç Tarihi';
  static const String endDate = 'Bitiş Tarihi';

  // ── Mesaj ─────────────────────────────────────────────────────────────────
  static const String messages = 'Mesajlar';
  static const String sendMessage = 'Mesaj Gönder';
  static const String bulkMessage = 'Toplu Mesaj';
  static const String messageTitle = 'Başlık';
  static const String messageBody = 'Mesaj';
  static const String noMessages = 'Henüz mesaj yok';

  // ── Bildirimler ───────────────────────────────────────────────────────────
  static const String notifications = 'Bildirimler';
  static const String noNotifications = 'Bildirim bulunmuyor';
  static const String markAllRead = 'Tümünü Okundu İşaretle';

  // ── Profil ────────────────────────────────────────────────────────────────
  static const String profile = 'Profil';
  static const String editProfile = 'Profili Düzenle';
  static const String changePassword = 'Şifre Değiştir';
  static const String deleteAccount = 'Hesabı Sil';
  static const String settings = 'Ayarlar';
  static const String logoutConfirm = 'Çıkış yapmak istediğinizden emin misiniz?';
  static const String deleteAccountConfirm =
      'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  // ── Hata mesajları ────────────────────────────────────────────────────────
  static const String errorEmailRequired = 'E-posta adresi zorunludur.';
  static const String errorEmailInvalid = 'Geçerli bir e-posta adresi giriniz.';
  static const String errorPasswordRequired = 'Şifre zorunludur.';
  static const String errorPasswordMin = 'Şifre en az 8 karakter olmalıdır.';
  static const String errorPasswordMatch = 'Şifreler eşleşmiyor.';
  static const String errorNameRequired = 'Ad soyad zorunludur.';
  static const String errorInvalidCredentials = 'E-posta veya şifre hatalı.';
  static const String errorEmailInUse = 'Bu e-posta adresi zaten kullanılıyor.';
  static const String errorWeakPassword = 'Şifreniz çok zayıf.';
  static const String errorInviteCodeRequired = 'Davet kodu zorunludur.';
  static const String errorInviteCodeInvalid = 'Geçersiz davet kodu.';
  static const String errorInviteCodeExpired = 'Bu davet kodunun süresi dolmuş.';
  static const String errorInviteCodeUsed = 'Bu davet kodu daha önce kullanılmış.';
  static const String errorNoAccess = 'Bu öğrenciye erişim yetkiniz bulunmuyor.';
  static const String errorNetwork = 'İnternet bağlantısı kurulamadı. Lütfen tekrar deneyin.';
  static const String errorSaveFailed = 'Kaydedilemedi. Bilgileri kontrol edip tekrar deneyin.';
  static const String errorUnknown = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorHomeworkTitleRequired = 'Ödev başlığı zorunludur.';
  static const String errorSubjectRequired = 'Ders seçimi zorunludur.';
  static const String errorDueDatePast = 'Teslim tarihi geçmiş bir tarih olamaz.';
  static const String errorSelectStudents = 'En az bir öğrenci veya tüm sınıf seçilmelidir.';
  static const String errorNegativeNumber = 'Negatif değer girilemez.';
  static const String errorClassNameRequired = 'Sınıf adı zorunludur.';
  static const String errorStudentNameRequired = 'Öğrenci adı zorunludur.';
  static const String errorClassRequired = 'Sınıf seçimi zorunludur.';
  static const String errorTermsRequired = 'Kullanım koşullarını kabul etmelisiniz.';

  // ── Başarı mesajları ──────────────────────────────────────────────────────
  static const String successSaved = 'Başarıyla kaydedildi.';
  static const String successDeleted = 'Başarıyla silindi.';
  static const String successPasswordReset = 'Şifre sıfırlama bağlantısı e-postanıza gönderildi.';
  static const String successInviteCodeCopied = 'Davet kodu kopyalandı.';
  static const String successMessageSent = 'Mesaj başarıyla gönderildi.';
  static const String successHomeworkAdded = 'Ödev başarıyla eklendi.';
  static const String successExamAdded = 'Deneme sonucu başarıyla eklendi.';

  // ── Dersler ───────────────────────────────────────────────────────────────
  static const List<String> subjects = [
    'Türkçe',
    'Matematik',
    'Fen Bilimleri',
    'Sosyal Bilgiler',
    'İngilizce',
    'Din Kültürü',
    'Görsel Sanatlar',
    'Beden Eğitimi',
    'Müzik',
    'Bilişim Teknolojileri',
    'Trafik ve İlkyardım',
    'Diğer',
  ];

  // ── Sınıf seviyeleri ──────────────────────────────────────────────────────
  static const List<int> gradeLevels = [1, 2, 3, 4, 5, 6, 7, 8];

  // ── Akademik yıllar ───────────────────────────────────────────────────────
  static const List<String> academicYears = [
    '2025-2026',
    '2026-2027',
    '2027-2028',
  ];
}
