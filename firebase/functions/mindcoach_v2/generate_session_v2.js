const fs = require('fs');
const path = require('path');
const axios = require('axios');
const functions = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

const {
  SCHEMA_VERSION,
  PROMPT_VERSION,
  FALLBACK_TEMPLATE_ID,
  VALID_CONTEXT_MODES,
  VALID_ENTRY_SOURCES,
  VALID_MINDSET_VALUES,
  VALID_DELIVERY_LENGTHS,
  VALID_TONES,
  VALID_VARK,
  CONTENT_LIBRARY_EXPECTED_ROWS,
  TEMPLATE_IDS,
  TEMPLATES_JSON_PATH,
  CONTENT_LIBRARY_CSV_PATH,
  SCENARIO_TAGS_CSV_PATH,
} = require('./contracts_v2');
const { getMindCoachSessionDefinition } = require('./catalog_v2');
const { resolveContextMode } = require('./context_resolver_v2');
const { chooseTemplate } = require('./template_selector_v2');
const { selectContent, normalizeLength } = require('./content_selector_v2');
const { validateAndCorrect } = require('./runtime_validator_v2');
const {
  parseCsvFile,
  validateContentLibraryIntegrity,
} = require('./csv_utils_v2');

const db = admin.firestore();
const GEMINI_KEY_SECRET = defineSecret('GEMINI_KEY_APP');

let promptCache = null;
let templatesCache = null;
let contentCache = null;
let scenarioCache = null;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function sanitizeForFirestore(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => sanitizeForFirestore(item))
      .filter((item) => item !== undefined);
  }
  if (value && typeof value === 'object') {
    const out = {};
    for (const [key, item] of Object.entries(value)) {
      const sanitized = sanitizeForFirestore(item);
      if (sanitized !== undefined) {
        out[key] = sanitized;
      }
    }
    return out;
  }
  return value === undefined ? undefined : value;
}

function getGeminiApiKeySafe() {
  try {
    return GEMINI_KEY_SECRET.value() || process.env.GEMINI_KEY_APP || '';
  } catch (error) {
    logger.warn('[MCv2:gemini] failed reading GEMINI_KEY_APP secret, falling back to env', {
      error: error.message,
    });
    return process.env.GEMINI_KEY_APP || '';
  }
}

const FALLBACK_TEMPLATES = [
  {
    id: 'MC_T01_PRE_ROUND_CLARITY',
    name: 'Pre-Round Clarity',
    allowed_routine_types: ['⏳ Pre-Round'],
    allowed_cues: ['😮‍💨 Deep Breath', '🎯 Visualization', '🗣️ Trigger Word'],
    delivery_lengths: ['micro_15s', 'standard_45s', 'deep_2m'],
    primary_pillar: 'FOCUS',
  },
  {
    id: 'MC_T02_PRE_SHOT_FOCUS',
    name: 'Pre-Shot Focus',
    allowed_routine_types: ['📐 Pre-Shot'],
    allowed_cues: ['🎯 Visualization', '🗣️ Trigger Word', '💬 Self-Talk'],
    delivery_lengths: ['micro_10s', 'standard_30s', 'deep_90s'],
    primary_pillar: 'FOCUS',
  },
  {
    id: 'MC_T03_BETWEEN_SHOTS_RESET',
    name: 'Between-Shots Reset',
    allowed_routine_types: ['🚶 Between Shots'],
    allowed_cues: ['🔄 Reset', '😮‍💨 Deep Breath'],
    delivery_lengths: ['micro_10s', 'standard_30s', 'deep_60s'],
    primary_pillar: 'CONTROL',
  },
  {
    id: 'MC_T04_POST_SHOT_LETTING_GO',
    name: 'Post-Shot Letting Go',
    allowed_routine_types: ['🧘 Post-Shot'],
    allowed_cues: ['✋ Letting Go', '🔄 Reset', '😮‍💨 Deep Breath'],
    delivery_lengths: ['micro_8s', 'standard_25s', 'deep_60s'],
    primary_pillar: 'CONTROL',
  },
  {
    id: 'MC_T05_MISTAKE_RECOVERY',
    name: 'Mistake Recovery',
    allowed_routine_types: ['🧘 Post-Shot', '🚶 Between Shots'],
    allowed_cues: ['🔄 Reset', '💬 Self-Talk', '✋ Letting Go'],
    delivery_lengths: ['micro_15s', 'standard_45s', 'deep_2m'],
    primary_pillar: 'CONTROL',
  },
  {
    id: 'MC_T06_PRESSURE_MOMENTS',
    name: 'Pressure Moments',
    allowed_routine_types: ['📐 Pre-Shot', '🚶 Between Shots'],
    allowed_cues: ['🗣️ Trigger Word', '😮‍💨 Deep Breath', '💬 Self-Talk'],
    delivery_lengths: ['micro_10s', 'standard_30s', 'deep_90s'],
    primary_pillar: 'CONFIDENCE',
  },
  {
    id: 'MC_T07_MOMENTUM_PROTECTION',
    name: 'Momentum Protection',
    allowed_routine_types: ['📐 Pre-Shot', '🚶 Between Shots'],
    allowed_cues: ['🎯 Visualization', '🗣️ Trigger Word', '💬 Self-Talk'],
    delivery_lengths: ['micro_10s', 'standard_30s', 'deep_90s'],
    primary_pillar: 'CONFIDENCE',
  },
  {
    id: 'MC_T08_END_OF_ROUND_REFLECTION',
    name: 'End-of-Round Reflection',
    allowed_routine_types: ['⏳ Pre-Round', '🧘 Post-Shot'],
    allowed_cues: [
      '😮‍💨 Deep Breath',
      '💬 Self-Talk',
      '🎯 Visualization',
      '🗣️ Trigger Word',
      '✋ Letting Go',
      '🔄 Reset',
    ],
    delivery_lengths: ['micro_60s', 'standard_3m', 'deep_7m'],
    primary_pillar: 'ALL',
  },
  {
    id: 'MC_T09_POST_ROUND_INSIGHT',
    name: 'Post-Round Insight',
    allowed_routine_types: ['🧘 Post-Shot'],
    allowed_cues: [
      '💬 Self-Talk',
      '🎯 Visualization',
      '✋ Letting Go',
    ],
    delivery_lengths: ['micro_60s', 'standard_75s', 'deep_90s'],
    primary_pillar: 'ALL',
  },
];

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function mapTemplateDoc(data, docId) {
  const id = safeString(data.id || data.template_id || data.templateId || docId);
  return {
    id,
    name: safeString(data.name || data.template_name || data.templateName),
    allowed_routine_types: Array.isArray(data.allowed_routine_types)
      ? data.allowed_routine_types.map((v) => String(v))
      : Array.isArray(data.allowedRoutineTypes)
      ? data.allowedRoutineTypes.map((v) => String(v))
      : [],
    allowed_cues: Array.isArray(data.allowed_cues)
      ? data.allowed_cues.map((v) => String(v))
      : Array.isArray(data.allowedCues)
      ? data.allowedCues.map((v) => String(v))
      : [],
    delivery_lengths: Array.isArray(data.delivery_lengths)
      ? data.delivery_lengths.map((v) => String(v))
      : Array.isArray(data.deliveryLengths)
      ? data.deliveryLengths.map((v) => String(v))
      : [],
    primary_pillar: safeString(data.primary_pillar || data.primaryPillar),
  };
}

async function loadTemplates() {
  if (templatesCache) {
    logger.info('[MCv2:loadTemplates] returning cached templates', { count: templatesCache.length });
    return templatesCache;
  }

  try {
    const snapshot = await db.collection('mindcoach_templates').get();
    if (!snapshot.empty) {
      const mapped = snapshot.docs.map((doc) => mapTemplateDoc(doc.data(), doc.id));
      const templateMap = new Map(
        mapped.filter((template) => template.id).map((template) => [template.id, template]),
      );
      for (const fallback of FALLBACK_TEMPLATES) {
        if (!templateMap.has(fallback.id)) {
          templateMap.set(fallback.id, fallback);
        }
      }
      templatesCache = Array.from(templateMap.values());
      if (templatesCache.length) {
        logger.info('[MCv2:loadTemplates] loaded from Firestore', { count: templatesCache.length });
        return templatesCache;
      }
    }
    logger.warn('[MCv2:loadTemplates] Firestore collection empty, falling back to JSON');
  } catch (err) {
    logger.warn('[MCv2:loadTemplates] Firestore read failed, falling back to JSON', { error: err.message });
  }

  try {
    const json = JSON.parse(fs.readFileSync(TEMPLATES_JSON_PATH, 'utf8'));
    const templates = (json.templates || []).map((template) =>
      mapTemplateDoc(template, template.id),
    );
    const templateMap = new Map(templates.map((template) => [template.id, template]));
    for (const fallback of FALLBACK_TEMPLATES) {
      if (!templateMap.has(fallback.id)) {
        templateMap.set(fallback.id, fallback);
      }
    }
    templatesCache = Array.from(templateMap.values());
    logger.info('[MCv2:loadTemplates] loaded from JSON file', { count: templates.length, path: TEMPLATES_JSON_PATH });
    return templatesCache;
  } catch (err) {
    logger.warn('[MCv2:loadTemplates] JSON file read failed, using hardcoded fallback', { error: err.message });
    templatesCache = FALLBACK_TEMPLATES;
    return templatesCache;
  }
}

