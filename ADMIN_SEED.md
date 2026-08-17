# MatPusula Admin — Manuel Seed Rehberi

Admin hesapları uygulama içinden oluşturulmaz. İlk süper kullanıcı Firebase Console üzerinden manuel eklenir.

## Adımlar

1. [Firebase Console](https://console.firebase.google.com) → Proje: `odevtakipsistemi-b93b2`
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

5. Admin paneli çalıştır:

```bash
cd web-panel
flutter pub get
flutter run -d chrome
```

6. Yukarıdaki e-posta/şifre ile giriş yap.

## Cloud Functions (toplu push)

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Notlar

- `teacher` veya `parent` hesapları admin panele **giremez**.
- Toplu push için mobil kullanıcıların FCM token kaydetmiş olması gerekir (uygulama açılışında bildirim izni).
- Admin panel salt okunurdur; öğretmen işlemleri mobil uygulamada yapılır.
