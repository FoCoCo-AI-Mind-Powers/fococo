const test = require('node:test');
const assert = require('node:assert/strict');

const dailyInsights = require('../fococo_daily_insights')._private;
const engine = require('../intelligence_engine');

test('findReusableInsight returns the previous entry when the context hash is unchanged', () => {
  const reusable = dailyInsights.findReusableInsight(
    [
      { context_hash: 'hash_a', insight_text: 'Old insight.' },
      { context_hash: 'hash_b', insight_text: 'Other insight.' },
    ],
    'hash_a',
  );

  assert.equal(reusable.insight_text, 'Old insight.');
});

test('serializeHistoryInsight keeps the mobile payload contract', () => {
  const serialized = dailyInsights.serializeHistoryInsight('doc_1', {
    insight_text: 'You stayed steadier once the routine settled in.',
    date: '2026-04-08',
    opened: true,
    played_audio: true,
    time_on_screen_sec: 12.5,
    generation_version: 'fococo_tab_v3',
  });

  assert.deepEqual(serialized, {
    insightId: 'doc_1',
    insightText: 'You stayed steadier once the routine settled in.',
    insightDate: '2026-04-08',
    playedAudio: true,
    opened: true,
    timeOnScreenSec: 12.5,
    generationVersion: 'fococo_tab_v3',
  });
});

test('migrateLegacyInsightToHistory preserves engagement fields from ai_insights', () => {
  const history = dailyInsights.migrateLegacyInsightToHistory(
    {
      id: 'legacy_doc',
      data: {
        insightContent: 'Legacy text.',
        insightDate: '2026-04-08',
        contextPayloadHash: 'context_hash_1',
        generationVersion: 'fococo_tab_v1',
        opened: true,
        playedAudio: true,
        timeOnScreenSec: 19,
      },
    },
    'user_1',
    '2026-04-08',
  );

  assert.equal(history.user_id, 'user_1');
  assert.equal(history.insight_text, 'Legacy text.');
  assert.equal(history.context_hash, 'context_hash_1');
  assert.equal(history.opened, true);
  assert.equal(history.played_audio, true);
  assert.equal(history.time_on_screen_sec, 19);
});

test('normalizeInsightText formats exactly two sentences with a paragraph break', () => {
  const normalized = dailyInsights.normalizeInsightText(
    'Your best shots came when the decision was clear.\nToday, protect that moment before the swing.',
  );
  assert.equal(
    normalized,
    'Your best shots came when the decision was clear.\n\nToday, protect that moment before the swing.',
  );
});

test('validateInsightText rejects incomplete and generic insights', () => {
  assert.equal(
    dailyInsights.validateInsightText(
      'You often drift when the round speeds up and',
    ),
    'needs_exactly_two_sentences',
  );
  assert.equal(
    dailyInsights.validateInsightText(
      'You are ready to elevate your mental game today.\n\nStart your journey with confidence now.',
    ),
    'generic_copy',
  );
  assert.equal(
    dailyInsights.validateInsightText(
      'Your best shots came when the decision was clear before you stepped in.\n\nToday, protect that moment before the swing.',
    ),
    '',
  );
});

test('coerceInsightTextFromModelOutput prefers valid structured JSON', () => {
  const text = dailyInsights.coerceInsightTextFromModelOutput(
    JSON.stringify({
      observation:
        'Your best shots came when the decision was clear before you stepped in.',
      direction: 'Today, protect that moment before the swing.',
    }),
  );
  assert.equal(
    text,
    'Your best shots came when the decision was clear before you stepped in.\n\nToday, protect that moment before the swing.',
  );
});

test('coerceInsightTextFromModelOutput falls back to plain text when JSON is invalid', () => {
  const text = dailyInsights.coerceInsightTextFromModelOutput(
    'You reset faster after bogeys last round.\n\nName one cue before your first tee shot today.',
  );
  assert.equal(
    text,
    'You reset faster after bogeys last round.\n\nName one cue before your first tee shot today.',
  );
});

test('buildGeminiInsightGenerationConfig adds schema only when structured mode is enabled', () => {
  const plain = dailyInsights.buildGeminiInsightGenerationConfig(false);
  const structured = dailyInsights.buildGeminiInsightGenerationConfig(true);
  assert.equal(plain.responseMimeType, undefined);
  assert.equal(structured.responseMimeType, 'application/json');
  assert.equal(structured.responseSchema.required.join(','), 'observation,direction');
});

test('buildFococoTabInsightPayload includes required grounding fields', () => {
  const userPatterns = engine.deriveThinDataUserPatterns('user_1');
  userPatterns.top_risk_pattern = 'Commitment softened after a bad tee shot.';
  userPatterns.top_strength_pattern = 'Routine held steady on approach shots.';
  const coachingState = engine.deriveThinDataCoachingState('user_1');
  const payload = engine.buildFococoTabInsightPayload({
    userPatterns,
    coachingState,
    roundSummaries: [],
    activeRound: null,
    justTalkPhrases: ['Stay with the breath before the putt.'],
    lastMindCoachSession: {
      session_key: 'focus_one_thing',
      pillar: 'focus',
      completed_at: '2026-05-30T12:00:00.000Z',
      context_mode: 'pre_round',
    },
    chatSummary: { themes: ['pressure'] },
    trainingSummary: engine.deriveThinDataTrainingSummary('user_1'),
  });

  assert.equal(payload.weakest_pillar, 'focus');
  assert.equal(payload.recent_missed_pattern, 'Commitment softened after a bad tee shot.');
  assert.equal(payload.recent_justtalk_phrases.length, 1);
  assert.equal(payload.last_mindcoach_session.session_key, 'focus_one_thing');
  assert.equal(payload.active_round_status.status, 'none');
});