function mapContentRow(row) {
  return {
    content_id: safeString(row.content_id || row.contentId),
    template_id: safeString(row.template_id || row.templateId),
    vark_mode: safeString(row.vark_mode || row.varkMode || 'ReadWrite'),
    level: safeString(row.level || 'Foundation'),
    length: safeString(row.length || 'standard'),
    scenario_tags: safeString(row.scenario_tags || row.scenarioTags),
    script_text: safeString(row.script_text || row.scriptText),
    cta_question: safeString(row.cta_question || row.ctaQuestion),
    follow_up_prompt: safeString(row.follow_up_prompt || row.followUpPrompt),
  };
}

function assertContentLibraryIntegrity(entries, source) {
  const contentBackedTemplateIds = TEMPLATE_IDS.filter(
    (templateId) => templateId !== 'MC_T09_POST_ROUND_INSIGHT',
  );
  const report = validateContentLibraryIntegrity(entries, {
    templateIds: contentBackedTemplateIds,
    expectedRows: CONTENT_LIBRARY_EXPECTED_ROWS,
  });

  if (!report.ok) {
    logger.error('[MCv2:loadContent] integrity validation failed', {
      source,
      observedRows: report.observedRows,
      expectedRows: report.expectedRows,
      matrixSlotsPresent: report.matrixSlotsPresent,
      matrixSlotsExpected: report.matrixSlotsExpected,
      errors: report.errors,
      missingSample: report.missingCombinations.slice(0, 10),
      duplicateSample: report.duplicateCombinations.slice(0, 10),
    });
    throw new functions.https.HttpsError(
      'failed-precondition',
      'MindCoach content library is incomplete. Run seedMindCoachData with reseed.',
    );
  }

  logger.info('[MCv2:loadContent] integrity validation passed', {
    source,
    observedRows: report.observedRows,
    matrixSlotsPresent: report.matrixSlotsPresent,
  });
}

async function loadContentLibrary() {
  if (contentCache) {
    logger.info('[MCv2:loadContent] returning cached content', { count: contentCache.length });
    return contentCache;
  }

  try {
    const snapshot = await db.collection('mindcoach_content_library').get();
    if (!snapshot.empty) {
      const firestoreEntries = snapshot.docs.map((doc) => mapContentRow(doc.data()));
      if (firestoreEntries.length) {
        try {
          assertContentLibraryIntegrity(firestoreEntries, 'firestore');
          contentCache = firestoreEntries;
          logger.info('[MCv2:loadContent] loaded from Firestore', { count: contentCache.length });
          return contentCache;
        } catch (validationError) {
          logger.warn('[MCv2:loadContent] Firestore data invalid, falling back to CSV', {
            error: validationError.message,
          });
        }
      }
    }
    logger.warn('[MCv2:loadContent] Firestore collection empty, falling back to CSV');
  } catch (err) {
    logger.warn('[MCv2:loadContent] Firestore read failed, falling back to CSV', { error: err.message });
  }

  try {
    contentCache = parseCsvFile(CONTENT_LIBRARY_CSV_PATH).map(mapContentRow);
    assertContentLibraryIntegrity(contentCache, 'csv');
    logger.info('[MCv2:loadContent] loaded from CSV', { count: contentCache.length });
  } catch (err) {
    logger.warn('[MCv2:loadContent] CSV read/validation failed, using empty content library (deterministic fallback will be used)', { error: err.message });
    contentCache = [];
  }
  return contentCache;
}

async function loadScenarioTags() {
  if (scenarioCache) {
    logger.info('[MCv2:loadScenarios] returning cached scenarios', { count: scenarioCache.length });
    return scenarioCache;
  }

  try {
    const snapshot = await db.collection('mindcoach_scenario_tags').get();
    if (!snapshot.empty) {
      scenarioCache = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          scenario_tag: safeString(data.scenario_tag || data.tag_id || doc.id),
          description: safeString(data.description),
        };
      });
      if (scenarioCache.length) {
        logger.info('[MCv2:loadScenarios] loaded from Firestore', { count: scenarioCache.length });
        return scenarioCache;
      }
    }
    logger.warn('[MCv2:loadScenarios] Firestore collection empty, falling back to CSV');
  } catch (err) {
    logger.warn('[MCv2:loadScenarios] Firestore read failed, falling back to CSV', { error: err.message });
  }

  try {
    scenarioCache = parseCsvFile(SCENARIO_TAGS_CSV_PATH).map((row) => ({
      scenario_tag: safeString(row.scenario_tag),
      description: safeString(row.description),
    }));
    logger.info('[MCv2:loadScenarios] loaded from CSV', { count: scenarioCache.length });
  } catch (err) {
    logger.warn('[MCv2:loadScenarios] CSV read failed, using empty array', { error: err.message });
    scenarioCache = [];
  }
  return scenarioCache;
}

function detectScenarioTags({ userMessage, contextMode, scenarioTags }) {
  const detected = new Set();
  const message = safeString(userMessage).toLowerCase();

  if (message.includes('rushed') || message.includes('hurry')) {
    detected.add('fast_group_behind');
  }
  if (message.includes('nerv') || message.includes('pressure')) {
    detected.add('closing_holes_pressure');
  }
  if (message.includes('indecision') || message.includes('club')) {
    detected.add('club_choice_confusion');
  }
  if (message.includes('bad shot') || message.includes('miss')) {
    detected.add('after_bad_shot_release');
  }

  if (contextMode === 'during_round') {
    detected.add('walking_reset');
  }
  if (contextMode === 'after_round') {
    detected.add('post_round_learn');
  }

  // Approximate phrase matching against tag id and description.
  for (const tagRow of scenarioTags || []) {
    const id = safeString(tagRow.scenario_tag).toLowerCase();
    const desc = safeString(tagRow.description).toLowerCase();
    if (!id) {
      continue;
    }

    const idProbe = id.replace(/_/g, ' ');
    if (message.includes(idProbe) || (desc && message.includes(desc.split(' ')[0]))) {
      detected.add(id);
    }
  }

  return Array.from(detected);
}

/**
 * Parse the target duration in seconds from a delivery_length value.
 * Examples: 'micro_10s' → 10, 'standard_45s' → 45, 'deep_2m' → 120, 'deep_7m' → 420.
 */
function parseTargetSeconds(deliveryLength) {
  const raw = safeString(deliveryLength).toLowerCase();
  // Match patterns like _15s, _45s, _90s
  const secMatch = raw.match(/(\d+)s$/);
  if (secMatch) return parseInt(secMatch[1], 10);
  // Match patterns like _2m, _3m, _7m
  const minMatch = raw.match(/(\d+)m$/);
  if (minMatch) return parseInt(minMatch[1], 10) * 60;
  // Fallback defaults based on category
  const normalized = normalizeLength(raw);
  if (normalized === 'micro') return 15;
  if (normalized === 'deep') return 120;
  return 45; // standard default
}

/**
 * Compute how many coaching lines are appropriate for a given duration.
 */
function lineRangeForDuration(targetSec) {
  if (targetSec <= 15) return { min: 3, max: 5 };
  if (targetSec <= 30) return { min: 4, max: 7 };
  if (targetSec <= 60) return { min: 5, max: 10 };
  if (targetSec <= 120) return { min: 8, max: 16 };
  if (targetSec <= 300) return { min: 12, max: 24 };
  return { min: 16, max: 32 };
}

