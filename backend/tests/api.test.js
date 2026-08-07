'use strict';

const request = require('supertest');
const express = require('express');

// Mock pool ve sync modülleri
jest.mock('../src/db/pool', () => ({
  healthCheck: jest.fn().mockResolvedValue({ local: true, neon: false }),
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

describe('Node.js Sync Backend REST API Tests', () => {
  let app;
  const API_KEY = 'odev_takip_secret_key_2026';

  beforeAll(() => {
    process.env.API_SECRET_KEY = API_KEY;
    app = express();
    app.use(express.json());
    app.use('/api', require('../src/routes/backup'));
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

  test('GET /api/sync/stats — Yanlış API Key ile 401 dönmeli', async () => {
    const res = await request(app)
      .get('/api/sync/stats')
      .set('x-api-key', 'YANLIS_KEY');
    expect(res.statusCode).toEqual(401);
  });

  test('GET /api/sync/stats — Doğru API Key ile istatistik dönmeli', async () => {
    const res = await request(app)
      .get('/api/sync/stats')
      .set('x-api-key', API_KEY);
    expect(res.statusCode).toEqual(200);
    expect(res.body.totalSynced).toEqual(100);
  });

  test('GET /api/data/students — Doğru API Key ile öğrenci listesi dönmeli', async () => {
    const res = await request(app)
      .get('/api/data/students?teacherId=t-1')
      .set('x-api-key', API_KEY);
    expect(res.statusCode).toEqual(200);
    expect(res.body.source).toEqual('postgresql');
    expect(res.body.count).toEqual(1);
    expect(res.body.data[0].name).toEqual('Ahmet Yılmaz');
  });

  test('GET /api/data/exam-results — studentId parametresi yoksa 400 dönmeli', async () => {
    const res = await request(app)
      .get('/api/data/exam-results')
      .set('x-api-key', API_KEY);
    expect(res.statusCode).toEqual(400);
    expect(res.body.error).toContain('studentId gerekli');
  });

  test('GET /api/data/exam-results — Geçerli studentId ile sınav sonuçlarını dönmeli', async () => {
    const res = await request(app)
      .get('/api/data/exam-results?studentId=student-1')
      .set('x-api-key', API_KEY);
    expect(res.statusCode).toEqual(200);
    expect(res.body.data[0].total_net).toEqual(45.0);
  });
});
