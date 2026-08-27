# Eduly Admin — Manuel Seed Rehberi

Admin hesapları uygulama içinden oluşturulmaz. İlk süper kullanıcı Firebase Console üzerinden manuel eklenir.

## Adımlar

0. **Authentication’ı ilk kez aç** (henüz yapılmadıysa):
   - [Authentication](https://console.firebase.google.com/project/eduly-server/authentication) → **Get started**
   - **Sign-in method** → **Email/Password** → Enable → Save

1. [Firebase Console](https://console.firebase.google.com) → Proje: `eduly-server`
2. **Authentication** → **Add user** → admin e-postası ve güçlü şifre
3. Oluşan kullanıcının **UID** değerini kopyala
4. **Firestore Database** → `users` koleksiyonu → **Add document**
   - Document ID: kopyalanan UID
   - Alanlar:

```json
{
  "uid": "<UID>",
  "role": "admin",
  "name": "Platform Yöneticisi",
  "email": "admin@ornek.com",
  "isActive": true,
  "createdAt": "2026-08-17T12:00:00.000Z",
  "updatedAt": "2026-08-17T12:00:00.000Z"
}
```

5. Local panel:

```bash
cd web-panel
flutter pub get
flutter run -d chrome
```

6. Canlı Hosting (Faz B — [HANDOFF.md](HANDOFF.md)):

```bash
cd web-panel && flutter build web --release && cd ..
firebase deploy --only hosting
```

URL örneği: `https://eduly-server.web.app`

## Cloud Functions (toplu push)

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Notlar

- `teacher` veya `parent` hesapları admin panele **giremez**.
- `isActive: false` admin hesapları reddedilir.
- Toplu push için mobil kullanıcıların FCM token kaydetmiş olması gerekir.
- Admin panel salt okunur gözetimdir; öğretmen işlemleri mobil uygulamada yapılır.