function pickDeliveryLength({ preferred, template, contextMode }) {
  const allowed = Array.isArray(template.delivery_lengths)
    ? template.delivery_lengths
    : [];

  if (!allowed.length) {
    return 'standard_30s';
  }

  const preferredNormalized = normalizeLength(preferred);
  const matchesPreferred = allowed.find(
    (value) => normalizeLength(value) === preferredNormalized,
  );
  if (matchesPreferred) {
    return matchesPreferred;
  }

  const contextDefault =
    contextMode === 'during_round' ? 'micro' : contextMode === 'before_round' ? 'standard' : 'deep';

  const contextMatch = allowed.find(
    (value) => normalizeLength(value) === contextDefault,
  );
  if (contextMatch) {
    return contextMatch;
  }

  const standard = allowed.find((value) => normalizeLength(value) === 'standard');
  return standard || allowed[0];
}

function pickNearestDeliveryLength({ template, targetSec, preferred = 'auto', contextMode }) {
  if (!targetSec || targetSec <= 0) {
    return pickDeliveryLength({ preferred, template, contextMode });
  }

  const allowed = Array.isArray(template.delivery_lengths)
    ? template.delivery_lengths
    : [];
  if (!allowed.length) {
    return targetSec <= 15 ? 'micro_10s' : 'standard_45s';
  }

  return allowed.reduce((best, candidate) => {
    const bestDiff = Math.abs(parseTargetSeconds(best) - targetSec);
    const candidateDiff = Math.abs(parseTargetSeconds(candidate) - targetSec);
    return candidateDiff < bestDiff ? candidate : best;
  });
}

function buildPromptText({
  template,
  content,
  selectedDeliveryLength,
  fixedTargetSec,
  selectedLevel,
  contextMode,
  lockedSession,
  userMessage,
  customization,
  scenarioTags,
}) {
  if (!promptCache) {
    const promptPath = path.join(__dirname, 'prompts', 'mindcoach_system_v1.txt');
    try {
      promptCache = fs.readFileSync(promptPath, 'utf8');
    } catch (err) {
      logger.warn('[MCv2:buildPrompt] prompt file not found, using inline fallback', { error: err.message });
      promptCache = 'You are a golf mental performance coach. Generate a calm, concise coaching routine. Follow the parameters below exactly.';
    }
  }

  const baseScript = safeString(content?.script_text);
  const targetSec = fixedTargetSec || parseTargetSeconds(selectedDeliveryLength);
  const lineRange = lineRangeForDuration(targetSec);

  return `${promptCache}

Context mode: ${contextMode}
Locked pillar: ${safeString(lockedSession?.pillar, 'none')}
Locked session key: ${safeString(lockedSession?.key, 'none')}
Locked session name: ${safeString(lockedSession?.name, 'none')}
Locked session descriptor: ${safeString(lockedSession?.descriptor, 'none')}
Template ID: ${template.id}
Template name: ${template.name}
Allowed routine types: ${template.allowed_routine_types.join(', ')}
Allowed cues: ${template.allowed_cues.join(', ')}
Allowed delivery lengths: ${template.delivery_lengths.join(', ')}
Preferred delivery length: ${selectedDeliveryLength}
TARGET DURATION: ${targetSec} seconds total. The session MUST fill approximately ${targetSec} seconds of spoken coaching.
Selected level: ${selectedLevel}
Detected scenario tags: ${scenarioTags.join(', ') || 'none'}
User message: ${safeString(userMessage, 'none')}
Customization goal: ${safeString(customization.goal, 'none')}
Customization tone: ${safeString(customization.tone, 'auto')}
Customization vark_mode: ${safeString(customization.vark_mode, 'auto')}
Reference script: ${baseScript || 'none'}

Return JSON only with keys:
template_id, routine_type, recommended_cue, delivery_length, coaching_text, follow_up_question, session_key, session_name, session_descriptor, duration_sec.
REQUIRED: include "lines" (array of {text: string, startMs: number, durationMs: number}) and "total_duration_sec" (number).
If a locked session is supplied, you MUST preserve its session_name, session_descriptor, duration_sec, and fixed purpose.

TIMING RULES - CRITICAL:
- total_duration_sec MUST be approximately ${targetSec} seconds (±10%).
- Generate ${lineRange.min}-${lineRange.max} lines. Each line is one coaching phrase the golfer hears.
- Each line max 60 characters. Lines must be imperative, calm, short.
- Space lines with natural pauses between them. Include breathing pauses of 2-4 seconds between lines.
- startMs values should be spread to fill the full ${targetSec} seconds.
- durationMs per line: shorter lines ~2000-3000ms, longer lines ~3000-5000ms.
- The LAST line's (startMs + durationMs) should be close to ${targetSec * 1000}ms.
- For micro sessions (≤15s): quick, punchy cues with short pauses.
- For standard sessions (30-60s): measured pace with breathing breaks.
- For deep sessions (≥90s): slower pacing, longer pauses, richer imagery and body-scan cues.

Guardrails: No questions, no analysis, no "why" or "because" or "analyze" or "tell me".
Do not output markdown.
`;
}

const LINE_FORBIDDEN_PATTERNS = [
  /\bwhy\b/i,
  /\bbecause\b/i,
  /\banalyze\b/i,
  /\btell\s+me\b/i,
  /\?/,
];
const MAX_LINE_CHARS = 60;
const MIN_LINES = 3;
const MAX_LINES = 32;
const MAX_DURATION_DURING = 60;
const MAX_DURATION_OTHER = 90;

function validateAndNormalizeTimedLines(aiOutput, contextMode) {
  const lines = aiOutput?.lines;
  const totalSec = aiOutput?.total_duration_sec;
  if (!Array.isArray(lines) || lines.length === 0 || typeof totalSec !== 'number') {
    return null;
  }
  const maxSec = contextMode === 'during_round' ? MAX_DURATION_DURING : MAX_DURATION_OTHER;
  if (totalSec > maxSec || totalSec <= 0) {
    return null;
  }
  const normalized = [];
  for (const item of lines) {
    const text = safeString(item?.text);
    if (!text) continue;
    if (text.length > MAX_LINE_CHARS) continue;
    const hasForbidden = LINE_FORBIDDEN_PATTERNS.some((p) => p.test(text));
    if (hasForbidden) return null;
    const startMs = typeof item.startMs === 'number' ? item.startMs : normalized.length * 3000;
    const durationMs = typeof item.durationMs === 'number'
      ? item.durationMs
      : typeof item.endMs === 'number'
      ? Math.max(400, item.endMs - startMs)
      : 2500;
    const endMs = typeof item.endMs === 'number' ? item.endMs : startMs + durationMs;
    normalized.push({ text, startMs, durationMs, endMs });
  }
  if (normalized.length < MIN_LINES || normalized.length > MAX_LINES) {
    return null;
  }
  const computedTotalSec = Math.ceil(
    Math.max(...normalized.map((line) => line.endMs), 0) / 1000,
  );
  const coachingTextFromLines = normalized.map((l) => l.text).join('\n');
  return {
    lines: normalized,
    total_duration_sec: Math.min(Math.max(totalSec, computedTotalSec), maxSec),
    coaching_text: coachingTextFromLines,
  };
}

function parseJsonFromModelText(text) {
  if (!text || typeof text !== 'string') {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch (_) {
    // Try extracting first JSON block.
  }

  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start >= 0 && end > start) {
    const candidate = text.slice(start, end + 1);
    try {
      return JSON.parse(candidate);
    } catch (_) {
      return null;
    }
  }

  return null;
}

async function generateWithGemini({ prompt }) {
  const apiKey = getGeminiApiKeySafe();

  if (!apiKey) {
    logger.warn('[MCv2:gemini] No API key available, skipping generation');
    return {
      output: null,
      modelVersion: 'gemini_unavailable_no_api_key',
    };
  }

  const endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  for (let attempt = 0; attempt < 2; attempt += 1) {
    logger.info('[MCv2:gemini] generation attempt', { attempt: attempt + 1 });
    try {
      const response = await axios.post(
        endpoint,
        {
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.4,
            maxOutputTokens: 800,
          },
          contents: [
            {
              role: 'user',
              parts: [{ text: prompt }],
            },
          ],
        },
        {
          timeout: 12000,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        },
      );

      const text =
        response.data?.candidates?.[0]?.content?.parts?.[0]?.text || null;

      const parsed = parseJsonFromModelText(text);
      logger.info('[MCv2:gemini] generation succeeded', {
        attempt: attempt + 1,
        hasOutput: !!parsed,
        hasTimedLines: !!(parsed && Array.isArray(parsed.lines)),
        outputKeys: parsed ? Object.keys(parsed) : [],
      });

      return {
        output: parsed,
        modelVersion: 'gemini-2.5-flash',
      };
    } catch (err) {
      logger.warn('[MCv2:gemini] generation attempt failed', {
        attempt: attempt + 1,
        error: err.message,
        status: err.response?.status,
      });
    }
  }

  logger.error('[MCv2:gemini] all generation attempts failed');
  return {
    output: null,
    modelVersion: 'gemini_generation_failed',
  };
}

