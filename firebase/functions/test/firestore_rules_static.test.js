const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rulesPath = path.join(__dirname, '..', '..', 'firestore.rules');
const rules = fs.readFileSync(rulesPath, 'utf8');

const derivedCollections = [
  'round_summaries',
  'round_insights',
  'user_patterns',
  'coaching_state',
  'training_summary',
  'chat_summary',
  'context_cache',
  'insight_history',
];

for (const collection of derivedCollections) {
  test(`rules keep ${collection} owner-readable and backend-write-only`, () => {
    const matchBlock = new RegExp(
      `match /${collection}/\\{document\\} \\{[\\s\\S]*?allow read: if ownsResourceDoc\\(\\);[\\s\\S]*?allow create, update, delete: if false;`,
    );
    assert.match(rules, matchBlock);
  });
}
