const functions = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

const db = admin.firestore();

const VALID_COMPLETION_STATUS = new Set([
  'completed',
  'abandoned',
  'auto_dismissed',
]);

const VALID_MINDSET_AFTER = new Set([
  'peak_focus',
  'calm_in_control',
  'neutral',
  'distracted',
  'scattered',
]);

async function findRun({ userId, sessionId, runId }) {
  if (runId) {
    const runRef = db.collection('mindcoach_session_runs').doc(runId);
    const runSnap = await runRef.get();
    if (!runSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Run not found');
    }
    const data = runSnap.data() || {};
    if (data.user_id !== userId || data.session_id !== sessionId) {
      throw new functions.https.HttpsError('permission-denied', 'Run does not belong to user');
    }
    return runRef;
  }

  const query = await db
    .collection('mindcoach_session_runs')
    .where('user_id', '==', userId)
    .where('session_id', '==', sessionId)
    .where('status', '==', 'in_progress')
    .orderBy('started_at', 'desc')
    .limit(1)
    .get();

  if (!query.empty) {
    return query.docs[0].ref;
  }

  const newRunRef = db.collection('mindcoach_session_runs').doc();
  await newRunRef.set({
    run_id: newRunRef.id,
    session_id: sessionId,
    user_id: userId,
    status: 'in_progress',
    ui_mode: 'guided_extended',
    started_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return newRunRef;
}

async function completeMindCoachSessionRunV2(data, context) {
  if (!context.auth) {
    logger.warn('[MCv2:completeRun] unauthenticated request rejected');
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const userId = context.auth.uid;
  const sessionId = String(data.session_id || '').trim();
  const runId = String(data.run_id || '').trim();
  const completionStatus = String(data.completion_status || '').trim();
  const mindsetAfter = data.mindset_after == null ? null : String(data.mindset_after).trim();
  const helpfulnessRating = data.helpfulness_rating == null
    ? null
    : Number(data.helpfulness_rating);
  const saveFavorite = data.save_favorite === true;

  logger.info('[MCv2:completeRun] ENTRY', {
    userId,
    sessionId,
    runId: runId || null,
    completionStatus,
    mindsetAfter,
    helpfulnessRating,
    saveFavorite,
  });

  if (!sessionId) {
    throw new functions.https.HttpsError('invalid-argument', 'session_id is required');
  }
  if (!VALID_COMPLETION_STATUS.has(completionStatus)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid completion_status');
  }
  if (mindsetAfter && !VALID_MINDSET_AFTER.has(mindsetAfter)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid mindset_after');
  }
  if (
    helpfulnessRating != null &&
    (!Number.isFinite(helpfulnessRating) || helpfulnessRating < 1 || helpfulnessRating > 5)
  ) {
    throw new functions.https.HttpsError('invalid-argument', 'helpfulness_rating must be between 1 and 5');
  }

  const sessionRef = db.collection('mindcoach_sessions').doc(sessionId);
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Session not found');
  }
  const sessionData = sessionSnap.data() || {};
  const ownerId = sessionData.user_id || sessionData.userId;
  if (ownerId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Session does not belong to user');
  }

  const runRef = await findRun({ userId, sessionId, runId: runId || null });
  logger.info('[MCv2:completeRun] run resolved', { resolvedRunId: runRef.id });

  await runRef.set(
    {
      status: completionStatus,
      completed_at: admin.firestore.FieldValue.serverTimestamp(),
      mindset_after: mindsetAfter || null,
      helpfulness_rating: helpfulnessRating == null ? null : helpfulnessRating,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  let favoriteSaved = false;
  if (saveFavorite) {
    const favoriteRef = db
      .collection('mindcoach_favorites')
      .doc(`${userId}_${sessionId}`);

    await favoriteRef.set(
      {
        favorite_id: favoriteRef.id,
        user_id: userId,
        session_id: sessionId,
        template_id: sessionData.template_id || sessionData.templateId || null,
        routine_type: sessionData.routine_type || sessionData.routineType || null,
        coaching_text: sessionData.coaching_text || sessionData.coachingText || null,
        saved_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    favoriteSaved = true;
    logger.info('[MCv2:completeRun] favorite saved', { favoriteId: favoriteRef.id });
  }

  logger.info('[MCv2:completeRun] RESPONSE', {
    runId: runRef.id,
    favoriteSaved,
    completionStatus,
  });

  return {
    run_id: runRef.id,
    favorite_saved: favoriteSaved,
  };
}

module.exports = {
  completeMindCoachSessionRunV2:
    functions.https.onCall(completeMindCoachSessionRunV2),
};
