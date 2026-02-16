const assert = require('assert');
const { chooseTemplate } = require('./template_selector_v2');

(function run() {
  const selected = chooseTemplate({
    contextMode: 'during_round',
    scenarioTags: ['after_bad_shot_release'],
    recentTemplateId: 'MC_T05_MISTAKE_RECOVERY',
    availableTemplateIds: [
      'MC_T02_PRE_SHOT_FOCUS',
      'MC_T03_BETWEEN_SHOTS_RESET',
      'MC_T05_MISTAKE_RECOVERY',
    ],
  });

  assert.strictEqual(selected, 'MC_T03_BETWEEN_SHOTS_RESET');
  console.log('template_selector_v2.spec.js passed');
})();
