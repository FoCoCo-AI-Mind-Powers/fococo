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

function stableHash(value) {
  const raw = String(value || '');
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return hash;
}

function buildReflection(sessionData, sessionId) {
  const pillar = String(sessionData.pillar || 'focus').toLowerCase();
  const contextMode = String(sessionData.context_mode || '').toLowerCase();
  if (contextMode === 'during_round') {
    return null;
  }

  const significanceGate = stableHash(`${sessionId}|${pillar}|${contextMode}`) % 100;
  if (significanceGate > 69) {
    return null;
  }

  const pools = {
    focus: [
      'Clarity held when the round narrowed to one thing at a time.',
      'The routine drew your attention back to what mattered most in the moment.',
      'You gave the round less noise and more clear intention.',
    ],
    confidence: [
      'Trust looked steadier once the decision mattered more than the result.',
      'The session kept belief attached to your choice, not the outcome.',
      'Confidence showed up in the way you stayed with the decision.',
    ],
    control: [
      'Composure grew the moment you stopped asking the round to feel perfect.',
      'Control looked quieter and steadier than pressure first suggested.',
      'The reset mattered because you let the round settle before judging it.',
    ],
  };

  const options = pools[pillar] || pools.focus;
  return options[stableHash(`${sessionId}|reflection`) % options.length];
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

  logger.info('[MCv2:completeRun] ENTRY', {
    userId,
    sessionId,
    runId: runId || null,
    completionStatus,
    mindsetAfter,
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

  const reflection =
    completionStatus === 'completed' ? buildReflection(sessionData, sessionId) : null;

  const runRef = await findRun({ userId, sessionId, runId: runId || null });
  logger.info('[MCv2:completeRun] run resolved', { resolvedRunId: runRef.id });

  await runRef.set(
    {
      status: completionStatus,
      completed_at: admin.firestore.FieldValue.serverTimestamp(),
      mindset_after: mindsetAfter || null,
      reflection_text: reflection,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  logger.info('[MCv2:completeRun] RESPONSE', {
    runId: runRef.id,
    completionStatus,
    hasReflection: !!reflection,
  });

  return {
    run_id: runRef.id,
    reflection,
  };
}

module.exports = {
  completeMindCoachSessionRunV2:
    functions.https.onCall(completeMindCoachSessionRunV2),
};
