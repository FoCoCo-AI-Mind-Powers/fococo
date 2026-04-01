const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const crypto = require('crypto');

const db = admin.firestore();
const geminiKey = defineSecret('GEMINI_KEY');

const FOCOCO_DAILY_INSIGHT_TYPE = 'fococo_daily';
const FOCOCO_GENERATION_VERSION = 'fococo_tab_v1';
const GEMINI_MODEL = 'gemini-2.0-flash';
const INITIAL_PHRASE_BLACKLIST = [
  'you tend to',
  'you often',
  "you're starting to",
];
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

function ensureAuthenticated(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }
}

function ensureAdmin(request) {
  ensureAuthenticated(request);
  if (!request.auth.token.admin && !request.auth.token.content_admin) {
    throw new HttpsError('permission-denied', 'Admin privileges required');
  }
}

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'number') return new Date(value);
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function getUserTimeZone(userData) {
  const candidate = safeString(userData?.timezone);
  return candidate || 'UTC';
}

function zonedDateParts(date, timeZone) {
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'long',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const parts = formatter.formatToParts(date);
  const get = (type) => parts.find((part) => part.type === type)?.value ?? '';
  const year = Number.parseInt(get('year'), 10);
  const month = Number.parseInt(get('month'), 10);
  const day = Number.parseInt(get('day'), 10);
  const hour = Number.parseInt(get('hour'), 10);
  return {
    year,
    month,
    day,
    hour,
    weekday: get('weekday'),
    isoDate: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
  };
}

function getSeason(month) {
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  if (month >= 9 && month <= 11) return 'autumn';
  return 'winter';
}

function getTimeOfDay(hour) {
  if (hour < 6) return 'early morning';
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  if (hour < 21) return 'evening';
  return 'night';
}

function differenceInDays(from, to) {
  if (!(from instanceof Date) || !(to instanceof Date)) return null;
  return Math.max(0, Math.floor((to.getTime() - from.getTime()) / 86400000));
}

function deterministicStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map((item) => deterministicStringify(item)).join(',')}]`;
  }
  if (value && typeof value === 'object') {
    const keys = Object.keys(value).sort();
    return `{${keys
      .map((key) => `${JSON.stringify(key)}:${deterministicStringify(value[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value);
}

function md5(value) {
  return crypto.createHash('md5').update(value).digest('hex');
}

function buildDailyInsightDocId(userId, insightDate) {
  return `fococo_daily_${userId}_${insightDate}`;
}

function pickRandom(items) {
  return items[Math.floor(Math.random() * items.length)];
}

function chooseVariation(previous) {
  const toneTypes = ['observational', 'reflective', 'contrast_based'];
  const structureTypes = ['single_sentence', 'two_short_sentences', 'contrast', 'time_based'];
  const angleTypes = ['calm', 'friction', 'progress', 'awareness', 'pattern_recognition'];

  for (let attempt = 0; attempt < 12; attempt += 1) {
    const variation = {
      toneType: pickRandom(toneTypes),
      structureType: pickRandom(structureTypes),
      angleType: pickRandom(angleTypes),
    };
    if (
      !previous ||
      variation.toneType !== previous.toneType ||
      variation.structureType !== previous.structureType ||
      variation.angleType !== previous.angleType
    ) {
      return variation;
    }
  }

  return {
    toneType: 'observational',
    structureType: 'single_sentence',
    angleType: 'awareness',
  };
}

function cleanToken(token) {
  return token
    .toLowerCase()
    .replace(/[^a-z]/g, '')
    .trim();
}

function tokenize(text) {
  return safeString(text)
    .split(/\s+/)
    .map((token) => cleanToken(token))
    .filter((token) => token.length >= 4 && !STOP_WORDS.has(token));
}

function countValues(values) {
  const counts = new Map();
  for (const value of values) {
    const key = safeString(value);
    if (!key) continue;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return counts;
}

function topCountEntry(counts) {
  let bestKey = '';
  let bestCount = 0;
  for (const [key, count] of counts.entries()) {
    if (count > bestCount) {
      bestKey = key;
      bestCount = count;
    }
  }
  return { value: bestKey, count: bestCount };
}

function extractRepeatedPhrases(recentInsights) {
  if (recentInsights.length < 3) return [];

  const phraseCounts = new Map();
  for (const text of recentInsights) {
    const tokens = tokenize(text);
    const seenInInsight = new Set();
    for (let index = 0; index < tokens.length - 1; index += 1) {
      const phrase = `${tokens[index]} ${tokens[index + 1]}`;
      if (seenInInsight.has(phrase)) continue;
      seenInInsight.add(phrase);
      phraseCounts.set(phrase, (phraseCounts.get(phrase) ?? 0) + 1);
    }
  }

  return Array.from(phraseCounts.entries())
    .filter(([, count]) => count >= 3)
    .map(([phrase]) => phrase);
}

function extractTopKeywords(texts, limit = 5) {
  const counts = new Map();
  for (const text of texts) {
    for (const token of tokenize(text)) {
      counts.set(token, (counts.get(token) ?? 0) + 1);
    }
  }
  return Array.from(counts.entries())
    .sort((left, right) => right[1] - left[1])
    .slice(0, limit)
    .map(([token]) => token);
}

function classifySignalStrength(roundCount, sessionCount, golfChatUsed) {
  if (roundCount >= 2) return 'rounds_available';
  if (sessionCount >= 2) return 'mindcoach_available';
  if (golfChatUsed) return 'golfchat_available';
  return 'thin_data';
}

function inferRoundPatterns(rounds, now) {
  const rounds7 = [];
  const rounds30 = [];
  for (const round of rounds) {
    const date = toDate(round.date);
    if (!date) continue;
    const daysAgo = differenceInDays(date, now);
    if (daysAgo <= 7) rounds7.push(round);
    if (daysAgo <= 30) rounds30.push(round);
  }

  const sourceRounds = rounds7.length >= 2 ? rounds7 : rounds30;
  const cueCounts = countValues(sourceRounds.map((round) => round.bestCue));
  const courseTypeCounts = countValues(sourceRounds.map((round) => round.courseType));
  const summaryTexts = sourceRounds
    .flatMap((round) => [round.aiRoundSummary, round.technicalSummary, round.voiceTranscription])
    .map((value) => safeString(value))
    .filter(Boolean);

  const averageFocus = average(sourceRounds.map((round) => round.mindsetFocus));
  const averageConfidence = average(sourceRounds.map((round) => round.mindsetConfidence));
  const averageControl = average(sourceRounds.map((round) => round.mindsetControl));
  const pillarScores = [
    { pillar: 'focus', score: averageFocus },
    { pillar: 'confidence', score: averageConfidence },
    { pillar: 'control', score: averageControl },
  ].filter((entry) => entry.score != null);

  pillarScores.sort((left, right) => (left.score ?? 0) - (right.score ?? 0));
  const weakestPillar = pillarScores[0]?.pillar ?? '';
  const strongestPillar = pillarScores[pillarScores.length - 1]?.pillar ?? '';
  const repeatedCue = topCountEntry(cueCounts);
  const repeatedCourseType = topCountEntry(courseTypeCounts);
  const recoveryHeavy = sourceRounds.filter((round) => Array.isArray(round.recoveryHoles) && round.recoveryHoles.length > 0).length >= 2;

  return {
    totalRounds: rounds.length,
    roundsInLast7Days: rounds7.length,
    roundsInLast30Days: rounds30.length,
    recentRounds: sourceRounds.slice(0, 5).map((round) => ({
      date: zonedDateParts(toDate(round.date) ?? now, 'UTC').isoDate,
      courseName: safeString(round.courseName),
      courseType: safeString(round.courseType),
      bestCue: safeString(round.bestCue),
      aiRoundSummary: safeString(round.aiRoundSummary),
      technicalSummary: safeString(round.technicalSummary),
      voiceTranscription: safeString(round.voiceTranscription),
    })),
    patternCandidates: {
      weakestPillar,
      strongestPillar,
      repeatedBestCue: repeatedCue.count >= 2 ? repeatedCue.value : '',
      repeatedCourseType: repeatedCourseType.count >= 2 ? repeatedCourseType.value : '',
      recoveryPattern: recoveryHeavy ? 'recovers after mistakes often enough to be a pattern' : '',
      dominantKeywords: extractTopKeywords(summaryTexts, 4),
    },
  };
}

function inferMindCoachPatterns(sessions, now) {
  const sessions7 = [];
  const sessions30 = [];
  for (const session of sessions) {
    const timestamp = toDate(session.timestamp);
    if (!timestamp) continue;
    const daysAgo = differenceInDays(timestamp, now);
    if (daysAgo <= 7) sessions7.push(session);
    if (daysAgo <= 30) sessions30.push(session);
  }

  const sourceSessions = sessions7.length >= 2 ? sessions7 : sessions30;
  const routineCounts = countValues(sourceSessions.map((session) => session.routineType));
  const scenarioCounts = countValues(sourceSessions.map((session) => session.scenarioTag));
  const lengthCounts = countValues(sourceSessions.map((session) => session.deliveryLength));
  const routine = topCountEntry(routineCounts);
  const scenario = topCountEntry(scenarioCounts);
  const length = topCountEntry(lengthCounts);
  const lastSession = sourceSessions[0];

  return {
    totalSessions: sessions.length,
    sessionsInLast7Days: sessions7.length,
    sessionsInLast30Days: sessions30.length,
    recentSessions: sourceSessions.slice(0, 5).map((session) => ({
      timestamp: toDate(session.timestamp)?.toISOString() ?? '',
      routineType: safeString(session.routineType),
      scenarioTag: safeString(session.scenarioTag),
      deliveryLength: safeString(session.deliveryLength),
      cueUsed: safeString(session.cueUsed),
    })),
    patternCandidates: {
      repeatedRoutineType: routine.count >= 2 ? routine.value : '',
      repeatedScenarioTag: scenario.count >= 2 ? scenario.value : '',
      repeatedDeliveryLength: length.count >= 2 ? length.value : '',
      daysSinceLastSession: lastSession ? differenceInDays(toDate(lastSession.timestamp), now) : null,
    },
  };
}

function average(numbers) {
  const valid = numbers.filter((value) => Number.isFinite(value));
  if (!valid.length) return null;
  return valid.reduce((sum, value) => sum + value, 0) / valid.length;
}

function csvEscape(value) {
  const text = safeString(value);
  if (!text.includes(',') && !text.includes('"') && !text.includes('\n')) {
    return text;
  }
  return `"${text.replace(/"/g, '""')}"`;
}

