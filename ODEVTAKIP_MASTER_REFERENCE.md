# Ödev Takip Sistemi — Flutter Master Reference

## 📌 Proje Özeti

**Ödev Takip Sistemi**, öğretmenlerin öğrenci çalışmalarını merkezi olarak yönetmesini ve velilerin kendi çocuklarının gelişimini mobil uygulamadan takip etmesini sağlayan bir eğitim takip platformudur.

- **Platform:** iOS + Android
- **Mobil teknoloji:** Flutter
- **MVP backend:** Firebase
- **Kimlik doğrulama:** Firebase Authentication
- **Veritabanı:** Cloud Firestore
- **Dosya yükleme:** Firebase Storage
- **Bildirim:** Firebase Cloud Messaging
- **Roller:** Öğretmen ve Veli
- **Öğrenci hesabı:** İlk sürümde yok
- **Dil:** İlk sürüm Türkçe, altyapı TR/EN uyumlu
- **Web panel:** İlk sürümde yok

---

# 1. Ürün Vizyonu

Öğretmenin sınıfındaki tüm öğrencilerin ödev, deneme, konu gelişimi ve hedef bilgilerini tek uygulamadan yönetebilmesi; velinin ise karmaşık eğitim terimlerine maruz kalmadan çocuğunun mevcut durumunu anlaşılır biçimde görebilmesi.

## Ana değer önerisi

- Öğretmen için hızlı veri girişi
- Veli için sade ve güvenilir takip
- Çocuk bazında yetkilendirilmiş veri erişimi
- iOS ve Android'de aynı işlev
- Gereksiz özelliklerden arındırılmış MVP

---

# 2. Kapsam

## 2.1 MVP kapsamı

### Öğretmen

- Kayıt ve giriş
- Sınıf yönetimi
- Öğrenci yönetimi
- Veli davet kodu
- Ödev oluşturma
- Ödev durum güncelleme
- Deneme sonucu girişi
- Konu ilerleme haritası
- Grafikler
- Hedef belirleme
- Bireysel ve toplu veli mesajı
- Bildirim gönderme

### Veli

- Davet koduyla kayıt
- Giriş
- Bağlı çocuk seçimi
- Ödev listesi
- Ödev durumu
- Deneme sonuçları
- Konu gelişimi
- Grafikler
- Hedef durumu
- Öğretmen mesajları
- Bildirimler

## 2.2 MVP dışı

- Öğrenci rolü
- Yapay zekâ önerisi
- Yapay zekâ analiz raporu
- Kitap takibi
- Rozet ve oyunlaştırma
- Online ödeme
- Canlı sohbet
- Web yönetim paneli
- PDF rapor dışa aktarma

---

# 3. Referans Görselin Uygulamaya Uyarlanması

| Referans ekran | Yeni sistemde karşılığı | Durum |
|---|---|---|
| Giriş ekranı | Öğretmen / Veli rol seçimi | Kullanılacak |
| Öğretmen ana paneli | Günlük ödev, yaklaşan teslim, eksik ödev ve mesaj özeti | Kullanılacak |
| Öğrenci listesi | Sınıfa göre filtrelenmiş öğrenci listesi | Kullanılacak |
| Öğrenci profili | Öğrenci, veli, okul, hedef ve öğretmen notları | Kullanılacak |
| Ödev sistemi | Aktif, tamamlanan ve geciken ödevler | Kullanılacak |
| Ödev detayı | Açıklama, teslim tarihi, ek ve durum | Kullanılacak |
| Akıllı ödev önerisi | Yapay zekâ özelliği | Ertelenecek |
| Deneme girişi | Ders bazlı doğru/yanlış/boş ve puan | Kullanılacak |
| Matematik analizi | Tüm derslere uyarlanmış performans analizi | Kullanılacak |
| Konu haritası | Konu bazlı tamamlandı/geliştirilmeli/eksik | Kullanılacak |
| Yapay zekâ analizi | Otomatik AI raporu | Ertelenecek |
| Veli paneli | Çocuğun günlük özeti | Kullanılacak |
| Grafikler | Net, başarı yüzdesi ve ilerleme grafikleri | Kullanılacak |
| Kitap takibi | Kaynak/kitap ilerleme sistemi | Ertelenecek |
| Hedef sistemi | Puan veya çalışma hedefi | Kullanılacak |
| Rozetler | Oyunlaştırma | Ertelenecek |
| Bildirimler | Ödev, deneme ve öğretmen notları | Kullanılacak |
| Toplu mesaj | Sınıf velilerine duyuru | Kullanılacak |
| Raporlar | PDF dışa aktarma | Ertelenecek |
| Web panel | Tarayıcı yönetimi | Gelecek sürüm |

