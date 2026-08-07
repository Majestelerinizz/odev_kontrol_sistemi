# 🚀 Ödev Takip Sistemi (MatPusula) — Release & Mağaza Yayın Rehberi

Bu belge, uygulamanın **Google Play Store** ve **Apple App Store** üzerindeki test/yayın süreçlerini adım adım özetlemektedir.

---

## 🔑 1. Android Imzalama Anahtarı (Keystore) Üretimi

Terminalde aşağıdaki komutu çalıştırarak `upload-keystore.jks` üretin:

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

İstenen şifreyi girin ve `android/key.properties` dosyasını oluşturup bilgileri yazın:

```properties
storePassword=GIRDIGINIZ_STORE_SIFRESI
keyPassword=GIRDIGINIZ_KEY_SIFRESI
keyAlias=upload
storeFile=../upload-keystore.jks
```

> ⚠️ `upload-keystore.jks` ve `key.properties` dosyalarını **asla Git deposuna commit etmeyin**. (`.gitignore` dosyasına eklenmiştir).

---

## 📦 2. Android Release Paketi (App Bundle) Üretimi

Google Play Store yayınlamak için `.aab` paketi üretilir:

```bash
flutter build appbundle --release
```

Üretilen dosya konumu:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 3. iOS Archive / IPA Üretimi (macOS + Xcode)

iOS için ipa paketi üretilir:

```bash
flutter build ipa --release
```

Üretilen dosya konumu:
`build/ios/archive/Runner.xcarchive` veya `build/ios/ipa/*.ipa`

---

## 📋 4. Mağaza Gönderim Kontrol Listesi

### Google Play Console (Android)
- [ ] **Uygulama Adı:** Ödev Takip Sistemi — MatPusula
- [ ] **Kısa Açıklama:** Öğretmen ve veliler için ödev, deneme sınavı net takibi ve anlık duyuru platformu.
- [ ] **Uzun Açıklama:** MatPusula, öğretmenlerin sınıftaki öğrencilere kolayca ödev atayabildiği, deneme sınavı doğru/yanlış/net hesabı yaptığı ve velilerin çocuklarının gelişimini grafiklerle takip edebildiği eğitim platformudur.
- [ ] **Ekran Görüntüleri:** En az 2 adet telefon ekran görüntüsü (Öğretmen paneli & Veli paneli).
- [ ] **Gizlilik Politikası (Privacy Policy):** KVKK ve Çocuk Güvenliği Koşulları (Uygulama içi profil ekranından erişilebilir).
- [ ] **Veri Güvenliği Formu (Data Safety):**
  - E-posta ve Ad Soyad (Hesap yönetimi için toplanır).
  - Şifreli iletim (HTTPS / SSL).
  - Hesap Silme Talebi (Profil ekranında mevcut).

### App Store Connect (iOS)
- [ ] **App Name:** MatPusula — Ödev Takip
- [ ] **Category:** Education / Eğitim
- [ ] **Age Rating:** 4+ (Çocuk güvenli, reklamsız)
- [ ] **App Privacy:** Contact Info (Name, Email).
- [ ] **Test Flight:** İç test grubu davetleri.

---

## 🧪 5. Doğrulama Komutları

Mağazaya paketi yüklemeden önce tüm testleri çalıştırarak doğruluğundan emin olun:

```bash
# 1. Flutter Birim & Widget Testleri (27 test)
flutter test

# 2. Node.js Sync Backend REST API Testleri (7 test)
cd backend && npm test
```
