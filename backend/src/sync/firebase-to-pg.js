// ═══════════════════════════════════════════════════════════════
// sync/firebase-to-pg.js
// Firebase Firestore'u gerçek zamanlı dinleyip PostgreSQL'e yazan
// tek yönlü sync motoru. Her koleksiyon için onSnapshot listener.
// ═══════════════════════════════════════════════════════════════
'use strict';

const { queryAll } = require('../db/pool');

// Aktif listener'ları sakla (unsubscribe için)
const listeners = new Map();
let syncStats = {
  totalSynced: 0,
  errors: 0,
  startedAt: null,
  lastSyncAt: null,
  byCollection: {},
};

// ── Sync log kaydı ─────────────────────────────────────────────
async function logSync(collection, docId, operation, status, errorMessage = null) {
  try {
    await queryAll(
      `INSERT INTO sync_log (collection, doc_id, operation, status, error_message)
       VALUES ($1, $2, $3, $4, $5)`,
      [collection, docId, operation, status, errorMessage]
    );
  } catch (_) {
    // Log hatası ana akışı engellemez
  }
}

// ── UPSERT Yardımcıları ────────────────────────────────────────

async function upsertUser(data) {
  const sql = `
    INSERT INTO users (uid, email, full_name, role, phone_number, created_at, synced_at)
    VALUES ($1, $2, $3, $4, $5, $6, NOW())
    ON CONFLICT (uid) DO UPDATE SET
      email        = EXCLUDED.email,
      full_name    = EXCLUDED.full_name,
      role         = EXCLUDED.role,
      phone_number = EXCLUDED.phone_number,
      updated_at   = NOW(),
      synced_at    = NOW()`;
  return queryAll(sql, [
    data.uid, data.email, data.fullName, data.role,
    data.phoneNumber || null,
    data.createdAt?.toDate?.() || new Date(),
  ]);
}

async function upsertClass(id, data) {
  const sql = `
    INSERT INTO classes (id, teacher_id, name, grade_level, student_count, created_at, synced_at)
    VALUES ($1, $2, $3, $4, $5, $6, NOW())
    ON CONFLICT (id) DO UPDATE SET
      name          = EXCLUDED.name,
      grade_level   = EXCLUDED.grade_level,
      student_count = EXCLUDED.student_count,
      updated_at    = NOW(),
      synced_at     = NOW()`;
  return queryAll(sql, [
    id, data.teacherId, data.name, data.gradeLevel || null,
    data.studentCount || 0,
    data.createdAt?.toDate?.() || new Date(),
  ]);
}

async function upsertStudent(id, data) {
  const sql = `
    INSERT INTO students (id, class_id, teacher_id, name, school_number, parent_ids, target_score, teacher_note, created_at, synced_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
    ON CONFLICT (id) DO UPDATE SET
      class_id     = EXCLUDED.class_id,
      name         = EXCLUDED.name,
      school_number= EXCLUDED.school_number,
      parent_ids   = EXCLUDED.parent_ids,
      target_score = EXCLUDED.target_score,
      teacher_note = EXCLUDED.teacher_note,
      updated_at   = NOW(),
      synced_at    = NOW()`;
  return queryAll(sql, [
    id, data.classId || null, data.teacherId, data.name,
    data.schoolNumber || null,
    data.parentIds || [],
    data.targetScore || null,
    data.teacherNote || null,
    data.createdAt?.toDate?.() || new Date(),
  ]);
}

async function upsertInviteCode(code, data) {
  const sql = `
    INSERT INTO invite_codes (code, student_id, teacher_id, expires_at, is_used, synced_at)
    VALUES ($1, $2, $3, $4, $5, NOW())
    ON CONFLICT (code) DO UPDATE SET
      is_used   = EXCLUDED.is_used,
      synced_at = NOW()`;
  return queryAll(sql, [
    code, data.studentId || null, data.teacherId || null,
    data.expiresAt?.toDate?.() || null,
    data.isUsed || false,
  ]);
}