async function fetchUserRecord(userId) {
  const userSnapshot = await db.collection('user').doc(userId).get();
  return userSnapshot.exists ? userSnapshot.data() : {};
}

async function fetchRecentFoCoCoInsights(userId, limit = 4) {
  const snapshot = await db
    .collection('ai_insights')
    .where('userId', '==', userId)
    .where('insightType', '==', FOCOCO_DAILY_INSIGHT_TYPE)
    .orderBy('createdTime', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function fetchRoundLogs(userId) {
  const snapshot = await db
    .collection('round_logs')
    .where('userId', '==', userId)
    .orderBy('date', 'desc')
    .limit(50)
    .get();

  return snapshot.docs.map((doc) => doc.data());
}

async function fetchMindCoachSessions(userId) {
  const snapshot = await db
    .collection('mindcoach_sessions')
    .where('userId', '==', userId)
    .orderBy('timestamp', 'desc')
    .limit(50)
    .get();

  return snapshot.docs.map((doc) => doc.data());
}

async function fetchGolfChatContext(userId, now) {
  let sessions = [];
  try {
    const sessionSnapshot = await db
      .collection('voice_chat_sessions')
      .where('userId', '==', userId)
      .where('sessionMetadata.surface', '==', 'golfchat')
      .orderBy('startTime', 'desc')
      .limit(8)
      .get();
    sessions = sessionSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    logger.warn('[FoCoCo] GolfChat sessions query failed', { userId, error: error.message });
    sessions = [];
  }

  let stats = {};
  try {
    const statsSnapshot = await db.collection('user_voice_chat_stats').doc(userId).get();
    stats = statsSnapshot.exists ? statsSnapshot.data() : {};
  } catch (error) {
    logger.warn('[FoCoCo] GolfChat stats read failed', { userId, error: error.message });
  }

  const recentSessions = sessions.slice(0, 3);
  const sessionMessages = await Promise.all(
    recentSessions.map(async (session) => {
      try {
        const messagesSnapshot = await db
          .collection('voice_chat_messages')
          .where('userId', '==', userId)
          .where('sessionId', '==', session.id)
          .orderBy('timestamp', 'asc')
          .get();
        return messagesSnapshot.docs.map((doc) => doc.data());
      } catch (error) {
        logger.warn('[FoCoCo] GolfChat messages query failed', {
          userId,
          sessionId: session.id,
          error: error.message,
        });
        return [];
      }
    }),
  );

  const allUserMessages = sessionMessages
    .flat()
    .filter((message) => message?.isUser === true)
    .map((message) => safeString(message.content))
    .filter(Boolean);

  const topTopics = Array.isArray(stats?.topTopics)
    ? stats.topTopics.map((topic) => safeString(topic)).filter(Boolean)
    : [];

  const lastChatDate = toDate(recentSessions[0]?.startTime);
  const chatKeywords = extractTopKeywords(allUserMessages, 5);

  return {
    used: recentSessions.length > 0 || allUserMessages.length > 0 || topTopics.length > 0,
    totalSessions: sessions.length,
    recentSessions: recentSessions.map((session) => ({
      title: safeString(session.title),
      startTime: toDate(session.startTime)?.toISOString() ?? '',
      messageCount: session.messageCount ?? 0,
    })),
    recentUserMessages: allUserMessages.slice(-8),
    patternCandidates: {
      topTopics: topTopics.slice(0, 5),
      extractedThemes: chatKeywords,
      daysSinceLastGolfChat: lastChatDate ? differenceInDays(lastChatDate, now) : null,
    },
  };
}

function buildPhraseBlacklist(recentInsights) {
  return Array.from(new Set([
    ...INITIAL_PHRASE_BLACKLIST,
    ...extractRepeatedPhrases(recentInsights),
  ]));
}

function buildContextPayload({
  userId,
  userData,
  now,
  timeZone,
  recentFoCoCoInsights,
  roundContext,
  mindCoachContext,
  golfChatContext,
  variation,
}) {
  const zoned = zonedDateParts(now, timeZone);
  const recentInsightTexts = recentFoCoCoInsights
    .map((insight) => safeString(insight.insightContent))
    .filter(Boolean)
    .slice(0, 3);

  return {
    userId,
    userProfile: {
      displayName: safeString(userData?.displayName),
      golfExperience: safeString(userData?.golfExperience),
      handicap: userData?.handicap ?? null,
      homeClub: safeString(userData?.homeClub),
      timeZone,
    },
    temporal: {
      insightDate: zoned.isoDate,
      weekday: zoned.weekday,
      season: getSeason(zoned.month),
      timeOfDay: getTimeOfDay(zoned.hour),
    },
    signalPriority: ['round_logs', 'mindcoach_sessions', 'golfchat'],
    dataSignals: {
      rounds: roundContext.totalRounds,
      mindcoachSessions: mindCoachContext.totalSessions,
      golfchatUsed: golfChatContext.used,
      dominantSource: classifySignalStrength(
        roundContext.roundsInLast30Days,
        mindCoachContext.sessionsInLast30Days,
        golfChatContext.used,
      ),
    },
    recency: {
      primaryWindowDays: 7,
      secondaryWindowDays: 30,
      lifetimeBackgroundOnly: true,
    },
    roundContext,
    mindCoachContext,
    golfChatContext,
    recentInsights: recentInsightTexts,
    phraseBlacklist: buildPhraseBlacklist(recentInsightTexts),
    variation,
  };
}

function systemPrompt(contextPayload) {
  return `
You are the MindGame System, the AI intelligence engine inside FoCoCo.
You are generating one home-screen insight for the FoCoCo tab.

LOCKED RULES:
- Maximum 2 sentences. Absolute.
- Write only in second person.
- No coaching instructions, no advice, no commands.
- No exclamation marks.
- No numbers, scores, percentages, or metrics in the final text.
- One idea only. Never combine multiple observations.
- Never sound motivational, preachy, poetic, or abstract.
- The text must feel like a quiet, accurate observation.
- It must connect mind to behaviour. The behavioural anchor can be implicit, but it must be present.
- If you do not have a repeated pattern across multiple data points, switch to thin-data mode: warm, curious, observational about beginning, presence, attention, or consistency. Do not invent trends.
- GolfChat is low-priority context only. If round patterns exist, GolfChat must not lead.
- Recent behaviour must lead. Prefer last 7 days, then last 30 days. Lifetime data is background only.

VARIATION RULES:
- Write in a ${contextPayload.variation.toneType} tone.
- Use a ${contextPayload.variation.structureType} structure.
- Focus on the emotional angle of ${contextPayload.variation.angleType}.
- Variation must never reduce truth or clarity.

ANTI-REPETITION:
- Avoid repeating themes or phrasing from the recent insights supplied in context.
- Avoid using any blacklisted phrase supplied in context.

FORMAT:
- Return plain text only.
- No labels.
- No markdown.
- No quotation marks around the answer.
`.trim();
}

function userPrompt(contextPayload) {
  return `
Context payload for today's FoCoCo tab insight:
${deterministicStringify(contextPayload)}

Choose the strongest true signal.
Lead with round behaviour if a repeated round pattern exists.
Use MindCoach only when it is the strongest repeated pattern.
Use GolfChat only for reflection theme or tone context.
Generate the insight now.
`.trim();
}

async function callGeminiForInsight(contextPayload) {
  const apiKey = geminiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Gemini key not configured');
  }

  let lastValidationError = '';
  let lastText = '';
  let lastUsage = {};

  for (let attempt = 0; attempt < 2; attempt += 1) {
    const extraReminder =
      attempt === 0
        ? ''
        : `\nThe previous draft failed validation because: ${lastValidationError}. Rewrite with exact compliance.`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: {
            parts: [{ text: `${systemPrompt(contextPayload)}${extraReminder}` }],
          },
          contents: [
            {
              role: 'user',
              parts: [{ text: userPrompt(contextPayload) }],
            },
          ],
          generationConfig: {
            temperature: 0.8,
            maxOutputTokens: 120,
            topP: 0.95,
          },
        }),
      },
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new HttpsError('internal', `Gemini request failed: ${response.status} ${errorText}`);
    }

    const payload = await response.json();
    lastUsage = payload.usageMetadata ?? {};
    const text =
      payload?.candidates?.[0]?.content?.parts?.map((part) => part?.text ?? '').join(' ').trim() ?? '';

    lastText = normalizeInsightText(text);
    lastValidationError = validateInsightText(lastText);
    if (!lastValidationError) {
      return {
        insightText: lastText,
        tokensUsed: lastUsage.totalTokenCount ?? 0,
        rawResponse: payload,
      };
    }
  }

  if (lastText) {
    return {
      insightText: lastText,
      tokensUsed: lastUsage.totalTokenCount ?? 0,
      rawResponse: { validationWarning: lastValidationError },
    };
  }

  throw new HttpsError('internal', 'Gemini returned no usable FoCoCo insight');
}

