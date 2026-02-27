const {
  FALLBACK_TEMPLATE_ID,
  FORBIDDEN_LANGUAGE_PATTERNS,
} = require('./contracts_v2');
const logger = require('firebase-functions/logger');

function validateAndCorrect({
  aiOutput,
  template,
  fallbackTemplate,
  modelVersion,
  promptVersion,
  requestedTemplateId,
}) {
  logger.info('[MCv2:validator] ENTRY', {
    requestedTemplateId,
    modelVersion,
    hasAiOutput: !!aiOutput,
  });

  const failedRules = [];
  const replacements = {};
  const contentFlags = [];

  const safeFallback = fallbackTemplate || template;
  const baseTemplate = template || safeFallback;

  const output = sanitizeInput(aiOutput);

  if (!baseTemplate) {
    logger.error('[MCv2:validator] no template available, using hard fallback');
    return {
      session: buildHardFallback({
        templateId: FALLBACK_TEMPLATE_ID,
      }),
      log: {
        validator_status: 'FAIL_FALLBACK',
        failed_rules: ['template_dataset_unavailable'],
        replacements: {},
        content_flags: ['template_dataset_unavailable'],
        model_version: modelVersion,
        prompt_version: promptVersion,
        template_id_requested: requestedTemplateId || null,
        template_id_returned: FALLBACK_TEMPLATE_ID,
      },
    };
  }

  const selectedTemplateId = baseTemplate.id;
  output.template_id = output.template_id || selectedTemplateId;

  if (output.template_id !== selectedTemplateId) {
    failedRules.push('template_id_not_allowed');
    replacements.template_id = {
      from: output.template_id,
      to: selectedTemplateId,
    };
    logger.warn('[MCv2:validator] template_id corrected', { from: output.template_id, to: selectedTemplateId });
    output.template_id = selectedTemplateId;
  }

  const allowedRoutineTypes = normalizeArray(baseTemplate.allowed_routine_types);
  const allowedCues = normalizeArray(baseTemplate.allowed_cues);
  const allowedDeliveryLengths = normalizeArray(baseTemplate.delivery_lengths);

  if (!allowedRoutineTypes.includes(output.routine_type)) {
    failedRules.push('routine_type_not_allowed');
    replacements.routine_type = {
      from: output.routine_type,
      to: allowedRoutineTypes[0] || '',
    };
    logger.warn('[MCv2:validator] routine_type corrected', { from: output.routine_type, to: allowedRoutineTypes[0] });
    output.routine_type = allowedRoutineTypes[0] || '';
  }

  if (!allowedCues.includes(output.recommended_cue)) {
    failedRules.push('cue_not_allowed');
    const deepBreath = allowedCues.find((cue) => cue.includes('Deep Breath'));
    const replacementCue = deepBreath || allowedCues[0] || '';
    replacements.recommended_cue = {
      from: output.recommended_cue,
      to: replacementCue,
    };
    logger.warn('[MCv2:validator] cue corrected', { from: output.recommended_cue, to: replacementCue });
    output.recommended_cue = replacementCue;
  }

  if (!allowedDeliveryLengths.includes(output.delivery_length)) {
    failedRules.push('delivery_length_not_allowed');
    const standard = allowedDeliveryLengths.find((length) =>
      String(length).includes('standard'),
    );
    const replacementLength = standard || allowedDeliveryLengths[0] || 'standard_30s';
    replacements.delivery_length = {
      from: output.delivery_length,
      to: replacementLength,
    };
    logger.warn('[MCv2:validator] delivery_length corrected', { from: output.delivery_length, to: replacementLength });
    output.delivery_length = replacementLength;
  }

  if (typeof output.coaching_text !== 'string' || output.coaching_text.trim().length === 0) {
    failedRules.push('coaching_text_missing');
    replacements.coaching_text = {
      from: output.coaching_text,
      to: buildSafeFallbackText(baseTemplate),
    };
    logger.warn('[MCv2:validator] coaching_text missing, using fallback');
    output.coaching_text = buildSafeFallbackText(baseTemplate);
  }

  const maxLen = maxCharsForLength(output.delivery_length);
  if (output.coaching_text.length > maxLen) {
    failedRules.push('coaching_text_too_long');
    replacements.coaching_text = {
      from: output.coaching_text,
      to: output.coaching_text.slice(0, maxLen).trim(),
    };
    logger.warn('[MCv2:validator] coaching_text too long, truncated', { length: output.coaching_text.length, maxLen });
    output.coaching_text = output.coaching_text.slice(0, maxLen).trim();
  }

  if (output.follow_up_question != null) {
    const followUp = String(output.follow_up_question).trim();
    if (!followUp || followUp.length > 140 || countQuestions(followUp) > 1) {
      failedRules.push('follow_up_invalid');
      replacements.follow_up_question = {
        from: output.follow_up_question,
        to: null,
      };
      logger.warn('[MCv2:validator] follow_up_question invalid, removed');
      output.follow_up_question = null;
    } else {
      output.follow_up_question = followUp;
    }
  }

  const textForSafety = `${output.coaching_text || ''} ${output.follow_up_question || ''}`;
  const safetyHits = detectForbiddenLanguage(textForSafety);
  if (safetyHits.length > 0) {
    failedRules.push('forbidden_language_detected');
    contentFlags.push(...safetyHits);
    replacements.coaching_text = {
      from: output.coaching_text,
      to: buildSafeFallbackText(baseTemplate),
    };
    logger.error('[MCv2:validator] forbidden language detected', { hits: safetyHits });
    output.coaching_text = buildSafeFallbackText(baseTemplate);
    output.follow_up_question = null;
    delete output.lines;
    delete output.total_duration_sec;
  }

  const validatorStatus = buildStatus(failedRules, safetyHits.length > 0);

  logger.info('[MCv2:validator] RESULT', {
    validatorStatus,
    failedRulesCount: failedRules.length,
    failedRules,
    contentFlagsCount: contentFlags.length,
    templateIdReturned: output.template_id,
  });

  const session = {
    template_id: output.template_id,
    routine_type: output.routine_type,
    recommended_cue: output.recommended_cue,
    delivery_length: output.delivery_length,
    coaching_text: output.coaching_text,
    follow_up_question: output.follow_up_question ?? null,
    validator_status: validatorStatus,
    model_version: modelVersion,
    prompt_version: promptVersion,
  };
  if (Array.isArray(output.lines) && output.lines.length > 0) {
    session.lines = output.lines;
  }
  if (typeof output.total_duration_sec === 'number') {
    session.total_duration_sec = output.total_duration_sec;
  }
  return {
    session,
    log: {
      validator_status: validatorStatus,
      failed_rules: failedRules,
      replacements,
      content_flags: contentFlags,
      model_version: modelVersion,
      prompt_version: promptVersion,
      template_id_requested: requestedTemplateId || null,
      template_id_returned: output.template_id,
    },
  };
}

