# ⚙️ Firebase Phone Auth — Kurulum & Yapılandırma Kılavuzu

**Proje:** MatPusula  
**Hedef:** Google Firebase Console & Platform Yapılandırması

---

## 1. 🌐 Firebase Console Ayarları (Zorunlu)

1. **Phone Provider'ı Etkinleştirin:**
   * Firebase Console -> **Authentication** -> **Sign-in method** sekmesine gidin.
   * **Phone** (Telefon) sağlayıcısını bulun ve **Enable** yapın.
2. **SMS Region Allowlist (Bölge İzin Listesi):**
   * SMS Toll Fraud ve spam saldırılarını önlemek için yalnızca hizmet verdiğiniz ülkeleri seçin:
     * `TR` (Türkiye - +90)
     * *(Varsa)* `DE` (Almanya - +49), `NL` (Hollanda - +31)
3. **Authorized Domains (Web için İzinli Alan Adları):**
   * Firebase Console -> **Authentication** -> **Settings** -> **Authorized domains** bölümüne şunları ekleyin:
     * `odevtakipsistemi-b93b2.web.app`
     * `odevtakipsistemi-b93b2.firebaseapp.com`
     * *(Özel alan adınız varsa)* `matpusula.app`

---

## 2. 🤖 Android Platform Yapılandırması (Play Integrity & SHA-1 / SHA-256)

1. **SHA Parmak İzlerini Ekleyin:**
   * Firebase Console -> **Project Settings** -> **Android Apps** -> Uygulamanızı seçin.
   * `SHA-256` parmak izini ekleyin -> **Google Play Integrity** için zorunludur.
   * `SHA-1` parmak izini ekleyin -> **reCAPTCHA Fallback** için zorunludur.
2. **Parmak izini almak için komut:**
   ```bash
   cd android
   ./gradlew signingReport
   ```

---

## 3. 🍎 iOS Platform Yapılandırması (APNs & Background Modes)

1. **Xcode Ayarları:**
   * Xcode projesinde **Signing & Capabilities** sekmesini açın.
   * `+ Capability` butonuna basarak **Push Notifications** özelliğini ekleyin.
   * `+ Capability` butonuna basarak **Background Modes** ekleyin ve şunları işaretleyin:
     * ☑️ **Background fetch**
     * ☑️ **Remote notifications**
2. **APNs Anahtarı (Apple Push Notification Service):**
   * Apple Developer Portal üzerinden bir **APNs Auth Key (.p8)** dosyası üretin.
   * Firebase Console -> **Project Settings** -> **Cloud Messaging** -> **Apple app configuration** altına bu anahtarı yükleyin.

---

## 4. 🧪 Geliştirme & Test Numaraları (Sınırsız & Ücretsiz Test)

Firebase kotasını harcamadan ve gerçek SMS beklemeden anında test yapmak için:
* Firebase Console -> **Authentication** -> **Sign-in method** -> **Phone** -> **Phone numbers for testing** altına ekleyin:
  * **Telefon:** `+90 531 563 50 49`
  * **Sabit Kod:** `123456`
