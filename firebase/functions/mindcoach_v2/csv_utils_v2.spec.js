const assert = require('assert');

const {
  parseCsvContent,
  validateContentLibraryIntegrity,
} = require('./csv_utils_v2');
const { TEMPLATE_IDS } = require('./contracts_v2');

(function run() {
  const parsed = parseCsvContent(
    [
      'content_id,template_id,vark_mode,level,length,scenario_tags,script_text',
      'MC_1,MC_T02_PRE_SHOT_FOCUS,ReadWrite,Foundation,standard,walking_reset,\"Line one.',
      'Line two with comma, still same field.\"',
    ].join('\n'),
  );

  assert.strictEqual(parsed.length, 1);
  assert.ok(parsed[0].script_text.includes('Line two with comma, still same field.'));

  const entries = [];
  for (const templateId of TEMPLATE_IDS) {
    for (const varkMode of ['Visual', 'Aural', 'ReadWrite', 'Kinesthetic']) {
      for (const level of ['Foundation', 'Build', 'Compete', 'Maintain']) {
        for (const length of ['micro', 'standard', 'deep']) {
          entries.push({
            content_id: `${templateId}_${varkMode}_${level}_${length}`,
            template_id: templateId,
            vark_mode: varkMode,
            level,
            length,
          });
        }
      }
    }
  }

  const report = validateContentLibraryIntegrity(entries, {
    templateIds: TEMPLATE_IDS,
    expectedRows: 384,
  });
  assert.strictEqual(report.ok, true);
  assert.strictEqual(report.observedRows, 384);
  assert.strictEqual(report.missingCombinations.length, 0);

  const missingReport = validateContentLibraryIntegrity(entries.slice(1), {
    templateIds: TEMPLATE_IDS,
    expectedRows: 384,
  });
  assert.strictEqual(missingReport.ok, false);
  assert.ok(missingReport.errors.some((error) => error.startsWith('content_rows_too_low')));

  console.log('csv_utils_v2.spec.js passed');
})();
