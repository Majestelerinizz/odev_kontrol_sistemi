// ═══════════════════════════════════════════════════════════════
// src/routes/auth.js — Firebase Kimlik Doğrulama & PostgreSQL Eşitleme
// ═══════════════════════════════════════════════════════════════
'use strict';

const express = require('express');
const router = express.Router();
const { requireFirebaseAuth } = require('../middleware/authMiddleware');
const { query } = require('../db/pool');

/**
 * POST /api/auth/verify-session
 * Firebase ID Token doğrular ve kullanıcının profilini PostgreSQL'e kaydeder.
 */
router.post('/auth/verify-session', requireFirebaseAuth, async (req, res) => {
  const { uid, phone_number, email } = req.user;
  const { name, role } = req.body;

  const userRole = role || (phone_number ? 'parent' : 'teacher');
  const cleanPhone = phone_number || null;
  const cleanEmail = email || null;

  try {
    // PostgreSQL kullanıcılar tablosuna UPSERT et
    const sql = `
      INSERT INTO users (id, role, name, email, phone, is_active, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, true, NOW(), NOW())
      ON CONFLICT (id) DO UPDATE
      SET name = COALESCE($3, users.name),
          email = COALESCE($4, users.email),
          phone = COALESCE($5, users.phone),
          updated_at = NOW()
      RETURNING id, role, name, email, phone, is_active;
    `;

    const result = await query(sql, [uid, userRole, name || 'Kullanıcı', cleanEmail, cleanPhone]);

    res.json({
      success: true,
      message: 'Oturum başarıyla doğrulandı ve veritabanı ile eşitlendi.',
      user: result.rows[0] || { uid, role: userRole, phone: cleanPhone, email: cleanEmail },
    });
  } catch (err) {
    // Veritabanı bağlantısı olmasa bile token doğrulaması geçerli sayılır
    res.json({
      success: true,
      message: 'Oturum Firebase üzerinde doğrulandı.',
      user: { uid, role: userRole, phone: cleanPhone, email: cleanEmail },
    });
  }
});

module.exports = router;
