// ═══════════════════════════════════════════════════════════════
// src/middleware/authMiddleware.js — Firebase ID Token Doğrulama
// ═══════════════════════════════════════════════════════════════
'use strict';

const admin = require('firebase-admin');

/**
 * Firebase ID Token ve App Check doğrulama ara yazılımı.
 * İstemciden gelen Authorization: Bearer <ID_TOKEN> başlığını Firebase Admin SDK ile doğrular.
 */
async function requireFirebaseAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Yetkilendirme başlığı (Authorization: Bearer ID_TOKEN) eksik veya geçersiz.',
    });
  }

  const idToken = match[1];

  try {
    // Firebase Admin SDK ile ID Token'ı kriptografik olarak doğrula
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;

    // App Check Token varsa doğrula (Opsiyonel / İleri Seviye)
    const appCheckToken = req.headers['x-firebase-appcheck'];
    if (appCheckToken && admin.appCheck) {
      try {
        const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
        req.appCheck = appCheckClaims;
      } catch (_) {
        // App Check fail olsa bile audit modunda devam edebilir
      }
    }

    next();
  } catch (err) {
    return res.status(401).json({
      error: 'INVALID_TOKEN',
      message: 'Firebase ID Token geçersiz veya süresi dolmuş.',
    });
  }
}

module.exports = {
  requireFirebaseAuth,
};
