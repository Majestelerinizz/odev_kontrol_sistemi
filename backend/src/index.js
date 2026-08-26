// ═══════════════════════════════════════════════════════════════
// src/index.js — Ana Uygulama Giriş Noktası
// Firebase Admin başlatma + PostgreSQL sağlık kontrolü +
// Express server + Realtime sync başlatma + Firebase oturum doğrulama & AI Vision
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
const aiVisionRouter = require('./routes/ai-vision');
const authRouter = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ─────────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('dev'));

// ── Rotalar ────────────────────────────────────────────────────
app.use('/api', authRouter);
app.use('/api', backupRouter);
app.use('/api', aiVisionRouter);

// ── Kök endpoint ───────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    service: '📋 MatPusula — Backend & AI Vision Sync Engine',
    version: '1.2.0',
    endpoints: {
      health:       'GET  /api/health',
      verifySession: 'POST /api/auth/verify-session (Firebase ID Token gerekli)',
      me:            'GET  /api/auth/me          (Firebase ID Token gerekli)',
      aiVision:     'POST /api/ai/analyze-exam-photo',
      syncStats:    'GET  /api/sync/stats       (API Key gerekli)',
      fullSync:     'POST /api/sync/full        (API Key gerekli)',
      students:     'GET  /api/data/students    (API Key gerekli)',
      examResults:  'GET  /api/data/exam-results?studentId=XXX (API Key gerekli)',
      syncLog:      'GET  /api/data/sync-log    (API Key gerekli)',
    },
  });
});

// ── Firebase Admin SDK İlklendirme ─────────────────────────────
let firebaseInitialized = false;

function initFirebase() {
  if (admin.apps.length > 0) {
    firebaseInitialized = true;
    return;
  }

  try {
    // 1. Ortam değişkenlerinden yapılandırma (Production & Cloud Platformlar)
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
      const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey,
        }),
      });
      firebaseInitialized = true;
      console.log('✅ Firebase Admin SDK (Ortam Değişkenleri ile) başarıyla bağlandı.');
      return;
    }

    // 2. Dosya üzerinden yapılandırma (serviceAccountKey.json)
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
      ? path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
      : path.join(__dirname, '..', 'serviceAccountKey.json');

    const fs = require('fs');
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      firebaseInitialized = true;
      console.log('✅ Firebase Admin SDK (serviceAccountKey.json ile) başarıyla bağlandı.');
      return;
    }

    // 3. Test ve Emülatör / ADC ortamı
    if (process.env.NODE_ENV === 'test') {
      console.log('ℹ️ Test modunda Firebase Admin pasif başlatıldı.');
    } else {
      console.warn('⚠️ serviceAccountKey.json veya FIREBASE_* ortam değişkenleri bulunamadı. Firebase Auth / Sync pasif modda.');
    }
  } catch (err) {
    console.error('❌ Firebase Admin başlatma hatası:', err.message);
  }
}

// ── Sunucuyu Başlat ───────────────────────────────────────────
async function startServer() {
  initFirebase();

  if (firebaseInitialized) {
    try {
      const db = admin.firestore();
      await fullSync(db);
      startRealtimeSync(db);
    } catch (err) {
      console.error('❌ İlk sync hatası:', err.message);
    }
  }

  if (process.env.NODE_ENV !== 'test') {
    app.listen(PORT, () => {
      console.log(`🚀 Backend & AI Vision Servisi çalışıyor: http://localhost:${PORT}`);
    });
  }
}

startServer();

module.exports = app;
