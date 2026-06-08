const crypto = require('crypto');

const GENERATION_VERSION = 'intelligence_layer_v1';
const FOCOCO_TAB_GENERATION_VERSION = 'fococo_tab_v3';
const SURFACES = ['fococo_tab', 'golfchat', 'mindcoach', 'webapp_insights', 'the_zone'];
const MIN_PREP_CUE_VALID_EVENTS = 5;
const VALID_COMPLETED_MINDCOACH_STATUSES = new Set(['completed', 'auto_dismissed']);
const VALID_COMPLETED_CHAT_STATUSES = new Set(['completed']);
const VALID_CUES = new Set([
  'deep_breath',
  'self_talk',
  'visualization',
  'trigger_word',
  'letting_go',
  'reset',
]);
const STOP_WORDS = new Set([
  'about',
  'after',
  'again',
  'against',
  'being',
  'between',
  'could',
  'every',
  'focus',
  'from',
  'game',
  'golf',
  'have',
  'into',
  'just',
  'mental',
  'mind',
  'more',
  'most',
  'much',
  'over',
  'round',
  'same',
  'session',
  'still',
  'than',
  'that',
  'their',
  'there',
  'these',
  'they',
  'this',
  'through',
  'today',
  'very',
  'when',
  'with',
  'your',
  'you',
]);

function safeString(value, fallback = '') {
  if (value == null) {
    return fallback;
  }
  return String(value).trim();
}

