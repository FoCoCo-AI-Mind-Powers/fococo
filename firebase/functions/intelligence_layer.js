const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

const {
  GENERATION_VERSION,
  SURFACES,
  buildChatSummary,
  buildContextCacheDocuments,
  buildRoundInsights,
  buildRoundSummary,
  extractRecentJustTalkPhrases,
  summarizeLastMindCoachSession,
  deriveCoachingState,
  deriveThinDataCoachingState,
  deriveThinDataTrainingSummary,
  deriveThinDataUserPatterns,
  deriveTrainingSummary,
  deriveUserPatterns,
  isCompletedChatSession,
  joinCompletedMindCoachSessions,
  normalizeCaddyPlayMoment,
  normalizeGolfRound,
  normalizeMindCoachRun,
  normalizeMindCoachSession,
  normalizeShotLog,
  normalizeVoiceChatMessage,
  normalizeVoiceChatSession,
  sortByDateDesc,
  toDate,
} = require('./intelligence_engine');

const COLLECTIONS = {
  roundSummaries: 'round_summaries',
  roundInsights: 'round_insights',
  userPatterns: 'user_patterns',
  coachingState: 'coaching_state',
  trainingSummary: 'training_summary',
  chatSummary: 'chat_summary',
  contextCache: 'context_cache',
  insightHistory: 'insight_history',
};

const FOCOCO_TAB_SURFACE = 'fococo_tab';
const RECENT_COMPLETED_ROUND_LIMIT = 12;
const RECENT_MINDCOACH_LIMIT = 60;
const RECENT_INSIGHT_HISTORY_LIMIT = 10;
const CONTEXT_CACHE_STALE_HOURS = 12;
const REPAIR_STALE_HOURS = 24;

function getDb() {
  return admin.firestore();
}

function safeString(value, fallback = '') {
  if (value == null) {
    return fallback;
  }
  return String(value).trim();
}

function safeNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function nowIso() {
  return new Date().toISOString();
}

function ensureAuthenticatedRequest(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }
}

function ensureAdminRequest(request) {
  ensureAuthenticatedRequest(request);
  if (!request.auth.token.admin && !request.auth.token.content_admin) {
    throw new HttpsError('permission-denied', 'Admin privileges required');
  }
}

function buildContextCacheDocId(userId, surface) {
  return `${surface}__${userId}`;
}

function buildInsightHistoryDocId(userId, surface, date) {
  if (surface === FOCOCO_TAB_SURFACE) {
    return `fococo_daily_${userId}_${date}`;
  }
  return `${surface}_${userId}_${date}`.replace(/[^a-zA-Z0-9_-]/g, '_');
}

function isCompletedRoundRecord(roundId, data = {}) {
  return normalizeGolfRound(roundId, data).status === 'completed';
}

function isStaleTimestamp(value, staleHours) {
  const date = toDate(value);
  if (!date) {
    return true;
  }
  return Date.now() - date.getTime() > staleHours * 60 * 60 * 1000;
}

function dedupeDocs(docs) {
  const seen = new Map();
  for (const doc of docs) {
    seen.set(doc.id, doc);
  }
  return [...seen.values()];
}

function normalizeRoundOwnership(round, moments, legacyRoundLog) {
  return (
    safeString(round?.user_id) ||
    safeString(legacyRoundLog?.userId || legacyRoundLog?.user_id) ||
    safeString(moments[0]?.user_id)
  );
}

function dominantTrainingPillar(trainingSummary) {
  const pillars = [
    { pillar: 'focus', count: safeNumber(trainingSummary.focus_sessions) },
    { pillar: 'confidence', count: safeNumber(trainingSummary.confidence_sessions) },
    { pillar: 'control', count: safeNumber(trainingSummary.control_sessions) },
  ];
  return pillars.sort((left, right) => {
    if (right.count !== left.count) {
      return right.count - left.count;
    }
    return left.pillar.localeCompare(right.pillar);
  })[0].pillar;
}

