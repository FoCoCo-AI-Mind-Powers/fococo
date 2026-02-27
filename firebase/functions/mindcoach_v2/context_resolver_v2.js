const {
  VALID_CONTEXT_MODES,
  VALID_UI_MODES,
} = require('./contracts_v2');
const logger = require('firebase-functions/logger');

function deriveUiMode(contextMode) {
  if (contextMode === 'during_round') {
    return 'live_minimal';
  }
  return 'guided_extended';
}

async function resolveContextMode({
  requestedMode,
  userId,
  db,
  now = new Date(),
}) {
  const safeRequestedMode = VALID_CONTEXT_MODES.has(requestedMode)
    ? requestedMode
    : 'auto';

  logger.info('[MCv2:contextResolver] resolving', { requestedMode, safeRequestedMode, userId });

  if (safeRequestedMode !== 'auto') {
    const uiMode = deriveUiMode(safeRequestedMode);
    logger.info('[MCv2:contextResolver] using request override', { contextMode: safeRequestedMode, uiMode });
    return {
      contextMode: safeRequestedMode,
      uiMode: VALID_UI_MODES.has(uiMode) ? uiMode : 'guided_extended',
      signals: {
        source: 'request_override',
      },
    };
  }

  let latestRoundAt = null;
  try {
    const roundSnapshot = await db
      .collection('golf_rounds')
      .where('userId', '==', userId)
      .orderBy('date', 'desc')
      .limit(1)
      .get();

    if (!roundSnapshot.empty) {
      const raw = roundSnapshot.docs[0].data().date;
      if (raw && typeof raw.toDate === 'function') {
        latestRoundAt = raw.toDate();
      }
    }
    logger.info('[MCv2:contextResolver] golf_rounds query result', {
      hasRound: !!latestRoundAt,
      latestRoundAt: latestRoundAt ? latestRoundAt.toISOString() : null,
    });
  } catch (err) {
    logger.warn('[MCv2:contextResolver] golf_rounds query failed', { error: err.message });
  }

  let contextMode = 'off_day';
  if (latestRoundAt instanceof Date) {
    const deltaHours = Math.max(0, (now.getTime() - latestRoundAt.getTime()) / 3600000);
    if (deltaHours <= 4) {
      contextMode = 'during_round';
    } else if (deltaHours <= 24) {
      contextMode = 'after_round';
    }
    logger.info('[MCv2:contextResolver] inferred from round delta', { deltaHours: deltaHours.toFixed(1), contextMode });
  } else {
    const hour = now.getHours();
    if (hour < 10) {
      contextMode = 'before_round';
    }
    logger.info('[MCv2:contextResolver] inferred from time-of-day', { hour, contextMode });
  }

  const uiMode = deriveUiMode(contextMode);
  logger.info('[MCv2:contextResolver] RESULT', { contextMode, uiMode });

  return {
    contextMode,
    uiMode: VALID_UI_MODES.has(uiMode) ? uiMode : 'guided_extended',
    signals: {
      source: 'auto_inference',
      latest_round_at: latestRoundAt ? latestRoundAt.toISOString() : null,
    },
  };
}

module.exports = {
  resolveContextMode,
  deriveUiMode,
};
