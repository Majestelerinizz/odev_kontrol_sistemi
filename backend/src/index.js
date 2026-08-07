// ═══════════════════════════════════════════════════════════════
// src/index.js — Ana Uygulama Giriş Noktası
// Firebase Admin başlatma + PostgreSQL sağlık kontrolü +
// Express server + Realtime sync başlatma
// ═══════════════════════════════════════════════════════════════
'use strict';

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const admin = require('firebase-admin');
const path = require('path');

const { healthCheck } = require('./db/pool');
const { startRealtimeSync, fullSync } = require('./sync/firebase-to-pg');
const backupRouter = require('./routes/backup');

const app = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ─────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// ── Rotalar ────────────────────────────────────────────────────
app.use('/api', backupRouter);

// ── Kök endpoint ───────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    service: '📋 Ödev Takip Sistemi — Sync Backend',
    version: '1.0.0',
    endpoints: {
      health:       'GET  /api/health',
      syncStats:    'GET  /api/sync/stats       (API Key gerekli)',
      fullSync:     'POST /api/sync/full        (API Key gerekli)',
      students:     'GET  /api/data/students    (API Key gerekli)',
      examResults:  'GET  /api/data/exam-results?studentId=XXX (API Key gerekli)',
      syncLog:      'GET  /api/data/sync-log    (API Key gerekli)',
    },
  });
});

// ── Hata yakalama ──────────────────────────────────────────────
app.use((err, req, res, _next) => {
  console.error('❌ Sunucu hatası:', err.message);
  res.status(500).json({ error: err.message });
});

// ── Uygulama Başlatma ──────────────────────────────────────────
async function bootstrap() {
  console.log('\n══════════════════════════════════════════════');
  console.log('  📋 Ödev Takip Sistemi — Sync Backend v1.0');
  console.log('══════════════════════════════════════════════\n');

  // 1. Firebase Admin SDK başlat
  const serviceAccountPath = path.resolve(__dirname, '..', process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 'serviceAccountKey.json');
  
  try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ Firebase Admin SDK başlatıldı');
  } catch (err) {
    console.error('❌ Firebase başlatma hatası:', err.message);
    console.error('   → serviceAccountKey.json dosyasını backend/ klasörüne koyun.');
    console.error('   → Firebase Console → Proje Ayarları → Hizmet Hesapları → Yeni özel anahtar oluştur');
    process.exit(1);
  }

  const db = admin.firestore();

  // 2. PostgreSQL bağlantı kontrolü
  console.log('\n🔍 PostgreSQL bağlantıları kontrol ediliyor...');
  const dbStatus = await healthCheck();
  
  if (!dbStatus.local && !dbStatus.neon) {
    console.error('\n❌ Hiçbir PostgreSQL veritabanına bağlanılamadı!');
    console.error('   → Docker için: docker compose up -d komutunu çalıştırın');
    console.error('   → Neon için: .env dosyasındaki NEON_DATABASE_URL\'yi yapılandırın\n');
    process.exit(1);
  }

  // 3. İlk tam sync (varsa daha önce girilmiş veriler)
  console.log('\n🔄 İlk tam sync yapılıyor (mevcut veriler aktarılıyor)...');
  await fullSync(db);

  // 4. Gerçek zamanlı sync başlat
  if (process.env.REALTIME_SYNC !== 'false') {
    startRealtimeSync(db);
  }

  // 5. HTTP sunucusu başlat
  app.listen(PORT, () => {
    console.log(`\n🌐 Sunucu çalışıyor: http://localhost:${PORT}`);
    console.log(`📊 pgAdmin:          http://localhost:5050`);
    console.log(`🔑 API Key:          x-api-key: ${process.env.API_SECRET_KEY || '(ayarlanmamış)'}\n`);
  });

  // 6. Graceful shutdown
  process.on('SIGTERM', gracefulShutdown);
  process.on('SIGINT',  gracefulShutdown);
}

function gracefulShutdown() {
  console.log('\n⏹  Uygulama kapatılıyor...');
  const { stopAllListeners } = require('./sync/firebase-to-pg');
  stopAllListeners();
  process.exit(0);
}

bootstrap().catch((err) => {
  console.error('❌ Kritik hata:', err);
  process.exit(1);
});