function buildHardFallback({ templateId }) {
  return {
    template_id: templateId,
    routine_type: '📐 Pre-Shot',
    recommended_cue: '😮‍💨 Deep Breath',
    delivery_length: 'standard_30s',
    coaching_text: 'Pause. One slow breath. One clear target. Commit and swing.',
    follow_up_question: null,
    validator_status: 'FAIL_FALLBACK',
    model_version: 'fallback_validator',
    prompt_version: 'mindcoach_system_v1',
  };
}

function sanitizeInput(raw) {
  const source = raw && typeof raw === 'object' ? raw : {};
  const out = {
    template_id: source.template_id ? String(source.template_id) : null,
    routine_type: source.routine_type ? String(source.routine_type) : null,
    recommended_cue: source.recommended_cue ? String(source.recommended_cue) : null,
    delivery_length: source.delivery_length ? String(source.delivery_length) : null,
    coaching_text: source.coaching_text ? String(source.coaching_text).trim() : '',
    follow_up_question:
      source.follow_up_question == null
        ? null
        : String(source.follow_up_question).trim(),
  };
  if (Array.isArray(source.lines) && source.lines.length > 0) {
    out.lines = source.lines;
  }
  if (typeof source.total_duration_sec === 'number') {
    out.total_duration_sec = source.total_duration_sec;
  }
  return out;
}

function normalizeArray(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map((v) => String(v));
}

function buildSafeFallbackText(template) {
  const templateName = String(template.name || 'MindCoach').trim();
  return `Reset. Breathe once. Stay present. Use ${templateName} to focus on the next shot.`;
}

function maxCharsForLength(deliveryLength) {
  const raw = String(deliveryLength || '').toLowerCase();
  if (raw.includes('micro')) return 500;
  if (raw.includes('7m')) return 4000;
  if (raw.includes('3m')) return 3200;
  if (raw.includes('deep') || raw.includes('2m')) return 2400;
  return 1400;
}

function countQuestions(text) {
  return (text.match(/\?/g) || []).length;
}

function detectForbiddenLanguage(text) {
  const flags = [];
  for (const pattern of FORBIDDEN_LANGUAGE_PATTERNS) {
    if (pattern.test(text)) {
      flags.push(pattern.toString());
    }
  }
  return flags;
}

function buildStatus(failedRules, hasUnsafeContent) {
  if (hasUnsafeContent) {
    return 'FAIL_FALLBACK';
  }
  if (failedRules.length > 0) {
    return 'FAIL_CORRECTED';
  }
  return 'PASS';
}

module.exports = {
  validateAndCorrect,
};