function normalizeInsightText(text) {
  const cleaned = safeString(text)
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/\s+/g, ' ')
    .replace(/!/g, '')
    .trim()
    .replace(/^"+|"+$/g, '');

  const sentences = cleaned
    .split(/(?<=[.!?])\s+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean);

  if (sentences.length <= 2) {
    return cleaned;
  }
  return sentences.slice(0, 2).join(' ').trim();
}

function validateInsightText(text) {
  if (!text) return 'empty_output';
  if (/\d/.test(text)) return 'contains_numbers';
  if (text.includes('!')) return 'contains_exclamation';
  const lower = text.toLowerCase();
  if (lower.startsWith('your mindgame system') || lower.startsWith('mindgame system')) {
    return 'self_reference';
  }
  const sentences = text
    .split(/(?<=[.!?])\s+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean);
  if (sentences.length > 2) return 'too_many_sentences';
  return '';
}

function serializeFoCoCoInsight(doc) {
  const data = doc.data();
  return {
    insightId: doc.id,
    insightText: safeString(data?.insightContent),
    insightDate: safeString(data?.insightDate),
    playedAudio: data?.playedAudio === true,
    opened: data?.opened === true,
    timeOnScreenSec: Number(data?.timeOnScreenSec ?? 0),
    generationVersion: safeString(data?.generationVersion, FOCOCO_GENERATION_VERSION),
  };
}

