# 📋 Ödev Takip Sistemi (MatPusula)

**Ödev Takip Sistemi**, öğretmenlerin sınıf, öğrenci, ödev, deneme sınavı sonuçları ve hedeflerini kolayca yönetebildiği; velilerin ise canlı senkronizasyon ile **yalnızca kendi çocuklarına ait** bilgileri ve performans grafiklerini takip edebildiği Flutter ile geliştirilmiş gelişmiş bir iOS ve Android mobil uygulamasıdır.

> **Canlı Senkronizasyon & Offline Desteği:** Firebase Cloud Firestore'un `snapshots` yapısı sayesinde öğretmen bir ödevi kontrol ettiği veya sınav sonucu girdiği anda velinin ekranında veriler **canlı (real-time)** güncellenir.

---

## 📑 İçindekiler
- [Özellikler](#-özellikler)
- [Teknoloji Stack](#-teknoloji-stack)
- [Gereksinimler](#-gereksinimler)
- [Hızlı Kurulum](#-hızlı-kurulum)
- [Proje & Klasör Yapısı](#-proje--klasör-yapısı)
- [Veritabanı Şeması (Firestore)](#-veritabanı-şeması-firestore)
- [Güvenlik & Rol Kuralları](#-güvenlik--rol-kuralları)
- [Komutlar & Testler](#-komutlar--testler)
- [Yol Haritası](#-yol-haritası)
- [Lisans](#-lisans)

---

## ✨ Özellikler

### 1. 🔑 Güvenli Rol Tabanlı Kimlik Doğrulama (Auth & RoleGuard)
- **Öğretmen ve Veli Ayrımı**: Kayıt esnasında seçilen role uygun özelleştirilmiş kayıt akışları.
- **RoleGuard Yönlendirme**: `GoRouter` ile öğretmenin veli ekranlarına, velinin öğretmen yönetimine erişimi engellenir.
- **Şifre Sıfırlama & Profil**: Firebase Auth e-posta doğrulama ve şifre yenileme.

### 2. 🏫 Sınıf ve Öğrenci Yönetimi
- **Sınıf Oluşturma**: Sınıf adı ve seviye (örn: *8-A Sınıfı*) belirleme.
- **Öğrenci Kaydı & Arama**: Sınıfa okul numarası ve ad-soyad ile öğrenci ekleme, canlı arama filtresi.
- **6 Haneli Veli Davet Kodu**: Her öğrenciye özel otomatik `OT-XXXXXX` davet kodu üretme. Tek tıkla kopyalama ve veli hesabı ile eşleştirme.

### 3. 📚 Ödev Oluşturma, Atama ve Kontrol
- **Esnek Ödev Atama**: Sınıfa Ders (Matematik, Türkçe, Fen vb.), Ödev Başlığı, Kaynak Kitap, Soru Aralığı ve Son Teslim Tarihi belirleme.
- **Öğretmen Kontrol Paneli**: Öğrencilerin ödev durumlarını tek tıkla **Tamamlandı** (Yeşil), **Yapılmadı** (Kırmızı) veya **Bekliyor** (Amber) olarak işaretleme.
- **Veli Ödev Takibi**: Velinin çocuğuna atanan aktif, geciken ve tamamlanan ödevleri renkli rozetlerle (`StatusBadge`) takip etmesi.

### 4. 📊 Deneme Sınavı Girişi, Net Hesabı ve Grafikler (`fl_chart`)
- **Otomatik Net Hesaplama**: Ders bazında Doğru, Yanlış ve Boş verisi girildiğinde sistem **4 Yanlış = 1 Doğru** formülüyle (`Doğru - (Yanlış / 4)`) netleri ve toplam puanı anında hesaplar.
- **Gelişim Çizgi Grafiği (`LineChart`)**: `fl_chart` kütüphanesi ile öğrencinin denemeler arası net ve puan yükseliş/düşüş eğrisi.
- **Hedef Takip Sistemi**: Öğrenciye özel belirlenen LGS/YKS hedef puanı, mevcut puan ve hedefe kalan puan ilerleme çubuğu.

---

## 🛠 Teknoloji Stack

| Katman | Teknoloji / Kütüphane | Açıklama |
|---|---|---|
| **Framework** | **Flutter 3.x / Dart 3.x** | iOS ve Android tek kod tabanı |
| **State Management** | **Flutter Riverpod 2.6** | Reaktif ve modüler durum yönetimi |
| **Navigation** | **GoRouter 14.8** | Rol tabanlı yönlendirme ve RoleGuard |
| **Backend & DB** | **Firebase Cloud Firestore** | Canlı WebSocket akışları ve çevrimdışı önbellekleme |
| **Authentication** | **Firebase Auth** | E-posta/Şifre ile güvenli oturum yönetimi |
| **Grafikler** | **fl_chart 0.68** | Net ve Puan ilerleme çizgi grafikleri |
| **UI Design** | **Vanilla Material 3** | Özel renk paleti, tipografi ve micro-animation |

---

## 💻 Gereksinimler

- **Flutter SDK**: `>=3.3.0 <4.0.0`
- **Dart SDK**: `>=3.3.0 <4.0.0`
- **Android Studio** (Android emulator için) veya **Xcode** (iOS simulator için)
- **Firebase Projesi**: `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS)

---

## 🚀 Hızlı Kurulum

### 1) Projeyi Klonlayın
```bash
git clone https://github.com/Majestelerinizz/odev_kontrol_sistemi.git
cd odev_kontrol_sistemi
```

### 2) Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3) Firebase Yapılandırması
Firebase konsolunuzdan indirdiğiniz yapılandırma dosyalarını ilgili dizinlere ekleyin:
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`

### 4) Uygulamayı Çalıştırın
```bash
# Android Emulator veya Cihazda Çalıştır
flutter run

# iOS Simulator'de Çalıştır
flutter run -d iPhone
```

---

## 📁 Proje & Klasör Yapısı

Clean Architecture (Domain, Data, Presentation) prensiplerine uygun özellik (feature) bazlı klasör yapısı:

```text
lib/
├── app/
│   ├── app.dart                   # MaterialApp & Riverpod konfigürasyonu
│   └── router.dart                # GoRouter ve RoleGuard yönlendirme kuralları
├── core/
│   ├── extensions/                # String, DateTime ve Net uzantıları
│   ├── theme/                     # AppTheme, AppColors, AppTextStyles, AppSizes
│   ├── utils/                     # NetCalculator, HomeworkStatusCalculator
│   └── widgets/                   # AppButtons, AppTextField, StatusBadge, EmptyState
└── features/
    ├── analytics/                 # fl_chart Gelişim Grafikleri ve Analiz Ekranı
    ├── auth/                      # Kayıt, Giriş, Rol Seçimi ve Auth Providers
    ├── classes/                   # Sınıf Listeleme, Sınıf Detayı ve Sınıf Ekleme
    ├── dashboard/                 # Öğretmen ve Veli Ana Ekran Panelleri
    ├── exams/                     # Deneme Sınavı Girişi ve Sınav Listesi
    ├── goals/                     # Hedef Puan / Net Takip Modülü
    ├── homeworks/                 # Ödev Atama, Ödev Kontrol ve Veli Takibi
    └── students/                  # Öğrenci Detayı ve Veli Davet Kodu Üretimi
```

---

## 🗄 Veritabanı Şeması (Firestore)

Koleksiyonlar ve temel alanları:

* **`users`**: `uid`, `email`, `fullName`, `role` (`teacher` | `parent`), `phoneNumber`, `createdAt`
* **`classes`**: `id`, `teacherId`, `name`, `gradeLevel`, `studentCount`, `createdAt`
* **`students`**: `id`, `classId`, `teacherId`, `name`, `schoolNumber`, `parentIds` (List), `targetScore`, `teacherNote`
* **`invite_codes`**: `code` (örn: `OT-8A9K2M`), `studentId`, `teacherId`, `expiresAt`, `isUsed`
* **`homeworks`**: `id`, `teacherId`, `classId`, `title`, `subject`, `sourceName`, `questionRange`, `dueDate`
* **`homework_assignments`**: `id`, `homeworkId`, `studentId`, `status` (`pending` | `completed` | `missed`), `completedAt`
* **`exam_results`**: `id`, `studentId`, `classId`, `examName`, `publisher`, `scores` (Map), `totalNet`, `totalScore`, `examDate`
* **`goals`**: `id`, `studentId`, `type`, `targetValue`, `currentValue`, `isActive`

---

## 🛡 Güvenlik & Rol Kuralları

`firestore.rules` dosyasında tanımlanan veritabanı güvenlik kuralları:
- **Öğretmen Yetkileri**: Sadece kendi oluşturduğu sınıfları, öğrencileri, ödevleri ve sınavları yazabilir/güncelleyebilir.
- **Veli Yetkileri**: Davet kodu ile eşleştiği **yalnızca kendi çocuğunun** ödev durumlarını ve sınav sonuçlarını okuyabilir.

---

## 🧪 Komutlar & Testler

Birim ve widget testlerini çalıştırmak için:

```bash
# Tüm testleri çalıştır (25/25 test)
flutter test

# Statik kod analizi yap
flutter analyze
```

---

## 🛣 Yol Haritası

- [x] **Faz 1 — Çekirdek & Auth**: Temel mimari, tema, GoRouter, Firebase Auth & Rol kayıtları.
- [x] **Faz 2.1 — Sınıf & Öğrenci**: Sınıf yönetimi, öğrenci ekleme, canlı arama ve Veli Davet Kodu üretimi.
- [x] **Faz 2.2 — Ödev Sistemi**: Ödev oluşturma, sınıfa toplu atama, öğretmen kontrolü ve veli takibi.
- [x] **Faz 2.3 — Deneme & Grafikler**: Anlık net hesaplayıcı, `fl_chart` çizgi grafikleri ve hedef takibi.
- [ ] **Faz 3 — Yayınlama**: App Store ve Play Store release build yapılandırmaları ve mağaza görselleri.

---

## 📜 Lisans

© 2026 Yusuf Karagüzel · Tüm hakları saklıdır.  
İzinsiz kopyalanması veya dağıtılması yasaktır.
