# ⚙️ Firebase Phone Auth — Kurulum & Yapılandırma Kılavuzu

**Proje:** MatPusula (`odevtakipsistemi-b93b2`)
**Mimari:** Tek kaynak — Firebase Authentication (Blaze planı). Backend OTP üretmez.
**Son güncelleme:** 26 Ağustos 2026

---

## 0. 📌 Mevcut Durum Özeti

| Öğe | Durum |
|---|---|
| Web App kaydı | ✅ `1:1063947496038:web:6cee255dd02a3a4e711ba7` |
| Android App kaydı | ✅ `1:1063947496038:android:c424f96a4fa7ed77711ba7` (`com.odevtakip.odev_takip`) |
| iOS App kaydı | ✅ `1:1063947496038:ios:30ce2503a12b750b711ba7` (`com.odevtakip.odevTakip`) |
| `lib/firebase_options.dart` | ✅ `flutterfire configure` ile üretildi |
| `android/app/google-services.json` | ✅ Firebase'den indirildi |
| `ios/Runner/GoogleService-Info.plist` | ✅ Firebase'den indirildi |
| Android SHA-1 | ✅ `b5:56:09:37:cf:61:a3:3d:7f:61:df:e6:70:14:b6:f0:53:f5:26:0c` (debug) |
| Android SHA-256 | ✅ `8d:1a:31:b0:...:ae:9f:15:0a` (debug) |
| Authorized domains | ✅ `localhost`, `*.firebaseapp.com`, `*.web.app` |
| **Blaze faturalandırma** | ⬜ **Console'dan doğrulanmalı** |
| **Phone provider (Sign-in method)** | ⬜ **Console'dan doğrulanmalı** |
| **SMS region allowlist** | ⬜ **Yalnızca TR seçilmeli** |
| iOS APNs anahtarı | ⬜ macOS + Apple Developer hesabı gerekir |

---

## 1. 💳 Blaze Planı (SMS için ZORUNLU)

Firebase Phone Authentication artık ücretsiz Spark planında gerçek SMS göndermez.
Gerçek numaraya kod gitmesi için projenin **Blaze (Pay as you go)** planında olması gerekir.