async function commitBatchWithRetry(batch, attempts = 2) {
  let lastError;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      await batch.commit();
      return;
    } catch (error) {
      lastError = error;
      logger.warn('[MCv2:generate] Firestore batch commit failed', {
        attempt: attempt + 1,
        error: error.message,
      });
      if (attempt < attempts - 1) {
        await sleep(250);
      }
    }
  }
  throw lastError;
}

function buildDeterministicOutput({
  template,
  content,
  selectedDeliveryLength,
  fixedTargetSec,
  contextMode,
  uiMode,
  userId,
  lockedSession,
  recentCoachingTexts = [],
  fallbackSeed = '',
}) {
  const routineType = template.allowed_routine_types[0] || '📐 Pre-Shot';
  const cue = template.allowed_cues[0] || '😮‍💨 Deep Breath';

  const sourceScriptText = safeString(content?.script_text);
  const fallbackText = chooseDeterministicFallbackText({
    templateId: template.id,
    selectedDeliveryLength,
    contextMode,
    uiMode,
    userId,
    recentCoachingTexts,
    fallbackSeed,
  });
  const coachingText = sourceScriptText || fallbackText;
  const timed = buildTimedFallbackLines({
    coachingText,
    selectedDeliveryLength,
    fixedTargetSec,
    uiMode,
  });

  return {
    template_id: template.id,
    session_key: safeString(lockedSession?.key, template.id),
    session_name: safeString(lockedSession?.name, template.name),
    session_descriptor: safeString(
      lockedSession?.descriptor,
      safeString(content?.cta_question),
    ),
    duration_sec: fixedTargetSec || timed.totalDurationSec,
    routine_type: routineType,
    recommended_cue: cue,
    delivery_length: selectedDeliveryLength,
    coaching_text: coachingText,
    follow_up_question:
      contextMode === 'during_round' ? null : safeString(content?.cta_question) || null,
    lines: timed.lines,
    total_duration_sec: timed.totalDurationSec,
  };
}