function buildExportRow(doc) {
  const data = doc.data();
  return {
    insightId: doc.id,
    userId: safeString(data.userId),
    date: safeString(data.insightDate),
    insightText: safeString(data.insightContent),
    contextPayloadHash: safeString(data.contextPayloadHash),
    rounds: Number(data?.dataSignals?.rounds ?? 0),
    mindcoachSessions: Number(data?.dataSignals?.mindcoachSessions ?? 0),
    golfchatUsed: data?.dataSignals?.golfchatUsed === true,
    opened: data?.opened === true,
    playedAudio: data?.playedAudio === true,
    timeOnScreenSec: Number(data?.timeOnScreenSec ?? 0),
    variationToneType: safeString(data?.variationToneType),
    variationStructureType: safeString(data?.variationStructureType),
    variationAngleType: safeString(data?.variationAngleType),
    generationVersion: safeString(data?.generationVersion),
    createdTime: toDate(data?.createdTime)?.toISOString() ?? '',
  };
}

function buildCsv(rows) {
  const headers = [
    'insightId',
    'userId',
    'date',
    'insightText',
    'contextPayloadHash',
    'rounds',
    'mindcoachSessions',
    'golfchatUsed',
    'opened',
    'playedAudio',
    'timeOnScreenSec',
    'variationToneType',
    'variationStructureType',
    'variationAngleType',
    'generationVersion',
    'createdTime',
  ];
  const lines = [
    headers.join(','),
    ...rows.map((row) => headers.map((header) => csvEscape(row[header])).join(',')),
  ];
  return lines.join('\n');
}

