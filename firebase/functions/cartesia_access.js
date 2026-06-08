const axios = require('axios');
const functions = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const { defineSecret, defineString } = require('firebase-functions/params');

const CARTESIA_API_SECRET = defineSecret('CARTESIA_API');
const CARTESIA_LINE_AGENT_ID = defineString('CARTESIA_LINE_AGENT_ID', {
  default: '',
});
const CARTESIA_PRONUNCIATION_DICT_ID = defineString('CARTESIA_PRONUNCIATION_DICT_ID', {
  default: '',
});

const CARTESIA_BASE_URL = 'https://api.cartesia.ai';
const CARTESIA_VERSION = '2025-04-16';

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function getCartesiaKeySafe() {
  try {
    return CARTESIA_API_SECRET.value() || process.env.CARTESIA_API || '';
  } catch (error) {
    logger.warn('[cartesia:access] failed reading CARTESIA_API secret', {
      error: error.message,
    });
    return process.env.CARTESIA_API || '';
  }
}

/**
 * Non-secret voice runtime knobs for authenticated clients.
 */
async function getCartesiaVoiceRuntimeConfigImpl(_data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required',
    );
  }

  return {
    line_agent_id: safeString(CARTESIA_LINE_AGENT_ID.value()),
    pronunciation_dict_id: safeString(CARTESIA_PRONUNCIATION_DICT_ID.value()),
    cartesia_version: CARTESIA_VERSION,
  };
}

/**
 * Mint a short-lived Cartesia access token for Line WebSocket clients.
 * Never return the raw CARTESIA_API key.
 */
async function mintCartesiaAccessTokenImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required',
    );
  }

  const apiKey = getCartesiaKeySafe();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'CARTESIA_API secret is not configured.',
    );
  }

  const agentId =
    safeString(data && data.agent_id) || safeString(CARTESIA_LINE_AGENT_ID.value());
  if (!agentId) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'CARTESIA_LINE_AGENT_ID is not configured. Deploy the Line agent and set the param.',
    );
  }

  const expiresIn =
    typeof (data && data.expires_in) === 'number' && data.expires_in > 0
      ? Math.min(data.expires_in, 600)
      : 300;

  try {
    const response = await axios.post(
      `${CARTESIA_BASE_URL}/access-token`,
      {
        grants: { agent: agentId },
        expires_in: expiresIn,
      },
      {
        timeout: 15000,
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Cartesia-Version': CARTESIA_VERSION,
          'Content-Type': 'application/json',
        },
      },
    );

    const token =
      (response.data && (response.data.access_token || response.data.token)) || '';
    if (!token) {
      throw new Error('access-token response missing token');
    }

    return {
      access_token: token,
      agent_id: agentId,
      expires_in: expiresIn,
      cartesia_version: CARTESIA_VERSION,
    };
  } catch (error) {
    const status = error.response?.status;
    const upstream =
      error.response?.data?.error || error.response?.data || error.message;
    logger.warn('[cartesia:access] mint token failed', { status, upstream });

    if (status === 401 || status === 403) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Cartesia auth problem: ${JSON.stringify(upstream)}`,
      );
    }
    throw new functions.https.HttpsError(
      'internal',
      `Failed to mint Cartesia access token: ${JSON.stringify(upstream)}`,
    );
  }
}

exports.getCartesiaVoiceRuntimeConfig = functions.https.onCall(
  getCartesiaVoiceRuntimeConfigImpl,
);

exports.mintCartesiaAccessToken = functions
  .runWith({ secrets: [CARTESIA_API_SECRET] })
  .https.onCall(mintCartesiaAccessTokenImpl);

/**
 * Mint a short-lived access token scoped to Cartesia TTS (WebSocket / SSE / bytes).
 * Clients use this for instant streaming synthesis — never ship CARTESIA_API.
 */
async function mintCartesiaTtsAccessTokenImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required',
    );
  }

  const apiKey = getCartesiaKeySafe();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'CARTESIA_API secret is not configured.',
    );
  }

  const expiresIn =
    typeof (data && data.expires_in) === 'number' && data.expires_in > 0
      ? Math.min(data.expires_in, 600)
      : 300;

  try {
    const response = await axios.post(
      `${CARTESIA_BASE_URL}/access-token`,
      {
        grants: { tts: true },
        expires_in: expiresIn,
      },
      {
        timeout: 15000,
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Cartesia-Version': CARTESIA_VERSION,
          'Content-Type': 'application/json',
        },
      },
    );

    const token =
      (response.data && (response.data.access_token || response.data.token)) || '';
    if (!token) {
      throw new Error('access-token response missing token');
    }

    return {
      access_token: token,
      expires_in: expiresIn,
      cartesia_version: CARTESIA_VERSION,
    };
  } catch (error) {
    const status = error.response?.status;
    const upstream =
      error.response?.data?.error || error.response?.data || error.message;
    logger.warn('[cartesia:access] mint TTS token failed', { status, upstream });

    if (status === 401 || status === 403) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Cartesia auth problem: ${JSON.stringify(upstream)}`,
      );
    }
    throw new functions.https.HttpsError(
      'internal',
      `Failed to mint Cartesia TTS access token: ${JSON.stringify(upstream)}`,
    );
  }
}

exports.mintCartesiaTtsAccessToken = functions
  .runWith({ secrets: [CARTESIA_API_SECRET] })
  .https.onCall(mintCartesiaTtsAccessTokenImpl);
