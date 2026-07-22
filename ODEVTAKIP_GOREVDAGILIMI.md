# 📋 Ödev Takip Sistemi — Tek Kişilik Geliştirme Yol Haritası ve Görev Dağılımı

Bu belge, referans görseldeki ekran yapısını **öğretmen + veli** rollerine uyarlayan, Flutter ile iOS ve Android için geliştirilecek **Ödev Takip Sistemi** projesinin tek kişilik çalışma planıdır.

> Proje tek kişi tarafından geliştirileceği için klasik ekip görevleri yerine aynı geliştiricinin farklı zamanlarda üstleneceği “rol şapkaları” kullanılmıştır.

---

## 1. Proje Hedefi

Öğretmenlerin sınıf, öğrenci, ödev, deneme sonucu, konu ilerlemesi, hedef ve duyuru süreçlerini yönetebildiği; velilerin ise yalnızca kendi çocuklarına ait bilgileri takip edebildiği bir mobil uygulama geliştirmek.

### Kullanıcı rolleri

| Rol | Temel Yetkiler |
|---|---|
| **Öğretmen** | Sınıf ve öğrenci yönetimi, ödev oluşturma, sonuç girişi, konu analizi, hedef belirleme, veli mesajı ve bildirim gönderme |
| **Veli** | Çocuğunun ödevlerini, tamamlanma durumunu, deneme sonuçlarını, konu gelişimini, hedeflerini ve öğretmen mesajlarını görüntüleme |
| **Öğrenci** | İlk sürümde ayrı giriş hesabı bulunmaz; öğrenci sistemde öğretmene ve veliye bağlı veri kaydı olarak tutulur |

---

## 2. Referans Görselden Alınacak ve Çıkarılacak Modüller

### MVP içinde kullanılacak ekranlar

1. Rol seçimi ve giriş
2. Öğretmen ana paneli
3. Sınıf ve öğrenci listesi
4. Öğrenci profili
5. Ödev listesi
6. Ödev oluşturma ve ödev detayı
7. Deneme sonucu girişi
8. Ders / konu analizi
9. Konu haritası
10. Veli ana paneli
11. Grafikler
12. Hedef sistemi
13. Bildirimler
14. Toplu veli mesajı
15. Profil ve ayarlar

### İlk üç fazdan çıkarılan modüller

- Öğrenci hesabıyla giriş
- Yapay zekâ ile ödev önerisi
- Yapay zekâ analiz raporu
- Kitap takibi
- Rozet sistemi
- PDF rapor dışa aktarma
- Web yönetim paneli

Bu modüller proje tamamlandıktan sonra **Faz 4 / Gelecek Sürüm** listesine alınacaktır.

---

## 3. Tek Kişilik Projede Üstleneceğin Roller

| Rol Şapkası | Yapacağın İş |
|---|---|
| **Ürün Yöneticisi** | Kapsamı korumak, yapılacaklar listesini yönetmek, gereksiz özellikleri ertelemek |
| **UI/UX Tasarımcısı** | Ekran akışları, renkler, tipografi, bileşenler ve erişilebilirlik |
| **Flutter Geliştiricisi** | Ekranlar, yönlendirme, state management, form doğrulama ve cihaz uyumu |
| **Backend/Firebase Geliştiricisi** | Kimlik doğrulama, Firestore modeli, Storage, bildirim ve güvenlik kuralları |
| **Test Uzmanı** | Birim, widget, entegrasyon, gerçek cihaz ve kullanıcı testleri |
| **Yayın Sorumlusu** | Android ve iOS imzalama, mağaza görselleri, test sürümleri ve yayın süreci |

### Haftalık çalışma kuralı

- Haftanın ilk günü: görev planı ve ekran hedefi
- Orta günler: geliştirme
- Son gün: hata düzeltme, test ve Git yedeği
- Aynı anda en fazla **bir ana modül** geliştir
- Her ekranı bitirmeden sonraki ekrana geçme

---

