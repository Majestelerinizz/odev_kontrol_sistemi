// ═══════════════════════════════════════════════════════════════
// db/health-check.js — Bağımsız sağlık kontrol scripti
// Komut: npm run db:health
// ═══════════════════════════════════════════════════════════════
'use strict';

require('dotenv').config();
const { healthCheck } = require('./pool');

(async () => {
  console.log('\n🔍 PostgreSQL bağlantıları test ediliyor...\n');
  const status = await healthCheck();
  
  console.log('\n📊 Sonuç:');
  console.log(`   Docker (Yerel) : ${status.local ? '✅ Aktif' : '❌ Bağlanamadı'}`);
  console.log(`   Neon   (Bulut) : ${status.neon  ? '✅ Aktif' : '⚠️  Yapılandırılmamış/Erişilemez'}`);
  
  process.exit(status.local ? 0 : 1);
})();