function safeNumber(value, fallback = null) {
  if (value == null || value === '') {
    return fallback;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') {
    return value.toDate();
  }
  if (typeof value === 'number') {
    return new Date(value);
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function toIso(value) {
  const date = toDate(value);
  return date ? date.toISOString() : null;
}

function deterministicStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map((item) => deterministicStringify(item)).join(',')}]`;
  }
  if (value && typeof value === 'object') {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${deterministicStringify(value[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value);
}

function sha256(value) {
  return crypto.createHash('sha256').update(String(value || '')).digest('hex');
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function average(values) {
  const valid = values.filter((value) => Number.isFinite(value));
  if (!valid.length) return null;
  return valid.reduce((sum, value) => sum + value, 0) / valid.length;
}

function sortByDateDesc(items, selector) {
  return [...items].sort((left, right) => {
    const leftDate = toDate(selector(left));
    const rightDate = toDate(selector(right));
    return (rightDate?.getTime() || 0) - (leftDate?.getTime() || 0);
  });
}

function enumLabel(value) {
  return safeString(value)
    .replace(/_/g, ' ')
    .trim();
}

function normalizeFocusLevel(value) {
  const raw = safeString(value).toLowerCase();
  switch (raw) {
    case 'high':
    case 'clear':
      return 'high';
    case 'mid':
    case 'medium':
    case 'neutral':
      return 'mid';
    case 'low':
    case 'distracted':
      return 'low';
    default:
      return null;
  }
}

function normalizeCommitmentLevel(value) {
  const raw = safeString(value).toLowerCase();
  switch (raw) {
    case 'high':
      return 'high';
    case 'mid':
    case 'medium':
      return 'mid';
    case 'low':
      return 'low';
    default:
      return null;
  }
}

function normalizeShotResult(value) {
  const raw = safeString(value).toLowerCase();
  switch (raw) {
    case 'good':
      return 'good';
    case 'ok':
    case 'okay':
      return 'ok';
    case 'bad':
    case 'poor':
      return 'bad';
    default:
      return null;
  }
}

function normalizePreparation(value) {
  const raw = safeString(value).toLowerCase();
  switch (raw) {
    case 'yes':
      return 'yes';
    case 'partly':
    case 'partial':
      return 'partly';
    case 'no':
      return 'no';
    default:
      return null;
  }
}

function normalizeCue(value) {
  const raw = safeString(value)
    .toLowerCase()
    .replace(/[ -]+/g, '_');
  return VALID_CUES.has(raw) ? raw : null;
}

function normalizeInputType(data) {
  const type = safeString(data.type).toLowerCase();
  const inputMethod = safeString(data.inputMethod || data.input_type).toLowerCase();
  if (type === 'mindsnap' || inputMethod === 'mindsnap') return 'mindsnap';
  if (type === 'talk' || inputMethod === 'voice') return 'voice';
  return 'tap';
}

function normalizeShotType(value) {
  const raw = safeString(value).toLowerCase();
  switch (raw) {
    case 'tee':
    case 'approach':
    case 'short':
    case 'putt':
      return raw;
    default:
      return null;
  }
}

function normalizeRoutineType(value) {
  const raw = safeString(value).toLowerCase();
  switch (raw) {
    case 'pre':
    case 'post':
    case 'between':
      return raw;
    default:
      return null;
  }
}

function focusScore(value) {
  return {
    high: 1,
    mid: 0.55,
    low: 0.15,
  }[value] ?? null;
}

function commitmentScore(value) {
  return {
    high: 1,
    mid: 0.55,
    low: 0.15,
  }[value] ?? null;
}

function preparationScore(value) {
  return {
    yes: 1,
    partly: 0.5,
    no: 0,
  }[value] ?? null;
}

function resultScore(value) {
  return {
    good: 1,
    ok: 0.55,
    bad: 0.1,
  }[value] ?? null;
}

function inferRoundStatus(data) {
  const raw = safeString(data.status).toLowerCase();
  if (['completed', 'complete', 'finished', 'synced'].includes(raw)) {
    return 'completed';
  }
  if (['active', 'in_progress', 'draft'].includes(raw)) {
    return raw === 'in_progress' ? 'active' : raw;
  }
  if (safeNumber(data.scoreToPar) != null || safeNumber(data.score_relative_to_par) != null) {
    return 'completed';
  }
  if (data.endTime || data.end_time || data.completedAt || data.completed_at) {
    return 'completed';
  }
  return 'active';
}

function normalizeWeather(value) {
  if (typeof value === 'string') {
    return safeString(value);
  }
  if (value && typeof value === 'object') {
    if (safeString(value.description)) return safeString(value.description);
    if (safeString(value.raw)) return safeString(value.raw).slice(0, 120);
    return safeString(value.condition || value.weatherCode || value.code);
  }
  return '';
}

function normalizeGolfRound(roundId, data = {}) {
  const date =
    toDate(data.end_time) ||
    toDate(data.endTime) ||
    toDate(data.date) ||
    toDate(data.updatedTime) ||
    toDate(data.createdTime);
  const holesPlayed =
    safeNumber(data.holes_played) ??
    safeNumber(data.holesPlayed) ??
    safeNumber(data.holes_total) ??
    safeNumber(data.holesTotal) ??
    (safeNumber(data.score) != null ? 18 : 0);
  return {
    round_id: roundId,
    user_id: safeString(data.user_id || data.userId),
    course_name: safeString(data.course_name || data.courseName),
    holes_played: holesPlayed,
    start_time: toIso(data.start_time || data.startTime || data.date || data.createdTime),
    end_time: toIso(data.end_time || data.endTime || data.updatedTime || data.completedAt || date),
    round_type: safeString(data.round_type || data.roundType || data.courseType),
    weather: normalizeWeather(data.weather),
    score_relative_to_par:
      safeNumber(data.score_relative_to_par) ??
      safeNumber(data.scoreToPar) ??
      0,
    tap_count: safeNumber(data.tap_count) ?? safeNumber(data.tapCount) ?? 0,
    talk_count: safeNumber(data.talk_count) ?? safeNumber(data.talkCount) ?? 0,
    mindsnap_count:
      safeNumber(data.mindsnap_count) ?? safeNumber(data.mindSnapCount) ?? 0,
    status: inferRoundStatus(data),
    round_date: toIso(date),
  };
}

function normalizeCaddyPlayMoment(momentId, data = {}) {
  const input_type = normalizeInputType(data);
  const preparation = normalizePreparation(
    data.pre_shot_preparation || data.preShotPreparation || data.preShotRoutine || data.routine,
  );
  const cue = normalizeCue(data.cue_used || data.cueUsed);
  return {
    moment_id: momentId,
    user_id: safeString(data.user_id || data.userId),
    round_id: safeString(data.round_id || data.roundId || data.sessionId),
    hole_number: safeNumber(data.hole_number) ?? safeNumber(data.holeNumber) ?? 1,
    timestamp: toIso(data.timestamp || data.capturedAt || data.createdTime),
    focus_level: normalizeFocusLevel(data.focus_level || data.focusLevel || data.focus),
    commitment: normalizeCommitmentLevel(data.commitment),
    pre_shot_preparation: preparation,
    cue_used: cue,
    shot_type: normalizeShotType(data.shot_type || data.shotType),
    club_used: safeString(data.club_used || data.clubUsed) || null,
    routine_type: normalizeRoutineType(data.routine_type || data.routineType),
    shot_result: normalizeShotResult(data.shot_result || data.shotResult || data.result),
    input_type,
    transcript:
      safeString(data.transcript || data.transcription || data.voiceTranscription) || null,
    mindsnap_sequence:
      safeString(data.mindsnap_sequence || data.mindSnapSequence).toLowerCase() || null,
  };
}

function normalizeShotLog(shotId, data = {}) {
  return {
    shot_id: safeString(data.shot_id || data.shotId || shotId),
    user_id: safeString(data.user_id || data.userId),
    round_id: safeString(data.round_id || data.roundId),
    hole_number: safeNumber(data.hole_number) ?? safeNumber(data.holeNumber) ?? null,
    club_used: safeString(data.club_used || data.clubUsed) || null,
    distance: safeNumber(data.distance || data.distanceAttempted),
    confidence_level:
      normalizeFocusLevel(data.confidence_level || data.confidenceLevel) || null,
    created_at: toIso(data.created_at || data.createdTime || data.timestamp),
    cue_used: normalizeCue(data.cue_used || data.cueUsed),
  };
}

function normalizeMindCoachSession(sessionId, data = {}) {
  return {
    session_id: sessionId,
    user_id: safeString(data.user_id || data.userId),
    template_id: safeString(data.template_id || data.templateId),
    pillar: safeString(data.pillar).toLowerCase() || null,
    context: data.context || {},
    context_mode:
      safeString(data.context_mode || data.contextMode || data.context?.mode).toLowerCase() ||
      null,
    completion_status:
      safeString(data.completion_status || data.completionStatus || data.status).toLowerCase() ||
      null,
    created_at: toIso(data.created_at || data.createdTime || data.timestamp),
    completed_at: toIso(data.completed_at || data.completedAt),
    session_key: safeString(data.session_key || data.sessionKey) || null,
  };
}

function normalizeMindCoachRun(runId, data = {}) {
  return {
    run_id: runId,
    session_id: safeString(data.session_id || data.sessionId),
    user_id: safeString(data.user_id || data.userId),
    status: safeString(data.status).toLowerCase() || null,
    started_at: toIso(data.started_at || data.startedAt),
    completed_at: toIso(data.completed_at || data.completedAt),
    mindset_after: safeString(data.mindset_after || data.mindsetAfter).toLowerCase() || null,
  };
}

function normalizeVoiceChatSession(sessionId, data = {}) {
  return {
    session_id: sessionId,
    user_id: safeString(data.user_id || data.userId),
    created_at: toIso(data.created_at || data.createdTime || data.startTime),
    ended_at: toIso(data.ended_at || data.endedAt || data.endTime),
    message_count: safeNumber(data.message_count) ?? safeNumber(data.messageCount) ?? 0,
    status: safeString(data.status).toLowerCase() || 'active',
    surface:
      safeString(data.surface || data.sessionMetadata?.surface).toLowerCase() || null,
    title: safeString(data.title) || null,
  };
}

function normalizeVoiceChatMessage(messageId, data = {}) {
  const role = data.role
    ? safeString(data.role).toLowerCase()
    : data.isUser === true
      ? 'user'
      : data.isSystem === true
        ? 'system'
        : 'assistant';
  return {
    message_id: messageId,
    session_id: safeString(data.session_id || data.sessionId),
    user_id: safeString(data.user_id || data.userId),
    role,
    content: safeString(data.content),
    timestamp: toIso(data.timestamp || data.createdAt),
    message_type: safeString(data.message_type || data.messageType).toLowerCase() || 'text',
  };
}

function isCompletedMindCoachRun(run) {
  return VALID_COMPLETED_MINDCOACH_STATUSES.has(safeString(run.status).toLowerCase());
}

function isCompletedChatSession(session) {
  return (
    VALID_COMPLETED_CHAT_STATUSES.has(safeString(session.status).toLowerCase()) ||
    !!session.ended_at
  );
}

function joinCompletedMindCoachSessions(sessions, runs) {
  const sessionsById = new Map(
    sessions.map((session) => [session.session_id, session]),
  );
  const completedRuns = runs.filter(isCompletedMindCoachRun);
  const joined = [];

  for (const run of completedRuns) {
    const session = sessionsById.get(run.session_id);
    if (!session) continue;
    joined.push({
      session_id: session.session_id,
      user_id: session.user_id || run.user_id,
      pillar: session.pillar || 'focus',
      template_id: session.template_id || null,
      context_mode: session.context_mode || null,
      session_key: session.session_key || null,
      completed_at: run.completed_at || session.completed_at || session.created_at,
    });
  }

  if (joined.length) {
    return sortByDateDesc(joined, (item) => item.completed_at);
  }

  return sortByDateDesc(
    sessions.filter((session) => isCompletedMindCoachRun(session)),
    (item) => item.completed_at || item.created_at,
  );
}

function groupByRoundId(items) {
  return items.reduce((accumulator, item) => {
    if (!item.round_id) return accumulator;
    if (!accumulator[item.round_id]) {
      accumulator[item.round_id] = [];
    }
    accumulator[item.round_id].push(item);
    return accumulator;
  }, {});
}

function sortMomentsAsc(moments) {
  return [...moments].sort((left, right) => {
    const leftDate = toDate(left.timestamp);
    const rightDate = toDate(right.timestamp);
    if ((leftDate?.getTime() || 0) === (rightDate?.getTime() || 0)) {
      return (left.hole_number || 0) - (right.hole_number || 0);
    }
    return (leftDate?.getTime() || 0) - (rightDate?.getTime() || 0);
  });
}

function segmentForHole(holeNumber, holesPlayed) {
  const holes = Math.max(Number(holesPlayed || 18), 1);
  const ratio = (Math.max(Number(holeNumber || 1), 1) - 1) / holes;
  if (ratio < 1 / 3) return 'early';
  if (ratio < 2 / 3) return 'mid';
  return 'late';
}

function buildSegmentStats(moments, holesPlayed) {
  const segments = {
    early: [],
    mid: [],
    late: [],
  };
  for (const moment of moments) {
    segments[segmentForHole(moment.hole_number, holesPlayed)].push(moment);
  }
  return Object.fromEntries(
    Object.entries(segments).map(([segment, rows]) => [
      segment,
      {
        count: rows.length,
        focus_avg: average(rows.map((moment) => focusScore(moment.focus_level))),
        commitment_avg: average(rows.map((moment) => commitmentScore(moment.commitment))),
        result_avg: average(rows.map((moment) => resultScore(moment.shot_result))),
      },
    ]),
  );
}

function collectAfterBadResultWindows(moments) {
  const windows = [];
  for (let index = 0; index < moments.length; index += 1) {
    const moment = moments[index];
    if (moment.shot_result !== 'bad') continue;
    windows.push({
      source: moment,
      next_moments: moments.slice(index + 1, index + 3),
    });
  }
  return windows;
}

function calculateRecoveryScore(moments) {
  const windows = collectAfterBadResultWindows(moments);
  if (!windows.length) {
    return {
      score: null,
      recovered_count: 0,
      unresolved_count: 0,
      window_count: 0,
    };
  }

  let recovered = 0;
  let unresolved = 0;
  for (const window of windows) {
    const nextResults = window.next_moments
      .map((moment) => resultScore(moment.shot_result))
      .filter((value) => value != null);
    const nextFocus = window.next_moments
      .map((moment) => focusScore(moment.focus_level))
      .filter((value) => value != null);
    const combined = average([...nextResults, ...nextFocus]);
    if (combined != null && combined >= 0.6) {
      recovered += 1;
    } else {
      unresolved += 1;
    }
  }

  return {
    score: recovered / windows.length,
    recovered_count: recovered,
    unresolved_count: unresolved,
    window_count: windows.length,
  };
}

function calculateLateRoundDrop(segmentStats) {
  const earlyComposite = average([
    segmentStats.early.focus_avg,
    segmentStats.early.commitment_avg,
    segmentStats.early.result_avg,
  ]);
  const lateComposite = average([
    segmentStats.late.focus_avg,
    segmentStats.late.commitment_avg,
    segmentStats.late.result_avg,
  ]);

  if (earlyComposite == null || lateComposite == null) {
    return {
      flag: false,
      delta: null,
    };
  }

  return {
    flag: earlyComposite - lateComposite >= 0.18,
    delta: earlyComposite - lateComposite,
  };
}

function calculateVolatilityFlag(moments) {
  const values = moments
    .map((moment) =>
      average([
        focusScore(moment.focus_level),
        commitmentScore(moment.commitment),
        resultScore(moment.shot_result),
      ]),
    )
    .filter((value) => value != null);
  if (values.length < 4) {
    return false;
  }
  const avg = average(values);
  const variance =
    values.reduce((sum, value) => sum + ((value - avg) ** 2), 0) / values.length;
  return Math.sqrt(variance) >= 0.22;
}

function calculateRoutineEffect(moments) {
  const valid = moments.filter((moment) => moment.pre_shot_preparation != null);
  if (valid.length < MIN_PREP_CUE_VALID_EVENTS) {
    return {
      classification: 'insufficient_data',
      delta: null,
      valid_count: valid.length,
    };
  }

  const yesAverage = average(
    valid
      .filter((moment) => moment.pre_shot_preparation === 'yes')
      .map((moment) => resultScore(moment.shot_result)),
  );
  const noAverage = average(
    valid
      .filter((moment) => moment.pre_shot_preparation === 'no')
      .map((moment) => resultScore(moment.shot_result)),
  );
  const delta =
    yesAverage != null && noAverage != null ? yesAverage - noAverage : null;

  let classification = 'mixed';
  if (delta != null && delta >= 0.2) {
    classification = 'positive';
  } else if (delta != null && delta <= -0.12) {
    classification = 'negative';
  }

  return {
    classification,
    delta,
    valid_count: valid.length,
  };
}

function calculatePreparationTrend(moments) {
  const valid = moments.filter((moment) => moment.pre_shot_preparation != null);
  if (valid.length < MIN_PREP_CUE_VALID_EVENTS) {
    return {
      label: 'insufficient_data',
      average: null,
      valid_count: valid.length,
    };
  }
  const prepAverage = average(valid.map((moment) => preparationScore(moment.pre_shot_preparation)));
  let label = 'mixed';
  if (prepAverage >= 0.72) {
    label = 'mostly_set';
  } else if (prepAverage <= 0.35) {
    label = 'mostly_missing';
  }
  return {
    label,
    average: prepAverage,
    valid_count: valid.length,
  };
}

function calculateCuePattern(moments) {
  const valid = moments.filter((moment) => moment.cue_used != null);
  if (valid.length < MIN_PREP_CUE_VALID_EVENTS) {
    return {
      label: 'insufficient_data',
      cue_used: null,
      valid_count: valid.length,
    };
  }

  const counts = new Map();
  for (const moment of valid) {
    counts.set(moment.cue_used, (counts.get(moment.cue_used) || 0) + 1);
  }
  const best = [...counts.entries()].sort((left, right) => right[1] - left[1])[0];
  return {
    label: best && best[1] >= 2 ? 'repeated_cue' : 'mixed',
    cue_used: best ? best[0] : null,
    valid_count: valid.length,
  };
}

function calculateCorrelations(moments) {
  const paired = moments.filter(
    (moment) => moment.focus_level && moment.commitment && moment.shot_result,
  );
  const focusResult = paired
    .filter((moment) => moment.focus_level != null && moment.shot_result != null)
    .map((moment) => ({
      x: focusScore(moment.focus_level),
      y: resultScore(moment.shot_result),
    }));
  const commitmentResult = paired
    .filter((moment) => moment.commitment != null && moment.shot_result != null)
    .map((moment) => ({
      x: commitmentScore(moment.commitment),
      y: resultScore(moment.shot_result),
    }));

  return {
    focus_result: simpleCorrelation(focusResult),
    commitment_result: simpleCorrelation(commitmentResult),
  };
}

function simpleCorrelation(pairs) {
  if (!pairs.length) return null;
  const xs = pairs.map((pair) => pair.x);
  const ys = pairs.map((pair) => pair.y);
  const xAvg = average(xs);
  const yAvg = average(ys);
  const numerator = pairs.reduce(
    (sum, pair) => sum + ((pair.x - xAvg) * (pair.y - yAvg)),
    0,
  );
  const xVariance = xs.reduce((sum, value) => sum + ((value - xAvg) ** 2), 0);
  const yVariance = ys.reduce((sum, value) => sum + ((value - yAvg) ** 2), 0);
  if (!xVariance || !yVariance) return 0;
  return clamp(numerator / Math.sqrt(xVariance * yVariance), -1, 1);
}

function calculateStreaks(moments) {
  let bestGood = 0;
  let bestBad = 0;
  let currentGood = 0;
  let currentBad = 0;
  for (const moment of moments) {
    if (moment.shot_result === 'good') {
      currentGood += 1;
      currentBad = 0;
    } else if (moment.shot_result === 'bad') {
      currentBad += 1;
      currentGood = 0;
    } else {
      currentGood = 0;
      currentBad = 0;
    }
    bestGood = Math.max(bestGood, currentGood);
    bestBad = Math.max(bestBad, currentBad);
  }
  return {
    good_streak: bestGood,
    bad_streak: bestBad,
  };
}

function buildRepeatedPatternCandidates(metrics) {
  const candidates = [];
  if (metrics.focus_average != null && metrics.focus_average <= 0.42) {
    candidates.push({
      key: 'focus_drop',
      weight: 0.92,
      risk: true,
      text: 'Focus dropped across multiple moments and results followed it.',
      tag: 'focus',
    });
  }
  if (metrics.commitment_average != null && metrics.commitment_average <= 0.42) {
    candidates.push({
      key: 'commitment_softening',
      weight: 0.88,
      risk: true,
      text: 'Commitment softened more than once before weaker results.',
      tag: 'commitment',
    });
  }
  if (metrics.preparation.label === 'mostly_missing') {
    candidates.push({
      key: 'preparation_thin',
      weight: 0.82,
      risk: true,
      text: 'Preparation was thin often enough to show up as a real pattern.',
      tag: 'preparation',
    });
  }
  if (metrics.recovery.score != null && metrics.recovery.score <= 0.34) {
    candidates.push({
      key: 'poor_recovery',
      weight: 0.96,
      risk: true,
      text: 'After a bad result, the next moments often carried the same instability forward.',
      tag: 'recovery',
    });
  }
  if (metrics.late_round_drop.flag) {
    candidates.push({
      key: 'late_round_drop',
      weight: 0.86,
      risk: true,
      text: 'The round thinned out late rather than at the start.',
      tag: 'late_round',
    });
  }
  if (metrics.routine_effect.classification === 'positive') {
    candidates.push({
      key: 'routine_helped',
      weight: 0.74,
      risk: false,
      text: 'When preparation was clearly there, the round looked more stable.',
      tag: 'routine',
    });
  }
  if (metrics.correlations.focus_result != null && metrics.correlations.focus_result >= 0.35) {
    candidates.push({
      key: 'focus_result_link',
      weight: 0.8,
      risk: false,
      text: 'When focus stayed clearer, shot results were steadier with it.',
      tag: 'focus_result',
    });
  }
  if (
    metrics.correlations.commitment_result != null &&
    metrics.correlations.commitment_result >= 0.35
  ) {
    candidates.push({
      key: 'commitment_result_link',
      weight: 0.78,
      risk: false,
      text: 'When commitment stayed high, the result usually held better too.',
      tag: 'commitment_result',
    });
  }
  if (metrics.volatility_flag) {
    candidates.push({
      key: 'volatility',
      weight: 0.68,
      risk: true,
      text: 'The round swung between settled and rushed moments instead of holding one shape.',
      tag: 'volatility',
    });
  }
  if (metrics.streaks.bad_streak >= 2) {
    candidates.push({
      key: 'bad_streak',
      weight: 0.63,
      risk: true,
      text: 'Weaker moments stacked instead of staying isolated.',
      tag: 'streaks',
    });
  }
  return candidates.sort((left, right) => right.weight - left.weight);
}

function buildRoundSummary({
  round,
  moments,
  shot_logs = [],
  legacy_round_log = null,
}) {
  const orderedMoments = sortMomentsAsc(moments);
  const resultMoments = orderedMoments.filter((moment) => moment.shot_result != null);
  const focusAverage = average(resultMoments.map((moment) => focusScore(moment.focus_level)));
  const commitmentAverage = average(
    resultMoments.map((moment) => commitmentScore(moment.commitment)),
  );
  const segmentStats = buildSegmentStats(resultMoments, round.holes_played || 18);
  const recovery = calculateRecoveryScore(resultMoments);
  const lateRoundDrop = calculateLateRoundDrop(segmentStats);
  const volatilityFlag = calculateVolatilityFlag(resultMoments);
  const preparation = calculatePreparationTrend(resultMoments);
  const cuePattern = calculateCuePattern(resultMoments);
  const routineEffect = calculateRoutineEffect(resultMoments);
  const correlations = calculateCorrelations(resultMoments);
  const streaks = calculateStreaks(resultMoments);

  const metrics = {
    focus_average: focusAverage,
    commitment_average: commitmentAverage,
    preparation,
    cue_pattern: cuePattern,
    recovery,
    late_round_drop: lateRoundDrop,
    volatility_flag: volatilityFlag,
    routine_effect: routineEffect,
    correlations,
    streaks,
  };

  const patternCandidates = buildRepeatedPatternCandidates(metrics);
  const riskPattern = patternCandidates.find((candidate) => candidate.risk) || null;
  const strengthPattern = patternCandidates.find((candidate) => !candidate.risk) || null;

  const focusImpact = average([
    focusAverage == null ? null : 1 - focusAverage,
    lateRoundDrop.flag ? 0.82 : 0.1,
    volatilityFlag ? 0.45 : 0.15,
  ]) || 0;
  const confidenceImpact = average([
    commitmentAverage == null ? null : 1 - commitmentAverage,
    correlations.commitment_result == null ? null : 1 - clamp(correlations.commitment_result, 0, 1),
    riskPattern?.key === 'commitment_softening' ? 0.85 : 0.2,
  ]) || 0;
  const controlImpact = average([
    recovery.score == null ? null : 1 - recovery.score,
    routineEffect.classification === 'negative' ? 0.8 : 0.2,
    volatilityFlag ? 0.75 : 0.2,
  ]) || 0;

  const coachingRelevance =
    patternCandidates.filter((candidate) => candidate.risk).length >= 2
      ? 'high'
      : patternCandidates.length
        ? 'medium'
        : 'low';

  const fallbackSummary =
    legacy_round_log && !patternCandidates.length
      ? safeString(legacy_round_log.aiRoundSummary || legacy_round_log.ai_round_summary)
      : '';

  return {
    round_id: round.round_id,
    user_id: round.user_id,
    round_date: round.round_date || round.end_time || round.start_time,
    score_relative_to_par: round.score_relative_to_par,
    focus_signal:
      focusAverage == null
        ? 'insufficient_data'
        : focusAverage >= 0.72
          ? 'stable_high'
          : focusAverage <= 0.42
            ? 'unstable_low'
            : 'mixed',
    commitment_trend:
      commitmentAverage == null
        ? 'insufficient_data'
        : commitmentAverage >= 0.72
          ? 'stable_high'
          : commitmentAverage <= 0.42
            ? 'weakening'
            : 'mixed',
    prep_trend: preparation.label,
    recovery_trend:
      recovery.score == null
        ? 'insufficient_data'
        : recovery.score >= 0.66
          ? 'steady_recovery'
          : recovery.score <= 0.34
            ? 'poor_recovery'
            : 'mixed_recovery',
    volatility_flag: volatilityFlag,
    late_round_drop: lateRoundDrop.flag,
    key_pattern: strengthPattern?.text || riskPattern?.text || fallbackSummary || 'No repeated pattern was strong enough for a confident claim.',
    risk_pattern: riskPattern?.text || null,
    coaching_relevance: coachingRelevance,
    ai_summary:
      patternCandidates.length > 0
        ? patternCandidates.slice(0, 2).map((candidate) => candidate.text).join(' ')
        : fallbackSummary || 'This round did not create a repeated enough signal for stronger pattern claims.',
    pillar_impacts: {
      focus: Number(focusImpact.toFixed(3)),
      confidence: Number(confidenceImpact.toFixed(3)),
      control: Number(controlImpact.toFixed(3)),
    },
    weakness_flags: {
      focus: focusImpact >= 0.55,
      confidence: confidenceImpact >= 0.55,
      control: controlImpact >= 0.55,
    },
    pattern_tags: patternCandidates.map((candidate) => candidate.tag),
    metrics: {
      focus_average: focusAverage,
      commitment_average: commitmentAverage,
      preparation_average: preparation.average,
      recovery_score: recovery.score,
      late_round_delta: lateRoundDrop.delta,
      routine_effect_delta: routineEffect.delta,
      cue_used: cuePattern.cue_used,
      shot_log_count: shot_logs.length,
      streaks,
    },
    generated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function buildRoundInsights(roundSummary) {
  const insights = [];
  const tags = [];
  const seen = new Set();

  for (const text of [roundSummary.risk_pattern, roundSummary.key_pattern, roundSummary.ai_summary]) {
    const value = safeString(text);
    if (!value || seen.has(value)) continue;
    seen.add(value);
    insights.push(value);
  }

  if (roundSummary.late_round_drop && !seen.has('The round thinned out late rather than at the start.')) {
    insights.push('The round thinned out late rather than at the start.');
  }
  if (roundSummary.volatility_flag) {
    insights.push('The round swung between settled and rushed moments instead of holding one shape.');
  }
  if (roundSummary.prep_trend === 'mostly_missing') {
    insights.push('Preparation was thin often enough to show up as a real pattern.');
  }

  for (const tag of roundSummary.pattern_tags || []) {
    if (!tags.includes(tag)) {
      tags.push(tag);
    }
  }

  return {
    round_id: roundSummary.round_id,
    user_id: roundSummary.user_id,
    round_date: roundSummary.round_date,
    insights: insights.slice(0, 5),
    tags,
    created_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function weightedRoundSummaries(roundSummaries) {
  const recent = sortByDateDesc(roundSummaries, (item) => item.round_date).slice(0, 5);
  return recent.map((summary, index) => ({
    summary,
    weight: index < 2 ? 2 : 1,
  }));
}

function aggregateTrend(roundSummaries, field) {
  const recent = sortByDateDesc(roundSummaries, (item) => item.round_date).slice(0, 5);
  const values = recent
    .map((summary) => safeNumber(summary.metrics?.[field]))
    .filter((value) => value != null);
  if (values.length < 2) return 'insufficient_data';
  const recentWindow = average(values.slice(0, 2));
  const previousWindow = average(values.slice(2));
  if (previousWindow == null) return 'emerging';
  if (recentWindow - previousWindow >= 0.12) return 'improving';
  if (previousWindow - recentWindow >= 0.12) return 'slipping';
  return 'steady';
}

function chooseActivePillar(weightedSummaries, previousActivePillar = null) {
  const totalWeight = weightedSummaries.reduce((sum, item) => sum + item.weight, 0) || 1;
  const pillars = ['focus', 'confidence', 'control'];
  const scores = {};

  for (const pillar of pillars) {
    const weaknessFrequency =
      weightedSummaries.reduce(
        (sum, item) => sum + (item.summary.weakness_flags?.[pillar] ? item.weight : 0),
        0,
      ) / totalWeight;
    const scoreImpact =
      weightedSummaries.reduce(
        (sum, item) => sum + ((item.summary.pillar_impacts?.[pillar] || 0) * item.weight),
        0,
      ) / totalWeight;
    const recentTwoImpact =
      weightedSummaries
        .slice(0, 2)
        .reduce(
          (sum, item) => sum + ((item.summary.pillar_impacts?.[pillar] || 0) * item.weight),
          0,
        ) / Math.max(weightedSummaries.slice(0, 2).reduce((sum, item) => sum + item.weight, 0), 1);
    scores[pillar] = {
      pillar,
      total: Number((0.6 * weaknessFrequency + 0.4 * scoreImpact).toFixed(4)),
      weakness_frequency: Number(weaknessFrequency.toFixed(4)),
      score_impact: Number(scoreImpact.toFixed(4)),
      recent_two_impact: Number(recentTwoImpact.toFixed(4)),
    };
  }

  return pillars
    .map((pillar) => scores[pillar])
    .sort((left, right) => {
      if (right.total !== left.total) return right.total - left.total;
      if (right.recent_two_impact !== left.recent_two_impact) {
        return right.recent_two_impact - left.recent_two_impact;
      }
      if (right.score_impact !== left.score_impact) {
        return right.score_impact - left.score_impact;
      }
      if (previousActivePillar && left.pillar === previousActivePillar) return -1;
      if (previousActivePillar && right.pillar === previousActivePillar) return 1;
      return left.pillar.localeCompare(right.pillar);
    })[0];
}

function improvementDirection(roundSummaries) {
  const recent = sortByDateDesc(roundSummaries, (item) => item.round_date).slice(0, 5);
  if (recent.length < 2) return 'insufficient_data';
  const recentScores = recent.slice(0, 2).map((item) => safeNumber(item.score_relative_to_par, 0));
  const previousScores = recent.slice(2).map((item) => safeNumber(item.score_relative_to_par, 0));
  if (!previousScores.length) return 'emerging';
  const recentAvg = average(recentScores);
  const previousAvg = average(previousScores);
  if (previousAvg - recentAvg >= 1.2) return 'improving';
  if (recentAvg - previousAvg >= 1.2) return 'slipping';
  return 'steady';
}

function deriveNeed(activePillar, userPatterns, trainingSummary) {
  if (!userPatterns.source_round_ids?.length) {
    return {
      active_need: 'build baseline',
      why_now: 'There is not enough repeated round data yet, so the system needs a baseline first.',
      next_best_action_type: 'mindcoach_session',
      next_best_action_id: 'focus_one_thing',
      next_best_action_label: 'Starter Session',
      time_horizon: 'this_week',
    };
  }

  const gap = trainingSummary.training_gap;

  if (activePillar === 'focus') {
    if (userPatterns.late_round_pattern === 'recurring') {
      return {
        active_need: 'stabilize late round attention',
        why_now: 'Recent rounds keep thinning late, so attention control is the clearest repeated signal.',
        next_best_action_type: 'mindcoach_session',
        next_best_action_id: 'focus_between_shots',
        next_best_action_label: 'Focus - Between Shots',
        time_horizon: 'next_round',
      };
    }
    if (userPatterns.routine_effect === 'negative') {
      return {
        active_need: 'build a cleaner pre-shot start',
        why_now: 'Preparation drops are showing up often enough to affect what follows.',
        next_best_action_type: 'mindcoach_session',
        next_best_action_id: 'focus_narrow_the_target',
        next_best_action_label: 'Focus - Narrow the Target',
        time_horizon: 'next_round',
      };
    }
    return {
      active_need: gap === 'long' ? 'rebuild baseline attention' : 'protect attention under pressure',
      why_now: 'Focus is the repeated pressure point across the latest completed rounds.',
      next_best_action_type: 'mindcoach_session',
      next_best_action_id: gap === 'long' ? 'focus_one_thing' : 'focus_clear_start',
      next_best_action_label:
        gap === 'long' ? 'Focus - One Thing' : 'Focus - Clear Start',
      time_horizon: gap === 'long' ? 'this_week' : 'next_round',
    };
  }

  if (activePillar === 'confidence') {
    if (userPatterns.mistake_recovery_pattern === 'recurring_struggle') {
      return {
        active_need: 'recover trust after misses',
        why_now: 'Confidence slips most clearly after a mistake rather than before the shot.',
        next_best_action_type: 'mindcoach_session',
        next_best_action_id: 'confidence_after_shot',
        next_best_action_label: 'Confidence - After Shot',
        time_horizon: 'next_round',
      };
    }
    return {
      active_need: gap === 'long' ? 'rebuild self-trust' : 'back the shot more fully',
      why_now: 'Commitment and result are separating often enough to matter now.',
      next_best_action_type: 'mindcoach_session',
      next_best_action_id:
        gap === 'long' ? 'confidence_quiet_confidence' : 'confidence_back_the_shot',
      next_best_action_label:
        gap === 'long'
          ? 'Confidence - Quiet Confidence'
          : 'Confidence - Back the Shot',
      time_horizon: gap === 'long' ? 'this_week' : 'next_round',
    };
  }

  if (userPatterns.mistake_recovery_pattern === 'recurring_struggle') {
    return {
      active_need: 'reset faster after disruption',
      why_now: 'Control drops most clearly in the moments right after a bad result.',
      next_best_action_type: 'mindcoach_session',
      next_best_action_id: 'control_after_shot',
      next_best_action_label: 'Control - After Shot',
      time_horizon: 'next_round',
    };
  }

  return {
    active_need: gap === 'long' ? 'rebuild steady control' : 'settle pressure earlier',
    why_now: 'Control is the strongest repeated weakness across the most recent completed rounds.',
    next_best_action_type: 'mindcoach_session',
    next_best_action_id:
      gap === 'long' ? 'control_breathe_first' : 'control_settle_under_pressure',
    next_best_action_label:
      gap === 'long' ? 'Control - Breathe First' : 'Control - Settle Under Pressure',
    time_horizon: gap === 'long' ? 'this_week' : 'next_round',
  };
}

function deriveUserPatterns(roundSummaries, previousCoachingState = null) {
  const weighted = weightedRoundSummaries(roundSummaries);
  const activePillarScore = chooseActivePillar(
    weighted,
    previousCoachingState?.active_pillar || null,
  );
  const recent = weighted.map((item) => item.summary);
  const topRiskPattern = recent
    .map((summary) => safeString(summary.risk_pattern))
    .filter(Boolean)[0] || null;
  const topStrengthPattern = recent
    .map((summary) => safeString(summary.key_pattern))
    .filter(Boolean)[0] || null;

  const pressureCount = recent.filter((summary) => summary.late_round_drop).length;
  const recoveryStruggles = recent.filter(
    (summary) => summary.recovery_trend === 'poor_recovery',
  ).length;
  const routinePositive = recent.filter(
    (summary) => summary.metrics?.routine_effect_delta != null && summary.metrics.routine_effect_delta > 0.18,
  ).length;
  const routineNegative = recent.filter(
    (summary) => summary.metrics?.routine_effect_delta != null && summary.metrics.routine_effect_delta < -0.08,
  ).length;

  return {
    user_id: recent[0]?.user_id || '',
    primary_pillar_need: {
      pillar: activePillarScore.pillar,
      score: activePillarScore.total,
    },
    focus_trend: aggregateTrend(recent, 'focus_average'),
    commitment_trend: aggregateTrend(recent, 'commitment_average'),
    preparation_trend: aggregateTrend(recent, 'preparation_average'),
    recovery_trend: aggregateTrend(recent, 'recovery_score'),
    pressure_pattern:
      pressureCount >= 2 ? 'recurring_pressure_drop' : pressureCount === 1 ? 'isolated_pressure_drop' : 'stable',
    late_round_pattern:
      pressureCount >= 2 ? 'recurring' : pressureCount === 1 ? 'occasional' : 'stable',
    mistake_recovery_pattern:
      recoveryStruggles >= 2
        ? 'recurring_struggle'
        : recoveryStruggles === 1
          ? 'occasional_struggle'
          : 'stable',
    routine_effect:
      routinePositive > routineNegative
        ? 'positive'
        : routineNegative > routinePositive
          ? 'negative'
          : 'mixed',
    top_risk_pattern: topRiskPattern,
    top_strength_pattern: topStrengthPattern,
    recent_improvement_direction: improvementDirection(recent),
    pillar_scores: {
      focus: activePillarScore.pillar === 'focus' ? activePillarScore.total : chooseActivePillar(weighted).total,
      confidence: weighted.length
        ? Number(
            (
              weighted.reduce((sum, item) => sum + ((item.summary.pillar_impacts?.confidence || 0) * item.weight), 0) /
              weighted.reduce((sum, item) => sum + item.weight, 0)
            ).toFixed(4),
          )
        : 0,
      control: weighted.length
        ? Number(
            (
              weighted.reduce((sum, item) => sum + ((item.summary.pillar_impacts?.control || 0) * item.weight), 0) /
              weighted.reduce((sum, item) => sum + item.weight, 0)
            ).toFixed(4),
          )
        : 0,
    },
    source_round_ids: recent.map((summary) => summary.round_id),
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function deriveTrainingSummary(completedMindCoachSessions, now = new Date()) {
  const sorted = sortByDateDesc(completedMindCoachSessions, (item) => item.completed_at);
  const last7 = sorted.filter((session) => differenceInDays(session.completed_at, now) <= 7);
  const last14 = sorted.filter((session) => differenceInDays(session.completed_at, now) <= 14);
  const pillarCounts = sorted.reduce(
    (accumulator, session) => {
      accumulator[session.pillar] = (accumulator[session.pillar] || 0) + 1;
      return accumulator;
    },
    { focus: 0, confidence: 0, control: 0 },
  );
  const daysSinceLast = sorted[0] ? differenceInDays(sorted[0].completed_at, now) : null;

  let completionTrend = 'inactive';
  if (last7.length >= 4) {
    completionTrend = 'active';
  } else if (last7.length >= 2) {
    completionTrend = 'steady';
  } else if (last14.length > last7.length) {
    completionTrend = 'slipping';
  } else if (last14.length > 0) {
    completionTrend = 'emerging';
  }

  let trainingGap = 'long';
  if (daysSinceLast == null) {
    trainingGap = 'long';
  } else if (daysSinceLast <= 3) {
    trainingGap = 'none';
  } else if (daysSinceLast <= 7) {
    trainingGap = 'short';
  } else if (daysSinceLast <= 14) {
    trainingGap = 'medium';
  }

  return {
    user_id: sorted[0]?.user_id || '',
    last_7_days_count: last7.length,
    last_14_days_count: last14.length,
    focus_sessions: pillarCounts.focus,
    confidence_sessions: pillarCounts.confidence,
    control_sessions: pillarCounts.control,
    completion_trend: completionTrend,
    training_gap: trainingGap,
    last_completed_at: sorted[0]?.completed_at || null,
    source_session_ids: sorted.slice(0, 20).map((session) => session.session_id),
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function differenceInDays(from, to) {
  const fromDate = toDate(from);
  const toDateValue = toDate(to);
  if (!(fromDate instanceof Date) || !(toDateValue instanceof Date)) return Number.POSITIVE_INFINITY;
  return Math.max(
    0,
    Math.floor((toDateValue.getTime() - fromDate.getTime()) / 86400000),
  );
}

function tokenize(text) {
  return safeString(text)
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .map((token) => token.trim())
    .filter((token) => token.length >= 4 && !STOP_WORDS.has(token));
}

function extractCommitments(messages) {
  const sentences = [];
  const patterns = [
    /\bi will\b/i,
    /\bi'll\b/i,
    /\bnext time\b/i,
    /\bgoing to\b/i,
    /\bneed to\b/i,
    /\bwant to\b/i,
  ];
  for (const message of messages) {
    const content = safeString(message.content);
    if (!content) continue;
    const chunks = content.split(/(?<=[.!?])\s+/);
    for (const chunk of chunks) {
      if (patterns.some((pattern) => pattern.test(chunk))) {
        sentences.push(chunk.trim());
      }
    }
  }
  return [...new Set(sentences)].slice(0, 3);
}

function inferPillarTagsFromTokens(tokens) {
  const tags = new Set();
  const text = tokens.join(' ');
  if (/(focus|present|target|routine|attention|clarity)/.test(text)) tags.add('focus');
  if (/(trust|belief|doubt|commit|confidence)/.test(text)) tags.add('confidence');
  if (/(calm|pressure|reset|steady|control|composure)/.test(text)) tags.add('control');
  return [...tags];
}

function inferTone(messages) {
  const text = messages.map((message) => safeString(message.content).toLowerCase()).join(' ');
  if (/(frustrated|angry|annoyed|rushed|tense)/.test(text)) return 'frustrated';
  if (/(not sure|unsure|confused|unclear|question)/.test(text)) return 'uncertain';
  if (/(learned|noticed|realised|realized|saw|pattern)/.test(text)) return 'reflective';
  return text ? 'steady' : 'unknown';
}

function buildChatSummary(session, messages) {
  const userMessages = sortMomentsAsc(
    messages.filter((message) => message.role === 'user' && safeString(message.content)),
  );
  if (!session || !userMessages.length) {
    return {
      user_id: session?.user_id || '',
      session_id: session?.session_id || null,
      themes: [],
      pillar_tags: [],
      commitments: [],
      emotional_tone: 'unknown',
      unresolved_thread: null,
      summary_text: '',
      message_count: 0,
      completed_at: session?.ended_at || null,
      updated_at: new Date().toISOString(),
      generation_version: GENERATION_VERSION,
    };
  }

  const counts = new Map();
  for (const message of userMessages) {
    for (const token of tokenize(message.content)) {
      counts.set(token, (counts.get(token) || 0) + 1);
    }
  }
  const themes = [...counts.entries()]
    .sort((left, right) => right[1] - left[1])
    .slice(0, 5)
    .map(([token]) => token);
  const pillarTags = inferPillarTagsFromTokens(themes);
  const commitments = extractCommitments(userMessages);
  const emotionalTone = inferTone(userMessages);
  const lastMessage = userMessages[userMessages.length - 1];
  const unresolvedThread =
    /\?$/.test(safeString(lastMessage.content)) ||
    /\bnot sure\b|\bdon't know\b|\bunclear\b/i.test(safeString(lastMessage.content))
      ? safeString(lastMessage.content)
      : null;
  const summaryText = [
    themes[0] ? `The conversation kept returning to ${themes[0]}.` : '',
    emotionalTone !== 'unknown' ? `The tone was ${emotionalTone}.` : '',
  ]
    .filter(Boolean)
    .join(' ');

  return {
    user_id: session.user_id,
    session_id: session.session_id,
    themes,
    pillar_tags: pillarTags,
    commitments,
    emotional_tone: emotionalTone,
    unresolved_thread: unresolvedThread,
    summary_text: summaryText,
    message_count: userMessages.length,
    completed_at: session.ended_at || session.created_at || null,
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function buildRecentRoundHeadlines(roundSummaries, roundInsights, limit = 5) {
  const insightsByRoundId = new Map(
    roundInsights.map((insight) => [insight.round_id, insight]),
  );
  return sortByDateDesc(roundSummaries, (item) => item.round_date)
    .slice(0, limit)
    .map((summary) => ({
      round_id: summary.round_id,
      round_date: summary.round_date,
      score_relative_to_par: summary.score_relative_to_par,
      key_pattern: summary.key_pattern,
      risk_pattern: summary.risk_pattern,
      insights: insightsByRoundId.get(summary.round_id)?.insights || [],
    }));
}

function buildRecentInsights(historyEntries, limit = 3) {
  return sortByDateDesc(historyEntries, (item) => item.created_at || item.date)
    .slice(0, limit)
    .map((entry) => ({
      insight_text: entry.insight_text,
      date: entry.date,
      surface: entry.surface,
    }));
}

function deriveStrongestWeakestPillar(userPatterns) {
  const scores = userPatterns?.pillar_scores || {};
  const ranked = ['focus', 'confidence', 'control']
    .map((pillar) => ({ pillar, score: safeNumber(scores[pillar]) }))
    .sort((left, right) => left.score - right.score);
  const weakest =
    safeString(userPatterns?.primary_pillar_need?.pillar) ||
    ranked[ranked.length - 1]?.pillar ||
    'focus';
  const strongest = ranked.find((entry) => entry.pillar !== weakest)?.pillar || 'confidence';
  return { strongest, weakest };
}

function extractRecentJustTalkPhrases(completedRoundInputs, limit = 5) {
  const phrases = [];
  for (const input of completedRoundInputs || []) {
    for (const moment of sortMomentsAsc(input.moments || [])) {
      if (moment.input_type !== 'voice') continue;
      const transcript = safeString(moment.transcript || moment.notes);
      if (!transcript) continue;
      phrases.push(transcript.length > 140 ? `${transcript.slice(0, 137)}...` : transcript);
    }
  }
  return phrases.slice(-limit);
}

function summarizeLastMindCoachSession(completedMindCoachSessions) {
  const last = (completedMindCoachSessions || [])[0];
  if (!last) return null;
  return {
    session_key: safeString(last.session_key) || null,
    pillar: safeString(last.pillar) || 'focus',
    completed_at: last.completed_at || null,
    context_mode: safeString(last.context_mode) || null,
  };
}

function buildFococoTabInsightPayload({
  userPatterns,
  coachingState,
  roundSummaries,
  activeRound,
  justTalkPhrases,
  lastMindCoachSession,
  chatSummary,
  trainingSummary,
}) {
  const { strongest, weakest } = deriveStrongestWeakestPillar(userPatterns);
  const sortedRounds = sortByDateDesc(roundSummaries || [], (item) => item.round_date);
  const lastRound = sortedRounds[0];
  return {
    last_round_summary: lastRound
      ? {
          round_id: lastRound.round_id,
          round_date: lastRound.round_date,
          key_pattern: safeString(lastRound.key_pattern),
          risk_pattern: safeString(lastRound.risk_pattern),
          focus_signal: safeString(lastRound.focus_signal),
          recovery_trend: safeString(lastRound.recovery_trend),
          late_round_drop: lastRound.late_round_drop === true,
        }
      : null,
    strongest_pillar: strongest,
    weakest_pillar: weakest,
    recent_missed_pattern: safeString(userPatterns?.top_risk_pattern) || null,
    recent_best_pattern: safeString(userPatterns?.top_strength_pattern) || null,
    selected_goal: {
      label: safeString(coachingState?.next_best_action_label),
      type: safeString(coachingState?.next_best_action_type),
      active_need: safeString(coachingState?.active_need),
      active_pillar: safeString(coachingState?.active_pillar),
    },
    active_round_status: activeRound
      ? {
          status: safeString(activeRound.status) || 'active',
          round_id: safeString(activeRound.round_id),
          course_name: safeString(activeRound.course_name),
          current_hole: activeRound.current_hole ?? null,
          holes_played: activeRound.holes_played ?? null,
        }
      : { status: 'none' },
    last_mindcoach_session: lastMindCoachSession,
    recent_justtalk_phrases: justTalkPhrases || [],
    pillar_trends: {
      focus: safeString(userPatterns?.focus_trend) || 'insufficient_data',
      confidence: safeString(userPatterns?.commitment_trend) || 'insufficient_data',
      control: safeString(userPatterns?.recovery_trend) || 'insufficient_data',
    },
    focus_confidence_control_scores: userPatterns?.pillar_scores || {},
    training_gap: safeString(trainingSummary?.training_gap) || null,
    chat_themes: (chatSummary?.themes || []).slice(0, 3),
  };
}

function buildContextCacheDocuments({
  userPatterns,
  coachingState,
  trainingSummary,
  chatSummary,
  roundSummaries,
  roundInsights,
  recentInsightHistory,
  activeRound = null,
  justTalkPhrases = [],
  lastMindCoachSession = null,
}) {
  const roundHeadlines = buildRecentRoundHeadlines(roundSummaries, roundInsights, 5);
  const recentGlobalInsights = buildRecentInsights(recentInsightHistory, 3);

  const documents = {};
  for (const surface of SURFACES) {
    let payload;
    if (surface === 'fococo_tab') {
      payload = {
        insight_inputs: buildFococoTabInsightPayload({
          userPatterns,
          coachingState,
          roundSummaries,
          activeRound,
          justTalkPhrases,
          lastMindCoachSession,
          chatSummary,
          trainingSummary,
        }),
        coaching_state: {
          active_pillar: coachingState.active_pillar,
          active_need: coachingState.active_need,
          next_best_action_label: coachingState.next_best_action_label,
        },
        last_3_rounds: roundHeadlines.slice(0, 3),
        last_3_insights: recentGlobalInsights,
      };
    } else if (surface === 'webapp_insights') {
      payload = {
        user_patterns: userPatterns,
        trends: {
          focus_trend: userPatterns.focus_trend,
          commitment_trend: userPatterns.commitment_trend,
          preparation_trend: userPatterns.preparation_trend,
          recovery_trend: userPatterns.recovery_trend,
        },
        last_5_rounds: roundHeadlines,
        last_3_insights: recentGlobalInsights,
      };
    } else if (surface === 'mindcoach') {
      payload = {
        coaching_state: coachingState,
        training_summary: trainingSummary,
        recent_round_headlines: roundHeadlines.slice(0, 3),
        recent_insights: recentGlobalInsights,
      };
    } else if (surface === 'golfchat') {
      payload = {
        user_patterns: userPatterns,
        coaching_state: coachingState,
        training_summary: trainingSummary,
        chat_summary: chatSummary,
        recent_insights: recentGlobalInsights,
      };
    } else {
      payload = {
        coaching_state: coachingState,
      };
    }

    documents[surface] = {
      user_id: userPatterns.user_id || coachingState.user_id,
      surface,
      context_hash: sha256(deterministicStringify(payload)),
      user_patterns: userPatterns,
      coaching_state: coachingState,
      training_summary: trainingSummary,
      recent_round_headlines: roundHeadlines.slice(0, surface === 'webapp_insights' ? 5 : 3),
      chat_themes: chatSummary.themes || [],
      recent_insights: recentGlobalInsights,
      payload,
      updated_at: new Date().toISOString(),
      generation_version: GENERATION_VERSION,
    };
  }
  return documents;
}

function deriveCoachingState({
  userPatterns,
  trainingSummary,
  chatSummary,
  previousCoachingState = null,
}) {
  const activePillar =
    userPatterns.primary_pillar_need?.pillar ||
    previousCoachingState?.active_pillar ||
    'focus';
  const need = deriveNeed(activePillar, userPatterns, trainingSummary);
  return {
    user_id: userPatterns.user_id || trainingSummary.user_id || chatSummary.user_id || '',
    active_pillar: activePillar,
    active_need: need.active_need,
    why_now: need.why_now,
    next_best_action_type: need.next_best_action_type,
    next_best_action_id: need.next_best_action_id,
    next_best_action_label: need.next_best_action_label,
    time_horizon: need.time_horizon,
    source_round_ids: userPatterns.source_round_ids || [],
    source_session_id: chatSummary.session_id || null,
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function deriveThinDataCoachingState(userId) {
  return {
    user_id: userId,
    active_pillar: 'focus',
    active_need: 'build baseline',
    why_now: 'There is not enough completed round data yet, so the system starts from baseline attention.',
    next_best_action_type: 'mindcoach_session',
    next_best_action_id: 'focus_one_thing',
    next_best_action_label: 'Starter Session',
    time_horizon: 'this_week',
    source_round_ids: [],
    source_session_id: null,
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function deriveThinDataUserPatterns(userId) {
  return {
    user_id: userId,
    primary_pillar_need: {
      pillar: 'focus',
      score: 0,
    },
    focus_trend: 'insufficient_data',
    commitment_trend: 'insufficient_data',
    preparation_trend: 'insufficient_data',
    recovery_trend: 'insufficient_data',
    pressure_pattern: 'insufficient_data',
    late_round_pattern: 'insufficient_data',
    mistake_recovery_pattern: 'insufficient_data',
    routine_effect: 'insufficient_data',
    top_risk_pattern: null,
    top_strength_pattern: null,
    recent_improvement_direction: 'insufficient_data',
    pillar_scores: {
      focus: 0,
      confidence: 0,
      control: 0,
    },
    source_round_ids: [],
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function deriveThinDataTrainingSummary(userId) {
  return {
    user_id: userId,
    last_7_days_count: 0,
    last_14_days_count: 0,
    focus_sessions: 0,
    confidence_sessions: 0,
    control_sessions: 0,
    completion_trend: 'inactive',
    training_gap: 'long',
    last_completed_at: null,
    source_session_ids: [],
    updated_at: new Date().toISOString(),
    generation_version: GENERATION_VERSION,
  };
}

function buildFococoTabFallbackText(contextCache) {
  const inputs = contextCache?.payload?.insight_inputs || {};
  const state = contextCache?.coaching_state || {};
  const missed = safeString(inputs.recent_missed_pattern);
  const best = safeString(inputs.recent_best_pattern);
  const goal = safeString(inputs.selected_goal?.label);
  const activeRound = inputs.active_round_status || {};
  const lastRound = inputs.last_round_summary || {};

  if (activeRound.status && activeRound.status !== 'none') {
    return `You are mid-round with attention still settling hole to hole.\n\nBefore the next shot, name one decision you already trust and stay with it through the swing.`;
  }
  if (best && missed) {
    return `${best}\n\nToday, repeat the habit behind that strength before you react to the miss that keeps returning.`;
  }
  if (missed) {
    return `${missed}\n\nToday, notice that pattern early and reset before it becomes the default reaction.`;
  }
  if (lastRound.key_pattern) {
    return `${safeString(lastRound.key_pattern)}\n\nCarry that same clarity into the first few shots today before the round speeds up.`;
  }
  if (state.active_need === 'build baseline') {
    return 'Your rounds are still too sparse for a repeated signal, but your attention drifts fastest when nothing is named before the shot.\n\nPick one cue before your first swing today and keep it for three holes.';
  }
  if (goal) {
    return `Your coaching focus is still on ${goal.toLowerCase()} because that need has not cleared yet.\n\nOpen today with one small action that matches that focus before you play.`;
  }
  return 'Your recent data is starting to hold one clearer pattern instead of several small ones.\n\nWatch whether that pattern shows up on the first tee today before the round picks up speed.';
}

module.exports = {
  FOCOCO_TAB_GENERATION_VERSION,
  GENERATION_VERSION,
  MIN_PREP_CUE_VALID_EVENTS,
  SURFACES,
  VALID_COMPLETED_CHAT_STATUSES,
  VALID_COMPLETED_MINDCOACH_STATUSES,
  average,
  buildChatSummary,
  buildContextCacheDocuments,
  buildFococoTabFallbackText,
  buildFococoTabInsightPayload,
  extractRecentJustTalkPhrases,
  summarizeLastMindCoachSession,
  buildRoundInsights,
  buildRoundSummary,
  buildRecentInsights,
  buildRecentRoundHeadlines,
  calculateLateRoundDrop,
  calculatePreparationTrend,
  calculateRecoveryScore,
  calculateRoutineEffect,
  deterministicStringify,
  deriveCoachingState,
  deriveThinDataCoachingState,
  deriveThinDataTrainingSummary,
  deriveThinDataUserPatterns,
  deriveTrainingSummary,
  deriveUserPatterns,
  differenceInDays,
  groupByRoundId,
  isCompletedChatSession,
  isCompletedMindCoachRun,
  joinCompletedMindCoachSessions,
  normalizeCaddyPlayMoment,
  normalizeCue,
  normalizeFocusLevel,
  normalizeGolfRound,
  normalizeMindCoachRun,
  normalizeMindCoachSession,
  normalizePreparation,
  normalizeShotLog,
  normalizeShotResult,
  normalizeVoiceChatMessage,
  normalizeVoiceChatSession,
  segmentForHole,
  sha256,
  sortByDateDesc,
  sortMomentsAsc,
  toDate,
  toIso,
};
