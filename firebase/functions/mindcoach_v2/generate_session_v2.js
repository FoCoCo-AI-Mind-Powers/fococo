const fs = require('fs');
const path = require('path');
const axios = require('axios');
const functions = require('firebase-functions/v1');
const { defineString } = require('firebase-functions/params');
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
  TEMPLATE_IDS,
  TEMPLATES_JSON_PATH,
  CONTENT_LIBRARY_CSV_PATH,
  SCENARIO_TAGS_CSV_PATH,
} = require('./contracts_v2');
const { resolveContextMode } = require('./context_resolver_v2');
const { chooseTemplate } = require('./template_selector_v2');
const { selectContent, normalizeLength } = require('./content_selector_v2');
const { validateAndCorrect } = require('./runtime_validator_v2');

const db = admin.firestore();
const GEMINI_API_KEY_PARAM = defineString('GEMINI_API_KEY', { default: '' });

let promptCache = null;
let templatesCache = null;
let contentCache = null;
let scenarioCache = null;

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
];

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function parseCsvLine(line) {
  const result = [];
  let inQuotes = false;
  let current = '';

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current);
  return result;
}

function parseCsvFile(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const lines = raw.split('\n').filter((line) => line.trim().length > 0);
  if (!lines.length) {
    return [];
  }

  const headers = parseCsvLine(lines[0]).map((header) => header.trim());
  const rows = [];

  for (let i = 1; i < lines.length; i += 1) {
    const values = parseCsvLine(lines[i]);
    if (values.length < headers.length) {
      continue;
    }

    const row = {};
    headers.forEach((header, index) => {
      row[header] = safeString(values[index]);
    });
    rows.push(row);
  }

  return rows;
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
    return templatesCache;
  }

  try {
    const snapshot = await db.collection('mindcoach_templates').get();
    if (!snapshot.empty) {
      const mapped = snapshot.docs.map((doc) => mapTemplateDoc(doc.data(), doc.id));
      templatesCache = mapped.filter((template) => template.id);
      if (templatesCache.length) {
        return templatesCache;
      }
    }
  } catch (_) {
    // Continue to JSON fallback.
  }

  try {
    const json = JSON.parse(fs.readFileSync(TEMPLATES_JSON_PATH, 'utf8'));
    const templates = (json.templates || []).map((template) =>
      mapTemplateDoc(template, template.id),
    );
    templatesCache = templates;
    return templates;
  } catch (_) {
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

async function loadContentLibrary() {
  if (contentCache) {
    return contentCache;
  }

  try {
    const snapshot = await db.collection('mindcoach_content_library').get();
    if (!snapshot.empty) {
      contentCache = snapshot.docs.map((doc) => mapContentRow(doc.data()));
      if (contentCache.length) {
        return contentCache;
      }
    }
  } catch (_) {
    // Continue to CSV fallback.
  }

  try {
    contentCache = parseCsvFile(CONTENT_LIBRARY_CSV_PATH).map(mapContentRow);
  } catch (_) {
    contentCache = [];
  }
  return contentCache;
}

async function loadScenarioTags() {
  if (scenarioCache) {
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
        return scenarioCache;
      }
    }
  } catch (_) {
    // Continue to CSV fallback.
  }

  try {
    scenarioCache = parseCsvFile(SCENARIO_TAGS_CSV_PATH).map((row) => ({
      scenario_tag: safeString(row.scenario_tag),
      description: safeString(row.description),
    }));
  } catch (_) {
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

function buildPromptText({
  template,
  content,
  selectedDeliveryLength,
  contextMode,
  userMessage,
  customization,
  scenarioTags,
}) {
  if (!promptCache) {
    const promptPath = path.join(__dirname, 'prompts', 'mindcoach_system_v1.txt');
    promptCache = fs.readFileSync(promptPath, 'utf8');
  }

  const baseScript = safeString(content?.script_text);

  return `${promptCache}

Context mode: ${contextMode}
Template ID: ${template.id}
Template name: ${template.name}
Allowed routine types: ${template.allowed_routine_types.join(', ')}
Allowed cues: ${template.allowed_cues.join(', ')}
Allowed delivery lengths: ${template.delivery_lengths.join(', ')}
Preferred delivery length: ${selectedDeliveryLength}
Detected scenario tags: ${scenarioTags.join(', ') || 'none'}
User message: ${safeString(userMessage, 'none')}
Customization goal: ${safeString(customization.goal, 'none')}
Customization tone: ${safeString(customization.tone, 'auto')}
Customization vark_mode: ${safeString(customization.vark_mode, 'auto')}
Reference script: ${baseScript || 'none'}

Return JSON only with keys:
template_id, routine_type, recommended_cue, delivery_length, coaching_text, follow_up_question.
Do not output markdown.
`;
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
  const apiKey = GEMINI_API_KEY_PARAM.value() || process.env.GEMINI_API_KEY || '';

  if (!apiKey) {
    return {
      output: null,
      modelVersion: 'gemini_unavailable_no_api_key',
    };
  }

  const endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      const response = await axios.post(
        `${endpoint}?key=${apiKey}`,
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
        },
      );

      const text =
        response.data?.candidates?.[0]?.content?.parts?.[0]?.text || null;

      return {
        output: parseJsonFromModelText(text),
        modelVersion: 'gemini-2.5-flash',
      };
    } catch (_) {
      // Retry once before fallback.
    }
  }

  return {
    output: null,
    modelVersion: 'gemini_generation_failed',
  };
}