exports.getOrCreateFoCoCoDailyInsight = onCall(
  { secrets: [geminiKey], timeoutSeconds: 60 },
  async (request) => {
    ensureAuthenticated(request);
    const userId = request.auth.uid;
    const now = new Date();

    const userData = await fetchUserRecord(userId);
    const timeZone = getUserTimeZone(userData);
    const insightDate = zonedDateParts(now, timeZone).isoDate;
    const docRef = db.collection('ai_insights').doc(buildDailyInsightDocId(userId, insightDate));

    const existingSnapshot = await docRef.get();
    if (existingSnapshot.exists) {
      return serializeFoCoCoInsight(existingSnapshot);
    }

    const [
      recentFoCoCoInsights,
      rounds,
      sessions,
      golfChatContext,
    ] = await Promise.all([
      fetchRecentFoCoCoInsights(userId, 4),
      fetchRoundLogs(userId),
      fetchMindCoachSessions(userId),
      fetchGolfChatContext(userId, now),
    ]);

    const previousVariation = recentFoCoCoInsights[0]
      ? {
          toneType: safeString(recentFoCoCoInsights[0].variationToneType),
          structureType: safeString(recentFoCoCoInsights[0].variationStructureType),
          angleType: safeString(recentFoCoCoInsights[0].variationAngleType),
        }
      : null;
    const variation = chooseVariation(previousVariation);
    const roundContext = inferRoundPatterns(rounds, now);
    const mindCoachContext = inferMindCoachPatterns(sessions, now);
    const contextPayload = buildContextPayload({
      userId,
      userData,
      now,
      timeZone,
      recentFoCoCoInsights,
      roundContext,
      mindCoachContext,
      golfChatContext,
      variation,
    });

    const contextPayloadHash = md5(deterministicStringify(contextPayload));
    const startedAt = Date.now();
    const geminiResult = await callGeminiForInsight(contextPayload);
    const nowTimestamp = admin.firestore.Timestamp.now();
    const createdData = {
      userId,
      sourceId: insightDate,
      sourceType: 'fococo_tab',
      insightType: FOCOCO_DAILY_INSIGHT_TYPE,
      category: 'daily_mirror',
      priority: 'medium',
      insightTitle: 'Daily Insight',
      insightContent: geminiResult.insightText,
      keyPoints: [],
      recommendations: [],
      personalizedElements: [],
      isRead: false,
      userRating: 0,
      userFeedback: '',
      actionsTaken: [],
      generatedTime: nowTimestamp,
      aiModel: GEMINI_MODEL,
      promptUsed: FOCOCO_GENERATION_VERSION,
      rawAiResponse: JSON.stringify(geminiResult.rawResponse ?? {}),
      processingTime: Date.now() - startedAt,
      tokensUsed: Number(geminiResult.tokensUsed ?? 0),
      costPerInsight: 0,
      generationVersion: FOCOCO_GENERATION_VERSION,
      status: 'active',
      expiryDate: admin.firestore.Timestamp.fromDate(
        new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000),
      ),
      viewCount: 0,
      shareCount: 0,
      relatedInsights: recentFoCoCoInsights.map((insight) => insight.id).slice(0, 3),
      followUpGenerated: false,
      createdTime: admin.firestore.FieldValue.serverTimestamp(),
      updatedTime: admin.firestore.FieldValue.serverTimestamp(),
      insightDate,
      contextPayloadHash,
      dataSignals: contextPayload.dataSignals,
      variationToneType: variation.toneType,
      variationStructureType: variation.structureType,
      variationAngleType: variation.angleType,
      opened: false,
      playedAudio: false,
      timeOnScreenSec: 0,
    };

    try {
      await docRef.create(createdData);
    } catch (error) {
      logger.warn('[FoCoCo] Daily insight create raced with another request', {
        userId,
        insightDate,
        error: error.message,
      });
    }

    const createdSnapshot = await docRef.get();
    if (!createdSnapshot.exists) {
      throw new HttpsError('internal', 'FoCoCo daily insight was not persisted');
    }

    logger.info('[FoCoCo] Daily insight ready', {
      userId,
      insightDate,
      variation,
      dataSignals: contextPayload.dataSignals,
    });

    return serializeFoCoCoInsight(createdSnapshot);
  },
);

exports.exportFoCoCoDailyInsightsReview = onCall(async (request) => {
  ensureAdmin(request);

  const format = safeString(request.data?.format).toLowerCase() === 'csv' ? 'csv' : 'json';
  const limit = Math.max(1, Math.min(Number(request.data?.limit ?? 200), 500));
  const startDate = safeString(request.data?.startDate);
  const endDate = safeString(request.data?.endDate);

  const snapshot = await db
    .collection('ai_insights')
    .where('insightType', '==', FOCOCO_DAILY_INSIGHT_TYPE)
    .orderBy('createdTime', 'desc')
    .limit(limit)
    .get();

  const rows = snapshot.docs
    .map((doc) => buildExportRow(doc))
    .filter((row) => (!startDate || row.date >= startDate) && (!endDate || row.date <= endDate));

  if (format === 'csv') {
    return {
      format: 'csv',
      rowCount: rows.length,
      csv: buildCsv(rows),
    };
  }

  return {
    format: 'json',
    rowCount: rows.length,
    items: rows,
  };
});
