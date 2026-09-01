# Eduly Admin (web-panel)

Flutter Web süper kullanıcı paneli. Öğretmen/veli mobil uygulamasının kopyası değildir.

## Özellikler

- Yalnızca `role=admin` giriş
- Genel bakış istatistikleri, öğretmen/öğrenci listeleri, aktivite, toplu FCM broadcast

## Geliştirme

```bash
cd web-panel
cp lib/firebase_options.example.dart lib/firebase_options.dart   # ilk kurulum
flutter pub get
flutter run -d chrome
```

## Üretim derlemesi (Hosting)

```bash
cd web-panel
flutter pub get
flutter build web --release
```

Çıktı: `web-panel/build/web` — `firebase.json` hosting `public` yolu buraya işaret eder.

Canlı deploy için kök `HANDOFF.md` Faz B runbook'una bakın (Firebase CLI gerekir).

Admin hesabı: kök [`ADMIN_SEED.md`](../ADMIN_SEED.md).
