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

describe('Node.js Sync Backend REST API & AI Vision Tests', () => {
  let app;
  const API_KEY = 'odev_takip_secret_key_2026';

  beforeAll(() => {
    process.env.API_SECRET_KEY = API_KEY;
    process.env.ALLOW_TEST_OTP = 'true';
    delete process.env.GEMINI_API_KEY;
    app = express();
    app.use(express.json());
    app.use('/api', require('../src/routes/backup'));
    app.use('/api', require('../src/routes/sms'));
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

  test('POST /api/sms/send-otp — Doğru telefon numarası ile OTP oluşturmalı', async () => {
    const res = await request(app)
      .post('/api/sms/send-otp')
      .send({ phone: '+905551234567' });
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toEqual(true);
  });

  test('POST /api/sms/verify-otp — Test kodu 123456 ile başarılı doğrulamalı', async () => {
    await request(app).post('/api/sms/send-otp').send({ phone: '+905551234567' });
    const res = await request(app)
      .post('/api/sms/verify-otp')
      .send({ phone: '+905551234567', code: '123456' });
    expect(res.statusCode).toEqual(200);
    expect(res.body.valid).toEqual(true);
  });

  test('POST /api/ai/analyze-exam-photo — API anahtarı yoksa sahte net dönmemeli', async () => {
    const res = await request(app)
      .post('/api/ai/analyze-exam-photo')
      .send({
        imageBase64: 'data:image/jpeg;base64,sample_base64_string',
        subject: 'Matematik',
      });
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toEqual(false);
    expect(res.body.error).toBeTruthy();
  });
});