function deriveTrainingLedCoachingState(userId, trainingSummary) {
  const activePillar = dominantTrainingPillar(trainingSummary);
  const longGap = trainingSummary.training_gap === 'long';

  if (activePillar === 'confidence') {
    return {
      user_id: userId,
      active_pillar: 'confidence',
      active_need: longGap ? 'restart confidence work' : 'keep confidence active',
      why_now: 'Recent completed MindCoach work is repeating most around confidence.',
      next_best_action_type: 'mindcoach_session',
      next_best_action_id: longGap ? 'confidence_quiet_confidence' : 'confidence_back_the_shot',
      next_best_action_label: longGap ? 'Starter Session' : 'Confidence - Back the Shot',
      time_horizon: longGap ? 'this_week' : 'next_round',
      source_round_ids: [],
      source_session_id: null,
      updated_at: nowIso(),
      generation_version: GENERATION_VERSION,
    };
  }

  if (activePillar === 'control') {
    return {
      user_id: userId,
      active_pillar: 'control',
      active_need: longGap ? 'restart control work' : 'keep control active',
      why_now: 'Recent completed MindCoach work is repeating most around control.',
      next_best_action_type: 'mindcoach_session',
      next_best_action_id: longGap ? 'control_breathe_first' : 'control_settle_under_pressure',
      next_best_action_label: longGap ? 'Starter Session' : 'Control - Settle Under Pressure',
      time_horizon: longGap ? 'this_week' : 'next_round',
      source_round_ids: [],
      source_session_id: null,
      updated_at: nowIso(),
      generation_version: GENERATION_VERSION,
    };
  }

  return {
    user_id: userId,
    active_pillar: 'focus',
    active_need: longGap ? 'restart focus work' : 'keep focus active',
    why_now: 'Recent completed MindCoach work is repeating most around focus.',
    next_best_action_type: 'mindcoach_session',
    next_best_action_id: longGap ? 'focus_one_thing' : 'focus_clear_start',
    next_best_action_label: longGap ? 'Starter Session' : 'Focus - Clear Start',
    time_horizon: longGap ? 'this_week' : 'next_round',
    source_round_ids: [],
    source_session_id: null,
    updated_at: nowIso(),
    generation_version: GENERATION_VERSION,
  };
}

function buildThinChatSummary(userId) {
  return buildChatSummary(
    {
      user_id: userId,
      session_id: null,
      ended_at: null,
      created_at: null,
    },
    [],
  );
}

function buildSignalSummary({ roundSummaries, completedMindCoachSessions, chatSummary }) {
  const repeatedRoundSignal = roundSummaries.length >= 2;
  const repeatedTrainingSignal = completedMindCoachSessions.length >= 2;
  return {
    repeated_signal_validated: repeatedRoundSignal || repeatedTrainingSignal,
    dominant_source: repeatedRoundSignal
      ? 'rounds'
      : repeatedTrainingSignal
        ? 'mindcoach'
        : chatSummary.message_count > 0
          ? 'golfchat'
          : 'thin_data',
    rounds: roundSummaries.length,
    mindcoach_sessions: completedMindCoachSessions.length,
    golfchat_messages: safeNumber(chatSummary.message_count),
  };
}

async function fetchLegacyRoundLog(roundId) {
  const db = getDb();
  const direct = await db.collection('round_logs').doc(roundId).get();
  if (direct.exists) {
    return direct.data() || null;
  }

  const byRoundId = await db
    .collection('round_logs')
    .where('roundId', '==', roundId)
    .limit(1)
    .get();
  if (!byRoundId.empty) {
    return byRoundId.docs[0].data() || null;
  }

  const byLinkedId = await db
    .collection('round_logs')
    .where('linkedGolfRoundId', '==', roundId)
    .limit(1)
    .get();
  if (!byLinkedId.empty) {
    return byLinkedId.docs[0].data() || null;
  }

  return null;
}

async function fetchNormalizedRoundInputs(roundId) {
  const db = getDb();
  const roundSnapshot = await db.collection('golf_rounds').doc(roundId).get();
  if (!roundSnapshot.exists) {
    return null;
  }

  const [momentsSnapshot, shotLogsSnapshot, legacyRoundLog] = await Promise.all([
    db
      .collection('caddyplay_logs')
      .where('sessionId', '==', roundId)
      .orderBy('capturedAt', 'asc')
      .get(),
    db.collection('shot_logs').where('roundId', '==', roundId).get(),
    fetchLegacyRoundLog(roundId),
  ]);

  const round = normalizeGolfRound(roundId, roundSnapshot.data() || {});
  const moments = momentsSnapshot.docs.map((doc) =>
    normalizeCaddyPlayMoment(doc.id, doc.data() || {}),
  );
  const shotLogs = shotLogsSnapshot.docs.map((doc) =>
    normalizeShotLog(doc.id, doc.data() || {}),
  );
  const userId = normalizeRoundOwnership(round, moments, legacyRoundLog);

  return {
    round: {
      ...round,
      user_id: userId || round.user_id,
    },
    moments,
    shotLogs,
    legacyRoundLog,
    userId: userId || round.user_id,
  };
}

