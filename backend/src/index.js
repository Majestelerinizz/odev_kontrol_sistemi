// ═══════════════════════════════════════════════════════════════
// src/index.js — Ana Uygulama Giriş Noktası
// Firebase Admin başlatma + PostgreSQL sağlık kontrolü +
// Express server + Realtime sync başlatma + Twilio & AI Vision
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
const smsRouter = require('./routes/sms');
const aiVisionRouter = require('./routes/ai-vision');
const webDashboardRouter = require('./routes/web-dashboard-api');

const app = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ─────────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('dev'));

// ── Rotalar ────────────────────────────────────────────────────
app.use('/api', backupRouter);
app.use('/api', smsRouter);
app.use('/api', aiVisionRouter);
app.use('/api', webDashboardRouter);

// ── Kök endpoint ───────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    service: '📋 MatPusula — Backend & AI Vision Sync Engine',
    version: '1.2.0',
    endpoints: {
      health:       'GET  /api/health',
      sendOtp:      'POST /api/sms/send-otp',
      verifyOtp:    'POST /api/sms/verify-otp',
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
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
    || path.join(__dirname, '..', 'serviceAccountKey.json');

  try {
    const fs = require('fs');
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      firebaseInitialized = true;
      console.log('✅ Firebase Admin SDK başarıyla bağlandı.');
    } else {
      console.warn('⚠️  serviceAccountKey.json bulunamadı. Firebase Sync pasif modda.');
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
      await fullSync();
      startRealtimeSync();
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
