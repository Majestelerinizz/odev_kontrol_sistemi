// ═══════════════════════════════════════════════════════════════
// db/pool.js — PostgreSQL Bağlantı Havuzları
// Hem Docker (yerel) hem de Neon (bulut) bağlantısını yönetir
// ═══════════════════════════════════════════════════════════════
'use strict';

require('dotenv').config();
const { Pool } = require('pg');

// ── Yerel Docker PostgreSQL Havuzu ─────────────────────────────
const localPool = new Pool({
  connectionString: process.env.LOCAL_DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  ssl: false,
});

localPool.on('error', (err) => {
  console.error('❌ [Docker PostgreSQL] Beklenmeyen hata:', err.message);
});

// ── Neon Bulut PostgreSQL Havuzu ───────────────────────────────
let neonPool = null;

if (process.env.NEON_DATABASE_URL && 
    !process.env.NEON_DATABASE_URL.includes('KULLANICI')) {
  neonPool = new Pool({
    connectionString: process.env.NEON_DATABASE_URL,
    max: 5,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
    ssl: { rejectUnauthorized: false },
  });

  neonPool.on('error', (err) => {
    console.error('❌ [Neon PostgreSQL] Beklenmeyen hata:', err.message);
  });
}

// ── Aktif hedef havuzları ──────────────────────────────────────
function getActivePools() {
  const target = process.env.DB_TARGET || 'local';
  const pools = [];

  if (target === 'local' || target === 'both') {
    pools.push({ name: 'Docker (Yerel)', pool: localPool });
  }
  if ((target === 'neon' || target === 'both') && neonPool) {
    pools.push({ name: 'Neon (Bulut)', pool: neonPool });
  }

  return pools;
}

// ── Her iki havuza paralel sorgu gönder ───────────────────────
async function queryAll(sql, params = []) {
  const pools = getActivePools();
  const results = await Promise.allSettled(
    pools.map(({ name, pool }) =>
      pool.query(sql, params).then((r) => ({ name, rows: r.rows }))
    )
  );

  results.forEach((result, i) => {
    if (result.status === 'rejected') {
      console.error(`❌ [${pools[i].name}] Sorgu hatası:`, result.reason.message);
    }
  });

  return results;
}

// ── Sağlık kontrolü ───────────────────────────────────────────
async function healthCheck() {
  const status = { local: false, neon: false };
  
  try {
    await localPool.query('SELECT 1');
    status.local = true;
    console.log('✅ [Docker PostgreSQL] Bağlantı başarılı');
  } catch (e) {
    console.error('❌ [Docker PostgreSQL] Bağlantı başarısız:', e.message);
  }

  if (neonPool) {
    try {
      await neonPool.query('SELECT 1');
      status.neon = true;
      console.log('✅ [Neon PostgreSQL] Bağlantı başarılı');
    } catch (e) {
      console.error('❌ [Neon PostgreSQL] Bağlantı başarısız:', e.message);
    }
  } else {
    console.warn('⚠️  [Neon PostgreSQL] NEON_DATABASE_URL yapılandırılmamış, atlanıyor.');
  }

  return status;
}

module.exports = { localPool, neonPool, getActivePools, queryAll, healthCheck };
