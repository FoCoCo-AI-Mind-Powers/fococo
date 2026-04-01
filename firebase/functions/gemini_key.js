const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");

// MindCoach v2 (`mindcoach_v2/generate_session_v2.js`) uses this param for REST Gemini.
const geminiApiKeyParam = defineString("GEMINI_API_KEY", { default: "" });

// Optional override via Secret Manager (same value you use for client REST fallback).
const geminiKeySecret = defineSecret("GEMINI_KEY");

/**
 * Returns the Gemini API key for client-side features (e.g. GolfChat REST fallback).
 *
 * Resolution order matches MindCoach deployment: [GEMINI_API_KEY] param first, then
 * [GEMINI_KEY] secret, then process.env. That way GolfChat gets the same key as
 * `generateMindCoachSessionV2` when only the param is configured.
 */
exports.getGeminiKey = onCall({ secrets: [geminiKeySecret] }, (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const key =
    (geminiApiKeyParam.value() && String(geminiApiKeyParam.value()).trim()) ||
    geminiKeySecret.value() ||
    process.env.GEMINI_API_KEY ||
    "";

  if (!key) {
    throw new HttpsError(
      "not-found",
      "Gemini key not configured. Set GEMINI_API_KEY (same as MindCoach) or GEMINI_KEY secret.",
    );
  }

  return { key };
});
