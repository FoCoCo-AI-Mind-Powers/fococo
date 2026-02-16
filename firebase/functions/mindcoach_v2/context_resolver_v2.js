const {
  VALID_CONTEXT_MODES,
  VALID_UI_MODES,
} = require('./contracts_v2');

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

  if (safeRequestedMode !== 'auto') {
    const uiMode = deriveUiMode(safeRequestedMode);
    return {
      contextMode: safeRequestedMode,
      uiMode: VALID_UI_MODES.has(uiMode) ? uiMode : 'guided_extended',
      signals: {
        source: 'request_override',
      },
    };
  }

  // Best-effort inference from recent golf rounds.
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
  } catch (_) {
    // Keep inference resilient.
  }

  let contextMode = 'off_day';
  if (latestRoundAt instanceof Date) {
    const deltaHours = Math.max(0, (now.getTime() - latestRoundAt.getTime()) / 3600000);
    if (deltaHours <= 4) {
      contextMode = 'during_round';
    } else if (deltaHours <= 24) {
      contextMode = 'after_round';
    }
  } else {
    const hour = now.getHours();
    if (hour < 10) {
      contextMode = 'before_round';
    }
  }

  const uiMode = deriveUiMode(contextMode);

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
