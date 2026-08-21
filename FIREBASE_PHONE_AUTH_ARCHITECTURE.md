# 📱 Firebase Telefon Doğrulama (SMS OTP) — Mimari ve Sistem Tasarımı

**Proje:** MatPusula — Ödev & Sınav Takip Sistemi  
**Tarih:** 21 Ağustos 2026  
**Durum:** Üretim Seviyesi (Production-Ready)

---

## 1. 🌟 Yönetici Özeti & Temel İlke

> ⚠️ **Üretim Kuralı:**  
> SMS doğrulama kodunu (OTP) asla kendi backend'inizde üretmeyin, saklamayın veya doğrulamayın!  
> Firebase Authentication, SMS gönderimi, OTP doğrulaması ve oturum yönetiminin **tek yetkili kaynağı (Single Source of Truth)** olmalıdır.  
> Kullanıcı Firebase ile başarıyla giriş yaptıktan sonra istemci **Firebase ID Token** alır ve bunu backend'e iletir. Backend ise **Firebase Admin SDK** ile bu token'ı doğrular.

---

## 2. 🔄 Uçtan Uca Telefon Doğrulama Akış Şeması (Sequence Diagram)

```mermaid
sequenceDiagram
    autonumber
    actor Parent as 👨‍👩‍👧 Veli (Kullanıcı)
    participant Client as 📱 Flutter Uygulaması (Web/Android/iOS)
    participant Google as ☁️ Firebase Authentication (SMS Gateway)
    participant Operator as 📡 GSM Operatörü (Turkcell / Vodafone / TT)
    participant Backend as 🐘 Node.js Express API
    participant PG as 🗄️ PostgreSQL Veritabanı
    participant Firestore as 🔥 Cloud Firestore

    Parent->>Client: Telefon Numarasını Girer (0531 563 50 49)
    Client->>Client: E.164 Normalizasyonu (+905315635049)
    Client->>Google: verifyPhoneNumber(E.164, RecaptchaVerifier / PlayIntegrity / APNs)
    Google->>Operator: 6 Haneli OTP Gönder (Google SMS)
    Operator->>Parent: SMS İletilir: "123456 - Google doğrulama kodunuz"
    Client->>Client: 60 Saniye Cooldown Sayacı Başlat
    Parent->>Client: 6 Haneli OTP Kodunu Girer (123456)
    Client->>Google: signInWithCredential(verificationId, smsCode)
    Google-->>Client: Firebase User + ID Token (JWT)
    
    par Dual Storage Sync
        Client->>Firestore: users & parent_profiles Eşitle / Öğrenciye Bağla
        Client->>Backend: POST /api/auth/verify-session (Bearer ID_TOKEN)
        Backend->>Google: Admin SDK verifyIdToken(idToken)
        Backend->>PG: UPSERT INTO users / parents
        Backend-->>Client: 200 OK (Doğrulandı)
    end
```

---

## 3. 🛡️ Platform Bazlı Uygulama Doğrulama (App Verification Fallbacks)

```mermaid
flowchart TD
    Start["Kullanıcı Numarayı Girer (+90 53X)"] --> Platform{Hangi Platform?}
    
    Platform -->|Android| PlayIntegrity["1. Google Play Integrity"]
    PlayIntegrity -->|Başarılı| SendSMS["Firebase SMS Gönderir"]
    PlayIntegrity -->|Başarısız / Cihaz Desteklemez| AndroidRecaptcha["2. Invisible reCAPTCHA Fallback"]
    AndroidRecaptcha --> SendSMS
    
    Platform -->|iOS| SilentAPNs["1. Silent APNs Bildirimi"]
    SilentAPNs -->|Başarılı| SendSMS
    SilentAPNs -->|Background Refresh Kapalı| IosRecaptcha["2. Safari / Web reCAPTCHA Fallback"]
    IosRecaptcha --> SendSMS
    
    Platform -->|Web / Tarayıcı| WebRecaptcha["Google Invisible RecaptchaVerifier"]
    WebRecaptcha --> SendSMS
```

---

## 4. 🗄️ Hibrit Çift Veritabanı Mimarisi (Firestore + PostgreSQL)

```mermaid
graph LR
    A["📱 Mobil / Web İstemci"] -->|Realtime Stream| B["🔥 Google Cloud Firestore"]
    A -->|Bearer ID Token| C["🐘 Node.js API (Express)"]
    C -->|Admin SDK| D["☁️ Firebase Auth"]
    C -->|SQL Bağlantısı| E["🗄️ PostgreSQL 16 Veritabanı"]
    B -.->|Realtime Listener| C
```

1. **Firebase Firestore:**
   * Anlık mobil ve web arayüzü akışı, canlı deneme net grafikleri (`fl_chart`), ödev bildirimleri.
2. **PostgreSQL 16:**
   * Kurumsal ilişkisel veri yapısı, SQL analitiği, muhasebe/raporlama ve kalıcı yedekleme.