function buildDeterministicOutput({
  template,
  content,
  selectedDeliveryLength,
  contextMode,
  uiMode,
}) {
  const routineType = template.allowed_routine_types[0] || '📐 Pre-Shot';
  const cue = template.allowed_cues[0] || '😮‍💨 Deep Breath';

  let coachingText =
    safeString(content?.script_text) ||
    'Pause. One breath. Let the last shot go. Your only job is the next target.';

  if (uiMode === 'live_minimal') {
    coachingText = coachingText
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean)
      .slice(0, 3)
      .join(' ');
  }

  return {
    template_id: template.id,
    routine_type: routineType,
    recommended_cue: cue,
    delivery_length: selectedDeliveryLength,
    coaching_text: coachingText,
    follow_up_question:
      contextMode === 'during_round' ? null : safeString(content?.cta_question) || null,
  };
}

async function applyRateLimit(userId) {
  const profileRef = db.collection('mindcoach_user_profiles').doc(userId);
  const profileSnap = await profileRef.get();

  const now = new Date();
  const dayKey = now.toISOString().slice(0, 10);
  const hourKey = `${dayKey}-${now.getUTCHours()}`;

  let dailyCount = 0;
  let hourlyCount = 0;

  if (profileSnap.exists) {
    const data = profileSnap.data() || {};
    dailyCount = data.daily_key === dayKey ? Number(data.daily_count || 0) : 0;
    hourlyCount = data.hourly_key === hourKey ? Number(data.hourly_count || 0) : 0;
  }

  if (dailyCount >= 50) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Daily MindCoach generation limit reached.',
    );
  }
  if (hourlyCount >= 10) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Hourly MindCoach generation limit reached.',
    );
  }

  await profileRef.set(
    {
      user_id: userId,
      daily_key: dayKey,
      daily_count: dailyCount + 1,
      hourly_key: hourKey,
      hourly_count: hourlyCount + 1,
      last_request_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
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
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Data processing consent is required for MindCoach AI generation.',
      );
    }
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    // Keep this check non-blocking on transient read errors.
  }
}

