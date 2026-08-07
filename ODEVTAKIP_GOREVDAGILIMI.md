# 👥 MatPusula — Takım Görev Dağılımı & Optik Okuma Proje Yol Haritası

**Proje Ekibi:** Yusuf (Lider), Seyid, Anıl, Abdullah  
**Son Güncelleme:** 7 Ağustos 2026

---

## 🎯 Ekip Rol ve Sorumluluk Dağılımı

| Ekip Üyesi | Sorumlu Olduğu Alan | Ana Görev ve Sorumluluklar |
|---|---|---|
| 👑 **Yusuf** | **Proje Lideri & Yapay Zeka & Görüntü İşleme Uzmanı** | • Optik form kabarcık (A, B, C, D) okuma & OCR entegrasyonu<br/>• Gemini AI Vision ile optik ve öğretmen tik/çarpı analizi<br/>• Kağıt hizalama ve doğru/yanlış/boş tespit motoru |
| 🐘 **Anıl** | **Mobil UI/UX Mimarı** | • Flutter mobil arayüz geliştirme (Riverpod, GoRouter, Tema)<br/>• Optik Tarama Kamerası Ekranı (`AiExamScannerScreen`) tasarımı<br/>• Öğretmen & Veli kontrol panelleri ve `fl_chart` net grafikleri |
| 🤖 **Seyid** | **Backend & Veritabanı Mimarı** | • Node.js Express REST API servisi ve PostgreSQL veritabanı şeması<br/>• Firebase Firestore Realtime Sync ve veri güvenliği kuralları<br/>• Optik sınav sonuçlarının veritabanına otomatik kaydedilmesi |
| 📱 **Abdullah**| **Entegrasyon, Twilio SMS & DevOps Uzmanı**| • Twilio SMS servisi ile velilere sınav sonuç SMS'i iletimi<br/>• Firebase Cloud Messaging (FCM) anlık uygulama içi bildirimler<br/>• Google Play Store & Apple App Store mağaza yayın süreçleri |

---

## 📋 Geliştirilecek Optik Okuma & Veli Bildirim Özellikleri

### 1. Optik Form & Test Kağıdı Okuma (Yusuf & Anıl)
- [ ] Kamera ile optik form hizalama ve fotoğraf çekimi.
- [ ] Cevap anahtarı şablonu (A, B, C, D) ile öğrenci cevaplarının otomatik eşleştirilmesi.
- [ ] Öğretmen kalem işaretlerinin (tik ✔️ / çarpı ❌) yapay zeka ile otomatik sayılması.

### 2. Anlık Net & Puanlama Motoru (Seyid & Yusuf)
- [ ] 4 yanlış 1 doğruyu götürür net hesaplama kuralı.
- [ ] Ders bazlı (Matematik, Türkçe, Fen) netlerin ve toplam net puanının hesaplanması.
- [ ] Sınıf içi derece ve başarı yüzdesi üretimi.

### 3. Otomatik Veli Bildirimi & SMS (Abdullah & Seyid)
- [ ] Sınav okunduğu an Twilio SMS ile veliye otomatik kısa bilgi SMS'i gönderimi.
- [ ] Mobil uygulamaya anlık push notification düşmesi.

### 4. Hiyerarşik "Soy Ağacı" İzleme Modülü (Anıl & Seyid)
- [ ] Okul ➔ Sınıf ➔ Öğretmen ➔ Öğrenci ➔ Veli hiyerarşik ağaç tasarımı.
- [ ] Velilerin anlık Twilio SMS iletim durumlarının (İletildi, Bekliyor, Hata) renkli rozetlerle takip edilmesi.
- [ ] Mobil uygulamada Flutter CustomPainter / TreeView ile görselleştirme.

---

## ❓ Detaylı Proje Karar & Soru-Cevap Anketi

### Soru 1: Optik Form ve Kağıt Okuma Yöntemi
- **A)** Öğretmen cevap anahtarını (Örn: `1-A, 2-C, 3-D`) girsin, optik formu kamera okuyarak harfleri eşleştirsin. *(Önerilen)*
- **B)** Cevap anahtarı olmadan kağıttaki öğretmen tikleri (✔️) ve çarpıları (❌) doğrudan sayılsın.

### Soru 2: Veli Bildirim Zamanlaması
- **A)** Sınav okunduğu **anında** velinin telefonuna Twilio SMS ve uygulama bildirimi gönderilsin. *(Önerilen)*
- **B)** Öğretmen tüm sınıfı bitirip *"Sonuçları Velilerle Paylaş"* butonuna bastığında toplu gönderilsin.

### Soru 3: Optik Form Şablonu
- **A)** Uygulama içinden çıktı alınabilecek standart MatPusula 20'lik optik formu kullanılsın.
- **B)** Piyasadaki tüm yayınların hazır optik formları ve test kitapçıkları desteklensin.

### Soru 4: Sınıf Derecesi ve İstatistikler
- **A)** Veliye öğrencinin sadece kendi netleri ve sınıf ortalamasına göre durumu gösterilsin.
- **B)** Veliye öğrencinin sınıftaki derecesi (Örn: *Sınıf 2.si*) de iletilsin.
