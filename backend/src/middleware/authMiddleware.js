// ═══════════════════════════════════════════════════════════════
// src/middleware/authMiddleware.js — Firebase ID Token & App Check Doğrulama
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
    if (admin.apps.length === 0) {
      console.warn('⚠️ Firebase Admin başlatılmamış. Test ortamı dışında token doğrulanamaz.');
      if (process.env.NODE_ENV === 'test') {
        req.user = { uid: 'test-user-uid', phone_number: '+905315635049', role: 'parent' };
        return next();
      }
      return res.status(503).json({
        error: 'AUTH_SERVICE_UNAVAILABLE',
        message: 'Kimlik doğrulama servisi şu anda kullanılamıyor.',
      });
    }

    // Firebase Admin SDK ile ID Token'ı kriptografik olarak doğrula
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;

    // ── App Check Token Doğrulaması (Environment-based Audit / Enforce Modu) ──
    const appCheckMode = (process.env.APP_CHECK_MODE || 'audit').toLowerCase();
    const appCheckToken = req.headers['x-firebase-appcheck'];

    if (admin.appCheck) {
      if (appCheckToken) {
        try {
          const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
          req.appCheck = appCheckClaims;
        } catch (appCheckErr) {
          if (appCheckMode === 'enforce') {
            return res.status(401).json({
              error: 'APP_CHECK_FAILED',
              message: 'Uygulama bütünlük doğrulaması (App Check) başarısız oldu.',
            });
          }
          console.warn('⚠️ App Check doğrulama uyarısı (Audit modu):', appCheckErr.message);
        }
      } else if (appCheckMode === 'enforce' && process.env.NODE_ENV === 'production') {
        return res.status(401).json({
          error: 'MISSING_APP_CHECK_TOKEN',
          message: 'Güvenlik doğrulaması (App Check) başlığı eksik.',
        });
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