# 🚀 FAZ 1 — Temel Altyapı, Tasarım Sistemi ve Giriş

## Süre

- **Tam zamanlı:** 2–3 hafta
- **Günde 2–3 saat:** 3–4 hafta

## Faz hedefi

Uygulamanın açılması, öğretmen/veli rol seçimi, kayıt ve giriş, rol bazlı yönlendirme, temel tasarım sistemi ve boş ana panellerin tamamlanması.

## 1.1 Ürün ve analiz görevleri

- Proje adını ve paket adını kesinleştir.
- Öğretmen ve veli kullanıcı hikâyelerini yaz.
- İlk sürüme girmeyecek özellikleri ayrı bir backlog dosyasına taşı.
- Ekran akışını aşağıdaki sırayla çiz:
  - Splash
  - Rol seçimi
  - Giriş / kayıt
  - Öğretmen ana paneli
  - Veli ana paneli
- Firestore koleksiyonlarını ve ilişkileri kağıt üzerinde planla.

## 1.2 Tasarım görevleri

- Figma içinde mobil frame oluştur.
- Ortak renk, font, boşluk ve radius değerlerini tanımla.
- Öğretmen arayüzünde ana renk olarak koyu lacivert kullan.
- Veli alanında yeşil vurgu kullan; uygulamanın genel tasarım sistemini bozma.
- Minimum gövde metni: **16sp**.
- Minimum dokunma alanı: **48dp**, ana buton yüksekliği: **56dp**.
- Bottom Navigation üzerinde ikon ve metin birlikte göster.
- Teknik hata kodlarını kullanıcıya gösterme.

## 1.3 Teknik kurulum görevleri

- Flutter ve Dart SDK kurulumu
- Android Studio ve Android SDK kurulumu
- VS Code veya Android Studio eklentileri
- Git repository oluşturma
- Firebase projesi açma
- Android ve iOS uygulamalarını Firebase'e bağlama
- Firebase Authentication etkinleştirme
- Cloud Firestore oluşturma
- Firebase Storage oluşturma
- Firebase Cloud Messaging altyapısını hazırlama

## 1.4 Flutter çekirdek görevleri

- Clean Architecture temelli klasör yapısı
- Riverpod state management
- GoRouter yönlendirme
- Uygulama tema dosyaları
- Form doğrulama yardımcıları
- Hata ve yüklenme bileşenleri
- RoleGuard yapısı
- Oturum kontrolü

## 1.5 Faz 1 ekranları

- Splash ekranı
- Hoş geldiniz ekranı
- Öğretmen / Veli rol seçimi
- Öğretmen kayıt
- Veli davet koduyla kayıt
- Giriş
- Şifremi unuttum
- Öğretmen boş dashboard
- Veli boş dashboard
- Profil ve çıkış

## 1.6 Faz 1 veri modeli

- `users`
- `teacher_profiles`
- `parent_profiles`
- `classes`
- `students`
- `invite_codes`

## 1.7 Faz 1 tamamlanma kriterleri

- [ ] Öğretmen hesap oluşturabiliyor
- [ ] Veli davet koduyla kayıt olabiliyor
- [ ] Kullanıcı kapatıp açtığında oturumu korunuyor
- [ ] Öğretmen yalnızca öğretmen paneline gidiyor
- [ ] Veli yalnızca veli paneline gidiyor
- [ ] Hatalı girişlerde anlaşılır Türkçe mesaj gösteriliyor
- [ ] Android emülatör ve gerçek cihazda temel akış çalışıyor
- [ ] iOS projesi en azından derlenebilir durumda

## Faz 1 teslim çıktısı

**Çalışan giriş sistemi + rol bazlı iki ayrı uygulama kabuğu.**

---

# 🚀 FAZ 2 — Ana İşlevler: Öğrenci, Ödev, Deneme ve Veli Takibi

## Süre

- **Tam zamanlı:** 4–6 hafta
- **Günde 2–3 saat:** 6–8 hafta

## Faz hedefi

