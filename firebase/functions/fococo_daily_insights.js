const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const {
  FOCOCO_TAB_GENERATION_VERSION,
  buildFococoTabFallbackText,
  deterministicStringify,
} = require('./intelligence_engine');
const {
  COLLECTIONS,
  FOCOCO_TAB_SURFACE,
  buildInsightHistoryDocId,
  ensureContextCacheForSurface,
  fetchRecentInsightHistory,
  hasValidatedRepeatedSignal,
} = require('./intelligence_layer');

const geminiKey = defineSecret('GEMINI_KEY_APP');

const FOCOCO_DAILY_INSIGHT_TYPE = 'fococo_daily';
const GEMINI_MODEL = 'gemini-3.1-pro-preview';
const THINKING_BUDGET_TOKENS = 2048;
const INITIAL_PHRASE_BLACKLIST = [
  'you tend to',
  'you often',
  "you're starting to",
  'mindgame system',
  'unlock your',
  'elevate your',
  'every round builds',
  'you\'ve got this',
];
const GENERIC_COPY_BANNED = [
  'mindgame system',
  'unlock your',
  'elevate your',
  'your journey',
  'remember that',
  'you\'ve got this',
  'every round builds',
  'mental performance journey',
];

const FOCOCO_INSIGHT_RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    observation: {
      type: 'string',
      description:
        'One complete second-person observation sentence grounded in insight_inputs.',
    },
    direction: {
      type: 'string',
      description: 'One complete second-person practical direction sentence for today.',
    },
  },
  required: ['observation', 'direction'],
};
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

function getDb() {
  return admin.firestore();
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

function safeNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
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

async function fetchUserRecord(userId) {
  const userSnapshot = await getDb().collection('user').doc(userId).get();
  return userSnapshot.exists ? userSnapshot.data() || {} : {};
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

function buildPhraseBlacklist(recentInsights) {
  return Array.from(
    new Set([
      ...INITIAL_PHRASE_BLACKLIST,
      ...extractRepeatedPhrases(recentInsights),
    ]),
  );
}

function buildGenerationContext({
  userId,
  userData,
  timeZone,
  now,
  contextDocument,
  recentHistory,
  variation,
}) {
  const zoned = zonedDateParts(now, timeZone);
  const recentInsightTexts = recentHistory
    .map((entry) => safeString(entry.insight_text))
    .filter(Boolean)
    .slice(0, 4);

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
    repeatedSignalValidated: hasValidatedRepeatedSignal(contextDocument),
    contextHash: safeString(contextDocument.context_hash),
    dataSignals: contextDocument.data_signals || {},
    coachingState: contextDocument.coaching_state || {},
    recentRoundHeadlines: contextDocument.recent_round_headlines || [],
    recentInsights: recentInsightTexts,
    phraseBlacklist: buildPhraseBlacklist(recentInsightTexts),
    variation,
    payload: contextDocument.payload || {},
    insight_inputs: contextDocument.payload?.insight_inputs || {},
  };
}

function systemPrompt(contextPayload) {
  return `
You are the FoCoCo intelligence layer generating one FoCoCo Tab daily insight.

LOCKED RULES:
- Output exactly two complete sentences on two lines separated by one blank line (line break between them).
- Line 1: one personal observation grounded in insight_inputs (last round, pillars, patterns, goal, active round, MindCoach, JustTalk, trends).
- Line 2: one practical direction for today — concrete and calm, not hype.
- Use only second person.
- No generic motivation, marketing copy, branding, or incomplete sentences.
- No exclamation marks.
- No numbers, scores, percentages, or explicit metrics in the final text.
- One real pattern only on line 1. Do not stack multiple unrelated ideas.
- Do not claim a repeated pattern unless repeatedSignalValidated is true.
- If repeatedSignalValidated is false, stay observational and baseline-focused using only what insight_inputs actually contain.
- Prefer round and JustTalk signals over chat themes when both exist.
- Avoid phraseBlacklist and recentInsights wording.

FORMAT:
- Plain text only.
- No labels, markdown, or quotation marks.
`.trim();
}

function userPrompt(contextPayload) {
  return `
Use this context for today's FoCoCo Tab insight:
${deterministicStringify(contextPayload)}

Select the strongest true pattern from the payload.
If contextHash has already produced a reusable observation, the caller will reuse it separately.
Generate the text now.
`.trim();
}

function isCompleteSentence(sentence) {
  const trimmed = safeString(sentence);
  if (trimmed.length < 12) return false;
  if (!/[.!?]$/.test(trimmed)) return false;
  if (/\b(and|but|or|when|because|that|which|the|your|to|for|with)\s*$/i.test(trimmed)) {
    return false;
  }
  return true;
}

function splitInsightSentences(text) {
  const lineChunks = safeString(text)
    .split(/\n+/)
    .map((chunk) => chunk.trim())
    .filter(Boolean);
  if (lineChunks.length >= 2) {
    return lineChunks.slice(0, 2);
  }
  return safeString(text)
    .split(/(?<=[.!?])\s+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean)
    .slice(0, 2);
}

function normalizeInsightText(text) {
  const cleaned = safeString(text)
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/!/g, '')
    .trim()
    .replace(/^"+|"+$/g, '');

  const sentences = splitInsightSentences(cleaned);
  if (sentences.length >= 2) {
    return `${sentences[0]}\n\n${sentences[1]}`.trim();
  }
  return cleaned.replace(/\s+/g, ' ').trim();
}

