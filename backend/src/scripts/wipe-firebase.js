const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '../../serviceAccountKey.json'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();
const auth = admin.auth();

async function deleteCollection(collectionPath) {
  const collectionRef = db.collection(collectionPath);
  const snapshot = await collectionRef.get();

  if (snapshot.empty) {
    console.log(`ℹ️ ${collectionPath} koleksiyonu zaten boş.`);
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();
  console.log(`✅ ${collectionPath} koleksiyonundaki ${snapshot.size} belge tamamen silindi.`);
}

async function wipeAllData() {
  console.log('🚀 Firebase Firestore & Auth verileri temizleniyor...');

  const collections = [
    'users',
    'teacher_profiles',
    'parent_profiles',
    'students',
    'classes',
    'homeworks',
    'homework_assignments',
    'exam_results',
    'invite_codes',
    'messages',
    'subject_progress'
  ];

  for (const col of collections) {
    try {
      await deleteCollection(col);
    } catch (err) {
      console.error(`⚠️ ${col} silinirken hata: ${err.message}`);
    }
  }

  // 2. Firebase Auth Kullanıcılarını Sil
  try {
    const listResult = await auth.listUsers(1000);
    const uids = listResult.users.map(u => u.uid);
    if (uids.length > 0) {
      await auth.deleteUsers(uids);
      console.log(`✅ ${uids.length} adet Firebase Auth kullanıcısı tamamen silindi!`);
    } else {
      console.log('ℹ️ Firebase Auth sisteminde kayıtlı kullanıcı bulunamadı.');
    }
  } catch (err) {
    console.error(`⚠️ Auth kullanıcıları silinirken hata: ${err.message}`);
  }

  console.log('🎉 Firebase üzerindeki TÜM VERİLER VE KULLANICILAR BAŞARIYLA TEMİZLENDİ!');
  process.exit(0);
}

wipeAllData();