Öğretmenin sınıf ve öğrenci oluşturabilmesi, ödev atayabilmesi, sonuç girebilmesi; velinin kendi çocuğuna ait verileri güvenli şekilde görebilmesi.

## 2.1 Sınıf ve öğrenci yönetimi

- Sınıf oluşturma
- Sınıf adı ve seviye seçimi
- Sınıf listesi
- Öğrenci ekleme
- Öğrenci düzenleme
- Öğrenci silme için onay penceresi
- Öğrenciye veli davet kodu oluşturma
- Öğrenci profil ekranı

## 2.2 Ödev sistemi

- Ödev oluşturma formu
- Ders seçimi
- Kaynak / test adı
- Soru aralığı veya açıklama
- Teslim tarihi
- Tüm sınıfa veya seçili öğrencilere atama
- Fotoğraf / PDF ekleme
- Ödev durumları:
  - Bekliyor
  - Tamamlandı
  - Yapılmadı
  - Gecikti
- Öğretmenin durumu güncellemesi
- Velinin ödev listesini görüntülemesi

## 2.3 Deneme sonucu sistemi

- Deneme adı
- Tarih
- Ders bazında doğru, yanlış, boş
- Net hesaplama
- Toplam puan
- Öğrenci geçmişi
- Öğretmen tarafından düzeltme ve silme

## 2.4 Konu analizi ve grafikler

- Ders bazında doğru/yanlış/net özeti
- Konu bazında durum:
  - Tamamlandı
  - Geliştirilmeli
  - Eksik
- Basit çizgi grafik
- Başarı yüzdesi grafiği
- Karmaşık yapay zekâ yorumu yerine kural tabanlı kısa açıklamalar

## 2.5 Hedef sistemi

- Öğretmenin öğrenciye hedef puan tanımlaması
- Mevcut puan
- Hedefe kalan puan
- Velinin hedef durumunu görüntülemesi
- Hedef güncelleme geçmişi

## 2.6 Bildirim ve mesajlaşma

- Yeni ödev bildirimi
- Teslim tarihi yaklaşan ödev bildirimi
- Öğretmen notu bildirimi
- Deneme sonucu eklendi bildirimi
- Tek veliye mesaj
- Sınıftaki tüm velilere toplu mesaj
- Mesajların uygulama içinde geçmiş olarak tutulması

## 2.7 Faz 2 güvenlik görevleri

- Öğretmen yalnızca kendi sınıflarını görmeli
- Veli yalnızca bağlı olduğu öğrenciyi görmeli
- Veli veri değiştirememeli
- Davet kodu tek kullanımlık ve süreli olmalı
- Firestore kuralları emülatörde test edilmeli
- Dosya yükleme boyut ve tür sınırları uygulanmalı

## 2.8 Faz 2 ekranları

### Öğretmen

- Ana panel
- Sınıflar
- Öğrenci listesi
- Öğrenci profili
- Ödev listesi
- Yeni ödev
- Ödev detayı
- Deneme sonucu ekle
- Matematik / ders analizi
- Konu haritası
- Grafikler
- Hedef belirleme
- Bildirimler
- Toplu mesaj

### Veli

- Veli ana paneli
- Çocuk özeti
- Ödevler
- Deneme sonuçları
- Grafikler
- Konu gelişimi
- Hedef durumu
- Öğretmen mesajları
- Bildirimler

## 2.9 Faz 2 tamamlanma kriterleri

- [ ] Öğretmen sınıf ve öğrenci ekleyebiliyor
- [ ] Davet kodu doğru öğrenciyle veliyi eşleştiriyor
- [ ] Öğretmen ödev atayabiliyor
- [ ] Veli ödevi anında görüntüleyebiliyor
- [ ] Öğretmen ödev durumunu değiştirebiliyor
- [ ] Deneme sonucu ve net hesabı doğru çalışıyor
- [ ] Grafikler boş veride hata vermiyor
- [ ] Veli başka öğrencinin verisine erişemiyor
- [ ] Push bildirimleri Android ve iOS test cihazlarında çalışıyor

