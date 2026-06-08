const test = require('node:test');
const assert = require('node:assert/strict');

const layer = require('../intelligence_layer')._private;

test('buildSignalSummary validates repeated signal from repeated training sessions', () => {
  const summary = layer.buildSignalSummary({
    roundSummaries: [],
    completedMindCoachSessions: [{}, {}],
    chatSummary: { message_count: 0 },
  });

  assert.equal(summary.repeated_signal_validated, true);
  assert.equal(summary.dominant_source, 'mindcoach');
});

test('deriveTrainingLedCoachingState chooses the dominant training pillar', () => {
  const coachingState = layer.deriveTrainingLedCoachingState('user_1', {
    focus_sessions: 1,
    confidence_sessions: 4,
    control_sessions: 2,
    training_gap: 'short',
  });

  assert.equal(coachingState.active_pillar, 'confidence');
  assert.equal(coachingState.next_best_action_id, 'confidence_back_the_shot');
});

test('isCompletedRoundRecord only treats completed rounds as ready for derivation', () => {
  assert.equal(
    layer.isCompletedRoundRecord('round_1', {
      userId: 'user_1',
      status: 'completed',
      date: '2026-04-08T10:00:00.000Z',
    }),
    true,
  );

  assert.equal(
    layer.isCompletedRoundRecord('round_2', {
      userId: 'user_1',
      status: 'active',
      date: '2026-04-08T10:00:00.000Z',
    }),
    false,
  );
});
