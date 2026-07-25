# 📝 Ödev Takip Sistemi — Yapılan Görevler ve Modül Raporu

Bu belge, **Ödev Takip Sistemi** projesinde tamamlanan tüm aşamaları, geliştirilen modülleri, yazılan testleri ve teknik mimari kararlarını detaylıca listelemektedir.

---

## 📌 Tamamlanan Aşamalar Özeti

| Faz | Açıklama | Durum | Test Durumu |
|---|---|---|---|
| **Faz 1** | Proje Mimarisi, Tema, Riverpod, GoRouter, Auth & Rol Girişleri | **%100 Tamamlandı** | 17/17 Geçti |
| **Faz 2.1** | Sınıf ve Öğrenci Yönetimi, 6 Haneli Veli Davet Kodu Üretimi | **%100 Tamamlandı** | 20/20 Geçti |
| **Faz 2.2** | Ödev Oluşturma, Sınıfa Toplu Atama ve Veli Durum Takibi | **%100 Tamamlandı** | 22/22 Geçti |
| **Faz 2.3** | Deneme Sınavı Girişi, Anlık Net Hesabı, `fl_chart` Grafikleri & Hedefler | **%100 Tamamlandı** | 25/25 Geçti |

---

## 🛠 Detaylı Görev Listesi

### 1. 🎨 Mimarinin ve Tasarım Sisteminin Kurulumu (Faz 1)
- [x] **Tasarım Sistemi**: `AppTheme`, `AppColors`, `AppTextStyles`, `AppSizes` oluşturuldu.
- [x] **Ortak Bileşenler**: `PrimaryButton`, `SecondaryButton`, `AppTextField`, `StatusBadge`, `EmptyState` kodlandı.
- [x] **Yönlendirme (`GoRouter`)**: `RoleGuard` eklendi. Öğretmenin veli sayfasına, velinin öğretmen sayfasına erişimi engellendi.
- [x] **Firebase Auth**: E-posta/Şifre ile kayıt, giriş ve şifre sıfırlama akışları bağlandı.
- [x] **Rol Seçim Ekranları**: Öğretmen ve Veli kayıt formları ayrıştırıldı.
- [x] **Güvenlik Kuralları**: `firestore.rules` ile öğretmen ve veli verilerine yetkisiz erişim kapatıldı.

### 2. 🏫 Sınıf ve Öğrenci Yönetimi (Faz 2.1)
- [x] `ClassEntity`, `ClassModel`, `StudentEntity`, `StudentModel` oluşturuldu.
- [x] `ClassesRepository` ve `StudentsRepository` Firestore canlı akışları (`snapshots`) yazıldı.
- [x] Öğretmen için **Sınıflarım Ekranı** (`ClassListScreen`) yapıldı.
- [x] **Sınıf Detay Ekranı** (`ClassDetailScreen`) eklendi: Öğrenci ekleme formu ve anlık isim/okul no arama filtresi.
- [x] **Veli Davet Kodu Mimarisi**: `InviteCodeModel` ile `OT-XXXXXX` biçiminde 14 gün geçerli 6 haneli benzersiz davet kodu üretme fonksiyonu yazıldı.
- [x] **Öğrenci Detay Ekranı** (`StudentDetailScreen`): Veli eşleşme durumu, davet kodunu kopyalama ve öğretmen özel notu alanı eklendi.

### 3. 📚 Ödev Sistemi (Faz 2.2)
- [x] `HomeworkEntity`, `HomeworkModel`, `HomeworkAssignmentEntity`, `HomeworkAssignmentModel` tanımlandı.
- [x] `HomeworksRepository` yazıldı: Ödev oluşturulduğunda sınıftaki tüm öğrencilere atomik batch ile `homework_assignments` üretilmesi sağlandı.
- [x] **Yeni Ödev Oluşturma Ekranı** (`CreateHomeworkScreen`): Sınıf, Ders (Matematik, Türkçe vb.), Kaynak adı, Soru aralığı, Açıklama ve Teslim Tarihi seçici eklendi.
- [x] **Öğretmen Ödev Yönetimi** (`TeacherHomeworkListScreen`): Ders çipleriyle filtreleme, yaklaşan/geciken ödev uyarıları.
- [x] **Ödev Kontrol Ekranı** (`HomeworkDetailScreen`): Sınıftaki her öğrenci için tek tıkla durum (`Tamamlandı` / `Yapılmadı` / `Bekliyor`) güncelleme araçları.
- [x] **Veli Ödev Takip Ekranı** (`ParentHomeworkListScreen`): Çocuğun ödevlerinin renkli durum etiketleri (`StatusBadge`) ve öğretmen notları ile izlenmesi.