## Faz 2 teslim çıktısı

**Öğretmen ve veli arasında gerçek verilerle çalışan tam MVP.**

---

# 🚀 FAZ 3 — Kalite, Güvenlik, Mağaza Hazırlığı ve Yayın

## Süre

- **Aktif geliştirme ve test:** 3–4 hafta
- **Mağaza test/yayın tamponu:** 2–4 hafta

## Faz hedefi

Uygulamayı gerçek kullanıcıya uygun hâle getirmek, hataları azaltmak, mağaza gereksinimlerini tamamlamak ve iOS/Android sürümlerini yayınlamak.

## 3.1 Kod temizliği ve performans

- Tekrarlanan widget'ları ortak bileşene taşı
- Firestore sorgularını indeksle
- Büyük listelerde sayfalama uygula
- Gereksiz rebuild işlemlerini azalt
- Görselleri sıkıştır
- Offline ve zayıf bağlantı durumlarını yönet
- Hata loglarını merkezi hâle getir

## 3.2 Test planı

### Birim testleri

- Net hesaplama
- Puan hesaplama
- Davet kodu doğrulama
- Ödev durum kuralları
- Tarih karşılaştırmaları

### Widget testleri

- Giriş formu
- Ödev formu
- Öğrenci listesi
- Durum kartları
- Boş liste ekranları

### Entegrasyon testleri

- Öğretmen kayıt → sınıf → öğrenci → ödev
- Veli davet kodu → giriş → ödev görüntüleme
- Öğretmen sonuç girişi → veli ekranında görünme
- Bildirim tıklama → doğru detay ekranı

### Gerçek cihaz testleri

- En az iki Android telefon
- En az bir iPhone
- Küçük ekran
- Büyük ekran
- Koyu mod açık / kapalı
- Büyük sistem yazı boyutu
- Zayıf internet

## 3.3 Yayın öncesi gerekli içerikler

- Uygulama adı
- Uygulama ikonu
- Splash görseli
- Android ve iPhone ekran görüntüleri
- Kısa ve uzun mağaza açıklaması
- Destek e-posta adresi
- Gizlilik politikası
- Kullanım koşulları
- Hesap silme akışı
- Veri güvenliği ve gizlilik formları
- Sürüm notları

## 3.4 Android yayın görevleri

- Uygulama paket adını sabitle
- Upload keystore oluştur ve yedekle
- Release signing ayarları
- `appbundle` üret
- Internal test
- Closed test
- Hata düzeltme sürümleri
- Production access başvurusu
- Mağaza listeleme ve yayın

## 3.5 iOS yayın görevleri

- Mac ve güncel Xcode ortamı
- Bundle ID oluşturma
- Signing & Capabilities ayarları
- Push notification capability
- App Store Connect uygulama kaydı
- Archive / IPA oluşturma
- TestFlight yükleme
- TestFlight beta testi
- App Review başvurusu

## 3.6 Faz 3 tamamlanma kriterleri

- [ ] Kritik akışların testleri geçiyor
- [ ] Uygulama çökmeden 30 dakika kullanılabiliyor
- [ ] Güvenlik kuralları yetkisiz okumayı engelliyor
- [ ] Gizlilik politikası uygulama içinden açılıyor
- [ ] Hesap silme akışı bulunuyor
- [ ] Android release paketi imzalı
- [ ] iOS archive başarıyla üretiliyor
- [ ] Test kullanıcılarından gelen kritik hatalar kapatılmış
- [ ] Mağaza görselleri ve açıklamaları hazır

## Faz 3 teslim çıktısı

**Test edilmiş, güvenli, mağazalara gönderilmeye hazır iOS + Android uygulaması.**

---

# 4. Toplam Süre Tahmini

| Çalışma düzeni | Aktif geliştirme | Yayın tamponu | Toplam |
|---|---:|---:|---:|
| Tam zamanlı ve Flutter deneyimli | 8–10 hafta | 2–3 hafta | 10–13 hafta |
| Günde 3–4 saat | 10–13 hafta | 2–4 hafta | 12–17 hafta |
| Yeni başlayan / öğrenerek ilerleyen | 14–18 hafta | 2–4 hafta | 16–22 hafta |