---

# 4. Teknik Mimari

## 4.1 Neden Firebase?

Tek geliştirici için giriş, veri tabanı, dosya, bildirim ve güvenlik ihtiyaçlarını ayrı bir Node.js sunucusu kurmadan tek platformdan yönetmeyi sağlar. Proje büyüdüğünde repository katmanı korunarak Node.js + PostgreSQL backend'e geçilebilir.

## 4.2 Flutter teknoloji seçimi

| Katman | Tercih |
|---|---|
| UI | Flutter Material 3 |
| State Management | Riverpod |
| Navigation | GoRouter |
| Model üretimi | Freezed + json_serializable |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Push | Firebase Cloud Messaging |
| Crash kayıt | Firebase Crashlytics |
| Grafik | fl_chart |
| Dosya seçme | file_picker / image_picker |
| Yerelleştirme | Flutter ARB |

> Paket sürümlerini sabitlemeden önce güncel kararlı sürümler `flutter pub add` ile kontrol edilmelidir.

---

# 5. Proje Klasör Yapısı

```text
odev_takip/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── bootstrap.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── dashboard/
│   │   ├── classes/
│   │   ├── students/
│   │   ├── parents/
│   │   ├── homeworks/
│   │   ├── exams/
│   │   ├── analytics/
│   │   ├── goals/
│   │   ├── messages/
│   │   ├── notifications/
│   │   └── profile/
│   ├── l10n/
│   │   ├── app_tr.arb
│   │   └── app_en.arb
│   └── shared/
│       ├── models/
│       └── widgets/
├── test/
├── integration_test/
├── android/
├── ios/
└── pubspec.yaml
```

## Feature içi yapı

