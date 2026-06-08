const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

const FALLBACK_CATALOG = [
  {
    key: 'wa_focus_clarity_10',
    name: 'Morning Clarity',
    descriptor: 'Set your focus before the round. Clear the noise and arrive at the first tee present.',
    pillar: 'focus',
    duration_min: 10,
    platform: 'webapp',
  },
  {
    key: 'wa_focus_pattern_12',
    name: 'Pattern Reset',
    descriptor: 'Interrupt the loop. Build a new mental response when your usual one stops working.',
    pillar: 'focus',
    duration_min: 12,
    platform: 'webapp',
  },
  {
    key: 'wa_confidence_build_10',
    name: 'Confidence Baseline',
    descriptor: 'Return to what you know works. Anchor to your strongest performances.',
    pillar: 'confidence',
    duration_min: 10,
    platform: 'webapp',
  },
  {
    key: 'wa_confidence_pressure_15',
    name: 'Under Pressure',
    descriptor: 'Train your response before the moment arrives. Pressure is a skill.',
    pillar: 'confidence',
    duration_min: 15,
    platform: 'webapp',
  },
  {
    key: 'wa_control_reset_12',
    name: 'Control Reset',
    descriptor: 'Reclaim your process when it slips. Rebuild the routine that keeps you steady.',
    pillar: 'control',
    duration_min: 12,
    platform: 'webapp',
  },
];

async function getWebAppMindCoachSessionsImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  try {
    const db = admin.firestore();
    const snap = await db
      .collection('mindcoach_webapp_sessions')
      .orderBy('sort_order', 'asc')
      .limit(20)
      .get();

    if (!snap.empty) {
      const sessions = snap.docs.map((doc) => {
        const d = doc.data();
        return {
          key: doc.id,
          name: d.name || d.title || '',
          descriptor: d.descriptor || d.description || '',
          pillar: d.pillar || 'focus',
          duration_min: d.duration_min || d.durationMinutes || 10,
          platform: 'webapp',
        };
      });
      return { sessions };
    }
  } catch (e) {
    // Firestore unavailable — fall through to hardcoded catalog
    functions.logger.warn('[webappSessions] Firestore read failed, using fallback', { error: e.message });
  }

  return { sessions: FALLBACK_CATALOG };
}

exports.getWebAppMindCoachSessions = functions.https.onCall(getWebAppMindCoachSessionsImpl);