### En gerçekçi öğrenci projesi tahmini

**12–16 hafta** hedefle. İlk 8–10 haftada çalışan MVP, kalan sürede test ve yayın hazırlığı yap.

---

# 5. Başlamadan Önce Gerekli Araçlar

## Donanım

- En az 16 GB RAM önerilen geliştirme bilgisayarı
- Android test telefonu
- iOS sürümü için Mac erişimi
- iPhone test cihazı veya TestFlight test kullanıcısı

## Yazılım

- Flutter SDK
- Dart SDK
- Android Studio
- VS Code veya IntelliJ
- Git ve GitHub/GitLab
- Figma
- Firebase Console
- Xcode

## Hesaplar

- Google hesabı
- Firebase projesi
- GitHub hesabı
- Google Play Console hesabı
- Apple Developer hesabı
- Destek e-posta adresi

---

# 6. Önerilen Haftalık Takvim

| Hafta | Ana çıktı |
|---:|---|
| 1 | Analiz, ekran haritası, Firebase ve Flutter kurulumu |
| 2 | Tasarım sistemi, giriş ve rol yönlendirmesi |
| 3 | Öğretmen/veli dashboard kabukları |
| 4 | Sınıf ve öğrenci yönetimi |
| 5 | Davet kodu ve veli eşleştirmesi |
| 6 | Ödev oluşturma ve listeleme |
| 7 | Ödev durumları ve dosya ekleme |
| 8 | Deneme sonucu girişi ve net hesaplama |
| 9 | Konu analizi, grafikler ve hedef sistemi |
| 10 | Bildirimler ve toplu mesaj |
| 11 | Güvenlik kuralları ve testler |
| 12 | UI düzeltmeleri ve release build |
| 13–14 | Android kapalı test / TestFlight |
| 15–16 | Son düzeltmeler ve mağaza başvuruları |

---

# 7. Git ve Çalışma Düzeni

## Branch isimleri

```text
main
feature/auth
feature/teacher-dashboard
feature/students
feature/homeworks
feature/exams
feature/parent-dashboard
feature/notifications
release/1.0.0
```

## Commit örnekleri

```text
feat: add teacher role registration
feat: create homework assignment flow
fix: prevent parent from reading unrelated student
ui: improve homework status card
chore: configure android release signing
```

## Her modül için bitirme sırası

1. Veri modeli
2. Repository
3. State / provider
4. Ekran
5. Form doğrulama
6. Hata ve boş durum
7. Test
8. Commit

---

# 8. Kapsam Koruma Kuralları

- İlk sürümde çevrim içi ders, canlı sohbet ve görüntülü görüşme ekleme.
- Yapay zekâ özelliklerini MVP'ye sokma.
- Öğrenci için ayrı uygulama hesabı açma.
- Web yönetim panelini mobil uygulama bitmeden başlatma.
- Aynı özelliği iki farklı şekilde geliştirme.
- Görsel mükemmellik uğruna çalışan özelliği geciktirme.

---

# 9. Projenin Başarı Tanımı

Proje aşağıdaki akış sorunsuz çalıştığında başarılı kabul edilir:

1. Öğretmen kayıt olur.
2. Sınıf oluşturur.
3. Öğrenci ekler.
4. Veli davet kodu üretir.
5. Veli kodla kayıt olur.
6. Öğretmen ödev atar.
7. Veli ödevi görür.
8. Öğretmen ödev durumunu günceller.
9. Öğretmen deneme sonucu girer.
10. Veli sonucu ve grafiği görür.
11. Öğretmen bildirim veya toplu mesaj gönderir.
12. Veli bildirimi alır.

---

**Durum:** Planlandı 🟡  
**Önerilen sürüm:** `v1.0.0-mvp`  
**Geliştirici sayısı:** 1
