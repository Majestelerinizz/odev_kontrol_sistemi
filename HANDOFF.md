# Handoff — Tasarım ekibi & Faz B (Firebase canlı)

Altyapı (auth, rules dosyaları, index dosyaları, FCM client, hosting config, local build) hazır.
**Faz B ilerleme (`eduly-server`):** Firestore rules + indexes canlı; Hosting canlı (`https://eduly-server.web.app`).
**Kalan:** Authentication’da Email/Password açılması (Console), admin seed, Cloud Functions için Blaze planı.

## Açılacak klasörler

| Klasör | Amaç |
|--------|------|
| `mobile/` | Öğretmen + veli Flutter uygulaması |
| `web-panel/` | Admin Flutter Web paneli (öğretmen kopyası değil) |
| `functions/` | `sendBroadcast` Cloud Function |
| `backend/` | Legacy / opsiyonel — lansman yolu değil |

Kökte Flutter `pubspec.yaml` yoktur. Android Studio / Xcode için `mobile/` açın.

## Tasarım ekibi ne yapar / ne yapmaz

**Yapar:** tema, layout, kopya, animasyon, boş durum görselleri, ikonografi.

**Yapmaz:** Firestore rules/indexes geri alma, demo OTP/passwordless geri getirme, `backend/`’i zorunlu kılma, auth rol mantığını değiştirme.

## Auth (üretim)

- Öğretmen: e-posta + şifre
- Veli: davet kodu ile kayıt (e-posta + şifre) veya e-posta ile giriş
- Admin: yalnızca `role=admin` + `isActive != false` — [ADMIN_SEED.md](ADMIN_SEED.md)

## Stabilize notları (kod)

- Firestore: `invite_codes` kullanılan kodlar anonim okunamaz; ödev `get` veli için `studentIds` ∩ `parent_profiles.studentIds`
- Yeni ödevler `studentIds` yazar; AI sınav tarayıcı UI gizlendi
- Crashlytics release’te açık; CI: `.github/workflows/ci.yml`
- Yasal sayfalar: Hosting `privacy.html` / `terms.html` / `support.html`

## Local smoke (Firebase projesi bağlı cihaz/emülatör)

- [ ] Öğretmen kayıt / giriş (yanlış rol sekmesi reddedilir)
- [ ] Sınıf + öğrenci + davet kodu
- [ ] Veli davet kaydı + ödev / deneme listesi (demo veri yok)
- [ ] Öğretmen mesajı
- [ ] Admin login (local `flutter run -d chrome`)
- [ ] Broadcast (FCM token’lı cihazda; Functions deploy sonrası)

## Faz B — DURAK: canlı Firebase (CLI + Blaze gerekir)

Proje: `eduly-server` (`.firebaserc`).

Önkoşullar:

1. `npm i -g firebase-tools` (veya mevcut CLI)
2. `firebase login`
3. Firebase Console’da Blaze planı
4. Admin seed ([ADMIN_SEED.md](ADMIN_SEED.md))

Komutlar (repo kökünden):

```bash
# 1) Rules + indexes
firebase deploy --only firestore:rules,firestore:indexes

# 2) Functions (predeploy tsc çalıştırır)
firebase deploy --only functions

# 3) Hosting — önce web build taze olsun
cd web-panel && flutter pub get && flutter build web --release && cd ..
firebase deploy --only hosting
```

veya birleşik:

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions,hosting
```

Deploy sonrası:

- Hosting URL: `https://eduly-server.web.app` (veya Console’daki Hosting URL)
- Authentication → Authorized domains: `*.web.app` / `*.firebaseapp.com` (genelde hazır)
- Canlı smoke: admin login, listeler, broadcast; mobile parent homework get

## Referanslar

- [README.md](README.md) — mimari ve çalıştırma
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) — mağaza paketleri (`mobile/`)
- [web-panel/README.md](web-panel/README.md) — admin panel
