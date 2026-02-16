function selectContent({
  entries,
  templateId,
  varkMode,
  level,
  length,
  scenarioTags = [],
}) {
  if (!Array.isArray(entries) || entries.length === 0) {
    return null;
  }

  const normalizedTags = scenarioTags
    .map((tag) => String(tag || '').trim().toLowerCase())
    .filter(Boolean);

  const desiredVark = normalizeVark(varkMode);
  const desiredLevel = normalizeLevel(level);
  const desiredLength = normalizeLength(length);

  let candidates = entries.filter((entry) => entry.template_id === templateId);
  if (candidates.length === 0) {
    return null;
  }

  // Step 2: scenario tag prioritization
  const scenarioMatches = candidates.filter((entry) =>
    hasScenarioMatch(entry.scenario_tags, normalizedTags),
  );
  if (scenarioMatches.length > 0) {
    candidates = scenarioMatches;
  }

  // Step 3: VARK
  const varkMatches = candidates.filter(
    (entry) => normalizeVark(entry.vark_mode) === desiredVark,
  );
  if (varkMatches.length > 0) {
    candidates = varkMatches;
  }

  // Step 4: level
  const levelMatches = candidates.filter(
    (entry) => normalizeLevel(entry.level) === desiredLevel,
  );
  if (levelMatches.length > 0) {
    candidates = levelMatches;
  }

  // Step 5: length
  const lengthMatches = candidates.filter(
    (entry) => normalizeLength(entry.length) === desiredLength,
  );
  if (lengthMatches.length > 0) {
    candidates = lengthMatches;
  }

  if (candidates.length > 0) {
    return chooseStable(candidates);
  }

  // Relaxation order: scenario_tag -> level -> vark_mode -> length
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

  return chooseStable(candidates);
}

function chooseStable(candidates) {
  if (!candidates || candidates.length === 0) {
    return null;
  }
  return [...candidates].sort((a, b) => {
    return String(a.content_id || '').localeCompare(String(b.content_id || ''));
  })[0];
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
