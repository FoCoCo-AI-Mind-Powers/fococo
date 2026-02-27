const logger = require('firebase-functions/logger');

function selectContent({
  entries,
  templateId,
  varkMode,
  level,
  length,
  scenarioTags = [],
  recentContentIds = [],
  rotationSeed = '',
}) {
  if (!Array.isArray(entries) || entries.length === 0) {
    logger.warn('[MCv2:contentSelector] no content entries available');
    return null;
  }

  const normalizedTags = scenarioTags
    .map((tag) => String(tag || '').trim().toLowerCase())
    .filter(Boolean);

  const desiredVark = normalizeVark(varkMode);
  const desiredLevel = normalizeLevel(level);
  const desiredLength = normalizeLength(length);

  logger.info('[MCv2:contentSelector] selecting', {
    templateId,
    desiredVark,
    desiredLevel,
    desiredLength,
    scenarioTagCount: normalizedTags.length,
    totalEntries: entries.length,
    recentContentCount: recentContentIds.length,
  });

  let candidates = entries.filter((entry) => entry.template_id === templateId);
  if (candidates.length === 0) {
    logger.warn('[MCv2:contentSelector] no entries match templateId', { templateId });
    return null;
  }

  logger.info('[MCv2:contentSelector] template-matched candidates', { count: candidates.length });

  const scenarioMatches = candidates.filter((entry) =>
    hasScenarioMatch(entry.scenario_tags, normalizedTags),
  );
  if (scenarioMatches.length > 0) {
    candidates = scenarioMatches;
    logger.info('[MCv2:contentSelector] narrowed by scenario tags', { count: candidates.length });
  }

  const varkMatches = candidates.filter(
    (entry) => normalizeVark(entry.vark_mode) === desiredVark,
  );
  if (varkMatches.length > 0) {
    candidates = varkMatches;
    logger.info('[MCv2:contentSelector] narrowed by VARK', { count: candidates.length });
  }

  const levelMatches = candidates.filter(
    (entry) => normalizeLevel(entry.level) === desiredLevel,
  );
  if (levelMatches.length > 0) {
    candidates = levelMatches;
    logger.info('[MCv2:contentSelector] narrowed by level', { count: candidates.length });
  }

  const lengthMatches = candidates.filter(
    (entry) => normalizeLength(entry.length) === desiredLength,
  );
  if (lengthMatches.length > 0) {
    candidates = lengthMatches;
    logger.info('[MCv2:contentSelector] narrowed by length', { count: candidates.length });
  }

  if (candidates.length > 0) {
    const result = chooseStable(candidates, {
      recentContentIds,
      rotationSeed,
    });
    logger.info('[MCv2:contentSelector] SELECTED', { contentId: result ? result.content_id : null });
    return result;
  }

  logger.info('[MCv2:contentSelector] relaxing constraints for fallback');
  candidates = entries.filter((entry) => entry.template_id === templateId);

  const noScenario = candidates;
  const noLevel = noScenario.filter(
    (entry) => normalizeVark(entry.vark_mode) === desiredVark,
  );
  if (noLevel.length > 0) {
    candidates = noLevel;
  }

  const noVark = candidates.filter(
    (entry) => normalizeLevel(entry.level) === desiredLevel,
  );
  if (noVark.length > 0) {
    candidates = noVark;
  }

  const standardFallback = candidates.filter(
    (entry) => normalizeLength(entry.length) === 'standard',
  );
  if (standardFallback.length > 0) {
    candidates = standardFallback;
  }

  const result = chooseStable(candidates, {
    recentContentIds,
    rotationSeed,
  });
  logger.info('[MCv2:contentSelector] SELECTED (relaxed)', { contentId: result ? result.content_id : null });
  return result;
}

function chooseStable(candidates, { recentContentIds = [], rotationSeed = '' } = {}) {
  if (!candidates || candidates.length === 0) {
    return null;
  }
  const sorted = [...candidates].sort((a, b) => {
    return String(a.content_id || '').localeCompare(String(b.content_id || ''));
  });

  const recentRank = new Map();
  recentContentIds
    .map((value) => String(value || '').trim())
    .filter(Boolean)
    .forEach((contentId, index) => {
      if (!recentRank.has(contentId)) {
        recentRank.set(contentId, index);
      }
    });

  const unseen = sorted.filter(
    (entry) => !recentRank.has(String(entry.content_id || '')),
  );
  if (unseen.length > 0) {
    if (!rotationSeed) {
      return unseen[0];
    }
    const index = stableHash(rotationSeed) % unseen.length;
    return unseen[index];
  }

  // All candidates were recently used; choose the least-recently used.
  const leastRecent = sorted
    .map((entry) => {
      const contentId = String(entry.content_id || '');
      const rank = recentRank.get(contentId);
      return {
        entry,
        // Larger index means older in recent list.
        score: rank == null ? Number.MAX_SAFE_INTEGER : rank,
      };
    })
    .sort((a, b) => b.score - a.score);

  return leastRecent[0]?.entry || sorted[0];
}

function stableHash(input) {
  const raw = String(input || '');
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return hash;
}

function hasScenarioMatch(rawTags, probes) {
  if (!probes.length) {
    return false;
  }
  const tags = Array.isArray(rawTags)
    ? rawTags
    : String(rawTags || '')
        .split(';')
        .map((tag) => tag.trim().toLowerCase())
        .filter(Boolean);

  return probes.some((probe) => tags.includes(probe));
}

function normalizeVark(value) {
  const raw = String(value || 'ReadWrite').trim().toLowerCase();
  if (raw === 'visual') return 'visual';
  if (raw === 'aural' || raw === 'auditory') return 'aural';
  if (raw === 'kinesthetic') return 'kinesthetic';
  return 'readwrite';
}

function normalizeLevel(value) {
  const raw = String(value || 'Foundation').trim().toLowerCase();
  if (raw === 'build') return 'build';
  if (raw === 'compete') return 'compete';
  if (raw === 'maintain') return 'maintain';
  return 'foundation';
}

function normalizeLength(value) {
  const raw = String(value || 'standard').trim().toLowerCase();
  if (raw.startsWith('micro')) return 'micro';
  if (raw.startsWith('deep')) return 'deep';
  return 'standard';
}

module.exports = {
  selectContent,
  normalizeLength,
};
