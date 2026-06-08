const fs = require('fs');
const path = require('path');

// Catalog ships with the Cloud Functions bundle (we cannot rely on the
// Flutter `assets/` folder being present on the Functions runtime). The
// canonical source lives in `assets/jsons/mindcoach_session_catalog_v1.json`
// at the repo root and a deploy-time copy is kept under `mindcoach_v2/data/`.
// We try the bundled path first and fall back to the legacy repo-relative
// path for local emulator runs from the repo root.
const BUNDLED_CATALOG_PATH = path.join(
  __dirname,
  'data',
  'mindcoach_session_catalog_v1.json',
);
const LEGACY_REPO_CATALOG_PATH = path.join(
  __dirname,
  '..',
  '..',
  '..',
  'assets',
  'jsons',
  'mindcoach_session_catalog_v1.json',
);

function readCatalogRaw() {
  if (fs.existsSync(BUNDLED_CATALOG_PATH)) {
    return fs.readFileSync(BUNDLED_CATALOG_PATH, 'utf8');
  }
  return fs.readFileSync(LEGACY_REPO_CATALOG_PATH, 'utf8');
}

let catalogCache = null;

function loadMindCoachCatalog() {
  if (catalogCache) {
    return catalogCache;
  }

  const raw = readCatalogRaw();
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
  try {
    return loadMindCoachCatalog().sessionsByKey.get(String(sessionKey).trim()) || null;
  } catch (e) {
    // Catalog couldn't be loaded — surface a softer signal so the caller can
    // proceed with the locked-session-less path instead of crashing the
    // entire callable with a generic INTERNAL error.
    return null;
  }
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
