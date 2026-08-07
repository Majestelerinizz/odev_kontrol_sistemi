-- ═══════════════════════════════════════════════════════════════
-- Ödev Takip Sistemi — PostgreSQL Şeması
-- Firebase Firestore koleksiyonlarının birebir karşılığı
-- ═══════════════════════════════════════════════════════════════

-- UUID desteği
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── 1. KULLANICILAR ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    uid             TEXT PRIMARY KEY,          -- Firebase UID
    email           TEXT NOT NULL UNIQUE,
    full_name       TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN ('teacher', 'parent')),
    phone_number    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()  -- Son Firebase sync zamanı
);

-- ── 2. SINIFLAR ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS classes (
    id              TEXT PRIMARY KEY,          -- Firebase doc ID
    teacher_id      TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    grade_level     TEXT,
    student_count   INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. ÖĞRENCİLER ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
    id              TEXT PRIMARY KEY,
    class_id        TEXT REFERENCES classes(id) ON DELETE SET NULL,
    teacher_id      TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    school_number   TEXT,
    parent_ids      TEXT[] DEFAULT '{}',       -- Firebase'deki List<String>
    target_score    NUMERIC(6,2),
    teacher_note    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 4. VELİ DAVET KODLARI ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS invite_codes (
    code            TEXT PRIMARY KEY,          -- OT-XXXXXX formatı
    student_id      TEXT REFERENCES students(id) ON DELETE CASCADE,
    teacher_id      TEXT REFERENCES users(uid) ON DELETE CASCADE,
    expires_at      TIMESTAMPTZ,
    is_used         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 5. ÖDEVLER ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS homeworks (
    id              TEXT PRIMARY KEY,
    teacher_id      TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    class_id        TEXT REFERENCES classes(id) ON DELETE SET NULL,
    title           TEXT NOT NULL,
    subject         TEXT NOT NULL,
    description     TEXT,
    source_name     TEXT,
    question_range  TEXT,
    due_date        TIMESTAMPTZ,
    attachment_urls TEXT[] DEFAULT '{}',
    assigned_to_all BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 6. ÖDEV ATAMALARI ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS homework_assignments (
    id              TEXT PRIMARY KEY,
    homework_id     TEXT NOT NULL REFERENCES homeworks(id) ON DELETE CASCADE,
    student_id      TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_id        TEXT,
    teacher_id      TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'completed', 'missed')),
    teacher_note    TEXT,
    completed_at    TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 7. SINAV SONUÇLARI ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS exam_results (
    id              TEXT PRIMARY KEY,
    student_id      TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_id        TEXT,
    teacher_id      TEXT NOT NULL,
    exam_name       TEXT NOT NULL,
    publisher       TEXT,
    scores          JSONB NOT NULL DEFAULT '{}',  -- { "mat": {"correct":20,"wrong":5,"empty":5} }
    total_net       NUMERIC(6,2) NOT NULL DEFAULT 0,
    total_score     NUMERIC(8,2) NOT NULL DEFAULT 0,
    exam_date       TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 8. HEDEFLER ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS goals (
    id              TEXT PRIMARY KEY,
    student_id      TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    teacher_id      TEXT,
    type            TEXT NOT NULL,             -- 'LGS', 'YKS' vb.
    target_value    NUMERIC(8,2) NOT NULL,
    current_value   NUMERIC(8,2) NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 9. MESAJLAR ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
    id              TEXT PRIMARY KEY,
    teacher_id      TEXT NOT NULL,
    parent_ids      TEXT[] DEFAULT '{}',
    title           TEXT,
    body            TEXT NOT NULL,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 10. SYNC LOG (Takip Tablosu) ──────────────────────────────
CREATE TABLE IF NOT EXISTS sync_log (
    id              BIGSERIAL PRIMARY KEY,
    collection      TEXT NOT NULL,
    doc_id          TEXT NOT NULL,
    operation       TEXT NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
    status          TEXT NOT NULL CHECK (status IN ('success', 'error')),
    error_message   TEXT,
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── İNDEKSLER ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_students_teacher_id     ON students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_students_class_id       ON students(class_id);
CREATE INDEX IF NOT EXISTS idx_homeworks_teacher_id    ON homeworks(teacher_id);
CREATE INDEX IF NOT EXISTS idx_homeworks_class_id      ON homeworks(class_id);
CREATE INDEX IF NOT EXISTS idx_hw_assign_student_id    ON homework_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_hw_assign_homework_id   ON homework_assignments(homework_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_student_id ON exam_results(student_id);
CREATE INDEX IF NOT EXISTS idx_goals_student_id        ON goals(student_id);
CREATE INDEX IF NOT EXISTS idx_sync_log_collection     ON sync_log(collection, synced_at DESC);

-- ── Başarılı kurulum mesajı ────────────────────────────────────
DO $$
BEGIN
  RAISE NOTICE '✅ Ödev Takip Sistemi PostgreSQL şeması başarıyla oluşturuldu!';
END $$;