async function upsertHomework(id, data) {
  const sql = `
    INSERT INTO homeworks (id, teacher_id, class_id, title, subject, description, source_name, question_range, due_date, attachment_urls, assigned_to_all, created_at, synced_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NOW())
    ON CONFLICT (id) DO UPDATE SET
      title           = EXCLUDED.title,
      subject         = EXCLUDED.subject,
      description     = EXCLUDED.description,
      source_name     = EXCLUDED.source_name,
      question_range  = EXCLUDED.question_range,
      due_date        = EXCLUDED.due_date,
      attachment_urls = EXCLUDED.attachment_urls,
      assigned_to_all = EXCLUDED.assigned_to_all,
      updated_at      = NOW(),
      synced_at       = NOW()`;
  return queryAll(sql, [
    id, data.teacherId, data.classId || null, data.title, data.subject,
    data.description || null, data.sourceName || null, data.questionRange || null,
    data.dueDate?.toDate?.() || null,
    data.attachmentUrls || [],
    data.assignedToAll !== false,
    data.createdAt?.toDate?.() || new Date(),
  ]);
}

async function upsertHomeworkAssignment(id, data) {
  const sql = `
    INSERT INTO homework_assignments (id, homework_id, student_id, class_id, teacher_id, status, teacher_note, completed_at, updated_at, synced_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NOW())
    ON CONFLICT (id) DO UPDATE SET
      status       = EXCLUDED.status,
      teacher_note = EXCLUDED.teacher_note,
      completed_at = EXCLUDED.completed_at,
      updated_at   = NOW(),
      synced_at    = NOW()`;
  return queryAll(sql, [
    id, data.homeworkId, data.studentId, data.classId || null,
    data.teacherId, data.status || 'pending',
    data.teacherNote || null,
    data.completedAt?.toDate?.() || null,
    data.updatedAt?.toDate?.() || new Date(),
  ]);
}

async function upsertExamResult(id, data) {
  const sql = `
    INSERT INTO exam_results (id, student_id, class_id, teacher_id, exam_name, publisher, scores, total_net, total_score, exam_date, synced_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW())
    ON CONFLICT (id) DO UPDATE SET
      exam_name   = EXCLUDED.exam_name,
      publisher   = EXCLUDED.publisher,
      scores      = EXCLUDED.scores,
      total_net   = EXCLUDED.total_net,
      total_score = EXCLUDED.total_score,
      synced_at   = NOW()`;
  return queryAll(sql, [
    id, data.studentId, data.classId || null, data.teacherId || '',
    data.examName, data.publisher || null,
    JSON.stringify(data.scores || {}),
    data.totalNet || 0, data.totalScore || 0,
    data.examDate?.toDate?.() || new Date(),
  ]);
}

async function upsertGoal(id, data) {
  const sql = `
    INSERT INTO goals (id, student_id, teacher_id, type, target_value, current_value, is_active, synced_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,NOW())
    ON CONFLICT (id) DO UPDATE SET
      type          = EXCLUDED.type,
      target_value  = EXCLUDED.target_value,
      current_value = EXCLUDED.current_value,
      is_active     = EXCLUDED.is_active,
      updated_at    = NOW(),
      synced_at     = NOW()`;
  return queryAll(sql, [
    id, data.studentId, data.teacherId || null, data.type,
    data.targetValue || 0, data.currentValue || 0,
    data.isActive !== false,
  ]);
}

async function upsertMessage(id, data) {
  const sql = `
    INSERT INTO messages (id, teacher_id, parent_ids, title, body, is_read, created_at, synced_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,NOW())
    ON CONFLICT (id) DO UPDATE SET
      is_read   = EXCLUDED.is_read,
      synced_at = NOW()`;
  return queryAll(sql, [
    id, data.teacherId, data.parentIds || [],
    data.title || null, data.body || '',
    data.isRead || false,
    data.createdAt?.toDate?.() || new Date(),
  ]);
}

// ── Silme işlemi ───────────────────────────────────────────────
async function deleteFromTable(table, idColumn, id) {
  return queryAll(`DELETE FROM ${table} WHERE ${idColumn} = $1`, [id]);
}

// ── Koleksiyon → Handler eşlemesi ─────────────────────────────
const COLLECTION_MAP = {
  users:               { upsert: (id, d) => upsertUser({ uid: id, ...d }),      table: 'users',               idCol: 'uid' },
  classes:             { upsert: upsertClass,                                    table: 'classes',             idCol: 'id'  },
  students:            { upsert: upsertStudent,                                  table: 'students',            idCol: 'id'  },
  invite_codes:        { upsert: upsertInviteCode,                               table: 'invite_codes',        idCol: 'code'},
  homeworks:           { upsert: upsertHomework,                                 table: 'homeworks',           idCol: 'id'  },
  homework_assignments:{ upsert: upsertHomeworkAssignment,                       table: 'homework_assignments',idCol: 'id'  },
  exam_results:        { upsert: upsertExamResult,                               table: 'exam_results',        idCol: 'id'  },
  goals:               { upsert: upsertGoal,                                     table: 'goals',               idCol: 'id'  },
  messages:            { upsert: upsertMessage,                                  table: 'messages',            idCol: 'id'  },
};