function validateInsightText(text) {
  if (!text) return 'empty_output';
  if (/\d/.test(text)) return 'contains_numbers';
  if (text.includes('!')) return 'contains_exclamation';

  const lower = text.toLowerCase();
  if (lower.startsWith('your mindgame system') || lower.startsWith('mindgame system')) {
    return 'self_reference';
  }
  for (const banned of GENERIC_COPY_BANNED) {
    if (lower.includes(banned)) return 'generic_copy';
  }

  const sentences = splitInsightSentences(text);
  if (sentences.length !== 2) return 'needs_exactly_two_sentences';
  for (const sentence of sentences) {
    if (!isCompleteSentence(sentence)) return 'incomplete_sentence';
  }
  return '';
}

function parseJsonFromModelText(text) {
  const raw = safeString(text);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (_) {
    const fenced = raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
    if (fenced) {
      try {
        return JSON.parse(fenced[1].trim());
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}

function insightTextFromStructuredPayload(parsed) {
  if (!parsed || typeof parsed !== 'object') return '';
  const observation = safeString(parsed.observation || parsed.line1 || parsed.line_1);
  const direction = safeString(parsed.direction || parsed.line2 || parsed.line_2);
  if (!observation || !direction) return '';
  return normalizeInsightText(`${observation}\n\n${direction}`);
}

function coerceInsightTextFromModelOutput(rawText) {
  const fromStructured = insightTextFromStructuredPayload(parseJsonFromModelText(rawText));
  if (fromStructured && validateInsightText(fromStructured) === '') {
    return fromStructured;
  }
  return normalizeInsightText(rawText);
}

function extractModelTextFromGeminiPayload(payload) {
  return (
    payload?.candidates?.[0]?.content?.parts
      ?.filter((part) => part && part.thought !== true)
      .map((part) => part?.text ?? '')
      .join(' ')
      .trim() || ''
  );
}

function buildGeminiInsightGenerationConfig(useStructuredOutput) {
  const generationConfig = {
    temperature: 0.55,
    maxOutputTokens: 280,
    topP: 0.9,
    thinkingConfig: {
      thinkingBudget: THINKING_BUDGET_TOKENS,
    },
  };
  if (useStructuredOutput) {
    generationConfig.responseMimeType = 'application/json';
    generationConfig.responseSchema = FOCOCO_INSIGHT_RESPONSE_SCHEMA;
  }
  return generationConfig;
}

function isStructuredOutputUnsupported(status, errorText) {
  if (status !== 400) return false;
  const lower = safeString(errorText).toLowerCase();
  return (
    lower.includes('responsemime') ||
    lower.includes('responseschema') ||
    lower.includes('response schema') ||
    lower.includes('unknown name') ||
    lower.includes('invalid json schema')
  );
}

async function requestGeminiInsightGeneration({
  apiKey,
  contextPayload,
  extraReminder,
  useStructuredOutput,
}) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
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
        generationConfig: buildGeminiInsightGenerationConfig(useStructuredOutput),
      }),
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    return {
      ok: false,
      status: response.status,
      errorText,
      payload: null,
    };
  }

  const payload = await response.json();
  return {
    ok: true,
    status: response.status,
    errorText: '',
    payload,
  };
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

    let geminiResult = await requestGeminiInsightGeneration({
      apiKey,
      contextPayload,
      extraReminder,
      useStructuredOutput: true,
    });

    if (
      !geminiResult.ok &&
      isStructuredOutputUnsupported(geminiResult.status, geminiResult.errorText)
    ) {
      logger.warn('[FoCoCo] structured insight output unavailable, falling back to plain text', {
        status: geminiResult.status,
      });
      geminiResult = await requestGeminiInsightGeneration({
        apiKey,
        contextPayload,
        extraReminder,
        useStructuredOutput: false,
      });
    }

    if (!geminiResult.ok) {
      throw new HttpsError(
        'internal',
        `Gemini request failed: ${geminiResult.status} ${geminiResult.errorText}`,
      );
    }

    const payload = geminiResult.payload;
    lastUsage = payload.usageMetadata ?? {};
    const rawText = extractModelTextFromGeminiPayload(payload);
    lastText = coerceInsightTextFromModelOutput(rawText);
    lastValidationError = validateInsightText(lastText);
    if (!lastValidationError) {
      return {
        insightText: lastText,
        tokensUsed: lastUsage.totalTokenCount ?? 0,
        rawResponse: payload,
      };
    }
  }

  if (lastText && lastValidationError) {
    throw new HttpsError(
      'internal',
      `FoCoCo insight validation failed: ${lastValidationError}`,
    );
  }

  throw new HttpsError('internal', 'Gemini returned no usable FoCoCo insight');
}