// Fallback lines keyed by template → delivery category (micro/standard/deep).
// Each category has multiple rotation pools.
const TEMPLATE_FALLBACK_LINES = {
  MC_T01_PRE_ROUND_CLARITY: {
    micro: [
      ['Breathe low and steady.', 'Picture your opening swing.', 'Trust tempo over force.', 'Start with one simple commit.'],
      ['Settle your shoulders.', 'See the first fairway target.', 'One smooth takeaway.', 'Play this shot, not the round.'],
    ],
    standard: [
      ['Close your eyes for a moment.', 'Breathe in through your nose.', 'Hold for two counts.', 'Exhale slowly through your mouth.', 'Picture the first tee box.', 'See the fairway opening up ahead.', 'Feel the club resting easy in your hands.', 'One smooth tempo is the only goal.', 'Trust your preparation.', 'Open your eyes and begin.'],
      ['Stand tall and settle your weight.', 'Let your arms hang loose.', 'Take a deep breath in.', 'Release it slowly.', 'Visualize a clean opening drive.', 'Feel the rhythm of your takeaway.', 'Commit to one clear target.', 'Trust the swing you have built.', 'Start with patience and intent.', 'You are ready.'],
    ],
    deep: [
      ['Find a quiet spot and close your eyes.', 'Let your shoulders drop away from your ears.', 'Breathe in for four counts.', 'Hold for two counts.', 'Exhale for six counts.', 'Repeat that breath cycle once more.', 'Now picture yourself on the first tee.', 'See the morning light on the fairway.', 'Feel the ground beneath your feet.', 'Notice how still your hands are.', 'Imagine your ideal opening swing.', 'See the ball climbing into the sky.', 'Watch it land exactly where you aimed.', 'Carry that image with you.', 'Set one intention for the round ahead.', 'Open your eyes and commit.'],
    ],
  },
  MC_T02_PRE_SHOT_FOCUS: {
    micro: [
      ['Pause.', 'One breath.', 'Lock on a tiny target.', 'Commit through the strike.'],
      ['Exhale once.', 'Feel your feet settle.', 'Eyes on the start line.', 'Trust your swing shape.'],
    ],
    standard: [
      ['Step behind the ball.', 'Pick a specific target.', 'See the ball flight in your mind.', 'Take one calming breath.', 'Walk into your stance.', 'Feel your feet settle.', 'Soften your grip pressure.', 'One smooth waggle.', 'Eyes on the target.', 'Swing with commitment.'],
      ['Pause before you address the ball.', 'Breathe out and release tension.', 'Name one tiny target.', 'See the start line clearly.', 'Step in with purpose.', 'Feel balanced and grounded.', 'Quiet your mind.', 'Trust the shape you chose.', 'Deliver through impact.', 'Hold the finish.'],
    ],
    deep: [
      ['Stand behind the ball and observe.', 'What shape does this shot need?', 'Pick a precise start line.', 'See the ball land on that line.', 'Take a slow breath in.', 'Let it out with any tension.', 'Walk into your stance with purpose.', 'Settle your feet into the ground.', 'Soften your hands on the grip.', 'Feel your weight centered.', 'One practice swing with full intent.', 'Now address the ball.', 'Breathe once more.', 'Eyes to target, then back to ball.', 'Trust your body to deliver.', 'Swing through with conviction.'],
    ],
  },
  MC_T03_BETWEEN_SHOTS_RESET: {
    micro: [
      ['Walk tall for ten steps.', 'Drop the last result.', 'Breathe in for four.', 'Arrive ready for the next shot.'],
      ['Reset your pace.', 'Let tension leave your jaw.', 'Feel both feet grounded.', 'Bring focus to the next decision.'],
    ],
    standard: [
      ['Start walking at an easy pace.', 'Let your arms swing naturally.', 'Release the last shot from your mind.', 'Breathe in through your nose.', 'Exhale slowly.', 'Look at something in the distance.', 'Notice the green around you.', 'Feel the rhythm of your walk.', 'Begin thinking about your next lie.', 'Arrive at the ball with a clear plan.'],
      ['Walk with good posture.', 'Drop your shoulders as you move.', 'Let the previous shot go completely.', 'Take a deep cleansing breath.', 'Relax your jaw and your hands.', 'Enjoy the walk between shots.', 'Start assessing wind direction.', 'Think about your next target.', 'Build a simple plan.', 'Arrive focused and ready.'],
    ],
    deep: [
      ['Begin your walk slowly and deliberately.', 'Feel each foot press into the ground.', 'Let the last shot dissolve behind you.', 'Nothing about it matters now.', 'Breathe in deeply for four counts.', 'Hold at the top for two.', 'Exhale for six smooth counts.', 'Repeat that cycle.', 'Notice the sky and the trees.', 'Bring yourself into this moment.', 'Scan your body for tension.', 'Release it with the next exhale.', 'Now think about the shot ahead.', 'What does the lie look like?', 'What is the smart play here?', 'Arrive with a clear, calm decision.'],
    ],
  },
  MC_T04_POST_SHOT_LETTING_GO: {
    micro: [
      ['That shot is done.', 'Exhale and release.', 'No replay, no blame.', 'Return to the next target.'],
      ['Acknowledge it and drop it.', 'Breathe out slowly.', 'Reset posture and pace.', 'Choose the next commitment.'],
    ],
    standard: [
      ['The ball has landed.', 'Whatever happened, it is over.', 'Take a breath and acknowledge it.', 'No judgment, just acceptance.', 'Feel your feet on the ground.', 'Drop your shoulders.', 'Relax your hands.', 'You cannot change the result.', 'Shift your attention forward.', 'The next shot is what matters.'],
      ['The shot is complete.', 'Let the result be what it is.', 'Breathe out any frustration.', 'Reset your body language.', 'Stand tall and walk forward.', 'Release the grip on the outcome.', 'Bring your attention to now.', 'There is nothing to fix here.', 'Focus on the next opportunity.', 'Move ahead with purpose.'],
    ],
    deep: [
      ['The ball has come to rest.', 'Take a moment to stand still.', 'Whatever the result, accept it fully.', 'It is done and cannot be changed.', 'Breathe in slowly.', 'As you exhale, release the tension.', 'Feel your hands relax.', 'Feel your jaw unclench.', 'Drop your shoulders away from your ears.', 'The emotion you feel is natural.', 'Acknowledge it without judgment.', 'Now let it pass like a cloud.', 'Your next shot starts fresh.', 'Every shot is a new opportunity.', 'Commit to moving forward with calm.', 'Walk with quiet confidence.'],
    ],
  },
  MC_T05_MISTAKE_RECOVERY: {
    micro: [
      ['One mistake is one moment.', 'Breathe and reset your body.', 'Pick a safer next target.', 'Build momentum with one clean shot.'],
      ['Name it, then release it.', 'Steady your breath.', 'Simplify the next choice.', 'Earn rhythm back now.'],
    ],
    standard: [
      ['Mistakes happen to every golfer.', 'This one does not define your round.', 'Take a slow, deep breath.', 'Let the frustration leave with the exhale.', 'Reset your posture.', 'Stand up tall and walk forward.', 'What is the smartest next play?', 'Keep it simple and safe.', 'One solid shot rebuilds momentum.', 'Commit and execute cleanly.'],
      ['That shot is behind you now.', 'Every golfer hits poor shots.', 'Breathe and slow your heart rate.', 'Release the tension in your hands.', 'Do not try to fix everything at once.', 'Pick the easiest next target.', 'Give yourself a simple task.', 'Execute with calm discipline.', 'One good shot is all you need.', 'Stack from here.'],
    ],
    deep: [
      ['Stop and acknowledge what happened.', 'Name the mistake clearly in your mind.', 'Now set it down and leave it there.', 'Take three slow breaths.', 'In for four, out for six.', 'Feel the tension draining from your body.', 'Shake your hands loose at your sides.', 'Roll your shoulders back twice.', 'You are not that mistake.', 'You are a capable golfer having one bad moment.', 'Think about a great shot you hit recently.', 'Hold that image for a few seconds.', 'Now look at your next lie.', 'What is the safest, smartest play?', 'Commit to that choice completely.', 'Execute one clean shot to rebuild.'],
    ],
  },
  MC_T06_PRESSURE_MOMENTS: {
    micro: [
      ['Pressure means this matters.', 'Breathe down to your pace.', 'Narrow to one target.', 'Trust your trained motion.'],
      ['Feel nerves, then center.', 'Exhale longer than inhale.', 'Pick one clear cue word.', 'Swing with conviction.'],
    ],
    standard: [
      ['Pressure shows you care about this.', 'That energy is useful.', 'Channel it into your process.', 'Take a long exhale.', 'Feel your heartbeat slow.', 'Simplify your target.', 'One small spot, nothing else.', 'This is a swing you have done before.', 'Trust the hours of practice.', 'Deliver with quiet confidence.'],
      ['You have been here before.', 'Nerves are a sign of readiness.', 'Breathe in for four counts.', 'Hold for two.', 'Exhale for six.', 'Feel the calm settle in.', 'Pick one specific target.', 'See the ball going there.', 'Commit to your process.', 'Execute with full trust.'],
    ],
    deep: [
      ['This moment feels big.', 'That is your body getting ready to perform.', 'Adrenaline is fuel, not a problem.', 'Breathe in slowly for four counts.', 'Hold the breath at the top.', 'Exhale slowly for six counts.', 'Repeat that breath once more.', 'Feel your heart rate settle.', 'Scan your body for tension.', 'Soften your jaw and your hands.', 'Think about your process.', 'You have trained for this exact moment.', 'Pick one tiny target on the course.', 'See the ball flight in your mind.', 'Step in with purpose.', 'Swing with complete trust.'],
    ],
  },
  MC_T07_MOMENTUM_PROTECTION: {
    micro: [
      ['Stay in process, not outcome.', 'Breathe and keep tempo.', 'Repeat your reliable routine.', 'Stack one quality shot now.'],
      ['Protect rhythm first.', 'Simple target, simple swing.', 'Keep body language strong.', 'Build from this moment.'],
    ],
    standard: [
      ['Things are going well right now.', 'Protect this feeling with your process.', 'Stay in the present shot.', 'Do not jump ahead in your mind.', 'Breathe and maintain your tempo.', 'Keep your routine the same length.', 'Choose a clear target.', 'Play the shot in front of you.', 'Stay patient and disciplined.', 'Stack another quality decision.'],
      ['Good momentum deserves protection.', 'Do not change your routine now.', 'Keep the same rhythm.', 'Stay present with each shot.', 'Breathe at the same steady pace.', 'Do not rush to the next hole.', 'Simple targets, simple execution.', 'Trust the process that got you here.', 'One shot at a time.', 'Build quietly and steadily.'],
    ],
    deep: [
      ['You have built positive momentum.', 'This is not the time to change anything.', 'Protect it by staying in your process.', 'Breathe with the same rhythm.', 'Walk at the same pace.', 'Do not let excitement speed you up.', 'Stay in the present moment.', 'The score will take care of itself.', 'Focus only on the shot in front of you.', 'Pick a precise target.', 'See the ball flight clearly.', 'Step into your stance the same way.', 'One waggle, one look, one commit.', 'Swing with the trust you have earned.', 'Hold your finish and walk forward.', 'Carry this calm confidence to the next.'],
    ],
  },
  MC_T08_END_OF_ROUND_REFLECTION: {
    micro: [
      ['Take one calming breath.', 'Name one decision you executed well.', 'Name one routine to sharpen.', 'Carry one clear cue to next round.'],
      ['Settle and review calmly.', 'Keep one win from today.', 'Choose one adjustment.', 'Leave with a focused next step.'],
    ],
    standard: [
      ['Find a quiet moment after your round.', 'Take three slow breaths.', 'Let the emotions of the day settle.', 'Think about one decision you are proud of.', 'Hold that memory for a moment.', 'Now think about one moment to improve.', 'What would you do differently?', 'Keep the lesson simple and clear.', 'Set one intention for your next round.', 'Walk away with that single focus.'],
      ['The round is over.', 'Take a breath and let it go.', 'Do not replay every shot.', 'Pick one highlight from today.', 'Something you controlled well.', 'Now pick one area to work on.', 'Not everything, just one thing.', 'Write it down if you can.', 'Set a clear goal for next time.', 'Carry that forward with confidence.'],
    ],
    deep: [
      ['Sit down somewhere comfortable.', 'Close your eyes for a moment.', 'Take a deep, slow breath.', 'Let the round replay at a distance.', 'Do not judge each shot.', 'Just observe the flow of the day.', 'Now pick one moment where your process worked.', 'Remember how that felt in your body.', 'Hold that feeling for ten seconds.', 'That is you at your best.', 'Now think about one challenge you faced.', 'What was your response in that moment?', 'What could you adjust next time?', 'Keep the adjustment simple.', 'Write down one takeaway.', 'Set one clear intention for practice.', 'When you open your eyes, leave the round here.', 'Carry only the lesson forward.'],
    ],
  },
};

const GENERIC_FALLBACK_LINES = {
  micro: [
    ['Pause and breathe.', 'Reset your body.', 'Choose one clear target.', 'Commit to the next shot.'],
    ['Slow exhale.', 'Relax your shoulders.', 'Keep the plan simple.', 'Execute with trust.'],
  ],
  standard: [
    ['Stand still for a moment.', 'Close your eyes briefly.', 'Take a slow breath in.', 'Exhale fully.', 'Feel the ground beneath you.', 'Let your shoulders drop.', 'Clear your mind of clutter.', 'Choose one simple focus.', 'Commit to the next action.', 'Execute with calm trust.'],
  ],
  deep: [
    ['Find your center.', 'Stand still and close your eyes.', 'Breathe in slowly for four counts.', 'Hold for two.', 'Exhale for six.', 'Repeat that cycle twice.', 'Scan your body from head to toe.', 'Release any tension you find.', 'Soften your jaw.', 'Relax your hands.', 'Drop your shoulders.', 'Feel balanced and grounded.', 'Choose one clear intention.', 'Hold that intention in your mind.', 'Open your eyes.', 'Move forward with purpose.'],
  ],
};

