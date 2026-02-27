const assert = require('assert');
const { selectContent } = require('./content_selector_v2');

(function run() {
  const baseEntries = [
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
    {
      content_id: 'MC_3',
      template_id: 'MC_T02_PRE_SHOT_FOCUS',
      vark_mode: 'ReadWrite',
      level: 'Foundation',
      length: 'standard',
      scenario_tags: 'indecision_over_ball',
    },
  ];

  const result = selectContent({
    entries: baseEntries,
    templateId: 'MC_T02_PRE_SHOT_FOCUS',
    varkMode: 'ReadWrite',
    level: 'Foundation',
    length: 'standard',
    scenarioTags: ['indecision_over_ball'],
  });

  assert.strictEqual(result.content_id, 'MC_1');

  const antiRepeatResult = selectContent({
    entries: baseEntries,
    templateId: 'MC_T02_PRE_SHOT_FOCUS',
    varkMode: 'ReadWrite',
    level: 'Foundation',
    length: 'standard',
    scenarioTags: ['indecision_over_ball'],
    recentContentIds: ['MC_1'],
  });

  assert.notStrictEqual(antiRepeatResult.content_id, 'MC_1');

  const deterministicA = selectContent({
    entries: baseEntries,
    templateId: 'MC_T02_PRE_SHOT_FOCUS',
    varkMode: 'ReadWrite',
    level: 'Foundation',
    length: 'standard',
    scenarioTags: ['indecision_over_ball'],
    recentContentIds: ['MC_1'],
    rotationSeed: 'seed-A',
  });
  const deterministicB = selectContent({
    entries: baseEntries,
    templateId: 'MC_T02_PRE_SHOT_FOCUS',
    varkMode: 'ReadWrite',
    level: 'Foundation',
    length: 'standard',
    scenarioTags: ['indecision_over_ball'],
    recentContentIds: ['MC_1'],
    rotationSeed: 'seed-A',
  });

  assert.strictEqual(deterministicA.content_id, deterministicB.content_id);

  const allRecentFallback = selectContent({
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
    recentContentIds: ['MC_1', 'MC_2'],
  });

  assert.strictEqual(allRecentFallback.content_id, 'MC_2');
  console.log('content_selector_v2.spec.js passed');
})();