function serializeHistoryInsight(docId, data) {
  return {
    insightId: docId,
    insightText: safeString(data?.insight_text || data?.insightContent),
    insightDate: safeString(data?.date || data?.insightDate),
    playedAudio: data?.played_audio === true || data?.playedAudio === true,
    opened: data?.opened === true,
    timeOnScreenSec: safeNumber(data?.time_on_screen_sec ?? data?.timeOnScreenSec, 0),
    generationVersion: safeString(
      data?.generation_version || data?.generationVersion,
      FOCOCO_TAB_GENERATION_VERSION,
    ),
  };
}

function buildCanonicalHistoryDoc({
  userId,
  insightDate,
  contextDocument,
  insightText,
  generationMode,
  aiModel,
  tokensUsed,
  rawResponse,
  variation,
}) {
  return {
    user_id: userId,
    surface: FOCOCO_TAB_SURFACE,
    date: insightDate,
    context_hash: safeString(contextDocument.context_hash),
    context_payload: contextDocument.payload || {},
    insight_text: insightText,
    generation_version: FOCOCO_TAB_GENERATION_VERSION,
    generation_mode: generationMode,
    ai_model: aiModel || null,
    tokens_used: safeNumber(tokensUsed, 0),
    raw_ai_response: rawResponse ? JSON.stringify(rawResponse) : '',
    variation_tone_type: safeString(variation?.toneType),
    variation_structure_type: safeString(variation?.structureType),
    variation_angle_type: safeString(variation?.angleType),
    data_signals: contextDocument.data_signals || {},
    repeated_signal_validated: hasValidatedRepeatedSignal(contextDocument),
    opened: false,
    played_audio: false,
    time_on_screen_sec: 0,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };
}

