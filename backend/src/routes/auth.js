// ═══════════════════════════════════════════════════════════════
// src/routes/auth.js — Firebase Oturum Doğrulama & PostgreSQL Senkronizasyonu
//
// ÖNEMLİ MİMARİ KURAL:
// SMS OTP üretimi, gönderimi ve doğrulaması TAMAMEN Firebase Authentication
// (Blaze planı) sorumluluğundadır. Backend asla OTP üretmez, saklamaz veya
// doğrulamaz. Backend'in tek görevi, istemcinin Firebase'den aldığı ID Token'ı
// Admin SDK ile kriptografik olarak doğrulayıp PostgreSQL ile eşitlemektir.
// Bkz. FIREBASE_PHONE_AUTH_ARCHITECTURE.md
// ═══════════════════════════════════════════════════════════════
'use strict';

const express = require('express');
const router = express.Router();
const { requireFirebaseAuth } = require('../middleware/authMiddleware');
const { query } = require('../db/pool');

// ── Oturum Doğrulama & PostgreSQL UPSERT ────────────────────────────────────
router.post('/auth/verify-session', requireFirebaseAuth, async (req, res) => {
  const { uid, phone_number, email } = req.user;
  const { name, role } = req.body || {};

  const userRole = role || (phone_number ? 'parent' : 'teacher');
  const cleanPhone = phone_number || null;
  const cleanEmail = email || null;
  const fullName = name && name.trim().length > 0 ? name.trim() : (cleanPhone ? `Veli (${cleanPhone})` : 'Kullanıcı');

  try {
    const sql = `
      INSERT INTO users (uid, role, full_name, email, phone_number, is_active, created_at, updated_at, synced_at)
      VALUES ($1, $2, $3, $4, $5, true, NOW(), NOW(), NOW())
      ON CONFLICT (uid) DO UPDATE
      SET full_name = COALESCE(NULLIF($3, ''), users.full_name),
          email = COALESCE($4, users.email),
          phone_number = COALESCE($5, users.phone_number),
          role = COALESCE($2, users.role),
          updated_at = NOW(),
          synced_at = NOW()
      RETURNING uid, role, full_name, email, phone_number, is_active;
    `;

    const result = await query(sql, [uid, userRole, fullName, cleanEmail, cleanPhone]);
    const dbUser = result.rows && result.rows.length > 0 ? result.rows[0] : null;

    res.json({
      success: true,
      message: 'Oturum başarıyla doğrulandı ve veritabanı ile eşitlendi.',
      data: {
        user: dbUser || {
          uid,
          role: userRole,
          full_name: fullName,
          email: cleanEmail,
          phone_number: cleanPhone,
          is_active: true,
        },
      },
    });
  } catch (err) {
    console.error('⚠️ PostgreSQL sync uyarısı (/auth/verify-session):', err.message);
    res.json({
      success: true,
      message: 'Oturum Firebase üzerinde doğrulandı.',
      data: {
        user: {
          uid,
          role: userRole,
          full_name: fullName,
          email: cleanEmail,
          phone_number: cleanPhone,
          is_active: true,
        },
      },
    });
  }
});

// ── Mevcut Oturum Kullanıcı Bilgisi Getir ────────────────────────────────────
router.get('/auth/me', requireFirebaseAuth, async (req, res) => {
  const { uid, phone_number, email } = req.user;

  try {
    const result = await query('SELECT uid, role, full_name, email, phone_number, is_active, created_at FROM users WHERE uid = $1', [uid]);
    if (result.rows && result.rows.length > 0) {
      return res.json({
        success: true,
        data: { user: result.rows[0] },
      });
    }

    return res.json({
      success: true,
      data: {
        user: {
          uid,
          role: phone_number ? 'parent' : 'teacher',
          full_name: phone_number ? `Veli (${phone_number})` : 'Kullanıcı',
          email: email || null,
          phone_number: phone_number || null,
          is_active: true,
        },
      },
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      error: 'SERVER_ERROR',
      message: 'Kullanıcı bilgisi alınırken sunucu hatası oluştu.',
    });
  }
});

module.exports = router;
