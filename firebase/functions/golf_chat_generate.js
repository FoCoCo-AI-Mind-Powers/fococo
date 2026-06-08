const axios = require('axios');
const functions = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');

// Server-side GolfChat fallback. The client first tries Firebase AI Logic
// (App Check authenticated, no raw key on device). When the underlying API
// key is flagged as "leaked" by Google's automatic scanner, the client falls
// back to this callable. The callable uses the `GEMINI_KEY_APP` secret from
// Secret Manager — that key never leaves the Cloud Functions runtime.
const GEMINI_KEY_SECRET = defineSecret('GEMINI_KEY_APP');

const DEFAULT_MODEL = 'gemini-2.5-flash';
const MAX_HISTORY_TURNS = 24;
const MAX_MESSAGE_CHARS = 4000;
// Internal reasoning budget — lets the model decide whether a visual helps and
// shape the data before answering. Separate from maxOutputTokens.
const GOLF_CHAT_THINKING_BUDGET = 2048;
// Cap on how many tool-call round-trips a single reply may take. Charts/tables
// are client-rendered, so one round is normally enough; the cap is a safety net.
const MAX_TOOL_ROUNDS = 3;

const FOCOCO_GOLFCHAT_SYSTEM =
  'GolfChat is not a swing coach. Keep responses focused on the golfer\'s decision, ' +
  'commitment, routine, focus, confidence, control, and response under pressure. ' +
  'Calm. Short. Observational. Pattern-based. One idea per reply. No lists. No therapy language. ' +
  'Structure every reply: Acknowledge → One observation from their data → One question only. ' +
  'Target 80–140 words; never exceed 180 words. Plain conversational text only — no markdown, ' +
  'headings, bullets, numbered lists, tables, or pipe characters. Never discuss swing mechanics, ' +
  'clubface, ball flight fixes, slice/hook causes, or body rotation sequences. ' +
  'Follow units_preference in context: metric uses metres and Celsius; do not use yards unless asked.';

const VISUAL_TOOL_GUIDANCE =
  'You can render visuals for the player when it genuinely helps understanding: ' +
  'call render_chart for trends, comparisons, or distributions, and render_table ' +
  'for side-by-side breakdowns. Prefer plain conversational text for most replies; ' +
  'reach for a visual only when the data is clearer shown than told. After rendering, ' +
  'briefly narrate what it shows in one or two sentences. Never invent numbers the ' +
  'player has not actually provided or that are not in the context.';

// Client-rendered tools: the function call args ARE the visual spec. The backend
// does not execute anything — it collects the spec, returns an acknowledgement so
// the model can narrate, and forwards the spec to the Flutter client to draw.
const VISUAL_TOOLS = [
  {
    functionDeclarations: [
      {
        name: 'render_chart',
        description:
          'Display a chart to the player to visualize golf performance or ' +
          'mental-game data. Use when a trend, comparison, or distribution is ' +
          'clearer as a visual than as text.',
        parameters: {
          type: 'object',
          properties: {
            chart_type: {
              type: 'string',
              enum: ['line', 'bar', 'radar'],
              description:
                'line for trends over time, bar for category comparisons, ' +
                'radar for multi-dimensional profiles.',
            },
            title: { type: 'string', description: 'Short chart title.' },
            x_label: { type: 'string', description: 'Optional x-axis label.' },
            y_label: { type: 'string', description: 'Optional y-axis label.' },
            series: {
              type: 'array',
              description: 'One or more data series to plot.',
              items: {
                type: 'object',
                properties: {
                  name: { type: 'string', description: 'Series label for the legend.' },
                  points: {
                    type: 'array',
                    description: 'Ordered data points for this series.',
                    items: {
                      type: 'object',
                      properties: {
                        label: { type: 'string', description: 'Category or x-axis label.' },
                        value: { type: 'number', description: 'Numeric value.' },
                      },
                      required: ['label', 'value'],
                    },
                  },
                },
                required: ['name', 'points'],
              },
            },
          },
          required: ['chart_type', 'series'],
        },
      },
      {
        name: 'render_table',
        description:
          'Display a structured table to the player. Use for side-by-side ' +
          'comparisons or itemized breakdowns that read better as a grid.',
        parameters: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'Short table title.' },
            columns: {
              type: 'array',
              description: 'Column headers, left to right.',
              items: { type: 'string' },
            },
            rows: {
              type: 'array',
              description: 'Rows; each row is an array of cell strings matching the columns.',
              items: { type: 'array', items: { type: 'string' } },
            },
          },
          required: ['columns', 'rows'],
        },
      },
    ],
  },
];

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

