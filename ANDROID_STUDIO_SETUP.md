# 🚀 Android Studio Kurulum & Çalıştırma Kılavuzu
## Ödev Takip Sistemi — Eduly

Bu kılavuz, projeyi Android Studio'da açıp çalıştırmak ve
PostgreSQL sync sistemini aktif etmek için gereken tüm adımları içerir.

---

## ✅ Ön Koşullar (Kurulu Olması Gerekenler)

| Araç | Minimum Sürüm | İndirme |
|------|--------------|---------|
| Android Studio | Hedgehog (2023.1.1) | [developer.android.com](https://developer.android.com/studio) |
| Flutter SDK | 3.3.0+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Docker Desktop | 4.x | [docker.com](https://www.docker.com/products/docker-desktop) |
| Node.js | 18.0.0+ | [nodejs.org](https://nodejs.org/) |
| Git | herhangi | [git-scm.com](https://git-scm.com/) |

---

## 🔧 BÖLÜM 1 — Android Studio Yapılandırması

### Adım 1.1 — Flutter & Dart Plugin Kurulumu

1. Android Studio'yu aç
2. `File → Settings → Plugins` (Windows/Linux) veya `Android Studio → Preferences → Plugins` (Mac)
3. **Marketplace** sekmesinde `Flutter` ara → **Install**
4. Dart plugini otomatik kurulur, onayla
5. **Restart IDE**

### Adım 1.2 — Flutter SDK'yı Tanıt

1. `File → Settings → Languages & Frameworks → Flutter`
2. **Flutter SDK path** alanına Flutter'ı kurduğun klasörü gir:
   ```
   Örnek (Windows): C:\flutter
   Örnek (Mac):     /Users/kullanici/flutter
   ```
3. Dart SDK path otomatik dolar → **OK**

### Adım 1.3 — Projeyi Aç

1. Android Studio'da `File → Open`
2. Repodaki `mobile` klasörünü seç (Flutter uygulaması artık kökte değil)
3. **Trust Project** → **OK**
4. Sağ altta "Indexing..." bitmesini bekle (~1-2 dk)

---

## 🔥 BÖLÜM 2 — Firebase Yapılandırması

> ⚠️ Bu adım olmadan uygulama başlamaz!

### Adım 2.1 — Service Account Key (Backend için)

1. [Firebase Console](https://console.firebase.google.com) → Projeyi Seç
2. `⚙️ Proje Ayarları → Hizmet hesapları`
3. **Yeni özel anahtar oluştur** → JSON dosyasını indir
4. Dosyayı yeniden adlandır: `serviceAccountKey.json`
5. Kopyala: `ODEV_SİSTEM_PROJESİ/backend/serviceAccountKey.json`

### Adım 2.2 — Android için google-services.json

1. Firebase Console → `Proje Ayarları → Uygulamalarım → Android uygulaması`
2. **google-services.json** dosyasını indir
3. Kopyala: `mobile/android/app/google-services.json` (şablon: `google-services.json.example`)

### Adım 2.3 — Flutter Firebase seçenekleri (web derlemesi)

Mobil projede Flutter web veya admin panelde derleme için:

```bash
# web-panel
cp web-panel/lib/firebase_options.example.dart web-panel/lib/firebase_options.dart

# mobile (yalnızca flutter run -d chrome gibi web hedefleri)
cp mobile/lib/firebase_options.example.dart mobile/lib/firebase_options.dart
```

Ardından `firebase_options.dart` içindeki placeholder değerleri Firebase Console'dan doldurun.
Alternatif: `dart pub global activate flutterfire_cli` → `flutterfire configure`

### Adım 2.4 — Firebase Phone Auth (veli SMS OTP)

1. Firebase Console → Authentication → Sign-in method → **Phone** → Enable
2. Android: Proje ayarları → SHA-1 ve SHA-256 fingerprint ekle (`keytool -list -v -keystore ...`)
3. Geliştirme için Console'da test telefon numarası + sabit OTP tanımlayabilirsiniz

### Adım 2.5 — iOS için (isteğe bağlı)
1. Firebase Console → iOS uygulaması → `GoogleService-Info.plist` indir
2. Kopyala: `ODEV_SİSTEM_PROJESİ/ios/Runner/GoogleService-Info.plist`

---

## 🐘 BÖLÜM 3 — PostgreSQL (Docker) Kurulumu

### Adım 3.1 — Docker Desktop'ı Başlat
Docker Desktop'ı aç ve çalıştığını doğrula (sistem tepsisinde balina ikonu).

### Adım 3.2 — PostgreSQL Container'larını Başlat

PowerShell veya Terminal'de:
```powershell
cd "C:\Users\yusuf\Desktop\ODEV_SİSTEM_PROJESİ"
docker compose up -d
```

**Beklenen çıktı:**
```
✔ Container odevtakip_postgres   Started
✔ Container odevtakip_pgadmin    Started
```

### Adım 3.3 — pgAdmin ile Doğrula (Opsiyonel)

1. Tarayıcıda aç: `http://localhost:5050`
2. Giriş:
   - E-posta: `admin@odevtakip.com`
   - Şifre: `admin123`
3. Sol panelde `Add New Server`:
   - **Name**: `OdevTakip Local`
   - **Host**: `postgres` (container adı)
   - **Port**: `5432`
   - **Username**: `odevuser`
   - **Password**: `odevpass123`
4. Tabloları gör: `Databases → odevtakip → Schemas → public → Tables`

---

## ☁️ BÖLÜM 4 — Neon.com Kurulumu (Bulut PostgreSQL)

### Adım 4.1 — Hesap Oluştur

1. [neon.tech](https://neon.tech) → **Get started for free**
2. GitHub ile giriş yap
3. **New Project** → İsim: `odevtakip` → Region: `EU Central` → **Create Project**

### Adım 4.2 — Connection String Al

1. Dashboard → Projen → **Connection Details**
2. **Connection string** kopyala:
   ```
   postgresql://user:pass@ep-xxx.eu-central-1.aws.neon.tech/neondb?sslmode=require
   ```

### Adım 4.3 — Şemayı Neon'a Uygula

1. Neon Dashboard → **SQL Editor**
2. `ODEV_SİSTEM_PROJESİ/backend/init.sql` dosyasının içeriğini yapıştır
3. **Run** → Tablolar oluşur

---

## ⚙️ BÖLÜM 5 — Backend .env Yapılandırması

```powershell
cd "C:\Users\yusuf\Desktop\ODEV_SİSTEM_PROJESİ\backend"
copy .env.example .env
```

`.env` dosyasını aç ve şu alanları doldur:
```env
NEON_DATABASE_URL=postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require
API_SECRET_KEY=odev2026gizli   # İstediğin herhangi bir şifre
```

**NEON_DATABASE_URL** dışında diğer tüm değerler varsayılan olarak çalışır.

---

## 🔄 BÖLÜM 6 — Sync Backend'i Başlat

```powershell
cd "C:\Users\yusuf\Desktop\ODEV_SİSTEM_PROJESİ\backend"

# Bağımlılıkları yükle (ilk kez)
npm install

# Veritabanı bağlantısını test et
npm run db:health

# Sync servisini başlat
npm run dev
```

**Beklenen çıktı:**
```
══════════════════════════════════════════════
  📋 Ödev Takip Sistemi — Sync Backend v1.0
══════════════════════════════════════════════

✅ Firebase Admin SDK başlatıldı
✅ [Docker PostgreSQL] Bağlantı başarılı
✅ [Neon PostgreSQL] Bağlantı başarılı

🔄 İlk tam sync yapılıyor...
  ✅ [users] 3 doküman aktarıldı
  ✅ [students] 12 doküman aktarıldı
  ...

🚀 Gerçek zamanlı sync başlatılıyor...
✅ 9 koleksiyon dinleniyor.

🌐 Sunucu çalışıyor: http://localhost:3001
```

---

## 📱 BÖLÜM 7 — Flutter Uygulamasını Android Studio'da Çalıştır

### Adım 7.1 — Bağımlılıkları Yükle

Android Studio Terminal panelinde (`View → Tool Windows → Terminal`):
```bash
cd mobile
flutter pub get
```

### Adım 7.2 — Android Emülatör Oluştur

1. `Tools → Device Manager`
2. **Create Virtual Device** → **Phone**
3. **Pixel 8** seç → **Next**
4. **API 34** (Android 14, UpsideDownCake) seç → İndir (gerekirse) → **Next**
5. AVD Name: `Pixel_8_API_34` → **Finish**
6. ▶ Play butonu ile emülatörü başlat

### Adım 7.3 — Uygulamayı Çalıştır

**Yöntem A — Toolbar'dan:**
1. Üst toolbar'da cihaz seçici açılır menüsünden `Pixel 8 API 34` seç
2. Yeşil ▶ **Run** butonuna tıkla (veya `Shift + F10`)

**Yöntem B — Terminal'den:**
```bash
flutter run -d emulator-5554
```

**Yöntem C — Gerçek Android Cihaz:**
1. Telefonda `Geliştirici Seçenekleri → USB Hata Ayıklama` aktif et
2. USB ile bağla
3. `flutter devices` ile cihazı gör
4. `flutter run -d CIHAZ_ID`

---

## 🧪 BÖLÜM 8 — Test & Doğrulama

### Sync çalışıyor mu?
```
Tarayıcıda: http://localhost:3001/api/health
```
```json
{
  "status": "ok",
  "database": { "local": true, "neon": true },
  "sync": { "activeListeners": 9, "totalSynced": 47 }
}
```

### Flutter testleri:
```bash
flutter test
```

### Kod analizi:
```bash
flutter analyze
```

---

## 📁 Son Proje Yapısı

```
ODEV_SİSTEM_PROJESİ/
├── 🐳 docker-compose.yml          ← PostgreSQL + pgAdmin
├── 📋 pubspec.yaml                ← http paketi eklendi
├── .gitignore                     ← Güncellendi (secrets korumalı)
│
├── backend/                       ← Node.js Sync Servisi
│   ├── .env.example               ← Bunu .env olarak kopyala
│   ├── package.json
│   ├── init.sql                   ← PostgreSQL tablo şeması
│   ├── serviceAccountKey.json     ← (GİZLİ - gitignore'da)
│   └── src/
│       ├── index.js               ← Ana uygulama
│       ├── db/
│       │   ├── pool.js            ← Docker + Neon bağlantıları
│       │   └── health-check.js
│       ├── sync/
│       │   └── firebase-to-pg.js  ← Gerçek zamanlı sync motoru
│       └── routes/
│           └── backup.js          ← REST API endpoint'leri
│
└── lib/
    └── core/
        └── services/
            └── postgres_api_service.dart  ← Flutter HTTP client
```

---

## 🆘 Sık Karşılaşılan Sorunlar

| Sorun | Çözüm |
|-------|-------|
| `flutter: command not found` | Flutter'ı PATH'e ekle |
| `google-services.json not found` | Firebase Console'dan indir, `android/app/` altına koy |
| `Docker daemon not running` | Docker Desktop'ı başlat |
| `port 5432 already in use` | `netstat -ano \| findstr 5432` ile kontrol et |
| `serviceAccountKey.json not found` | Firebase Hizmet Hesapları'ndan indir |
| Emülatör `10.0.2.2` bağlanmıyor | Backend'in `npm run dev` ile çalıştığını doğrula |
| `ERR_CLEARTEXT_NOT_PERMITTED` | `android/app/src/main/AndroidManifest.xml`'e `usesCleartextTraffic="true"` ekle |

---

## 📞 Hızlı Başlangıç Özeti

```powershell
# Terminal 1 — PostgreSQL
docker compose up -d

# Terminal 2 — Sync Backend
cd backend && npm install && npm run dev

# Terminal 3 — Flutter
cd mobile && flutter pub get && flutter run
```

**3 terminal, 3 komut — hepsi hazır!** 🎉
