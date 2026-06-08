const test = require('node:test');
const assert = require('node:assert/strict');

const { safeString } = (() => {
  function safeString(value, fallback = '') {
    if (value == null) return fallback;
    return String(value).trim();
  }
  return { safeString };
})();

test('archive preview uses last assistant line excerpt', () => {
  const lines = [
    'User: How was my round?',
    'Assistant: Your commitment held on the front nine.',
  ];
  const preview = lines[lines.length - 1].replace(/^(User|Assistant):\s*/, '');
  assert.equal(
    safeString(preview).slice(0, 160),
    'Your commitment held on the front nine.',
  );
});