// Normalize a model function call into a validated client visual spec, or null
// if the args are too malformed to render.
function buildVisualFromCall(call) {
  const name = safeString(call?.name);
  const args = call && typeof call.args === 'object' && call.args ? call.args : {};

  if (name === 'render_chart') {
    const rawSeries = Array.isArray(args.series) ? args.series : [];
    const series = rawSeries
      .map((s) => ({
        name: safeString(s?.name),
        points: (Array.isArray(s?.points) ? s.points : [])
          .map((p) => ({ label: safeString(p?.label), value: Number(p?.value) }))
          .filter((p) => Number.isFinite(p.value)),
      }))
      .filter((s) => s.points.length > 0);
    if (series.length === 0) return null;

    const chartType = safeString(args.chart_type, 'bar').toLowerCase();
    return {
      type: 'chart',
      chart_type: ['line', 'bar', 'radar'].includes(chartType) ? chartType : 'bar',
      title: safeString(args.title),
      x_label: safeString(args.x_label),
      y_label: safeString(args.y_label),
      series,
    };
  }

  if (name === 'render_table') {
    const columns = (Array.isArray(args.columns) ? args.columns : []).map((c) => safeString(c));
    const rows = (Array.isArray(args.rows) ? args.rows : [])
      .map((r) => (Array.isArray(r) ? r.map((c) => safeString(c)) : []))
      .filter((r) => r.length > 0);
    if (columns.length === 0 || rows.length === 0) return null;
    return { type: 'table', title: safeString(args.title), columns, rows };
  }

  return null;
}

function getGeminiApiKeySafe() {
  try {
    return GEMINI_KEY_SECRET.value() || process.env.GEMINI_KEY_APP || '';
  } catch (error) {
    logger.warn('[golfChat:gemini] failed reading GEMINI_KEY_APP secret', {
      error: error.message,
    });
    return process.env.GEMINI_KEY_APP || '';
  }
}

function unitsContextLine(units) {
  if (units === 'imperial') {
    return 'User unit preference: Imperial. Use yards and Fahrenheit. '
      + 'Do not use metres unless the user asks.';
  }
  return 'User unit preference: Metric. Use metres and Celsius. '
    + 'Do not use yards unless the user asks.';
}

function enrichContextWithUnits(reflectionContext, preferredUnits) {
  const trimmed = safeString(reflectionContext);
  if (/User unit preference:/i.test(trimmed)) {
    return trimmed;
  }
  const line = unitsContextLine(safeString(preferredUnits, 'metric'));
  return trimmed ? `${trimmed}\n\n${line}` : line;
}

function buildContents({ history, userMessage, context }) {
  const contents = [];
  const trimmedContext = safeString(context);
  const systemBlock = [FOCOCO_GOLFCHAT_SYSTEM, VISUAL_TOOL_GUIDANCE, trimmedContext]
    .filter(Boolean)
    .join('\n\n');
  contents.push({
    role: 'user',
    parts: [{ text: `System context:\n${systemBlock}` }],
  });
  contents.push({
    role: 'model',
    parts: [
      {
        text: 'Understood. I will reflect, ask short follow-ups, keep my tone calm and non-judgmental, and render a chart or table only when it makes the data clearer.',
      },
    ],
  });

  const safeHistory = Array.isArray(history) ? history.slice(-MAX_HISTORY_TURNS) : [];
  for (const turn of safeHistory) {
    if (!turn || typeof turn !== 'object') continue;
    const role = safeString(turn.role).toLowerCase();
    const text = safeString(turn.content).slice(0, MAX_MESSAGE_CHARS);
    if (!text) continue;
    contents.push({
      role: role === 'user' ? 'user' : 'model',
      parts: [{ text }],
    });
  }

  contents.push({
    role: 'user',
    parts: [{ text: safeString(userMessage).slice(0, MAX_MESSAGE_CHARS) }],
  });

  return contents;
}