```text
homeworks/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

# 6. Kullanıcı Rolleri ve Yetkiler

## 6.1 Teacher

- Kendi oluşturduğu sınıfları görür
- Kendi sınıflarına öğrenci ekler
- Kendi öğrencilerine ödev ve sonuç ekler
- Veli davet kodu üretir
- Kendi sınıflarındaki velilere mesaj gönderir
- Başka öğretmenin verisine erişemez

## 6.2 Parent

- Sadece davet koduyla kendisine bağlanan çocukları görür
- Ödev, sonuç, hedef ve mesaj verilerini okuyabilir
- Öğretmen verisini değiştiremez
- Başka öğrencinin verisine erişemez

## 6.3 Student

- Firestore içinde kayıt olarak bulunur
- Kimlik doğrulama hesabı yoktur
- Bir sınıfa bağlıdır
- Bir veya birden fazla veliyle ilişkilendirilebilir

---

# 7. Kimlik Doğrulama Akışları

## 7.1 Öğretmen kaydı

```text
Rol seçimi
→ Öğretmen
→ Ad soyad
→ E-posta
→ Şifre
→ Kullanım koşulları
→ Firebase Auth hesabı
→ users kaydı
→ teacher_profiles kaydı
→ Öğretmen dashboard
```

## 7.2 Veli kaydı

```text
Rol seçimi
→ Veli
→ Davet kodu
→ Kod doğrulama
→ Öğrenci adı ve sınıfı ön izleme
→ Ad soyad / e-posta / şifre
→ Firebase Auth hesabı
→ parent_profiles kaydı
→ student_parent_links kaydı
→ Kod kullanıldı olarak işaretlenir
→ Veli dashboard
```

## 7.3 Oturum yönlendirme

```text
Oturum yok → Giriş
Oturum var + role=teacher → /teacher/home
Oturum var + role=parent → /parent/home
Rol kaydı bozuk → Güvenli çıkış + destek mesajı
```

---

# 8. Firestore Veri Modeli

## 8.1 users

```json
{
  "uid": "firebase_uid",
  "role": "teacher | parent",
  "name": "Ad Soyad",
  "email": "example@mail.com",
  "phone": "+90...",
  "photoUrl": null,
  "isActive": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 8.2 classes

```json
{
  "id": "class_id",
  "teacherId": "teacher_uid",
  "name": "8-A",
  "gradeLevel": 8,
  "schoolName": "Atatürk Ortaokulu",
  "academicYear": "2026-2027",
  "studentCount": 24,
  "createdAt": "timestamp"
}
```

## 8.3 students

```json
{
  "id": "student_id",
  "classId": "class_id",
  "teacherId": "teacher_uid",
  "name": "Ahmet Yılmaz",
  "schoolNumber": "123",
  "phone": null,
  "parentIds": ["parent_uid"],
  "targetScore": 500,
  "teacherNote": "Problemlere ağırlık vermeli.",
  "createdAt": "timestamp"
}
```

## 8.4 invite_codes

```json
{
  "code": "OT-8A-A7K9M2",
  "studentId": "student_id",
  "teacherId": "teacher_uid",
  "expiresAt": "timestamp",
  "used": false,
  "usedBy": null,
  "createdAt": "timestamp"
}
```

## 8.5 homeworks

```json
{
  "id": "homework_id",
  "teacherId": "teacher_uid",
  "classId": "class_id",
  "title": "Bilgi Sarmal Test 32",
  "subject": "Matematik",
  "description": "Problemler konusu 1-40. sorular.",
  "sourceName": "Bilgi Sarmal",
  "questionRange": "1-40",
  "dueDate": "timestamp",
  "attachmentUrls": [],
  "assignedToAll": true,
  "createdAt": "timestamp"
}
```

## 8.6 homework_assignments

Her öğrenci için ayrı durum kaydı tutulur.

```json
{
  "id": "assignment_id",
  "homeworkId": "homework_id",
  "studentId": "student_id",
  "classId": "class_id",
  "teacherId": "teacher_uid",
  "status": "pending | completed | missed | overdue",
  "completedAt": null,
  "teacherNote": null,
  "updatedAt": "timestamp"
}
```

## 8.7 exam_results

```json
{
  "id": "exam_id",
  "studentId": "student_id",
  "classId": "class_id",
  "teacherId": "teacher_uid",
  "examName": "Deneme 5",
  "examDate": "timestamp",
  "publisher": "Bilgi Sarmal",
  "scores": {
    "turkce": {"correct": 16, "wrong": 4, "blank": 0, "net": 15.0},
    "matematik": {"correct": 16, "wrong": 4, "blank": 0, "net": 15.0}
  },
  "totalNet": 59.0,
  "totalScore": 470.25,
  "createdAt": "timestamp"
}
```

## 8.8 subject_progress

```json
{
  "id": "progress_id",
  "studentId": "student_id",
  "teacherId": "teacher_uid",
  "subject": "Matematik",
  "topic": "Problemler",
  "status": "completed | improve | missing",
  "correct": 5,
  "wrong": 5,
  "net": 3.75,
  "updatedAt": "timestamp"
}
```

## 8.9 goals

```json
{
  "id": "goal_id",
  "studentId": "student_id",
  "teacherId": "teacher_uid",
  "type": "score | net | homework_count",
  "targetValue": 500,
  "currentValue": 456,
  "startDate": "timestamp",
  "endDate": "timestamp",
  "isActive": true
}
```

## 8.10 messages

```json
{
  "id": "message_id",
  "teacherId": "teacher_uid",
  "parentIds": ["parent_uid"],
  "studentIds": ["student_id"],
  "classId": "class_id",
  "title": "Deneme Hatırlatması",
  "body": "Yarın saat 10.00'da deneme yapılacaktır.",
  "type": "individual | bulk",
  "createdAt": "timestamp"
}
```

## 8.11 notifications

```json
{
  "id": "notification_id",
  "userId": "target_uid",
  "title": "Yeni Ödev Eklendi",
  "body": "Bilgi Sarmal Test 32 ödevi eklendi.",
  "type": "homework | exam | message | system",
  "data": {"homeworkId": "homework_id"},
  "isRead": false,
  "createdAt": "timestamp"
}
```

---

# 9. Firestore İlişki Yapısı

```text
Teacher
 ├── Classes
 │    ├── Students
 │    │    ├── Parent links
 │    │    ├── Homework assignments
 │    │    ├── Exam results
 │    │    ├── Subject progress
 │    │    └── Goals
 │    ├── Homeworks
 │    └── Bulk messages
 └── Notifications

Parent
 └── Linked students
      ├── Homeworks
      ├── Exam results
      ├── Subject progress
      ├── Goals
      └── Messages
```

---

# 10. Güvenlik Kuralları Mantığı

## Temel kurallar

- Her istek oturum açmış kullanıcıdan gelmelidir.
- Kullanıcı rolü `users/{uid}.role` alanından doğrulanmalıdır.
- Öğretmen belgesindeki `teacherId`, oturum uid'siyle eşleşmelidir.
- Veli yalnızca `parentIds` alanında kendi uid'si bulunan öğrencileri okuyabilmelidir.
- Veli yazma yetkisine sahip olmamalıdır.
- Davet kodu doğrulama ve kullanma işlemi atomik olmalıdır.
- Bildirim hedef uid'si dışındaki kullanıcı tarafından okunmamalıdır.

## Kritik güvenlik testi

1. Veli A ile giriş yap.
2. Veli B'nin öğrenci ID'sini doğrudan sorgula.
3. Firestore `permission-denied` döndürmelidir.
4. Öğretmen A ile Öğretmen B'nin sınıfını sorgula.
5. Firestore `permission-denied` döndürmelidir.

---

# 11. Navigasyon Yapısı

## Ortak

```text
/splash
/welcome
/login
/register/teacher
/register/parent
/forgot-password
```

## Öğretmen

```text
/teacher/home
/teacher/classes
/teacher/classes/:classId
/teacher/students/:studentId
/teacher/homeworks
/teacher/homeworks/new
/teacher/homeworks/:homeworkId
/teacher/exams/new
/teacher/analytics/:studentId
/teacher/goals/:studentId
/teacher/messages
/teacher/notifications
/teacher/profile
```

## Veli

```text
/parent/home
/parent/children
/parent/children/:studentId
/parent/homeworks
/parent/exams
/parent/analytics
/parent/goals
/parent/messages
/parent/notifications
/parent/profile
```

---

# 12. Bottom Navigation

## Öğretmen

1. Ana Sayfa
2. Öğrenciler
3. Ödevler
4. Sonuçlar
5. Diğer

`Diğer` ekranında:

- Hedefler
- Mesajlar
- Bildirimler
- Profil

## Veli

1. Ana Sayfa
2. Ödevler
3. Sonuçlar
4. Mesajlar
5. Profil

---

# 13. Dashboard İçerikleri

## 13.1 Öğretmen dashboard

### Üst özet kartları

- Bugünkü ödevler
- Yaklaşan teslimler
- Tamamlanmayan ödevler
- Yeni veli mesajları

### Alt bölümler

- Son eklenen ödevler
- Teslimi yaklaşan ödevler
- Son deneme sonuçları
- Hızlı işlemler:
  - Yeni ödev
  - Öğrenci ekle
  - Deneme sonucu gir
  - Toplu mesaj

## 13.2 Veli dashboard

- Bugünkü ödev durumu
- Bu haftaki çalışma özeti
- Son deneme sonucu
- Hedefe kalan değer
- Öğretmen notu
- Son bildirimler

---

# 14. Ödev Durum Mantığı

| Durum | Açıklama | Renk |
|---|---|---|
| Bekliyor | Teslim tarihi geçmemiş ve tamamlanmamış | Amber |
| Tamamlandı | Öğretmen tarafından tamamlandı işaretlenmiş | Yeşil |
| Yapılmadı | Öğretmen yapılmadı olarak işaretlemiş | Kırmızı |
| Gecikti | Teslim tarihi geçmiş, tamamlanmamış | Koyu kırmızı |

## Otomatik durum hesabı

```text
status=completed → Tamamlandı
status=missed → Yapılmadı
status=pending + now > dueDate → Gecikti
status=pending + now <= dueDate → Bekliyor
```

Durum sadece renk ile gösterilmemeli; renk yanında mutlaka metin bulunmalıdır.

---

# 15. Net Hesaplama

Türkiye'deki yaygın dört yanlış bir doğruyu götürür kuralı için:

```text
net = doğru - (yanlış / 4)
```

Ancak farklı sınavlarda katsayı değişebileceği için sınıf veya deneme kaydında `wrongPenalty` alanı tutulabilir.

```text
net = doğru - (yanlış / wrongPenalty)
```

Varsayılan değer: `4`.

---

# 16. Bildirim Senaryoları

## Öğretmen eylemiyle

- Yeni ödev oluşturuldu
- Ödev teslim tarihi değişti
- Deneme sonucu eklendi
- Hedef güncellendi
- Öğretmen mesaj gönderdi

## Zamanlanmış

- Ödev teslimine 24 saat kaldı
- Ödev gecikti
- Haftalık gelişim özeti hazır

İlk MVP'de zamanlanmış bildirimler zorunlu değildir; manuel olay bildirimleri önce tamamlanmalıdır.

---

# 17. Tasarım Sistemi

## 17.1 Renkler

```dart
class AppColors {
  static const teacherPrimary = Color(0xFF123C8C);
  static const teacherLight = Color(0xFF2F6DE1);
  static const parentPrimary = Color(0xFF159A68);
  static const accent = Color(0xFF7C3AED);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);

  static const background = Color(0xFFF6F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
}
```

## 17.2 Tipografi

- Font: Nunito veya sistem fontu
- H1: 28sp / Bold
- H2: 22sp / Bold
- H3: 18sp / SemiBold
- Body: minimum 16sp
- Label: minimum 14sp
- Buton: 16–17sp / Bold

## 17.3 Boyutlar

```dart
class AppSizes {
  static const primaryButtonHeight = 56.0;
  static const minimumTouchTarget = 48.0;
  static const cardRadius = 14.0;
  static const inputRadius = 12.0;
  static const pagePadding = 16.0;
  static const listItemMinHeight = 72.0;
}
```

## 17.4 Tasarım kuralları

- Hamburger menü yerine Bottom Navigation
- Büyük ve açık butonlar
- Her ekranda tek belirgin ana aksiyon
- Kartlarda gereksiz gölge kullanma
- Başlıklar kısa ve Türkçe
- Teknik terim kullanma
- Renk + ikon + metin birlikte kullan
- Büyük sistem yazı boyutunu engelleme

---

# 18. Ortak Widget Listesi

```text
AppScaffold
AppTopBar
PrimaryButton
SecondaryButton
DangerButton
AppTextField
AppDropdown
StatusBadge
SummaryCard
StudentListTile
HomeworkCard
ExamResultCard
EmptyState
ErrorState
LoadingSkeleton
ConfirmDialog
RoleAvatar
NotificationTile
ProgressChartCard
```

---

# 19. Form Doğrulamaları

## Giriş

- E-posta zorunlu
- Geçerli e-posta biçimi
- Şifre minimum 8 karakter
- Hata metni alanın altında

## Öğrenci

- Ad soyad zorunlu
- Sınıf zorunlu
- Okul numarası opsiyonel
- Aynı sınıfta aynı okul numarası kontrolü

## Ödev

- Başlık zorunlu
- Ders zorunlu
- Teslim tarihi geçmiş olamaz
- En az bir öğrenci veya tüm sınıf seçilmelidir
- Dosya türü ve boyutu sınırlandırılmalıdır

## Deneme

- Doğru + yanlış + boş, soru sayısını aşmamalı
- Negatif sayı girilemez
- Puan aralığı deneme türüne göre doğrulanmalı

---

# 20. Hata Mesajları

```text
✅ “E-posta veya şifre hatalı.”
✅ “Bu davet kodunun süresi dolmuş.”
✅ “Bu öğrenciye erişim yetkiniz bulunmuyor.”
✅ “İnternet bağlantısı kurulamadı. Lütfen tekrar deneyin.”
✅ “Ödev kaydedilemedi. Bilgileri kontrol edip tekrar deneyin.”

❌ “FirebaseAuthException: invalid-credential”
❌ “PERMISSION_DENIED”
❌ “Null check operator used on a null value”
```

---

# 21. Test Stratejisi

## Unit

- Net hesaplama
- Tarihe göre ödev durumu
- Rol yönlendirmesi
- Davet kodu geçerlilik kontrolü
- Hedef yüzdesi

## Widget

- Giriş formu
- Öğrenci kartı
- Ödev kartı
- Deneme sonucu formu
- Boş liste ekranı

## Integration

- Öğretmen kayıt ve giriş
- Sınıf ve öğrenci oluşturma
- Davet koduyla veli kayıt
- Ödev oluşturma ve veli görüntüleme
- Sonuç ekleme ve veli görüntüleme
- Push bildirimi açma

## Manuel

- Android düşük seviye cihaz
- Android güncel cihaz
- iPhone
- Büyük font
- Koyu mod
- Zayıf bağlantı
- Uçak modu sonrası tekrar bağlanma

---

# 22. Performans Kuralları

- Ana panelde tüm geçmişi bir kerede çekme
- Listeleri sayfalayarak yükle
- Firestore sorgularında gerekli indeksleri oluştur
- Görselleri yüklemeden önce küçült
- Provider'ları ekran ömrüne göre `autoDispose` kullan
- Ağır grafik hesaplarını build içinde yapma
- Büyük listelerde `ListView.builder` kullan
- Kullanılmayan listener'ları kapat

---

# 23. Gizlilik ve Veri Güvenliği

- Öğrenci verisi hassas eğitim verisi olarak ele alınmalı
- Uygulamada gereksiz kişisel veri toplanmamalı
- Öğrenci fotoğrafı zorunlu olmamalı
- Kullanıcı hesap silme talebi oluşturabilmeli
- Silinen öğretmen hesabında bağlı veriler için açık politika bulunmalı
- Storage dosyaları herkese açık olmamalı
- E-posta ve telefon numarası arama indekslerinde gereksiz tutulmamalı
- Gizlilik politikası giriş ve ayarlar ekranından ulaşılabilir olmalı

---

# 24. Yayın Gereksinimleri

## Android

- Benzersiz paket adı
- İmzalama anahtarı
- Release AAB
- Uygulama ikonu
- Feature graphic
- Telefon ekran görüntüleri
- Kısa ve uzun açıklama
- Gizlilik politikası
- Veri güvenliği formu
- Test kullanıcıları

## iOS

- Mac + Xcode
- Apple Developer üyeliği
- Bundle ID
- Sertifika ve provisioning
- App Store Connect kaydı
- Uygulama ikonu
- iPhone ekran görüntüleri
- Gizlilik bilgileri
- TestFlight testi
- Review notları

---

# 25. Ortamlar

```text
dev     → geliştirme Firebase projesi
test    → kapalı test Firebase projesi
prod    → gerçek kullanıcı Firebase projesi
```

En azından `dev` ve `prod` ayrımı yapılmalıdır. Firestore test verileri production ortamına taşınmamalıdır.

---

# 26. Sürümleme

```text
0.1.0 → giriş ve tasarım sistemi
0.2.0 → sınıf ve öğrenci
0.3.0 → ödev sistemi
0.4.0 → veli paneli
0.5.0 → deneme ve grafikler
0.6.0 → bildirim ve mesaj
0.9.0 → beta
1.0.0 → mağaza sürümü
```

---

# 27. Üç Fazlık Geliştirme Özeti

## Faz 1 — Altyapı

- Flutter/Firebase kurulumu
- Tasarım sistemi
- Auth
- Öğretmen/veli rolü
- Boş dashboard

## Faz 2 — MVP

- Sınıf
- Öğrenci
- Davet kodu
- Ödev
- Deneme
- Analiz
- Hedef
- Mesaj ve bildirim

## Faz 3 — Yayın

- Güvenlik
- Test
- Performans
- Gizlilik
- Android closed test
- iOS TestFlight
- Mağaza başvuruları

---

# 28. Kabul Testi Senaryosu

```text
1. Öğretmen hesap oluşturur.
2. “8-A” sınıfını oluşturur.
3. Ahmet Yılmaz öğrencisini ekler.
4. Ahmet için veli davet kodu üretir.
5. Veli uygulamada kodu girer ve Ahmet'e bağlanır.
6. Öğretmen “Bilgi Sarmal Test 32” ödevini ekler.
7. Veli yeni ödev bildirimi alır.
8. Veli ödev detayını açar.
9. Öğretmen ödevi tamamlandı olarak işaretler.
10. Veli güncel durumu görür.
11. Öğretmen deneme sonucu ekler.
12. Veli net ve puan grafiğini görür.
13. Öğretmen hedefi 500 puan olarak belirler.
14. Veli hedefe kalan puanı görür.
15. Öğretmen sınıf velilerine toplu mesaj gönderir.
16. Veli mesajı ve bildirimi alır.
```

Bu senaryo baştan sona hatasız çalışıyorsa `v1.0.0` için ana ürün akışı tamamlanmış kabul edilir.

---

# 29. Gelecek Sürüm Backlog

## Faz 4

- Öğrenci hesabı
- Öğrenci ödev teslimi
- Kitap ve kaynak takibi
- Rozetler
- PDF rapor
- Web yönetim paneli
- Çoklu öğretmen
- Okul yöneticisi rolü

## Faz 5

- Yapay zekâ destekli çalışma önerisi
- Yapay zekâ gelişim özeti
- Otomatik risk uyarısı
- Gelişmiş istatistik
- Kurum lisansı

---

# 30. Son Karar

Bu proje için en güvenli yol:

1. Önce öğretmen ve veli girişini bitir.
2. Sonra sınıf → öğrenci → davet kodu zincirini tamamla.
3. Ödev sistemini tek başına çalışır hâle getir.
4. Deneme, grafik ve hedef modüllerini ekle.
5. Bildirimleri en sona yakın bağla.
6. Yapay zekâ ve web panelini ilk sürüme ekleme.
7. Test ve mağaza süresini geliştirme süresinden ayrı planla.

**Proje durumu:** Planlandı  
**Hedef sürüm:** `1.0.0`  
**Önerilen toplam süre:** 12–16 hafta  
**Geliştirici:** Tek kişi
