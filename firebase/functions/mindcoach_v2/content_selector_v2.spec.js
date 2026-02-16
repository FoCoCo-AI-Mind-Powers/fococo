const assert = require('assert');
const { selectContent } = require('./content_selector_v2');

(function run() {
  const result = selectContent({
    entries: [
      {
        content_id: 'MC_2',
        template_id: 'MC_T02_PRE_SHOT_FOCUS',
        vark_mode: 'ReadWrite',
        level: 'Foundation',
        length: 'standard',
        scenario_tags: 'indecision_over_ball',
      },
      {
        content_id: 'MC_1',
        template_id: 'MC_T02_PRE_SHOT_FOCUS',
        vark_mode: 'ReadWrite',
        level: 'Foundation',
        length: 'standard',
        scenario_tags: 'indecision_over_ball',
      },
    ],
    templateId: 'MC_T02_PRE_SHOT_FOCUS',
    varkMode: 'ReadWrite',
    level: 'Foundation',
    length: 'standard',
    scenarioTags: ['indecision_over_ball'],
  });

  assert.strictEqual(result.content_id, 'MC_1');
  console.log('content_selector_v2.spec.js passed');
})();
