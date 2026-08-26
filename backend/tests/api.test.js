'use strict';

const request = require('supertest');
const express = require('express');

// Mock pool ve sync modülleri
jest.mock('../src/db/pool', () => ({
  healthCheck: jest.fn().mockResolvedValue({ local: true, neon: false }),
  query: jest.fn().mockImplementation((sql, params) => {
    if (sql.includes('INSERT INTO users') || sql.includes('SELECT uid, role')) {
      return Promise.resolve({
        rows: [
          {
            uid: params[0] || 'test-user-uid',
            role: params[1] || 'parent',
            full_name: params[2] || 'Test Kullanıcı',
            email: params[3] || null,
            phone_number: params[4] || '+905315635049',
            is_active: true,
          },
        ],
      });
    }
    return Promise.resolve({ rows: [] });
  }),
  queryAll: jest.fn().mockImplementation((sql, params) => {
    if (sql.includes('students')) {
      return Promise.resolve([
        {
          status: 'fulfilled',
          value: {
            rows: [
              { id: 'student-1', name: 'Ahmet Yılmaz', class_id: 'class-8A' },
            ],
          },
        },
      ]);
    }
    if (sql.includes('exam_results')) {
      return Promise.resolve([
        {
          status: 'fulfilled',
          value: {
            rows: [
              { id: 'exam-1', student_id: 'student-1', total_net: 45.0 },
            ],
          },
        },
      ]);
    }
    return Promise.resolve([{ status: 'fulfilled', value: { rows: [] } }]);
  }),
}));

jest.mock('../src/sync/firebase-to-pg', () => ({
  getSyncStats: jest.fn().mockReturnValue({
    activeListeners: 9,
    totalSynced: 100,
    errors: 0,
    lastSyncAt: new Date().toISOString(),
    startedAt: new Date().toISOString(),
  }),
  fullSync: jest.fn().mockResolvedValue(true),
}));

describe('Node.js Sync Backend REST API & AI Vision Tests', () => {
  let app;
  const API_KEY = 'odev_takip_secret_key_2026';

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
    process.env.API_SECRET_KEY = API_KEY;
    app = express();
    app.use(express.json());
    app.use('/api', require('../src/routes/auth'));
    app.use('/api', require('../src/routes/backup'));
    app.use('/api', require('../src/routes/ai-vision'));
  });

  test('GET /api/health — Sağlık durumunu döndürmeli', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('ok');
    expect(res.body.database.local).toEqual(true);
    expect(res.body.sync.activeListeners).toEqual(9);
  });

  test('GET /api/sync/stats — API Key yoksa 401 dönmeli', async () => {
    const res = await request(app).get('/api/sync/stats');
    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toContain('Yetkisiz');
  });

  test('POST /api/auth/verify-session — Authorization Bearer başlığı yoksa 401 dönmeli', async () => {
    const res = await request(app)
      .post('/api/auth/verify-session')
      .send({ name: 'Ahmet Veli', role: 'parent' });
    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toEqual('UNAUTHORIZED');
  });

  test('POST /api/auth/verify-session — Geçerli Bearer Token ile PostgreSQL UPSERT yapıp 200 dönmeli', async () => {
    const res = await request(app)
      .post('/api/auth/verify-session')
      .set('Authorization', 'Bearer valid_mock_firebase_id_token')
      .send({ name: 'Ahmet Veli', role: 'parent' });
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toEqual(true);
    expect(res.body.data.user).toBeDefined();
    expect(res.body.data.user.role).toEqual('parent');
  });

  test('GET /api/auth/me — Yetkilendirilmiş kullanıcı profilini getirmeli', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer valid_mock_firebase_id_token');
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toEqual(true);
    expect(res.body.data.user.uid).toBeDefined();
  });
});