async function generateGolfChatResponseImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const userMessage = safeString(data.user_message);
  if (!userMessage) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'user_message is required',
    );
  }

  const conversationHistory = Array.isArray(data.conversation_history)
    ? data.conversation_history
    : [];
  const preferredUnits = safeString(data.preferred_units, 'metric');
  const reflectionContext = enrichContextWithUnits(
    safeString(data.context),
    preferredUnits,
  );
  const requestedModel = safeString(data.model, DEFAULT_MODEL);

  const apiKey = getGeminiApiKeySafe();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'GEMINI_KEY_APP secret is not configured.',
    );
  }

  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(requestedModel)}:generateContent`;

  const contents = buildContents({
    history: conversationHistory,
    userMessage,
    context: reflectionContext,
  });

  const visuals = [];
  let finalText = '';
  let totalAttempts = 0;

  try {
    for (let round = 0; round <= MAX_TOOL_ROUNDS; round += 1) {
      const { data, attempts } = await requestGeneration({ endpoint, apiKey, contents });
      totalAttempts += attempts;

      const candidate = data?.candidates?.[0];
      const parts = Array.isArray(candidate?.content?.parts)
        ? candidate.content.parts
        : [];

      const functionCalls = parts.filter((part) => part && part.functionCall);
      const text = parts
        .filter((part) => part && part.functionCall == null && part.thought !== true)
        .map((part) => part.text || '')
        .join('')
        .trim();
      if (text) finalText = text;

      if (functionCalls.length === 0 || round === MAX_TOOL_ROUNDS) {
        break;
      }

      // Echo the model turn back verbatim so the encrypted thoughtSignature on
      // each function-call part survives into the next request (required for
      // multi-step reasoning on 2.5/3 models).
      contents.push(candidate.content);

      const responseParts = functionCalls.map((part) => {
        const visual = buildVisualFromCall(part.functionCall);
        if (visual) visuals.push(visual);
        return {
          functionResponse: {
            name: safeString(part.functionCall?.name),
            response: { status: visual ? 'rendered' : 'ignored' },
          },
        };
      });
      contents.push({ role: 'user', parts: responseParts });
    }
  } catch (error) {
    const status = error?.response?.status;
    const upstream = error?.response?.data?.error?.message || error?.message;

    if (status === 400 && /api key/i.test(String(upstream))) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Gemini key configuration problem: ${upstream}`,
      );
    }

    throw new functions.https.HttpsError(
      'internal',
      `GolfChat generation failed: ${upstream || 'unknown error'}`,
    );
  }

  if (!finalText && visuals.length === 0) {
    throw new functions.https.HttpsError('internal', 'Empty response from Gemini');
  }

  return {
    response: finalText,
    visuals,
    model: requestedModel,
    attempts: totalAttempts,
  };
}

// Single generateContent request with a short retry. Returns the parsed body and
// the number of attempts it took; throws the last error if both attempts fail.
async function requestGeneration({ endpoint, apiKey, contents }) {
  let lastError;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      const response = await axios.post(
        endpoint,
        {
          generationConfig: {
            temperature: 0.7,
            topP: 0.95,
            maxOutputTokens: 768,
            thinkingConfig: { thinkingBudget: GOLF_CHAT_THINKING_BUDGET },
          },
          contents,
          tools: VISUAL_TOOLS,
        },
        {
          timeout: 20000,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        },
      );
      return { data: response.data, attempts: attempt + 1 };
    } catch (error) {
      lastError = error;
      logger.warn('[golfChat:gemini] generation attempt failed', {
        attempt: attempt + 1,
        error: error.message,
        status: error.response?.status,
      });
    }
  }
  throw lastError;
}

exports.generateGolfChatResponse = functions
  .runWith({ secrets: [GEMINI_KEY_SECRET] })
  .https.onCall(generateGolfChatResponseImpl);