function buildLegacyInsightMirror(historyDoc) {
  const createdDate = toDate(historyDoc.created_at) || new Date();
  return {
    userId: historyDoc.user_id,
    sourceId: historyDoc.date,
    sourceType: FOCOCO_TAB_SURFACE,
    insightType: FOCOCO_DAILY_INSIGHT_TYPE,
    category: 'daily_mirror',
    priority: 'medium',
    insightTitle: 'Daily Insight',
    insightContent: historyDoc.insight_text,
    keyPoints: [],
    recommendations: [],
    personalizedElements: [],
    isRead: false,
    userRating: 0,
    userFeedback: '',
    actionsTaken: [],
    generatedTime: admin.firestore.Timestamp.fromDate(createdDate),
    aiModel: historyDoc.ai_model || GEMINI_MODEL,
    promptUsed: FOCOCO_TAB_GENERATION_VERSION,
    rawAiResponse: historyDoc.raw_ai_response || '',
    processingTime: 0,
    tokensUsed: safeNumber(historyDoc.tokens_used, 0),
    costPerInsight: 0,
    generationVersion: historyDoc.generation_version,
    status: 'active',
    expiryDate: admin.firestore.Timestamp.fromDate(
      new Date(createdDate.getTime() + 90 * 24 * 60 * 60 * 1000),
    ),
    viewCount: 0,
    shareCount: 0,
    relatedInsights: [],
    followUpGenerated: false,
    createdTime: admin.firestore.FieldValue.serverTimestamp(),
    updatedTime: admin.firestore.FieldValue.serverTimestamp(),
    insightDate: historyDoc.date,
    contextPayloadHash: historyDoc.context_hash,
    dataSignals: historyDoc.data_signals || {},
    variationToneType: historyDoc.variation_tone_type,
    variationStructureType: historyDoc.variation_structure_type,
    variationAngleType: historyDoc.variation_angle_type,
    opened: historyDoc.opened === true,
    playedAudio: historyDoc.played_audio === true,
    timeOnScreenSec: safeNumber(historyDoc.time_on_screen_sec, 0),
  };
}

async function mirrorHistoryToLegacy(docId, historyDoc) {
  await getDb().collection('ai_insights').doc(docId).set(buildLegacyInsightMirror(historyDoc), {
    merge: true,
  });
}

async function readExistingLegacyInsight(docId) {
  const snapshot = await getDb().collection('ai_insights').doc(docId).get();
  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data() || {};
  if (safeString(data.insightType) !== FOCOCO_DAILY_INSIGHT_TYPE) {
    return null;
  }

  return {
    id: snapshot.id,
    data,
  };
}

function migrateLegacyInsightToHistory(legacyInsight, userId, insightDate) {
  const data = legacyInsight.data;
  return {
    user_id: userId,
    surface: FOCOCO_TAB_SURFACE,
    date: insightDate,
    context_hash: safeString(data.contextPayloadHash),
    context_payload: {},
    insight_text: safeString(data.insightContent),
    generation_version: safeString(data.generationVersion, FOCOCO_TAB_GENERATION_VERSION),
    generation_mode: 'legacy_migrated',
    ai_model: safeString(data.aiModel),
    tokens_used: safeNumber(data.tokensUsed, 0),
    raw_ai_response: safeString(data.rawAiResponse),
    variation_tone_type: safeString(data.variationToneType),
    variation_structure_type: safeString(data.variationStructureType),
    variation_angle_type: safeString(data.variationAngleType),
    data_signals: data.dataSignals || {},
    repeated_signal_validated: !!safeString(data.contextPayloadHash),
    opened: data.opened === true,
    played_audio: data.playedAudio === true,
    time_on_screen_sec: safeNumber(data.timeOnScreenSec, 0),
    created_at: toDate(data.createdTime)?.toISOString() || new Date().toISOString(),
    updated_at: toDate(data.updatedTime)?.toISOString() || new Date().toISOString(),
  };
}