function chooseDeterministicFallbackText({
  templateId,
  selectedDeliveryLength,
  contextMode,
  uiMode,
  userId,
  recentCoachingTexts,
  fallbackSeed,
}) {
  const templatePools = TEMPLATE_FALLBACK_LINES[templateId] || GENERIC_FALLBACK_LINES;
  const lengthCategory = normalizeLength(selectedDeliveryLength);

  // Select the pool for the matching delivery length category.
  let pools;
  if (typeof templatePools === 'object' && !Array.isArray(templatePools)) {
    pools = templatePools[lengthCategory] || templatePools.standard || templatePools.micro || [];
  } else {
    // Legacy array format fallback
    pools = templatePools;
  }

  if (!Array.isArray(pools) || pools.length === 0) {
    return 'Reset. Breathe. Focus on the next shot.';
  }

  const hourBucket = new Date().toISOString().slice(0, 13);
  const seedInput = `${fallbackSeed}|${userId}|${templateId}|${contextMode}|${selectedDeliveryLength}|${hourBucket}`;
  const baseIndex = stableHash(seedInput) % pools.length;

  const recent = new Set(
    (recentCoachingTexts || [])
      .map((value) => normalizeTextFingerprint(value))
      .filter(Boolean),
  );

  for (let offset = 0; offset < pools.length; offset += 1) {
    const lines = pools[(baseIndex + offset) % pools.length];
    const text = linesForUiMode(lines, uiMode);
    if (!recent.has(normalizeTextFingerprint(text))) {
      return text;
    }
  }

  return linesForUiMode(pools[baseIndex], uiMode);
}

function linesForUiMode(lines, uiMode) {
  const sanitized = (lines || [])
    .map((line) => safeString(line))
    .filter(Boolean);
  if (uiMode === 'live_minimal') {
    return sanitized.slice(0, 3).join(' ');
  }
  return sanitized.join('\n');
}

function normalizeTextFingerprint(value) {
  return safeString(value).replace(/\s+/g, ' ').toLowerCase();
}

function stableHash(value) {
  const raw = String(value || '');
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return hash;
}

function buildTimedFallbackLines({
  coachingText,
  selectedDeliveryLength,
  fixedTargetSec,
  uiMode,
}) {
  const targetSec = fixedTargetSec || parseTargetSeconds(selectedDeliveryLength);
  const targetMs = targetSec * 1000;

  const fragments = safeString(coachingText)
    .split(uiMode === 'live_minimal' ? /(?<=[.!?])\s+/ : /\n+/)
    .map((value) => safeString(value))
    .filter(Boolean);

  if (fragments.length === 0) {
    return { lines: [], totalDurationSec: 0 };
  }

  // Calculate proportional speaking time per line, then add pauses.
  const charCounts = fragments.map((f) => Math.max(f.length, 5));
  const totalChars = charCounts.reduce((a, b) => a + b, 0);

  // Reserve ~30% of time for pauses between lines.
  const pauseFraction = fragments.length <= 4 ? 0.35 : 0.30;
  const speakingMs = targetMs * (1 - pauseFraction);
  const totalPauseMs = targetMs * pauseFraction;
  const pausePerGap = fragments.length > 1 ? totalPauseMs / (fragments.length - 1) : 0;

  const lines = [];
  let cursor = 0;
  for (let i = 0; i < fragments.length; i += 1) {
    const proportion = charCounts[i] / totalChars;
    const durationMs = Math.round(Math.max(1200, speakingMs * proportion));
    lines.push({
      text: fragments[i],
      startMs: Math.round(cursor),
      durationMs,
      endMs: Math.round(cursor + durationMs),
    });
    cursor += durationMs;
    if (i < fragments.length - 1) {
      cursor += pausePerGap;
    }
  }

  // Ensure total comes close to target.
  const computedSec = Math.max(1, Math.ceil(cursor / 1000));
  return {
    lines,
    totalDurationSec: Math.max(computedSec, targetSec),
  };
}

/** Optional monthly soft nudge only — never blocks generation. */
async function trackMonthlySessionUsage(userId) {
  const profileRef = db.collection('mindcoach_user_profiles').doc(userId);
  const profileSnap = await profileRef.get();
  const now = new Date();
  const monthKey = now.toISOString().slice(0, 7);

  let monthlyCount = 0;
  if (profileSnap.exists) {
    const data = profileSnap.data() || {};
    monthlyCount =
      data.monthly_key === monthKey ? Number(data.monthly_count || 0) : 0;
  }

  const nextCount = monthlyCount + 1;
  await profileRef.set(
    {
      user_id: userId,
      monthly_key: monthKey,
      monthly_count: nextCount,
      last_request_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  if (nextCount === 80) {
    logger.info('[MCv2:usage] monthly soft nudge threshold', { userId, nextCount });
  }
}

async function assertUserConsent(userId) {
  try {
    const userRef = db.collection('user').doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      return;
    }
    const data = userSnap.data() || {};
    if (data.dataProcessingConsent === false) {
      logger.warn('[MCv2:consent] user declined data processing consent', { userId });
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Data processing consent is required for MindCoach AI generation.',
      );
    }
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    logger.warn('[MCv2:consent] consent check encountered transient error', { error: error.message });
  }
}

function chooseAutoVarkMode({ recentSessionCount, contextMode }) {
  const ordered = ['ReadWrite', 'Visual', 'Aural', 'Kinesthetic'];
  let offset = 0;
  if (contextMode === 'during_round') {
    offset = 1;
  } else if (contextMode === 'after_round') {
    offset = 2;
  }
  return ordered[(recentSessionCount + offset) % ordered.length];
}

function chooseExperienceLevel({ mindsetBefore, contextMode, recentSessionCount }) {
  const mindset = safeString(mindsetBefore).toLowerCase();
  if (mindset === 'distracted' || mindset === 'scattered') {
    return 'Foundation';
  }
  if (mindset === 'peak_focus' && contextMode === 'during_round') {
    return 'Compete';
  }
  if (contextMode === 'after_round') {
    return 'Maintain';
  }

  const ordered = ['Foundation', 'Build', 'Compete', 'Maintain'];
  return ordered[recentSessionCount % ordered.length];
}

