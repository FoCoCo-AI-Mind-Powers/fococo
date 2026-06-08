const { defineSecret } = require('firebase-functions/params');

const CARTESIA_VOICE_ID_SECRET = defineSecret('CARTESIA_VOICE_ID');

/** Last-resort fallback when Secret Manager is not yet bound in local emulators. */
const FALLBACK_VOICE_ID = 'fee439a9-751d-4d14-9974-a09de45bd053';

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function getCartesiaVoiceIdSafe() {
  try {
    const fromSecret = safeString(CARTESIA_VOICE_ID_SECRET.value());
    if (fromSecret) return fromSecret;
  } catch (_) {
    // Secret not available (emulator / pre-deploy).
  }
  const fromEnv = safeString(process.env.CARTESIA_VOICE_ID);
  return fromEnv || FALLBACK_VOICE_ID;
}

module.exports = {
  CARTESIA_VOICE_ID_SECRET,
  FALLBACK_VOICE_ID,
  getCartesiaVoiceIdSafe,
  safeString,
};
