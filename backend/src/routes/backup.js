// ═══════════════════════════════════════════════════════════════
// routes/backup.js — REST API Endpoint'leri
// Flutter veya herhangi bir istemciden erişilebilir
// ═══════════════════════════════════════════════════════════════
'use strict';

const express = require('express');
const router = express.Router();
const { getSyncStats, fullSync } = require('../sync/firebase-to-pg');
const { queryAll, healthCheck } = require('../db/pool');

// ── Basit API Key Doğrulaması ──────────────────────────────────
function verifyApiKey(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== process.env.API_SECRET_KEY) {
    return res.status(401).json({ error: 'Yetkisiz erişim. Geçerli API anahtarı gerekli.' });
  }
  next();
}

// ── GET /api/health — Sağlık Kontrolü ─────────────────────────
router.get('/health', async (req, res) => {
  const dbStatus = await healthCheck();
  const syncStats = getSyncStats();
  
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    database: dbStatus,
    sync: {
      activeListeners: syncStats.activeListeners,
      totalSynced: syncStats.totalSynced,
      errors: syncStats.errors,
      lastSyncAt: syncStats.lastSyncAt,
      startedAt: syncStats.startedAt,
    },
  });
});

// ── GET /api/sync/stats — Sync İstatistikleri ─────────────────
router.get('/sync/stats', verifyApiKey, (req, res) => {
  res.json(getSyncStats());
});

// ── POST /api/sync/full — Manuel Tam Sync ─────────────────────
router.post('/sync/full', verifyApiKey, async (req, res) => {
  try {
    // Firebase Admin app referansı global'den al
    const db = require('firebase-admin').firestore();
    res.json({ message: 'Tam sync başlatıldı, arka planda çalışıyor...' });
    await fullSync(db); // Async, response gönderdikten sonra çalışır
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/data/students — PostgreSQL'den Öğrenci Listesi ───
router.get('/data/students', verifyApiKey, async (req, res) => {
  try {
    const { teacherId, classId } = req.query;
    let sql = 'SELECT * FROM students WHERE 1=1';
    const params = [];

    if (teacherId) {
      params.push(teacherId);
      sql += ` AND teacher_id = $${params.length}`;
    }
    if (classId) {
      params.push(classId);
      sql += ` AND class_id = $${params.length}`;
    }
    sql += ' ORDER BY name ASC';

    const results = await queryAll(sql, params);
    const successResult = results.find((r) => r.status === 'fulfilled');
    
    if (!successResult) {
      return res.status(503).json({ error: 'Veritabanına erişilemiyor' });
    }
    
    res.json({
      source: 'postgresql',
      count: successResult.value.rows.length,
      data: successResult.value.rows,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/data/exam-results — Sınav Sonuçları ──────────────
router.get('/data/exam-results', verifyApiKey, async (req, res) => {
  try {
    const { studentId } = req.query;
    if (!studentId) {
      return res.status(400).json({ error: 'studentId gerekli' });
    }

    const results = await queryAll(
      'SELECT * FROM exam_results WHERE student_id = $1 ORDER BY exam_date DESC',
      [studentId]
    );
    const successResult = results.find((r) => r.status === 'fulfilled');
    
    res.json({
      source: 'postgresql',
      data: successResult?.value?.rows || [],
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/data/sync-log — Son Sync Logları ─────────────────
router.get('/data/sync-log', verifyApiKey, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const results = await queryAll(
      'SELECT * FROM sync_log ORDER BY synced_at DESC LIMIT $1',
      [limit]
    );
    const successResult = results.find((r) => r.status === 'fulfilled');
    
    res.json({
      data: successResult?.value?.rows || [],
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
