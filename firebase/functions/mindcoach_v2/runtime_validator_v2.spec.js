const assert = require('assert');
const { validateAndCorrect } = require('./runtime_validator_v2');

const template = {
  id: 'MC_T02_PRE_SHOT_FOCUS',
  name: 'Pre-Shot Focus',
  allowed_routine_types: ['📐 Pre-Shot'],
  allowed_cues: ['🎯 Visualization', '🗣️ Trigger Word', '💬 Self-Talk'],
  delivery_lengths: ['micro_10s', 'standard_30s', 'deep_90s'],
};

(function run() {
  const result = validateAndCorrect({
    aiOutput: {
      template_id: 'INVALID',
      routine_type: 'Bad',
      recommended_cue: 'Bad Cue',
      delivery_length: 'invalid_length',
      coaching_text: 'This will fix your anxiety disorder quickly.',
      follow_up_question: 'q1? q2?',
      lines: [
        { text: 'line 1', startMs: 0, durationMs: 1200, endMs: 1200 },
      ],
      total_duration_sec: 12,
    },
    template,
    fallbackTemplate: template,
    modelVersion: 'test-model',
    promptVersion: 'mindcoach_system_v1',
    requestedTemplateId: 'MC_T02_PRE_SHOT_FOCUS',
  });

  assert.strictEqual(result.session.template_id, 'MC_T02_PRE_SHOT_FOCUS');
  assert.strictEqual(result.session.validator_status, 'FAIL_FALLBACK');
  assert.ok(result.log.failed_rules.includes('forbidden_language_detected'));
  assert.strictEqual(result.session.lines, undefined);
  assert.strictEqual(result.session.total_duration_sec, undefined);

  console.log('runtime_validator_v2.spec.js passed');
})();