function findReusableInsight(recentHistory, contextHash) {
  return recentHistory.find((entry) => safeString(entry.context_hash) === safeString(contextHash)) || null;
}

function buildExportRow(doc) {
  return {
    insightId: doc.id,
    userId: safeString(doc.user_id),
    date: safeString(doc.date),
    insightText: safeString(doc.insight_text),
    contextHash: safeString(doc.context_hash),
    rounds: safeNumber(doc.data_signals?.rounds, 0),
    mindcoachSessions: safeNumber(doc.data_signals?.mindcoach_sessions, 0),
    golfchatMessages: safeNumber(doc.data_signals?.golfchat_messages, 0),
    repeatedSignalValidated: doc.repeated_signal_validated === true,
    generationMode: safeString(doc.generation_mode),
    opened: doc.opened === true,
    playedAudio: doc.played_audio === true,
    timeOnScreenSec: safeNumber(doc.time_on_screen_sec, 0),
    generationVersion: safeString(doc.generation_version),
    createdAt: safeString(doc.created_at),
  };
}

function csvEscape(value) {
  const text = safeString(value);
  if (!text.includes(',') && !text.includes('"') && !text.includes('\n')) {
    return text;
  }
  return `"${text.replace(/"/g, '""')}"`;
}

function buildCsv(rows) {
  const headers = [
    'insightId',
    'userId',
    'date',
    'insightText',
    'contextHash',
    'rounds',
    'mindcoachSessions',
    'golfchatMessages',
    'repeatedSignalValidated',
    'generationMode',
    'opened',
    'playedAudio',
    'timeOnScreenSec',
    'generationVersion',
    'createdAt',
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
    const historyDocId = buildInsightHistoryDocId(userId, FOCOCO_TAB_SURFACE, insightDate);
    const historyRef = getDb().collection(COLLECTIONS.insightHistory).doc(historyDocId);

    const existingHistorySnapshot = await historyRef.get();
    if (existingHistorySnapshot.exists) {
      const existingHistory = existingHistorySnapshot.data() || {};
      const existingVersion = safeString(
        existingHistory.generation_version || existingHistory.generationVersion,
      );
      if (existingVersion === FOCOCO_TAB_GENERATION_VERSION) {
        return serializeHistoryInsight(historyDocId, existingHistory);
      }
      logger.info('[FoCoCo] regenerating daily insight for new generation version', {
        userId,
        insightDate,
        previousVersion: existingVersion,
        nextVersion: FOCOCO_TAB_GENERATION_VERSION,
      });
    }

    const legacyInsight = await readExistingLegacyInsight(historyDocId);
    if (legacyInsight) {
      const migratedHistory = migrateLegacyInsightToHistory(legacyInsight, userId, insightDate);
      await historyRef.set(migratedHistory, { merge: true });
      return serializeHistoryInsight(historyDocId, migratedHistory);
    }

    const [contextDocument, recentHistory] = await Promise.all([
      ensureContextCacheForSurface(userId, FOCOCO_TAB_SURFACE),
      fetchRecentInsightHistory(userId, FOCOCO_TAB_SURFACE, 6),
    ]);

    const previousVariation = recentHistory[0]
      ? {
          toneType: safeString(recentHistory[0].variation_tone_type),
          structureType: safeString(recentHistory[0].variation_structure_type),
          angleType: safeString(recentHistory[0].variation_angle_type),
        }
      : null;
    const variation = chooseVariation(previousVariation);
    const reusableInsight = findReusableInsight(recentHistory, contextDocument.context_hash);

    let historyDoc;
    if (reusableInsight) {
      historyDoc = buildCanonicalHistoryDoc({
        userId,
        insightDate,
        contextDocument,
        insightText: safeString(reusableInsight.insight_text),
        generationMode: 'reused_same_context',
        aiModel: reusableInsight.ai_model || null,
        tokensUsed: 0,
        rawResponse: null,
        variation,
      });
    } else {
      const generationContext = buildGenerationContext({
        userId,
        userData,
        timeZone,
        now,
        contextDocument,
        recentHistory,
        variation,
      });
      try {
        const geminiResult = await callGeminiForInsight(generationContext);
        historyDoc = buildCanonicalHistoryDoc({
          userId,
          insightDate,
          contextDocument,
          insightText: geminiResult.insightText,
          generationMode: 'gemini',
          aiModel: GEMINI_MODEL,
          tokensUsed: geminiResult.tokensUsed,
          rawResponse: geminiResult.rawResponse,
          variation,
        });
      } catch (error) {
        logger.error('[FoCoCo] gemini generation failed, using deterministic fallback', {
          userId,
          insightDate,
          contextHash: contextDocument.context_hash,
          error: error?.message || String(error),
        });
        historyDoc = buildCanonicalHistoryDoc({
          userId,
          insightDate,
          contextDocument,
          insightText: buildFococoTabFallbackText(contextDocument),
          generationMode: 'gemini_failed_fallback',
          aiModel: null,
          tokensUsed: 0,
          rawResponse: {
            fallbackReason: error?.message || String(error),
          },
          variation,
        });
      }
    }

    try {
      await historyRef.create(historyDoc);
    } catch (error) {
      logger.warn('[FoCoCo] insight history create raced with another request', {
        userId,
        insightDate,
        error: error.message,
      });
    }

    const createdHistorySnapshot = await historyRef.get();
    if (!createdHistorySnapshot.exists) {
      throw new HttpsError('internal', 'FoCoCo daily insight was not persisted');
    }

    const createdHistory = createdHistorySnapshot.data() || historyDoc;
    try {
      await mirrorHistoryToLegacy(historyDocId, createdHistory);
    } catch (error) {
      // History is the source of truth; legacy mirror failure must not fail the call.
      logger.error('[FoCoCo] legacy mirror write failed', {
        userId,
        insightDate,
        error: error?.message || String(error),
      });
    }

    logger.info('[FoCoCo] daily insight ready', {
      userId,
      insightDate,
      contextHash: createdHistory.context_hash,
      generationMode: createdHistory.generation_mode,
    });

    return serializeHistoryInsight(historyDocId, createdHistory);
  },
);

