// ═══════════════════════════════════════════════════════════════
// src/routes/ai-vision.js — Gemini AI Vision Sınav & Ödev Analiz Rotaları
// ═══════════════════════════════════════════════════════════════
'use strict';

const express = require('express');
const router = express.Router();
const { analyzeExamPhoto } = require('../services/ai-vision-service');

/**
 * POST /api/ai/analyze-exam-photo
 * Body: { imageBase64: "data:image/jpeg;base64,...", subject: "Matematik" }
 */
router.post('/ai/analyze-exam-photo', async (req, res) => {
  const { imageBase64, subject } = req.body;
  if (!imageBase64 || typeof imageBase64 !== 'string') {
    return res.status(400).json({ error: 'Analiz edilecek fotoğraf verisi (imageBase64) zorunludur.' });
  }

  try {
    const result = await analyzeExamPhoto(imageBase64, subject);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