### 4. 📊 Deneme Sınavları, Net Hesaplama & Grafikler (Faz 2.3)
- [x] `ExamResultEntity`, `ExamResultModel`, `SubjectScore`, `GoalEntity`, `GoalModel` yazıldı.
- [x] `NetCalculator` sınıfı ile **4 Yanlış = 1 Doğru** formülü (`Doğru - (Yanlış / 4)`) uygulandı.
- [x] **Deneme Sonucu Giriş Ekranı** (`CreateExamResultScreen`): Ders bazlı D/Y/B girdikçe **anlık hesaplanan canlı net** kartı tasarlandı.
- [x] **Öğretmen Sınav Listesi** (`TeacherExamListScreen`): Sınıf bazında deneme sonuçları ve net özetleri.
- [x] **`fl_chart` Gelişim Grafiği Ekranı** (`AnalyticsGraphScreen`): Öğrencinin denemeler arası net ve puan ilerleme çizgi grafiği (`LineChart`), Hedef Puan ilerleme çubuğu ve ders dağılım kartları.
- [x] **Veli Deneme Takip Ekranı** (`ParentExamListScreen`): Çocuğun deneme sonuçları ve net gelişim çizgi grafiği.

---

## 📂 Kod Tabanı Yapısı ve Rotalar

```text
Rotalar (GoRouter):
- /splash                      -> SplashScreen
- /welcome                     -> WelcomeScreen
- /role-selection              -> RoleSelectionScreen
- /register/teacher            -> TeacherRegisterScreen
- /register/parent             -> ParentRegisterScreen
- /login                       -> LoginScreen
- /forgot-password             -> ForgotPasswordScreen
- /teacher/home                -> TeacherHomeScreen
- /teacher/classes             -> ClassListScreen
- /teacher/classes/:classId    -> ClassDetailScreen
- /teacher/students/:studentId -> StudentDetailScreen
- /teacher/homeworks           -> TeacherHomeworkListScreen
- /teacher/homeworks/new       -> CreateHomeworkScreen
- /teacher/homeworks/:id       -> HomeworkDetailScreen
- /teacher/exams               -> TeacherExamListScreen
- /teacher/exams/new           -> CreateExamResultScreen
- /teacher/analytics/:studentId-> AnalyticsGraphScreen
- /parent/home                 -> ParentHomeScreen
- /parent/homeworks            -> ParentHomeworkListScreen
- /parent/exams                -> ParentExamListScreen
```

---

## 🧪 Test İstatistikleri

`flutter test` komutu ile çalıştırılan tüm unit ve widget testleri **25/25 yeşil** geçmiştir:

1. `test/unit/app_utils_test.dart` (17 test) ➔ Net hesabı, ödev durumları, e-posta/şifre doğrulamaları, Türkçe tarih formatlayıcı.
2. `test/unit/class_and_student_test.dart` (2 test) ➔ ClassEntity & StudentEntity kopyalama, veli eşleşme mantığı.
3. `test/unit/homework_test.dart` (2 test) ➔ HomeworkEntity gecikme kontrolü & HomeworkAssignmentEntity durum yardımcıları.
4. `test/unit/exam_and_goal_test.dart` (3 test) ➔ SubjectScore net hesabı, ders haritası erişimi, GoalEntity kalan puan hesabı.
5. `test/widget_test.dart` (1 test) ➔ Uygulama başlatma smoke testi.