async function fetchRecentCompletedRounds(userId, limit = RECENT_COMPLETED_ROUND_LIMIT) {
  const db = getDb();
  const snapshot = await db
    .collection('golf_rounds')
    .where('userId', '==', userId)
    .orderBy('date', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs
    .map((doc) => normalizeGolfRound(doc.id, doc.data() || {}))
    .filter((round) => round.status === 'completed');
}

async function fetchActiveGolfRound(userId) {
  const db = getDb();
  const snapshot = await db
    .collection('golf_rounds')
    .where('userId', '==', userId)
    .orderBy('date', 'desc')
    .limit(6)
    .get();

  for (const doc of snapshot.docs) {
    const round = normalizeGolfRound(doc.id, doc.data() || {});
    if (round.status === 'active' || round.status === 'draft') {
      return {
        round_id: round.round_id,
        status: round.status,
        course_name: round.course_name,
        current_hole: round.current_hole,
        holes_played: round.holes_played,
        score_relative_to_par: round.score_relative_to_par,
      };
    }
  }
  return null;
}

async function fetchNormalizedMindCoachSessions(userId) {
  const db = getDb();
  const [newShapeSnapshot, legacyShapeSnapshot] = await Promise.all([
    db
      .collection('mindcoach_sessions')
      .where('user_id', '==', userId)
      .orderBy('created_at', 'desc')
      .limit(RECENT_MINDCOACH_LIMIT)
      .get()
      .catch((error) => {
        logger.warn('[Intelligence] mindcoach new-shape query fallback', {
          userId,
          error: error.message,
        });
        return db.collection('mindcoach_sessions').where('user_id', '==', userId).limit(RECENT_MINDCOACH_LIMIT).get();
      }),
    db
      .collection('mindcoach_sessions')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(RECENT_MINDCOACH_LIMIT)
      .get()
      .catch((error) => {
        logger.warn('[Intelligence] mindcoach legacy-shape query fallback', {
          userId,
          error: error.message,
        });
        return db.collection('mindcoach_sessions').where('userId', '==', userId).limit(RECENT_MINDCOACH_LIMIT).get();
      }),
  ]);

  return dedupeDocs([
    ...newShapeSnapshot.docs,
    ...legacyShapeSnapshot.docs,
  ]).map((doc) => normalizeMindCoachSession(doc.id, doc.data() || {}));
}

async function fetchNormalizedMindCoachRuns(userId) {
  const db = getDb();
  const [completedSnapshot, autoDismissedSnapshot] = await Promise.all([
    db
      .collection('mindcoach_session_runs')
      .where('user_id', '==', userId)
      .where('status', '==', 'completed')
      .orderBy('started_at', 'desc')
      .limit(RECENT_MINDCOACH_LIMIT)
      .get(),
    db
      .collection('mindcoach_session_runs')
      .where('user_id', '==', userId)
      .where('status', '==', 'auto_dismissed')
      .orderBy('started_at', 'desc')
      .limit(RECENT_MINDCOACH_LIMIT)
      .get(),
  ]);

  return dedupeDocs([
    ...completedSnapshot.docs,
    ...autoDismissedSnapshot.docs,
  ]).map((doc) => normalizeMindCoachRun(doc.id, doc.data() || {}));
}

async function fetchLatestGolfChatSummary(userId) {
  const db = getDb();
  const sessionsSnapshot = await db
    .collection('voice_chat_sessions')
    .where('userId', '==', userId)
    .where('sessionMetadata.surface', '==', 'golfchat')
    .orderBy('startTime', 'desc')
    .limit(10)
    .get()
    .catch((error) => {
      logger.warn('[Intelligence] golfchat session query fallback', {
        userId,
        error: error.message,
      });
      return db
        .collection('voice_chat_sessions')
        .where('userId', '==', userId)
        .where('sessionMetadata.surface', '==', 'golfchat')
        .limit(10)
        .get();
    });

  const sessions = sessionsSnapshot.docs
    .map((doc) => normalizeVoiceChatSession(doc.id, doc.data() || {}))
    .filter(isCompletedChatSession);
  const latestSession = sortByDateDesc(sessions, (session) => session.ended_at || session.created_at)[0];

  if (!latestSession) {
    return buildThinChatSummary(userId);
  }

  const messagesSnapshot = await db
    .collection('voice_chat_messages')
    .where('userId', '==', userId)
    .where('sessionId', '==', latestSession.session_id)
    .orderBy('timestamp', 'asc')
    .get();
  const messages = messagesSnapshot.docs.map((doc) =>
    normalizeVoiceChatMessage(doc.id, doc.data() || {}),
  );
  return buildChatSummary(latestSession, messages);
}

async function fetchRecentInsightHistory(userId, surface, limit = RECENT_INSIGHT_HISTORY_LIMIT) {
  const db = getDb();
  const snapshot = await db
    .collection(COLLECTIONS.insightHistory)
    .where('user_id', '==', userId)
    .where('surface', '==', surface)
    .orderBy('created_at', 'desc')
    .limit(limit)
    .get()
    .catch((error) => {
      logger.warn('[Intelligence] insight history query fallback', {
        userId,
        surface,
        error: error.message,
      });
      return db
        .collection(COLLECTIONS.insightHistory)
        .where('user_id', '==', userId)
        .where('surface', '==', surface)
        .limit(limit)
        .get();
    });

  return sortByDateDesc(
    snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    (item) => item.created_at,
  ).slice(0, limit);
}

async function fetchRecentGlobalInsightHistory(userId, limit = RECENT_INSIGHT_HISTORY_LIMIT) {
  const db = getDb();
  const snapshot = await db
    .collection(COLLECTIONS.insightHistory)
    .where('user_id', '==', userId)
    .orderBy('created_at', 'desc')
    .limit(limit)
    .get()
    .catch((error) => {
      logger.warn('[Intelligence] recent global history fallback', {
        userId,
        error: error.message,
      });
      return db.collection(COLLECTIONS.insightHistory).where('user_id', '==', userId).limit(limit).get();
    });

  return sortByDateDesc(
    snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    (item) => item.created_at,
  ).slice(0, limit);
}

async function persistUserDerivedState({
  userId,
  roundSummaries,
  roundInsights,
  userPatterns,
  coachingState,
  trainingSummary,
  chatSummary,
  contextDocuments,
}) {
  const db = getDb();
  const batch = db.batch();

  for (const summary of roundSummaries) {
    batch.set(
      db.collection(COLLECTIONS.roundSummaries).doc(summary.round_id),
      summary,
      { merge: true },
    );
  }

  for (const insight of roundInsights) {
    batch.set(
      db.collection(COLLECTIONS.roundInsights).doc(insight.round_id),
      insight,
      { merge: true },
    );
  }

  batch.set(db.collection(COLLECTIONS.userPatterns).doc(userId), userPatterns, { merge: true });
  batch.set(db.collection(COLLECTIONS.coachingState).doc(userId), coachingState, { merge: true });
  batch.set(db.collection(COLLECTIONS.trainingSummary).doc(userId), trainingSummary, { merge: true });
  batch.set(db.collection(COLLECTIONS.chatSummary).doc(userId), chatSummary, { merge: true });

  for (const surface of SURFACES) {
    const contextDoc = contextDocuments[surface];
    batch.set(
      db.collection(COLLECTIONS.contextCache).doc(buildContextCacheDocId(userId, surface)),
      contextDoc,
      { merge: true },
    );
  }

  await batch.commit();
}

async function rebuildUserIntelligenceInternal(userId) {
  if (!safeString(userId)) {
    throw new HttpsError('invalid-argument', 'userId is required');
  }

  const db = getDb();
  const [previousCoachingStateSnapshot, recentRounds, sessions, runs, chatSummary, recentInsightHistory] =
    await Promise.all([
      db.collection(COLLECTIONS.coachingState).doc(userId).get(),
      fetchRecentCompletedRounds(userId),
      fetchNormalizedMindCoachSessions(userId),
      fetchNormalizedMindCoachRuns(userId),
      fetchLatestGolfChatSummary(userId),
      fetchRecentGlobalInsightHistory(userId),
    ]);

  const previousCoachingState = previousCoachingStateSnapshot.exists
    ? previousCoachingStateSnapshot.data() || null
    : null;

  const completedRoundInputs = [];
  for (const round of sortByDateDesc(recentRounds, (item) => item.round_date || item.end_time)) {
    const roundInput = await fetchNormalizedRoundInputs(round.round_id);
    if (!roundInput || roundInput.round.status !== 'completed') {
      continue;
    }
    completedRoundInputs.push(roundInput);
    if (completedRoundInputs.length >= 5) {
      break;
    }
  }

  const roundSummaries = completedRoundInputs.map((input) =>
    buildRoundSummary({
      round: input.round,
      moments: input.moments,
      shot_logs: input.shotLogs,
      legacy_round_log: input.legacyRoundLog,
    }),
  );
  const roundInsights = roundSummaries.map((summary) => buildRoundInsights(summary));

  const completedMindCoachSessions = joinCompletedMindCoachSessions(sessions, runs);
  const trainingSummary = completedMindCoachSessions.length
    ? deriveTrainingSummary(completedMindCoachSessions)
    : deriveThinDataTrainingSummary(userId);

  const hasRepeatedRoundSignal = roundSummaries.length >= 2;
  const hasRepeatedTrainingSignal = completedMindCoachSessions.length >= 2;

  let userPatterns;
  let coachingState;

  if (hasRepeatedRoundSignal) {
    userPatterns = deriveUserPatterns(roundSummaries, previousCoachingState);
    coachingState = deriveCoachingState({
      userPatterns,
      trainingSummary,
      chatSummary,
      previousCoachingState,
    });
  } else if (hasRepeatedTrainingSignal) {
    const activePillar = dominantTrainingPillar(trainingSummary);
    userPatterns = {
      ...deriveThinDataUserPatterns(userId),
      primary_pillar_need: {
        pillar: activePillar,
        score: 0.25,
      },
      updated_at: nowIso(),
    };
    coachingState = deriveTrainingLedCoachingState(userId, trainingSummary);
  } else {
    userPatterns = deriveThinDataUserPatterns(userId);
    coachingState = deriveThinDataCoachingState(userId);
  }

  const signalSummary = buildSignalSummary({
    roundSummaries,
    completedMindCoachSessions,
    chatSummary,
  });

  const [activeRound, justTalkPhrases] = await Promise.all([
    fetchActiveGolfRound(userId),
    Promise.resolve(extractRecentJustTalkPhrases(completedRoundInputs, 5)),
  ]);
  const lastMindCoachSession = summarizeLastMindCoachSession(completedMindCoachSessions);

  const contextDocuments = buildContextCacheDocuments({
    userPatterns,
    coachingState,
    trainingSummary,
    chatSummary,
    roundSummaries,
    roundInsights,
    recentInsightHistory,
    activeRound,
    justTalkPhrases,
    lastMindCoachSession,
  });

  for (const surface of SURFACES) {
    contextDocuments[surface] = {
      ...contextDocuments[surface],
      data_signals: signalSummary,
      repeated_signal_validated: signalSummary.repeated_signal_validated,
      dominant_signal_source: signalSummary.dominant_source,
    };
  }

  await persistUserDerivedState({
    userId,
    roundSummaries,
    roundInsights,
    userPatterns,
    coachingState,
    trainingSummary,
    chatSummary,
    contextDocuments,
  });

  logger.info('[Intelligence] user rebuilt', {
    userId,
    rounds: roundSummaries.length,
    completedMindCoachSessions: completedMindCoachSessions.length,
    dominantSource: signalSummary.dominant_source,
  });

  return {
    userId,
    roundSummaries,
    roundInsights,
    userPatterns,
    coachingState,
    trainingSummary,
    chatSummary,
    contextDocuments,
    signalSummary,
  };
}

async function rebuildRoundIntelligenceInternal(roundId, options = {}) {
  if (!safeString(roundId)) {
    throw new HttpsError('invalid-argument', 'roundId is required');
  }

  const db = getDb();
  const roundInput = await fetchNormalizedRoundInputs(roundId);
  if (!roundInput) {
    throw new HttpsError('not-found', 'Round not found');
  }

  const userId = roundInput.userId || roundInput.round.user_id;

  if (roundInput.round.status !== 'completed') {
    await Promise.all([
      db.collection(COLLECTIONS.roundSummaries).doc(roundId).delete().catch(() => null),
      db.collection(COLLECTIONS.roundInsights).doc(roundId).delete().catch(() => null),
    ]);

    if (userId && options.rebuildUser !== false) {
      await rebuildUserIntelligenceInternal(userId);
    }

    return {
      roundId,
      userId,
      deleted: true,
    };
  }

  const roundSummary = buildRoundSummary({
    round: roundInput.round,
    moments: roundInput.moments,
    shot_logs: roundInput.shotLogs,
    legacy_round_log: roundInput.legacyRoundLog,
  });
  const roundInsights = buildRoundInsights(roundSummary);

  await Promise.all([
    db.collection(COLLECTIONS.roundSummaries).doc(roundId).set(roundSummary, { merge: true }),
    db.collection(COLLECTIONS.roundInsights).doc(roundId).set(roundInsights, { merge: true }),
  ]);

  if (userId && options.rebuildUser !== false) {
    await rebuildUserIntelligenceInternal(userId);
  }

  logger.info('[Intelligence] round rebuilt', {
    roundId,
    userId,
  });

  return {
    roundId,
    userId,
    roundSummary,
    roundInsights,
  };
}

async function rebuildRecentIntelligenceInternal({
  limit = 25,
  staleHours = REPAIR_STALE_HOURS,
} = {}) {
  const db = getDb();
  const repairLimit = Math.max(1, Math.min(safeNumber(limit, 25), 100));

  const [recentRoundsSnapshot, recentCompletedRunsSnapshot, recentAutoDismissedRunsSnapshot, recentGolfChatSnapshot] =
    await Promise.all([
      db.collection('golf_rounds').orderBy('date', 'desc').limit(repairLimit * 3).get(),
      db
        .collection('mindcoach_session_runs')
        .where('status', '==', 'completed')
        .orderBy('started_at', 'desc')
        .limit(repairLimit * 2)
        .get(),
      db
        .collection('mindcoach_session_runs')
        .where('status', '==', 'auto_dismissed')
        .orderBy('started_at', 'desc')
        .limit(repairLimit * 2)
        .get(),
      db
        .collection('voice_chat_sessions')
        .where('sessionMetadata.surface', '==', 'golfchat')
        .orderBy('startTime', 'desc')
        .limit(repairLimit * 2)
        .get(),
    ]);

  const candidateUserIds = new Set();
  const recentCutoff = Date.now() - 14 * 24 * 60 * 60 * 1000;

  for (const doc of recentRoundsSnapshot.docs) {
    const round = normalizeGolfRound(doc.id, doc.data() || {});
    const roundDate = toDate(round.round_date || round.end_time || round.start_time);
    if (round.status === 'completed' && roundDate && roundDate.getTime() >= recentCutoff) {
      candidateUserIds.add(round.user_id);
    }
  }

  for (const doc of [...recentCompletedRunsSnapshot.docs, ...recentAutoDismissedRunsSnapshot.docs]) {
    const run = normalizeMindCoachRun(doc.id, doc.data() || {});
    const runDate = toDate(run.completed_at || run.started_at);
    if (runDate && runDate.getTime() >= recentCutoff) {
      candidateUserIds.add(run.user_id);
    }
  }

  for (const doc of recentGolfChatSnapshot.docs) {
    const session = normalizeVoiceChatSession(doc.id, doc.data() || {});
    const sessionDate = toDate(session.ended_at || session.created_at);
    if (isCompletedChatSession(session) && sessionDate && sessionDate.getTime() >= recentCutoff) {
      candidateUserIds.add(session.user_id);
    }
  }

  const repairedUserIds = [];
  for (const userId of [...candidateUserIds].filter(Boolean).slice(0, repairLimit)) {
    const cacheSnapshot = await db
      .collection(COLLECTIONS.contextCache)
      .doc(buildContextCacheDocId(userId, FOCOCO_TAB_SURFACE))
      .get();

    const cacheData = cacheSnapshot.exists ? cacheSnapshot.data() || null : null;
    if (!cacheData || isStaleTimestamp(cacheData.updated_at, staleHours)) {
      await rebuildUserIntelligenceInternal(userId);
      repairedUserIds.push(userId);
    }
  }

  return {
    scanned_users: [...candidateUserIds].filter(Boolean).length,
    repaired_users: repairedUserIds.length,
    repaired_user_ids: repairedUserIds,
  };
}

async function ensureContextCacheForSurface(userId, surface, options = {}) {
  const staleHours = safeNumber(options.staleHours, CONTEXT_CACHE_STALE_HOURS);
  const db = getDb();
  const docRef = db.collection(COLLECTIONS.contextCache).doc(buildContextCacheDocId(userId, surface));
  let snapshot = await docRef.get();

  const missingFococoInsightInputs =
    surface === FOCOCO_TAB_SURFACE &&
    snapshot.exists &&
    !snapshot.data()?.payload?.insight_inputs;

  if (
    !snapshot.exists ||
    isStaleTimestamp(snapshot.data()?.updated_at, staleHours) ||
    missingFococoInsightInputs
  ) {
    await rebuildUserIntelligenceInternal(userId);
    snapshot = await docRef.get();
  }

  if (!snapshot.exists) {
    throw new HttpsError('failed-precondition', `Context cache is missing for ${surface}`);
  }

  return {
    id: snapshot.id,
    ...snapshot.data(),
  };
}

function hasValidatedRepeatedSignal(contextDocument) {
  return contextDocument?.repeated_signal_validated === true;
}

async function syncLegacyFoCoCoInsightEngagementInternal(insightId, data) {
  if (safeString(data.insightType) !== 'fococo_daily') {
    return null;
  }

  const userId = safeString(data.user_id || data.userId);
  const historyDoc = {
    user_id: userId,
    surface: safeString(data.surface, FOCOCO_TAB_SURFACE),
    date: safeString(data.date || data.insightDate),
    insight_text: safeString(data.insight_text || data.insightContent),
    context_hash: safeString(data.context_hash || data.contextPayloadHash),
    generation_version: safeString(data.generation_version || data.generationVersion),
    opened: data.opened === true,
    played_audio: data.playedAudio === true || data.played_audio === true,
    time_on_screen_sec: safeNumber(data.timeOnScreenSec ?? data.time_on_screen_sec, 0),
    updated_at: nowIso(),
  };

  await getDb()
    .collection(COLLECTIONS.insightHistory)
    .doc(insightId)
    .set(historyDoc, { merge: true });

  return historyDoc;
}

const rebuildRoundIntelligence = onCall(async (request) => {
  ensureAdminRequest(request);
  const roundId = safeString(request.data?.roundId || request.data?.round_id);
  const result = await rebuildRoundIntelligenceInternal(roundId, {
    rebuildUser: request.data?.rebuildUser !== false,
  });
  return result;
});

const rebuildUserIntelligence = onCall(async (request) => {
  ensureAdminRequest(request);
  const userId = safeString(request.data?.userId || request.data?.user_id);
  const result = await rebuildUserIntelligenceInternal(userId);
  return {
    user_id: result.userId,
    round_count: result.roundSummaries.length,
    repeated_signal_validated: result.signalSummary.repeated_signal_validated,
    dominant_source: result.signalSummary.dominant_source,
  };
});

const repairRecentIntelligence = onCall(async (request) => {
  ensureAdminRequest(request);
  return rebuildRecentIntelligenceInternal({
    limit: request.data?.limit,
    staleHours: request.data?.staleHours,
  });
});

const onGolfRoundIntelligenceWrite = onDocumentWritten(
  'golf_rounds/{roundId}',
  async (event) => {
    const roundId = safeString(event.params.roundId);
    const beforeData = event.data.before.exists ? event.data.before.data() || {} : null;
    const afterData = event.data.after.exists ? event.data.after.data() || {} : null;
    const beforeCompleted = beforeData ? isCompletedRoundRecord(roundId, beforeData) : false;
    const afterCompleted = afterData ? isCompletedRoundRecord(roundId, afterData) : false;

    if (!beforeCompleted && !afterCompleted) {
      return null;
    }

    if (!afterCompleted) {
      const userId = safeString(afterData?.userId || beforeData?.userId);
      await Promise.all([
        getDb().collection(COLLECTIONS.roundSummaries).doc(roundId).delete().catch(() => null),
        getDb().collection(COLLECTIONS.roundInsights).doc(roundId).delete().catch(() => null),
      ]);
      if (userId) {
        await rebuildUserIntelligenceInternal(userId);
      }
      return null;
    }

    await rebuildRoundIntelligenceInternal(roundId);
    return null;
  },
);

const onMindCoachRunIntelligenceWrite = onDocumentWritten(
  'mindcoach_session_runs/{runId}',
  async (event) => {
    const beforeData = event.data.before.exists ? event.data.before.data() || {} : null;
    const afterData = event.data.after.exists ? event.data.after.data() || {} : null;
    const beforeStatus = safeString(beforeData?.status).toLowerCase();
    const afterStatus = safeString(afterData?.status).toLowerCase();
    const relevantStatuses = new Set(['completed', 'auto_dismissed']);

    if (!relevantStatuses.has(beforeStatus) && !relevantStatuses.has(afterStatus)) {
      return null;
    }

    const userId = safeString(afterData?.user_id || beforeData?.user_id);
    if (!userId) {
      return null;
    }

    await rebuildUserIntelligenceInternal(userId);
    return null;
  },
);

const onGolfChatSessionIntelligenceWrite = onDocumentWritten(
  'voice_chat_sessions/{sessionId}',
  async (event) => {
    const beforeData = event.data.before.exists ? event.data.before.data() || {} : null;
    const afterData = event.data.after.exists ? event.data.after.data() || {} : null;
    const beforeSurface = safeString(beforeData?.sessionMetadata?.surface).toLowerCase();
    const afterSurface = safeString(afterData?.sessionMetadata?.surface).toLowerCase();
    const beforeStatus = safeString(beforeData?.status).toLowerCase();
    const afterStatus = safeString(afterData?.status).toLowerCase();
    const beforeEnded = !!beforeData?.endTime;
    const afterEnded = !!afterData?.endTime;

    const wasRelevant = beforeSurface === 'golfchat' && (beforeStatus === 'completed' || beforeEnded);
    const isRelevant = afterSurface === 'golfchat' && (afterStatus === 'completed' || afterEnded);

    if (!wasRelevant && !isRelevant) {
      return null;
    }

    const userId = safeString(afterData?.userId || beforeData?.userId);
    if (!userId) {
      return null;
    }

    await rebuildUserIntelligenceInternal(userId);
    return null;
  },
);

const syncLegacyFoCoCoInsightEngagement = onDocumentWritten(
  'ai_insights/{insightId}',
  async (event) => {
    if (!event.data.after.exists) {
      return null;
    }

    const beforeData = event.data.before.exists ? event.data.before.data() || {} : {};
    const afterData = event.data.after.data() || {};
    const engagementChanged =
      beforeData.opened !== afterData.opened ||
      beforeData.playedAudio !== afterData.playedAudio ||
      safeNumber(beforeData.timeOnScreenSec, 0) !== safeNumber(afterData.timeOnScreenSec, 0);

    if (!engagementChanged && safeString(afterData.insightType) !== 'fococo_daily') {
      return null;
    }

    await syncLegacyFoCoCoInsightEngagementInternal(
      safeString(event.params.insightId),
      afterData,
    );
    return null;
  },
);

const nightlyRefreshIntelligence = onSchedule(
  {
    schedule: '0 3 * * *',
    timeZone: 'Africa/Casablanca',
  },
  async () => {
    const result = await rebuildRecentIntelligenceInternal();
    logger.info('[Intelligence] nightly refresh complete', result);
  },
);

module.exports = {
  COLLECTIONS,
  CONTEXT_CACHE_STALE_HOURS,
  FOCOCO_TAB_SURFACE,
  buildContextCacheDocId,
  buildInsightHistoryDocId,
  ensureContextCacheForSurface,
  fetchRecentInsightHistory,
  hasValidatedRepeatedSignal,
  rebuildRecentIntelligenceInternal,
  rebuildRoundIntelligence,
  rebuildRoundIntelligenceInternal,
  rebuildUserIntelligence,
  rebuildUserIntelligenceInternal,
  repairRecentIntelligence,
  syncLegacyFoCoCoInsightEngagementInternal,
  nightlyRefreshIntelligence,
  onGolfChatSessionIntelligenceWrite,
  onGolfRoundIntelligenceWrite,
  onMindCoachRunIntelligenceWrite,
  syncLegacyFoCoCoInsightEngagement,
};

module.exports._private = {
  buildSignalSummary,
  deriveTrainingLedCoachingState,
  dominantTrainingPillar,
  isCompletedRoundRecord,
  isStaleTimestamp,
};