### Yükseltme
1. [Firebase Console](https://console.firebase.google.com/project/odevtakipsistemi-b93b2/usage/details) → sol alt köşedeki plan rozeti → **Upgrade**
2. **Blaze — Pay as you go** seç → bir Cloud Billing hesabı bağla.

### ⚠️ Maliyet Koruması (Yükseltmeden HEMEN sonra yapılmalı)
Blaze, kullanım tavanı olmayan bir plandır. SMS pumping saldırısı ciddi fatura üretebilir.

1. **Bütçe alarmı kur:**
   [Google Cloud Billing → Budgets & alerts](https://console.cloud.google.com/billing/budgets) →
   **Create Budget** → Proje: `odevtakipsistemi-b93b2` → Aylık tutar belirle (örn. **$10**) →
   Eşikler: **%50 / %90 / %100** → e-posta bildirimi aç.
2. **SMS region allowlist'i daralt** (aşağıdaki Bölüm 2.2). En etkili maliyet korumasıdır.
3. **Firebase App Check'i etkinleştir** (Bölüm 4) — bot trafiğini kaynağında keser.

> Bütçe alarmı harcamayı **durdurmaz**, yalnızca haber verir. Asıl koruma allowlist + App Check'tir.

---

## 2. 🌐 Firebase Console Ayarları (Zorunlu)

### 2.1 Phone Provider'ı Etkinleştir
[Authentication → Sign-in method](https://console.firebase.google.com/project/odevtakipsistemi-b93b2/authentication/providers)
→ **Phone** → **Enable** → **Save**

Kapalıysa uygulama şu hatayı verir:
`operation-not-allowed` → *"Firebase Console üzerinde Telefon Doğrulama (Phone Provider) etkinleştirilmemiş."*

### 2.2 SMS Region Policy (Toll Fraud Koruması)
Aynı sayfada **SMS region policy** → **Allow only specific regions** →
yalnızca **Turkey (+90)** seç. Diğer 200+ ülke bloke olur.

### 2.3 Authorized Domains
[Authentication → Settings → Authorized domains](https://console.firebase.google.com/project/odevtakipsistemi-b93b2/authentication/settings)
Aşağıdakiler zaten ekli (doğrulandı):
* `localhost`
* `odevtakipsistemi-b93b2.firebaseapp.com`
* `odevtakipsistemi-b93b2.web.app`

Özel alan adı eklerseniz (örn. `matpusula.app`) buraya da eklenmelidir.

### 2.4 Test Numaraları (Kota harcamadan test)
Aynı Phone provider ekranında **Phone numbers for testing** →
* Telefon: `+90 531 563 50 49` → Kod: `123456`

Test numaraları **Spark planında da çalışır** ve gerçek SMS göndermez.
Akışın tamamını Blaze'e geçmeden doğrulamak için bunu kullanın.

---

## 3. 🤖 Android — Tamamlandı ✅

SHA parmak izleri Firebase'e kaydedildi. Doğrulamak için:

```bash
firebase apps:android:sha:list 1:1063947496038:android:c424f96a4fa7ed77711ba7
```

### ⚠️ Release İmzası İçin Ek Adım
`android/key.properties` **yok**, bu yüzden release build şu an **debug anahtarıyla** imzalanıyor
(`android/app/build.gradle.kts` içindeki fallback). Play Store'a çıkarken:

1. Release keystore üret, `android/key.properties` oluştur (`key.properties.example` örnek).
2. Release SHA'larını al ve kaydet:
   ```bash
   keytool -list -v -keystore <release.jks> -alias <alias>
   firebase apps:android:sha:create 1:1063947496038:android:c424f96a4fa7ed77711ba7 <SHA1>
   firebase apps:android:sha:create 1:1063947496038:android:c424f96a4fa7ed77711ba7 <SHA256>
   ```
3. **Play App Signing kullanıyorsanız**, Play Console'un ürettiği SHA'ları da ekleyin —
   aksi halde mağazadan inen sürümde Phone Auth çalışmaz.

---

## 4. 🛡️ App Check (Şiddetle Önerilir)

Phone Auth'u sahte istemcilerden korur ve SMS maliyetini düşürür.

1. [App Check](https://console.firebase.google.com/project/odevtakipsistemi-b93b2/appcheck) →
   Android: **Play Integrity**, iOS: **App Attest**, Web: **reCAPTCHA Enterprise**.
2. Backend zaten hazır: `backend/src/middleware/authMiddleware.js` `X-Firebase-AppCheck`
   başlığını doğruluyor. `APP_CHECK_MODE=audit` ile başlayın, log'lar temizse `enforce`'a alın.

---

## 5. 🍎 iOS — Kalan İşler (macOS gerekir)

`GoogleService-Info.plist` indirildi, ancak Xcode projesine **dosya referansı olarak eklenmelidir**
(Windows'ta yapılamaz):

1. Xcode → `Runner` → sağ tık → **Add Files to "Runner"** → `GoogleService-Info.plist`
   (**Copy items if needed** işaretli, hedef: Runner).
2. **Signing & Capabilities** → `+ Capability`:
   * **Push Notifications**
   * **Background Modes** → ☑️ Background fetch, ☑️ Remote notifications
3. Apple Developer Portal → **APNs Auth Key (.p8)** üret →
   [Cloud Messaging](https://console.firebase.google.com/project/odevtakipsistemi-b93b2/settings/cloudmessaging)
   → Apple app configuration → yükle.
4. APNs çalışmazsa Firebase reCAPTCHA'ya düşer; bunun için `Info.plist`'e
   `REVERSED_CLIENT_ID` URL scheme'i eklenmelidir (Google Sign-In etkinleştirilirse üretilir).

---

## 6. ✅ Doğrulama

```bash
flutter analyze          # No issues found
flutter test             # 36/36
cd backend && npm test   # 5/5
flutter build web --release
flutter build apk --debug
```

Canlı web dağıtımı:
```bash
firebase deploy --only hosting
```
