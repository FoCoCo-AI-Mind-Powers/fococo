const test = require('node:test');
const assert = require('node:assert/strict');

const engine = require('../intelligence_engine');

function iso(day, hour = 10) {
  return new Date(Date.UTC(2026, 3, day, hour, 0, 0)).toISOString();
}

function buildRound(overrides = {}) {
  return {
    round_id: 'round_1',
    user_id: 'user_1',
    round_date: iso(8),
    start_time: iso(8, 8),
    end_time: iso(8, 13),
    holes_played: 18,
    score_relative_to_par: 4,
    ...overrides,
  };
}

function buildMoment(index, overrides = {}) {
  return {
    moment_id: `moment_${index}`,
    user_id: 'user_1',
    round_id: 'round_1',
    hole_number: index,
    timestamp: iso(8, 8 + index),
    focus_level: 'high',
    commitment: 'high',
    pre_shot_preparation: 'yes',
    cue_used: 'deep_breath',
    shot_type: 'tee',
    shot_result: 'good',
    input_type: 'tap',
    transcript: null,
    mindsnap_sequence: null,
    ...overrides,
  };
}

function buildPatternSummary(index, overrides = {}) {
  return {
    round_id: `round_${index}`,
    user_id: 'user_1',
    round_date: iso(10 - index),
    score_relative_to_par: index,
    late_round_drop: false,
    recovery_trend: 'steady_recovery',
    key_pattern: 'The round held together.',
    risk_pattern: 'The round slipped when attention thinned.',
    pillar_impacts: {
      focus: 0.2,
      confidence: 0.2,
      control: 0.2,
    },
    weakness_flags: {
      focus: false,
      confidence: false,
      control: false,
    },
    metrics: {
      focus_average: 0.6,
      commitment_average: 0.6,
      preparation_average: 0.6,
      recovery_score: 0.6,
      routine_effect_delta: 0,
    },
    pattern_tags: [],
    ...overrides,
  };
}

test('buildRoundSummary excludes null preparation and cue values until five valid events exist', () => {
  const summary = engine.buildRoundSummary({
    round: buildRound(),
    moments: [
      buildMoment(1, { pre_shot_preparation: 'yes', cue_used: 'deep_breath', shot_result: 'good' }),
      buildMoment(2, { pre_shot_preparation: 'no', cue_used: 'deep_breath', shot_result: 'bad' }),
      buildMoment(3, { pre_shot_preparation: 'partly', cue_used: 'deep_breath', shot_result: 'ok' }),
      buildMoment(4, { pre_shot_preparation: 'yes', cue_used: 'deep_breath', shot_result: 'good' }),
      buildMoment(5, { pre_shot_preparation: null, cue_used: null, shot_result: 'good' }),
      buildMoment(6, { pre_shot_preparation: null, cue_used: null, shot_result: 'bad' }),
    ],
  });

  assert.equal(summary.prep_trend, 'insufficient_data');
  assert.equal(summary.metrics.preparation_average, null);
  assert.equal(summary.metrics.cue_used, null);
});

test('calculateRecoveryScore measures after-bad-shot recovery windows', () => {
  const score = engine.calculateRecoveryScore([
    buildMoment(1, { shot_result: 'bad', focus_level: 'low' }),
    buildMoment(2, { shot_result: 'good', focus_level: 'high' }),
    buildMoment(3, { shot_result: 'ok', focus_level: 'mid' }),
    buildMoment(4, { shot_result: 'bad', focus_level: 'low' }),
    buildMoment(5, { shot_result: 'ok', focus_level: 'low' }),
  ]);

  assert.equal(score.window_count, 2);
  assert.equal(score.recovered_count, 1);
  assert.equal(score.unresolved_count, 1);
  assert.equal(score.score, 0.5);
});

test('segmentForHole keeps early, mid, and late segments stable', () => {
  assert.equal(engine.segmentForHole(1, 18), 'early');
  assert.equal(engine.segmentForHole(7, 18), 'mid');
  assert.equal(engine.segmentForHole(16, 18), 'late');
});

test('deriveUserPatterns weights the latest two rounds twice when choosing the pillar', () => {
  const patterns = engine.deriveUserPatterns([
    buildPatternSummary(1, {
      pillar_impacts: { focus: 0.95, confidence: 0.2, control: 0.2 },
      weakness_flags: { focus: true, confidence: false, control: false },
    }),
    buildPatternSummary(2, {
      pillar_impacts: { focus: 0.9, confidence: 0.2, control: 0.2 },
      weakness_flags: { focus: true, confidence: false, control: false },
    }),
    buildPatternSummary(3, {
      pillar_impacts: { focus: 0.2, confidence: 0.82, control: 0.2 },
      weakness_flags: { focus: false, confidence: true, control: false },
    }),
    buildPatternSummary(4, {
      pillar_impacts: { focus: 0.2, confidence: 0.8, control: 0.2 },
      weakness_flags: { focus: false, confidence: true, control: false },
    }),
    buildPatternSummary(5, {
      pillar_impacts: { focus: 0.2, confidence: 0.78, control: 0.2 },
      weakness_flags: { focus: false, confidence: true, control: false },
    }),
  ]);

  assert.equal(patterns.primary_pillar_need.pillar, 'focus');
});

test('buildContextCacheDocuments produces deterministic context hashes', () => {
  const userPatterns = engine.deriveThinDataUserPatterns('user_1');
  const coachingState = engine.deriveThinDataCoachingState('user_1');
  const trainingSummary = engine.deriveThinDataTrainingSummary('user_1');
  const chatSummary = engine.buildChatSummary(
    { user_id: 'user_1', session_id: null, ended_at: null, created_at: null },
    [],
  );
  const input = {
    userPatterns,
    coachingState,
    trainingSummary,
    chatSummary,
    roundSummaries: [],
    roundInsights: [],
    recentInsightHistory: [],
  };

  const docsA = engine.buildContextCacheDocuments(input);
  const docsB = engine.buildContextCacheDocuments(input);

  assert.equal(docsA.fococo_tab.context_hash, docsB.fococo_tab.context_hash);
  assert.equal(docsA.golfchat.context_hash, docsB.golfchat.context_hash);
});

test('buildChatSummary ignores messages without finalized transcript text', () => {
  const summary = engine.buildChatSummary(
    {
      user_id: 'user_1',
      session_id: 'chat_1',
      ended_at: iso(8),
      created_at: iso(8),
    },
    [
      {
        role: 'user',
        content: '',
        timestamp: iso(8),
        message_type: 'audio',
      },
      {
        role: 'assistant',
        content: 'What happened on the back nine?',
        timestamp: iso(8, 11),
        message_type: 'text',
      },
    ],
  );

  assert.equal(summary.message_count, 0);
  assert.deepEqual(summary.themes, []);
});
