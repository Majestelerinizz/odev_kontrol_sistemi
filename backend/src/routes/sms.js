// ═══════════════════════════════════════════════════════════════
// src/routes/sms.js — Twilio SMS OTP Rotaları
// ═══════════════════════════════════════════════════════════════
'use strict';

const express = require('express');
const router = express.Router();
const { sendOtp, verifyOtp } = require('../services/twilio-service');

/**
 * POST /api/sms/send-otp
 * Body: { phone: "+905551234567" }
 */
router.post('/sms/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone || typeof phone !== 'string' || phone.trim().length < 8) {
    return res.status(400).json({ error: 'Geçerli bir telefon numarası girilmelidir.' });
  }

  try {
    const result = await sendOtp(phone);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/sms/verify-otp
 * Body: { phone: "+905551234567", code: "123456" }
 */
router.post('/sms/verify-otp', (req, res) => {
  const { phone, code } = req.body;
  if (!phone || !code) {
    return res.status(400).json({ error: 'Telefon numarası ve doğrulama kodu zorunludur.' });
  }

  const result = verifyOtp(phone, code);
  if (result.valid) {
    res.json(result);
  } else {
    res.status(400).json(result);
  }
});

module.exports = router;