// ── Bir koleksiyonu dinle ──────────────────────────────────────
function listenCollection(db, collectionName) {
  const handler = COLLECTION_MAP[collectionName];
  if (!handler) return;

  console.log(`👂 [Sync] "${collectionName}" dinleniyor...`);

  const unsubscribe = db.collection(collectionName).onSnapshot(
    async (snapshot) => {
      for (const change of snapshot.docChanges()) {
        const docId = change.doc.id;
        const data = change.doc.data();

        try {
          if (change.type === 'added' || change.type === 'modified') {
            await handler.upsert(docId, data);
            await logSync(collectionName, docId, change.type === 'added' ? 'insert' : 'update', 'success');
            syncStats.totalSynced++;
          } else if (change.type === 'removed') {
            await deleteFromTable(handler.table, handler.idCol, docId);
            await logSync(collectionName, docId, 'delete', 'success');
          }

          syncStats.lastSyncAt = new Date();
          syncStats.byCollection[collectionName] = (syncStats.byCollection[collectionName] || 0) + 1;

          if (process.env.LOG_LEVEL === 'verbose') {
            console.log(`  ✅ [${collectionName}] ${change.type} → doc: ${docId}`);
          }
        } catch (err) {
          syncStats.errors++;
          console.error(`  ❌ [${collectionName}] Sync hatası (${docId}):`, err.message);
          await logSync(collectionName, docId, 'update', 'error', err.message);
        }
      }
    },
    (err) => {
      console.error(`❌ [${collectionName}] Listener hatası:`, err.message);
    }
  );

  listeners.set(collectionName, unsubscribe);
}

// ── Tüm koleksiyonlar için tam sync (ilk başlatma) ────────────
async function fullSync(db) {
  console.log('\n🔄 Tam sync başlatılıyor — tüm Firebase verileri PostgreSQL\'e aktarılıyor...\n');
  
  for (const [collectionName, handler] of Object.entries(COLLECTION_MAP)) {
    try {
      const snapshot = await db.collection(collectionName).get();
      let count = 0;
      
      for (const doc of snapshot.docs) {
        try {
          await handler.upsert(doc.id, doc.data());
          count++;
        } catch (err) {
          console.error(`  ❌ [${collectionName}] ${doc.id}:`, err.message);
          syncStats.errors++;
        }
      }
      
      console.log(`  ✅ [${collectionName}] ${count} doküman aktarıldı`);
      syncStats.totalSynced += count;
      syncStats.byCollection[collectionName] = count;
    } catch (err) {
      console.error(`  ❌ [${collectionName}] Koleksiyon hatası:`, err.message);
    }
  }
  
  syncStats.lastSyncAt = new Date();
  console.log(`\n✅ Tam sync tamamlandı! Toplam: ${syncStats.totalSynced} doküman\n`);
}

// ── Realtime listener'ları başlat ─────────────────────────────
function startRealtimeSync(db) {
  syncStats.startedAt = new Date();
  console.log('\n🚀 Gerçek zamanlı sync başlatılıyor...\n');
  
  for (const collectionName of Object.keys(COLLECTION_MAP)) {
    listenCollection(db, collectionName);
  }
  
  console.log(`\n✅ ${Object.keys(COLLECTION_MAP).length} koleksiyon dinleniyor. Değişiklikler anında PostgreSQL'e yansıyacak.\n`);
}

// ── Tüm listener'ları durdur ───────────────────────────────────
function stopAllListeners() {
  console.log('⏹  Sync listener\'lar durduruluyor...');
  for (const [name, unsubscribe] of listeners) {
    unsubscribe();
    console.log(`  ✅ [${name}] durduruldu`);
  }
  listeners.clear();
}

// ── Sync istatistikleri ────────────────────────────────────────
function getSyncStats() {
  return {
    ...syncStats,
    activeListeners: listeners.size,
    collectionsMonitored: Object.keys(COLLECTION_MAP),
  };
}

module.exports = { startRealtimeSync, fullSync, stopAllListeners, getSyncStats };