exports.exportFoCoCoDailyInsightsReview = onCall(async (request) => {
  ensureAdmin(request);

  const format = safeString(request.data?.format).toLowerCase() === 'csv' ? 'csv' : 'json';
  const limit = Math.max(1, Math.min(safeNumber(request.data?.limit, 200), 500));
  const startDate = safeString(request.data?.startDate);
  const endDate = safeString(request.data?.endDate);

  const db = getDb();
  const snapshot = await db
    .collection(COLLECTIONS.insightHistory)
    .where('surface', '==', FOCOCO_TAB_SURFACE)
    .orderBy('created_at', 'desc')
    .limit(limit)
    .get();

  const rows = snapshot.docs
    .map((doc) => buildExportRow({ id: doc.id, ...doc.data() }))
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

module.exports._private = {
  buildCanonicalHistoryDoc,
  buildGenerationContext,
  buildGeminiInsightGenerationConfig,
  buildLegacyInsightMirror,
  buildPhraseBlacklist,
  coerceInsightTextFromModelOutput,
  findReusableInsight,
  insightTextFromStructuredPayload,
  isCompleteSentence,
  isStructuredOutputUnsupported,
  migrateLegacyInsightToHistory,
  normalizeInsightText,
  serializeHistoryInsight,
  splitInsightSentences,
  validateInsightText,
};
