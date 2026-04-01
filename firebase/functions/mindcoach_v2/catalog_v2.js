const fs = require('fs');
const path = require('path');

const CATALOG_PATH = path.join(
  __dirname,
  '..',
  '..',
  '..',
  'assets',
  'jsons',
  'mindcoach_session_catalog_v1.json',
);

let catalogCache = null;

function loadMindCoachCatalog() {
  if (catalogCache) {
    return catalogCache;
  }

  const raw = fs.readFileSync(CATALOG_PATH, 'utf8');
  const parsed = JSON.parse(raw);
  const sessionsByKey = new Map();
  const pillarsByKey = new Map();

  for (const pillar of parsed.pillars || []) {
    pillarsByKey.set(pillar.key, pillar);
    for (const contextValue of Object.values(pillar.contexts || {})) {
      for (const session of contextValue.sessions || []) {
        sessionsByKey.set(session.key, {
          ...session,
          pillar: pillar.key,
          context_mode: contextValue.label
            ? contextKeyFromLabel(contextValue.label)
            : null,
        });
      }
    }
  }

  catalogCache = {
    ...parsed,
    sessionsByKey,
    pillarsByKey,
  };
  return catalogCache;
}

function getMindCoachSessionDefinition(sessionKey) {
  if (!sessionKey) {
    return null;
  }
  return loadMindCoachCatalog().sessionsByKey.get(String(sessionKey).trim()) || null;
}

function contextKeyFromLabel(label) {
  const normalized = String(label || '').trim().toLowerCase();
  switch (normalized) {
    case 'before round':
      return 'before_round';
    case 'during round':
      return 'during_round';
    case 'after round':
      return 'after_round';
    default:
      return normalized.replace(/\s+/g, '_');
  }
}

module.exports = {
  loadMindCoachCatalog,
  getMindCoachSessionDefinition,
};