async function generateMindCoachSessionV2(data, context) {
  if (!context.auth) {
    logger.warn('[MCv2:generate] unauthenticated request rejected');
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  try {
    return await _generateMindCoachSessionV2Impl(data, context);
  } catch (err) {
    if (err instanceof functions.https.HttpsError) {
      throw err;
    }
    logger.error('[MCv2:generate] unhandled error', {
      message: err.message,
      stack: err.stack,
    });
    throw new functions.https.HttpsError(
      'internal',
      `MindCoach generation failed: ${err.message}`,
    );
  }
}

async function _generateMindCoachSessionV2Impl(data, context) {
  const userId = context.auth.uid;
  const requestedContextMode = safeString(data.context_mode, 'auto');
  const entrySource = safeString(data.entry_source, 'home_primary');
  const requestedPillar = safeString(data.pillar).toLowerCase();
  const sessionKey = safeString(data.session_key);
  const requestedSessionName = safeString(data.session_name);
  const requestedSessionDescriptor = safeString(data.session_descriptor);
  const targetDurationSec = Number(data.target_duration_sec || 0) || 0;
  const userMessage = safeString(data.user_message);
  const mindsetBefore = safeString(data.mindset_before);
  const preferredDeliveryLength = safeString(data.preferred_delivery_length, 'auto');
  const customization =
    data.customization && typeof data.customization === 'object'
      ? data.customization
      : {};

  logger.info('[MCv2:generate] ENTRY', {
    userId,
    requestedContextMode,
    entrySource,
    requestedPillar: requestedPillar || null,
    sessionKey: sessionKey || null,
    preferredDeliveryLength,
    mindsetBefore: mindsetBefore || null,
    hasUserMessage: !!userMessage,
    customization,
  });

  if (!VALID_CONTEXT_MODES.has(requestedContextMode)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid context_mode');
  }
  if (!VALID_ENTRY_SOURCES.has(entrySource)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid entry_source');
  }
  if (mindsetBefore && !VALID_MINDSET_VALUES.has(mindsetBefore)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid mindset_before');
  }
  if (!VALID_DELIVERY_LENGTHS.has(preferredDeliveryLength)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid preferred_delivery_length');
  }

  const customTone = safeString(customization.tone, 'auto');
  const customVark = safeString(customization.vark_mode, 'auto');
  if (!VALID_TONES.has(customTone)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid customization.tone');
  }
  if (!VALID_VARK.has(customVark)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid customization.vark_mode');
  }

  logger.info('[MCv2:generate] checking consent');
  await assertUserConsent(userId);
  logger.info('[MCv2:generate] consent OK, tracking monthly usage');
  await trackMonthlySessionUsage(userId);

  const lockedSession = sessionKey ? getMindCoachSessionDefinition(sessionKey) : null;
  if (sessionKey && !lockedSession) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Unknown session_key for MindCoach generation.',
    );
  }
  if (
    lockedSession &&
    requestedPillar &&
    requestedPillar !== String(lockedSession.pillar).toLowerCase()
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'pillar does not match the requested session_key.',
    );
  }

  let resolved;
  if (lockedSession) {
    resolved = {
      contextMode: safeString(lockedSession.context_mode),
      uiMode:
        safeString(lockedSession.context_mode) === 'during_round'
          ? 'live_minimal'
          : 'guided_extended',
      signals: {
        locked_catalog_session: true,
        locked_pillar: lockedSession.pillar,
      },
    };
  } else {
    try {
      const resolvedBase = await resolveContextMode({
        requestedMode: requestedContextMode,
        userId,
        db,
      });
      resolved = { ...resolvedBase };
      if (entrySource === 'builder' && resolved.contextMode === 'during_round') {
        resolved.contextMode = 'off_day';
        resolved.uiMode = 'guided_extended';
        resolved.signals = {
          ...resolved.signals,
          builder_mode_adjusted: true,
        };
        logger.info('[MCv2:generate] builder during-round adjusted to off_day');
      }
    } catch (error) {
      logger.error('[MCv2:generate] resolveContextMode failed, using safe defaults', {
        error: error.message,
      });
      resolved = {
        contextMode: requestedContextMode === 'during_round' ? 'during_round' : 'off_day',
        uiMode: requestedContextMode === 'during_round' ? 'live_minimal' : 'guided_extended',
        signals: {
          context_resolver_fallback: true,
        },
      };
    }
  }
  logger.info('[MCv2:generate] context resolved', {
    contextMode: resolved.contextMode,
    uiMode: resolved.uiMode,
    signals: resolved.signals,
  });

  let templates = [];
  try {
    templates = await loadTemplates();
  } catch (error) {
    logger.error('[MCv2:generate] loadTemplates failed, using fallback templates only', {
      error: error.message,
    });
    templates = FALLBACK_TEMPLATES;
  }
  const templatesById = new Map(templates.map((t) => [t.id, t]));

  let contentLibrary = [];
  let scenarioRows = [];
  try {
    contentLibrary = await loadContentLibrary();
  } catch (error) {
    logger.error('[MCv2:generate] loadContentLibrary failed, using deterministic fallback content', {
      error: error.message,
    });
    contentLibrary = [];
  }
  try {
    scenarioRows = await loadScenarioTags();
  } catch (error) {
    logger.warn('[MCv2:generate] loadScenarioTags failed, continuing without scenario tags', {
      error: error.message,
    });
    scenarioRows = [];
  }

  let recentTemplateId = null;
  let recentSessionCount = 0;
  const recentContentIds = [];
  const recentCoachingTexts = [];
  try {
    const recentSessions = await db
      .collection('mindcoach_sessions')
      .where('user_id', '==', userId)
      .orderBy('created_at', 'desc')
      .limit(12)
      .get();

    recentSessionCount = recentSessions.size;
    if (!recentSessions.empty) {
      const docs = recentSessions.docs;
      recentTemplateId = safeString(docs[0].data().template_id) || null;
      for (const doc of docs) {
        const docData = doc.data() || {};
        const contentId = safeString(docData.content_id);
        if (contentId && !recentContentIds.includes(contentId)) {
          recentContentIds.push(contentId);
        }
        const coachingText = safeString(docData.coaching_text || docData.coachingText);
        if (coachingText && !recentCoachingTexts.includes(coachingText)) {
          recentCoachingTexts.push(coachingText);
        }
      }
    }
    logger.info('[MCv2:generate] recency context loaded', {
      recentTemplateId,
      recentSessionCount,
      recentContentCount: recentContentIds.length,
      recentCoachingTextCount: recentCoachingTexts.length,
    });
  } catch (err) {
    logger.warn('[MCv2:generate] failed to fetch recency context', { error: err.message });
  }

  const scenarioTags = detectScenarioTags({
    userMessage,
    contextMode: resolved.contextMode,
    scenarioTags: scenarioRows,
  });
  logger.info('[MCv2:generate] scenario tags detected', { scenarioTags });

  const templateId = lockedSession
    ? safeString(lockedSession.template_id)
    : chooseTemplate({
        contextMode: resolved.contextMode,
        scenarioTags,
        recentTemplateId,
        availableTemplateIds: templates
          .map((template) => template.id)
          .filter((id) => TEMPLATE_IDS.includes(id)),
      });

  const template = templatesById.get(templateId) || templatesById.get(FALLBACK_TEMPLATE_ID);
  const fallbackTemplate = templatesById.get(FALLBACK_TEMPLATE_ID) || templates[0];
  const effectiveTemplate = template || fallbackTemplate || FALLBACK_TEMPLATES[0];
  logger.info('[MCv2:generate] template selected', {
    templateId,
    templateName: effectiveTemplate ? effectiveTemplate.name : 'MISSING',
  });

  const fixedTargetSec = lockedSession
    ? Number(lockedSession.duration_sec || 0)
    : targetDurationSec > 0
    ? targetDurationSec
    : 0;
  const selectedDeliveryLength = pickNearestDeliveryLength({
    preferred: preferredDeliveryLength,
    template: effectiveTemplate,
    targetSec: fixedTargetSec,
    contextMode: resolved.contextMode,
  });
  const effectiveVarkMode =
    customVark === 'auto'
      ? chooseAutoVarkMode({
          recentSessionCount,
          contextMode: resolved.contextMode,
        })
      : customVark;
  const effectiveLevel = chooseExperienceLevel({
    mindsetBefore,
    contextMode: resolved.contextMode,
    recentSessionCount,
  });
  const rotationSeed = `${userId}|${effectiveTemplate.id}|${resolved.contextMode}|${selectedDeliveryLength}|${scenarioTags.join(',')}`;

  logger.info('[MCv2:generate] delivery preferences selected', {
    selectedDeliveryLength,
    effectiveVarkMode,
    effectiveLevel,
  });

  const selectedContent = selectContent({
    entries: contentLibrary,
    templateId: effectiveTemplate.id,
    varkMode: effectiveVarkMode,
    level: effectiveLevel,
    length: normalizeLength(selectedDeliveryLength),
    scenarioTags,
    recentContentIds,
    rotationSeed,
  });
  logger.info('[MCv2:generate] content selected', {
    contentId: selectedContent ? selectedContent.content_id : null,
    hasScriptText: !!(selectedContent && selectedContent.script_text),
    usedFallback: selectedContent == null,
  });

  const prompt = buildPromptText({
    template: effectiveTemplate,
    content: selectedContent,
    selectedDeliveryLength,
    fixedTargetSec,
    selectedLevel: effectiveLevel,
    contextMode: resolved.contextMode,
    lockedSession: lockedSession
      ? {
          key: sessionKey,
          name: requestedSessionName || lockedSession.name,
          descriptor:
            requestedSessionDescriptor || lockedSession.descriptor,
          pillar: requestedPillar || lockedSession.pillar,
        }
      : null,
    userMessage,
    customization: {
      ...customization,
      vark_mode: effectiveVarkMode,
    },
    scenarioTags,
  });

  logger.info('[MCv2:generate] calling Gemini');
  const aiResult = await generateWithGemini({ prompt });
  const rawOutput = aiResult.output || {};
  logger.info('[MCv2:generate] AI result received', {
    modelVersion: aiResult.modelVersion,
    hasOutput: !!aiResult.output,
    rawOutputKeys: Object.keys(rawOutput),
  });

  const timedResult = validateAndNormalizeTimedLines(rawOutput, resolved.contextMode);
  if (timedResult) {
    rawOutput.coaching_text = timedResult.coaching_text;
    logger.info('[MCv2:generate] timed lines accepted', {
      lineCount: timedResult.lines.length,
      totalDurationSec: timedResult.total_duration_sec,
    });
  } else {
    logger.info('[MCv2:generate] timed lines not present or rejected, using fallback text');
  }
  const deterministicOutput = buildDeterministicOutput({
    template: effectiveTemplate,
    content: selectedContent,
    selectedDeliveryLength,
    fixedTargetSec,
    contextMode: resolved.contextMode,
    uiMode: resolved.uiMode,
    userId,
    lockedSession: lockedSession
      ? {
          key: sessionKey,
          name: requestedSessionName || lockedSession.name,
          descriptor:
            requestedSessionDescriptor || lockedSession.descriptor,
        }
      : null,
    recentCoachingTexts,
    fallbackSeed: rotationSeed,
  });

  const validatorInput = rawOutput.template_id ? rawOutput : deterministicOutput;
  logger.info('[MCv2:generate] running validator', {
    source: rawOutput.template_id ? 'ai_output' : 'deterministic_fallback',
  });

  const { session: validatedSession, log } = validateAndCorrect({
    aiOutput: validatorInput,
    template: effectiveTemplate,
    fallbackTemplate,
    modelVersion: aiResult.modelVersion,
    promptVersion: PROMPT_VERSION,
    requestedTemplateId: effectiveTemplate.id,
  });
  logger.info('[MCv2:generate] validation complete', {
    validatorStatus: log.validator_status,
    failedRulesCount: log.failed_rules.length,
    failedRules: log.failed_rules,
    hasReplacements: Object.keys(log.replacements).length > 0,
  });

  // Enforce contextual split rule.
  if (resolved.uiMode === 'live_minimal') {
    validatedSession.follow_up_question = null;
  }

  if (timedResult) {
    validatedSession.lines = timedResult.lines;
    validatedSession.total_duration_sec = timedResult.total_duration_sec;
  } else if (
    !Array.isArray(validatedSession.lines) ||
    validatedSession.lines.length === 0
  ) {
    validatedSession.lines = deterministicOutput.lines;
    validatedSession.total_duration_sec = deterministicOutput.total_duration_sec;
  }

  validatedSession.session_key = safeString(
    validatedSession.session_key,
    sessionKey || effectiveTemplate.id,
  );
  validatedSession.session_name = safeString(
    validatedSession.session_name,
    requestedSessionName || safeString(lockedSession?.name, effectiveTemplate.name),
  );
  validatedSession.session_descriptor = safeString(
    validatedSession.session_descriptor,
    requestedSessionDescriptor ||
      safeString(lockedSession?.descriptor, safeString(selectedContent?.cta_question)),
  );
  validatedSession.duration_sec =
    Number(validatedSession.duration_sec || 0) ||
    fixedTargetSec ||
    Number(validatedSession.total_duration_sec || 0);

  const sessionRef = db.collection('mindcoach_sessions').doc();
  const runRef = db.collection('mindcoach_session_runs').doc();
  const validatorLogRef = db.collection('ai_validator_logs').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const sessionDoc = {
    schema_version: SCHEMA_VERSION,
    user_id: userId,
    created_at: now,
    updated_at: now,
    pillar: safeString(requestedPillar, safeString(lockedSession?.pillar, 'focus')),
    context_mode: resolved.contextMode,
    entry_source: entrySource,
    template_id: validatedSession.template_id,
    session_key: validatedSession.session_key,
    session_name: validatedSession.session_name,
    session_descriptor: validatedSession.session_descriptor,
    duration_sec: validatedSession.duration_sec,
    routine_type: validatedSession.routine_type,
    recommended_cue: validatedSession.recommended_cue,
    delivery_length: validatedSession.delivery_length,
    coaching_text: validatedSession.coaching_text,
    follow_up_question: validatedSession.follow_up_question,
    scenario_tags: scenarioTags,
    content_id: selectedContent ? selectedContent.content_id : null,
    vark_mode_selected: effectiveVarkMode,
    level_selected: effectiveLevel,
    validator_status: validatedSession.validator_status,
    model_version: validatedSession.model_version,
    prompt_version: validatedSession.prompt_version,
    mindset_before: mindsetBefore || null,

    // Compatibility mirror fields for current app models.
    userId: userId,
    timestamp: now,
    pillarKey: safeString(requestedPillar, safeString(lockedSession?.pillar, 'focus')),
    templateId: validatedSession.template_id,
    sessionKey: validatedSession.session_key,
    sessionName: validatedSession.session_name,
    sessionDescriptor: validatedSession.session_descriptor,
    durationSec: validatedSession.duration_sec,
    routineType: validatedSession.routine_type,
    cueUsed: validatedSession.recommended_cue,
    deliveryLength: validatedSession.delivery_length,
    coachingText: validatedSession.coaching_text,
    followUpQuestion: validatedSession.follow_up_question,
  };
  if (validatedSession.lines?.length) {
    sessionDoc.lines = validatedSession.lines;
    sessionDoc.total_duration_sec = validatedSession.total_duration_sec;
    sessionDoc.totalDurationSec = validatedSession.total_duration_sec;
  }

  const runDoc = {
    run_id: runRef.id,
    session_id: sessionRef.id,
    user_id: userId,
    status: 'in_progress',
    ui_mode: resolved.uiMode,
    started_at: now,
    updated_at: now,
  };

  const logDoc = {
    timestamp: now,
    user_id: userId,
    session_id: sessionRef.id,
    template_id_requested: log.template_id_requested,
    template_id_returned: log.template_id_returned,
    validator_status: log.validator_status,
    failed_rules: log.failed_rules,
    replacements: log.replacements,
    model_version: log.model_version,
    prompt_version: log.prompt_version,
    content_flags: log.content_flags,
    entry_source: entrySource,

    // Compatibility mirror fields.
    userId: userId,
    templateIdRequested: log.template_id_requested,
    templateIdReturned: log.template_id_returned,
    validatorStatus: log.validator_status,
    failedRules: log.failed_rules,
    modelVersion: log.model_version,
    promptVersion: log.prompt_version,
    contentFlags: log.content_flags,
    sessionId: sessionRef.id,
    createdTime: now,
  };

  const sanitizedSessionDoc = sanitizeForFirestore(sessionDoc);
  const sanitizedRunDoc = sanitizeForFirestore(runDoc);
  const sanitizedLogDoc = sanitizeForFirestore(logDoc);

  const batch = db.batch();
  batch.set(sessionRef, sanitizedSessionDoc);
  batch.set(runRef, sanitizedRunDoc);
  batch.set(validatorLogRef, sanitizedLogDoc);
  logger.info('[MCv2:generate] persisting to Firestore', {
    sessionDocId: sessionRef.id,
    runDocId: runRef.id,
    validatorLogDocId: validatorLogRef.id,
  });
  await commitBatchWithRetry(batch, 2);
  logger.info('[MCv2:generate] Firestore batch committed');

  logger.info('[MCv2:generate] RESPONSE', {
    sessionId: sessionRef.id,
    runId: runRef.id,
    contextMode: resolved.contextMode,
    uiMode: resolved.uiMode,
    validatorStatus: validatedSession.validator_status,
    templateId: validatedSession.template_id,
    hasTimedLines: !!(validatedSession.lines && validatedSession.lines.length),
  });

  return {
    session_id: sessionRef.id,
    run_id: runRef.id,
    context_mode: resolved.contextMode,
    ui_mode: resolved.uiMode,
    session: {
      schema_version: SCHEMA_VERSION,
      pillar: safeString(requestedPillar, safeString(lockedSession?.pillar, 'focus')),
      template_id: validatedSession.template_id,
      session_key: validatedSession.session_key,
      session_name: validatedSession.session_name,
      session_descriptor: validatedSession.session_descriptor,
      duration_sec: validatedSession.duration_sec,
      routine_type: validatedSession.routine_type,
      recommended_cue: validatedSession.recommended_cue,
      delivery_length: validatedSession.delivery_length,
      coaching_text: validatedSession.coaching_text,
      follow_up_question: validatedSession.follow_up_question,
      validator_status: validatedSession.validator_status,
      model_version: validatedSession.model_version,
      prompt_version: validatedSession.prompt_version,
      content_id: selectedContent ? selectedContent.content_id : null,
      scenario_tags: scenarioTags,
      vark_mode_selected: effectiveVarkMode,
      level_selected: effectiveLevel,
      ...(validatedSession.lines?.length && {
        lines: validatedSession.lines,
        total_duration_sec: validatedSession.total_duration_sec,
      }),
    },
  };
}

module.exports = {
  generateMindCoachSessionV2: functions
    .runWith({ secrets: [GEMINI_KEY_SECRET] })
    .https.onCall(generateMindCoachSessionV2),
};
