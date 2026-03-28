const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const geminiKey = defineSecret("GEMINI_KEY");

/**
 * Returns the Gemini API key from Secret Manager.
 * Only authenticated users can call this function.
 */
exports.getGeminiKey = onCall({ secrets: [geminiKey] }, (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const key = geminiKey.value();
  if (!key) {
    throw new HttpsError("not-found", "Gemini key not configured in Secret Manager");
  }

  return { key };
});
