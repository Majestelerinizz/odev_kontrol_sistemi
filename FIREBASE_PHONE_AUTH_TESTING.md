# 🧪 Firebase Phone Auth — Test Kılavuzu & Doğrulama Matrisi

**Proje:** MatPusula  
**Kapsam:** Unit, Entegrasyon, Emulator ve Fiziksel Cihaz Testleri

---

## 1. 📊 Test Matrisi

| Test Senaryosu | Test Türü | Beklenen Sonuç | Durum |
|---|---|---|---|
| E.164 Dönüşümü (`0531...` -> `+90531...`) | Unit Test | Hatasız E.164 çıktısı | ✅ Geçti (28/28) |
| Geçersiz Telefon Formatı | Unit Test | `false` dönmesi ve hata fırlatılması | ✅ Geçti |
| Numara Maskeleme (`+90 531 *** ** 49`) | Unit Test | PII verisinin gizlenmesi | ✅ Geçti |
| Sabit Test Numarası ile Giriş | Entegrasyon | `123456` ile anında oturum açılması | ✅ Hazır |
| 60 Saniyelik Cooldown Sayacı | Widget / UI | Sayacın her saniye azalması ve butonu kilitlemesi | ✅ Hazır |
| Hatalı 6 Haneli OTP Girişi | Entegrasyon | Kullanıcı dostu Türkçe hata mesajı | ✅ Hazır |
| Backend ID Token Doğrulaması | API Test | Geçerli token: 200 OK, Geçersiz: 401 Unauthorized | ✅ Hazır |

---

## 2. 📱 Fiziksel Cihaz & Canlı Web Test Adımları

1. **Canlı Web Sürümünde Test (`https://odevtakipsistemi-b93b2.web.app`):**
   * Giriş ekranında **Veli Girişi** sekmesine tıklayın.
   * Telefon numarası olarak `0531 563 5049` girin.
   * **Doğrulama Kodu Gönder** butonuna basın (Arka planda invisible reCAPTCHA devreye girer).
   * Kod alanına test kodu olan `123456` (veya gelen SMS kodunu) girin.
   * **Doğrula & Giriş Yap** butonuna basarak veli paneline giriş yapıldığını teyit edin.
