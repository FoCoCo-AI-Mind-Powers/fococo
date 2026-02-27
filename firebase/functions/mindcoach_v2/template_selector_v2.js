const { FALLBACK_TEMPLATE_ID } = require('./contracts_v2');
const logger = require('firebase-functions/logger');

function normalizeTag(tag) {
  return String(tag || '').trim().toLowerCase();
}

function chooseTemplate({
  contextMode,
  scenarioTags = [],
  recentTemplateId,
  availableTemplateIds,
}) {
  const availableSet = new Set(availableTemplateIds || []);
  const tags = new Set(scenarioTags.map(normalizeTag).filter(Boolean));

  logger.info('[MCv2:templateSelector] choosing', {
    contextMode,
    scenarioTagCount: tags.size,
    recentTemplateId,
    availableCount: availableSet.size,
  });

  const candidates = [];

  if (contextMode === 'before_round') {
    candidates.push('MC_T01_PRE_ROUND_CLARITY', 'MC_T02_PRE_SHOT_FOCUS');
  } else if (contextMode === 'after_round') {
    candidates.push('MC_T08_END_OF_ROUND_REFLECTION', 'MC_T05_MISTAKE_RECOVERY');
  } else if (contextMode === 'off_day') {
    candidates.push('MC_T08_END_OF_ROUND_REFLECTION', 'MC_T01_PRE_ROUND_CLARITY');
  } else {
    if (
      hasAnyTag(tags, [
        'after_bad_shot_release',
        'missed_short_putt',
        'three_putt_frustration',
        'double_bogey_stop_bleed',
        'lost_ball_reset',
        'chunked_wedge_recover',
      ])
    ) {
      candidates.push('MC_T05_MISTAKE_RECOVERY');
    }

    if (hasAnyTag(tags, ['indecision_over_ball', 'club_choice_confusion', 'tee_shot_commitment'])) {
      candidates.push('MC_T02_PRE_SHOT_FOCUS');
    }

    if (hasAnyTag(tags, ['closing_holes_pressure', 'being_watched', 'protecting_score'])) {
      candidates.push('MC_T06_PRESSURE_MOMENTS');
    }

    if (hasAnyTag(tags, ['after_birdie_rush', 'great_start_discipline', 'protecting_lead'])) {
      candidates.push('MC_T07_MOMENTUM_PROTECTION');
    }

    candidates.push(
      'MC_T03_BETWEEN_SHOTS_RESET',
      'MC_T04_POST_SHOT_LETTING_GO',
      'MC_T02_PRE_SHOT_FOCUS',
    );
  }

  candidates.push(FALLBACK_TEMPLATE_ID);

  for (const templateId of candidates) {
    if (!availableSet.has(templateId)) {
      continue;
    }

    if (templateId === recentTemplateId) {
      logger.info('[MCv2:templateSelector] skipping recent template', { templateId });
      continue;
    }

    logger.info('[MCv2:templateSelector] SELECTED', { templateId, reason: 'candidate_match' });
    return templateId;
  }

  if (availableSet.has(recentTemplateId)) {
    logger.info('[MCv2:templateSelector] SELECTED (reused recent)', { templateId: recentTemplateId });
    return recentTemplateId;
  }

  if (availableSet.has(FALLBACK_TEMPLATE_ID)) {
    logger.warn('[MCv2:templateSelector] SELECTED fallback', { templateId: FALLBACK_TEMPLATE_ID });
    return FALLBACK_TEMPLATE_ID;
  }

  const result = availableTemplateIds && availableTemplateIds.length
    ? availableTemplateIds[0]
    : FALLBACK_TEMPLATE_ID;
  logger.warn('[MCv2:templateSelector] SELECTED last-resort', { templateId: result });
  return result;
}

function hasAnyTag(tagSet, probes) {
  return probes.some((probe) => tagSet.has(normalizeTag(probe)));
}

module.exports = {
  chooseTemplate,
};