async function generateMindCoachSessionV2(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const userId = context.auth.uid;
  const requestedContextMode = safeString(data.context_mode, 'auto');
  const entrySource = safeString(data.entry_source, 'home_primary');
  const userMessage = safeString(data.user_message);
  const mindsetBefore = safeString(data.mindset_before);
  const preferredDeliveryLength = safeString(data.preferred_delivery_length, 'auto');
  const customization =
    data.customization && typeof data.customization === 'object'
      ? data.customization
      : {};

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

  await assertUserConsent(userId);
  await applyRateLimit(userId);

  const resolvedBase = await resolveContextMode({
    requestedMode: requestedContextMode,
    userId,
    db,
  });
  const resolved = { ...resolvedBase };
  if (entrySource === 'builder' && resolved.contextMode === 'during_round') {
    resolved.contextMode = 'off_day';
    resolved.uiMode = 'guided_extended';
    resolved.signals = {
      ...resolved.signals,
      builder_mode_adjusted: true,
    };
  }

  const templates = await loadTemplates();
  const templatesById = new Map(templates.map((t) => [t.id, t]));

  const contentLibrary = await loadContentLibrary();
  const scenarioRows = await loadScenarioTags();

  let recentTemplateId = null;
  try {
    const recentSession = await db
      .collection('mindcoach_sessions')
      .where('user_id', '==', userId)
      .orderBy('created_at', 'desc')
      .limit(1)
      .get();

    if (!recentSession.empty) {
      recentTemplateId = safeString(recentSession.docs[0].data().template_id) || null;
    }
  } catch (_) {
    // Best-effort only.
  }

  const scenarioTags = detectScenarioTags({
    userMessage,
    contextMode: resolved.contextMode,
    scenarioTags: scenarioRows,
  });

  const templateId = chooseTemplate({
    contextMode: resolved.contextMode,
    scenarioTags,
    recentTemplateId,
    availableTemplateIds: templates
      .map((template) => template.id)
      .filter((id) => TEMPLATE_IDS.includes(id)),
  });

  const template = templatesById.get(templateId) || templatesById.get(FALLBACK_TEMPLATE_ID);
  const fallbackTemplate = templatesById.get(FALLBACK_TEMPLATE_ID) || templates[0];

  const selectedDeliveryLength = pickDeliveryLength({
    preferred: preferredDeliveryLength,
    template,
    contextMode: resolved.contextMode,
  });

  const selectedContent = selectContent({
    entries: contentLibrary,
    templateId: template.id,
    varkMode: customVark,
    level: 'Foundation',
    length: normalizeLength(selectedDeliveryLength),
    scenarioTags,
  });

  const prompt = buildPromptText({
    template,
    content: selectedContent,
    selectedDeliveryLength,
    contextMode: resolved.contextMode,
    userMessage,
    customization,
    scenarioTags,
  });

  const aiResult = await generateWithGemini({ prompt });
  const deterministicOutput = buildDeterministicOutput({
    template,
    content: selectedContent,
    selectedDeliveryLength,
    contextMode: resolved.contextMode,
    uiMode: resolved.uiMode,
  });

  const { session: validatedSession, log } = validateAndCorrect({
    aiOutput: aiResult.output || deterministicOutput,
    template,
    fallbackTemplate,
    modelVersion: aiResult.modelVersion,
    promptVersion: PROMPT_VERSION,
    requestedTemplateId: template.id,
  });

  // Enforce contextual split rule.
  if (resolved.uiMode === 'live_minimal') {
    validatedSession.follow_up_question = null;
  }

  const sessionRef = db.collection('mindcoach_sessions').doc();
  const runRef = db.collection('mindcoach_session_runs').doc();
  const validatorLogRef = db.collection('ai_validator_logs').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const sessionDoc = {
    schema_version: SCHEMA_VERSION,
    user_id: userId,
    created_at: now,
    updated_at: now,
    context_mode: resolved.contextMode,
    entry_source: entrySource,
    template_id: validatedSession.template_id,
    routine_type: validatedSession.routine_type,
    recommended_cue: validatedSession.recommended_cue,
    delivery_length: validatedSession.delivery_length,
    coaching_text: validatedSession.coaching_text,
    follow_up_question: validatedSession.follow_up_question,
    scenario_tags: scenarioTags,
    content_id: selectedContent ? selectedContent.content_id : null,
    validator_status: validatedSession.validator_status,
    model_version: validatedSession.model_version,
    prompt_version: validatedSession.prompt_version,
    mindset_before: mindsetBefore || null,

    // Compatibility mirror fields for current app models.
    userId: userId,
    timestamp: now,
    templateId: validatedSession.template_id,
    routineType: validatedSession.routine_type,
    cueUsed: validatedSession.recommended_cue,
    deliveryLength: validatedSession.delivery_length,
    coachingText: validatedSession.coaching_text,
    followUpQuestion: validatedSession.follow_up_question,
  };

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

  const batch = db.batch();
  batch.set(sessionRef, sessionDoc);
  batch.set(runRef, runDoc);
  batch.set(validatorLogRef, logDoc);
  await batch.commit();

  return {
    session_id: sessionRef.id,
    run_id: runRef.id,
    context_mode: resolved.contextMode,
    ui_mode: resolved.uiMode,
    session: {
      schema_version: SCHEMA_VERSION,
      template_id: validatedSession.template_id,
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
    },
  };
}

module.exports = {
  generateMindCoachSessionV2: functions.https.onCall(generateMindCoachSessionV2),
};
