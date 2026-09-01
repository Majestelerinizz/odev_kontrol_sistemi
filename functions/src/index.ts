import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

type Audience =
  | "all_teachers"
  | "all_parents"
  | "all_users"
  | "parents_of_teacher"
  | "teacher_and_parents_of_teacher";

interface BroadcastRequest {
  title?: string;
  body?: string;
  audience?: Audience;
  teacherId?: string;
}

async function assertAdmin(uid: string): Promise<void> {
  const doc = await db.collection("users").doc(uid).get();
  const data = doc.data();
  if (!doc.exists || data?.role !== "admin") {
    throw new HttpsError("permission-denied", "Yalnızca admin bu işlemi yapabilir.");
  }
  if (data?.isActive === false) {
    throw new HttpsError("permission-denied", "Hesabınız pasif durumda.");
  }
}

async function parentIdsForTeacher(teacherId: string): Promise<Set<string>> {
  const snap = await db
    .collection("students")
    .where("teacherId", "==", teacherId)
    .get();
  const parentIds = new Set<string>();
  snap.docs.forEach((doc) => {
    const ids = (doc.data().parentIds as string[] | undefined) ?? [];
    ids.forEach((id) => parentIds.add(id));
  });
  return parentIds;
}

async function resolveTargetUids(
  audience: Audience,
  teacherId?: string,
): Promise<Set<string>> {
  const uids = new Set<string>();

  if (audience === "all_teachers" || audience === "all_users") {
    const snap = await db
      .collection("users")
      .where("role", "==", "teacher")
      .get();
    snap.docs.forEach((doc) => uids.add(doc.id));
  }

  if (audience === "all_parents" || audience === "all_users") {
    const snap = await db
      .collection("users")
      .where("role", "==", "parent")
      .get();
    snap.docs.forEach((doc) => uids.add(doc.id));
  }

  if (
    audience === "parents_of_teacher" ||
    audience === "teacher_and_parents_of_teacher"
  ) {
    if (!teacherId) {
      throw new HttpsError(
        "invalid-argument",
        "Bu hedef kitle için teacherId zorunludur.",
      );
    }
    const parents = await parentIdsForTeacher(teacherId);
    parents.forEach((id) => uids.add(id));
    if (audience === "teacher_and_parents_of_teacher") {
      uids.add(teacherId);
    }
  }

  return uids;
}

async function collectTokens(uids: Set<string>): Promise<string[]> {
  const tokens: string[] = [];
  const uidList = Array.from(uids);

  for (let i = 0; i < uidList.length; i += 10) {
    const chunk = uidList.slice(i, i + 10);
    const reads = await Promise.all(
      chunk.map((uid) => db.collection("users").doc(uid).get()),
    );
    reads.forEach((doc) => {
      if (!doc.exists) return;
      const data = doc.data() ?? {};
      const fcmTokens = (data.fcmTokens as string[] | undefined) ?? [];
      fcmTokens.forEach((token) => {
        if (token && token.length > 0) tokens.push(token);
      });
    });
  }

  return Array.from(new Set(tokens));
}

export const sendBroadcast = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Oturum açmanız gerekir.");
  }

  await assertAdmin(request.auth.uid);

  const data = (request.data ?? {}) as BroadcastRequest;
  const title = (data.title ?? "").trim();
  const body = (data.body ?? "").trim();
  const audience = data.audience;
  const teacherId = data.teacherId;

  if (!title || !body) {
    throw new HttpsError("invalid-argument", "Başlık ve mesaj zorunludur.");
  }
  if (!audience) {
    throw new HttpsError("invalid-argument", "Hedef kitle zorunludur.");
  }

  const targetUids = await resolveTargetUids(audience, teacherId);
  const tokens = await collectTokens(targetUids);

  let sentCount = 0;
  const batchSize = 500;

  for (let i = 0; i < tokens.length; i += batchSize) {
    const chunk = tokens.slice(i, i + batchSize);
    if (chunk.length === 0) continue;

    const response = await messaging.sendEachForMulticast({
      tokens: chunk,
      notification: {title, body},
      data: {
        type: "system",
        audience,
      },
    });
    sentCount += response.successCount;
  }

  const now = FieldValue.serverTimestamp();

  const auditRef = db.collection("admin_broadcasts").doc();
  await auditRef.set({
    adminId: request.auth.uid,
    title,
    body,
    audience,
    teacherId: teacherId ?? null,
    targetUserCount: targetUids.size,
    sentCount,
    tokenCount: tokens.length,
    createdAt: now,
  });

  const uidList = Array.from(targetUids);
  const chunkSize = 400;
  for (let i = 0; i < uidList.length; i += chunkSize) {
    const chunk = uidList.slice(i, i + chunkSize);
    const batch = db.batch();
    chunk.forEach((uid) => {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: uid,
        title,
        body,
        type: "system",
        isRead: false,
        createdAt: now,
        source: "admin_broadcast",
      });
    });
    await batch.commit();
  }

  return {
    success: true,
    targetUserCount: targetUids.size,
    tokenCount: tokens.length,
    sentCount,
    broadcastId: auditRef.id,
  };
});

interface TeacherPreviewRequest {
  email?: string;
}

export const getTeacherAuthPreview = onCall(async (request) => {
  const email = ((request.data ?? {}) as TeacherPreviewRequest).email
    ?.trim()
    .toLowerCase();

  if (!email || !email.includes("@")) {
    throw new HttpsError("invalid-argument", "Geçerli bir e-posta gerekir.");
  }

  const snap = await db
    .collection("users")
    .where("email", "==", email)
    .limit(1)
    .get();

  if (snap.empty) {
    return {exists: false, name: null, role: null};
  }

  const data = snap.docs[0].data();
  return {
    exists: true,
    name: (data.name as string | undefined) ?? null,
    role: (data.role as string | undefined) ?? null,
  };
});
