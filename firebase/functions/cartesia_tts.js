const axios = require('axios');
const functions = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');
const {
  CARTESIA_VOICE_ID_SECRET,
  getCartesiaVoiceIdSafe,
  safeString,
} = require('./cartesia_voice_config');

// Single voice provider proxy. The Cartesia key lives in Secret Manager as
// `CARTESIA_API` and never leaves the Cloud Functions runtime — the client
// calls this callable and receives audio bytes, mirroring the GolfChat /
// GEMINI_KEY_APP pattern. Do NOT re-introduce a client-facing key endpoint.
const CARTESIA_API_SECRET = defineSecret('CARTESIA_API');

// Pinned constants — model/version kept in sync with Flutter CartesiaConfig.
const CARTESIA_TTS_MODEL = 'sonic-3-2026-01-12';
const CARTESIA_FINE_TUNE_ID = 'fine_tune_WyfawYF7uFdFJdRTia8rG5';
const CARTESIA_VERSION = '2025-04-16';
const CARTESIA_BASE_URL = 'https://api.cartesia.ai';

const MAX_TRANSCRIPT_CHARS = 4000;
// Per-call cap — long segments blow up WAV payloads and hit callable size limits.
const MAX_TRANSCRIPT_CHARS_PER_CALL = 1200;
const MAX_TTS_AUDIO_BYTES = 7 * 1024 * 1024; // ~7 MB raw before base64
const TTS_AXIOS_TIMEOUT_MS = 90000;

function getCartesiaKeySafe() {
  try {
    return CARTESIA_API_SECRET.value() || process.env.CARTESIA_API || '';
  } catch (error) {
    logger.warn('[cartesia:tts] failed reading CARTESIA_API secret', {
      error: error.message,
    });
    return process.env.CARTESIA_API || '';
  }
}

async function synthesizeSpeechImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required',
    );
  }

  const transcript = safeString(data.transcript).slice(0, MAX_TRANSCRIPT_CHARS);
  if (!transcript) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'transcript is required',
    );
  }
  if (transcript.length > MAX_TRANSCRIPT_CHARS_PER_CALL) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `transcript exceeds ${MAX_TRANSCRIPT_CHARS_PER_CALL} chars per synthesis call — split on the client`,
    );
  }

  const apiKey = getCartesiaKeySafe();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'CARTESIA_API secret is not configured.',
    );
  }

  const voiceId = safeString(data.voice_id, getCartesiaVoiceIdSafe());
  const modelId = safeString(data.model_id, CARTESIA_TTS_MODEL);
  const language = safeString(data.language, 'en');
  const outputFormat = (data.output_format && typeof data.output_format === 'object')
    ? data.output_format
    : { container: 'wav', encoding: 'pcm_s16le', sample_rate: 44100 };

  // Optional delivery-speed control (numeric multiplier or 'slow'/'normal'/
  // 'fast'). Prefer generation_config.speed when both are sent.
  const speed = data.speed;
  const generationConfig =
    data.generation_config && typeof data.generation_config === 'object'
      ? { ...data.generation_config }
      : {};
  if (speed != null && speed !== '' && generationConfig.speed == null) {
    const parsed = Number(speed);
    generationConfig.speed = Number.isFinite(parsed) ? parsed : speed;
  }
  const pronunciationDictId = safeString(data.pronunciation_dict_id);
  const contextId = safeString(data.context_id);
  const continueGeneration = data.continue === true;

  try {
    const payload = {
      model_id: modelId,
      transcript,
      voice: { mode: 'id', id: voiceId },
      output_format: outputFormat,
      language,
    };
    if (Object.keys(generationConfig).length > 0) {
      payload.generation_config = generationConfig;
    }
    if (pronunciationDictId) {
      payload.pronunciation_dict_id = pronunciationDictId;
    }
    if (contextId) {
      payload.context_id = contextId;
      payload.continue = continueGeneration;
    }
    // Instant generation: 0 = start on first transcript (Cartesia docs).
    payload.max_buffer_delay_ms =
      data.max_buffer_delay_ms != null ? data.max_buffer_delay_ms : 0;

    const response = await axios.post(
      `${CARTESIA_BASE_URL}/tts/bytes`,
      payload,
      {
        timeout: TTS_AXIOS_TIMEOUT_MS,
        responseType: 'arraybuffer',
        headers: {
          'Cartesia-Version': CARTESIA_VERSION,
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    const audioBytes = Buffer.from(response.data);
    if (audioBytes.length > MAX_TTS_AUDIO_BYTES) {
      logger.warn('[cartesia:tts] audio response too large', {
        bytes: audioBytes.length,
        transcriptChars: transcript.length,
      });
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Cartesia audio response too large (${audioBytes.length} bytes) — shorten the transcript segment`,
      );
    }

    return {
      audio_base64: audioBytes.toString('base64'),
      content_type: response.headers['content-type'] || 'audio/wav',
      voice_id: voiceId,
      model_id: modelId,
    };
  } catch (error) {
    const status = error.response?.status;
    let upstream = error.message;
    if (error.response?.data) {
      try {
        upstream = Buffer.from(error.response.data).toString('utf8');
      } catch (_) {
        // keep error.message
      }
    }
    logger.warn('[cartesia:tts] synthesis failed', {
      status,
      upstream,
      transcriptChars: transcript.length,
      hasContextId: Boolean(contextId),
      continueGeneration,
    });

    if (status === 401 || status === 403) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Cartesia auth problem: ${upstream}`,
      );
    }
    if (status === 404) {
      throw new functions.https.HttpsError(
        'not-found',
        `Cartesia voice not found (${voiceId}). Re-copy the voice ID from the dashboard.`,
      );
    }
    if (status === 413 || status === 429) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Cartesia synthesis limited: ${upstream}`,
      );
    }
    if (status === 408 || status === 504 || error.code === 'ECONNABORTED') {
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        `Cartesia synthesis timed out: ${upstream || error.message}`,
      );
    }
    throw new functions.https.HttpsError(
      'internal',
      `Cartesia synthesis failed: ${upstream || 'unknown error'}`,
    );
  }
}

exports.synthesizeSpeech = functions
  .runWith({
    secrets: [CARTESIA_API_SECRET, CARTESIA_VOICE_ID_SECRET],
    timeoutSeconds: 120,
    memory: '512MB',
  })
  .https.onCall(synthesizeSpeechImpl);

// STT uses a newer Cartesia API version + Bearer auth, matching the web app's
// transcribe route. Kept separate from the TTS version which is pinned to the
// migration-guide value.
const CARTESIA_STT_MODEL = 'ink-whisper';
const CARTESIA_STT_VERSION = '2026-03-01';
const MAX_STT_AUDIO_BYTES = 8 * 1024 * 1024; // 8 MB cap on uploaded clips

async function transcribeSpeechImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required',
    );
  }

  const audioB64 = safeString(data.audio_base64);
  if (!audioB64) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'audio_base64 is required',
    );
  }

  let audioBuffer;
  try {
    audioBuffer = Buffer.from(audioB64, 'base64');
  } catch (_) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'audio_base64 is not valid base64',
    );
  }
  if (audioBuffer.length === 0) {
    return { text: '', words: [], language: null, duration: null };
  }
  if (audioBuffer.length > MAX_STT_AUDIO_BYTES) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `audio exceeds ${MAX_STT_AUDIO_BYTES} byte limit`,
    );
  }

  const apiKey = getCartesiaKeySafe();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'CARTESIA_API secret is not configured.',
    );
  }

  const fileName = safeString(data.file_name, 'voice-input.wav');
  const mimeType = safeString(data.mime_type, 'audio/wav');
  const language = safeString(data.language);
  const encoding = safeString(data.encoding);
  const sampleRate = data.sample_rate;

  const form = new FormData();
  form.append('file', new Blob([audioBuffer], { type: mimeType }), fileName);
  form.append('model', CARTESIA_STT_MODEL);
  form.append('timestamp_granularities[]', 'word');
  if (language) form.append('language', language);

  const query = {};
  if (encoding) query.encoding = encoding;
  if (sampleRate != null) query.sample_rate = String(sampleRate);

  try {
    const response = await axios.post(`${CARTESIA_BASE_URL}/stt`, form, {
      timeout: 20000,
      params: Object.keys(query).length ? query : undefined,
      headers: {
        'Cartesia-Version': CARTESIA_STT_VERSION,
        'Authorization': `Bearer ${apiKey}`,
      },
    });

    const decoded = response.data || {};
    const words = Array.isArray(decoded.words)
      ? decoded.words
          .map((w) => safeString(w && w.word))
          .filter((w) => w.length > 0)
      : [];

    return {
      text: safeString(decoded.text),
      words,
      language: decoded.language || null,
      duration: typeof decoded.duration === 'number' ? decoded.duration : null,
    };
  } catch (error) {
    const status = error.response?.status;
    const upstream = error.response?.data?.error || error.response?.data || error.message;
    logger.warn('[cartesia:stt] transcription failed', { status, upstream });

    if (status === 401 || status === 403) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Cartesia auth problem: ${JSON.stringify(upstream)}`,
      );
    }
    throw new functions.https.HttpsError(
      'internal',
      `Cartesia transcription failed: ${JSON.stringify(upstream)}`,
    );
  }
}

exports.transcribeSpeech = functions
  .runWith({ secrets: [CARTESIA_API_SECRET, CARTESIA_VOICE_ID_SECRET] })
  .https.onCall(transcribeSpeechImpl);

// §2 boot self-check. Hits `GET /api/voices/{id}` so the client can fail-fast
// with a clear log if the pinned voice ID is wrong (see §9.1 — the ID has a
// suspicious 13-char final block). Returns a small status object instead of
// throwing so app boot is never blocked by it.
async function verifyVoiceImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required',
    );
  }

  const apiKey = getCartesiaKeySafe();
  if (!apiKey) {
    return { valid: false, status: 0, reason: 'CARTESIA_API not configured' };
  }

  const voiceId = safeString(data.voice_id, getCartesiaVoiceIdSafe());
  const fineTuneId = safeString(data.fine_tune_id, CARTESIA_FINE_TUNE_ID);

  async function fetchVoiceById(id) {
    const response = await axios.get(
      `${CARTESIA_BASE_URL}/voices/${encodeURIComponent(id)}`,
      {
        timeout: 10000,
        headers: {
          'Cartesia-Version': CARTESIA_VERSION,
          'Authorization': `Bearer ${apiKey}`,
        },
      },
    );
    return response;
  }

  try {
    const response = await fetchVoiceById(voiceId);
    return {
      valid: true,
      status: response.status,
      voice_id: voiceId,
      name: response.data?.name || null,
    };
  } catch (error) {
    const status = error.response?.status || 0;

    // Fine-tuned clones are listed under the fine-tune, not always at GET /voices/{id}.
    if (status === 404 && fineTuneId) {
      try {
        const list = await axios.get(
          `${CARTESIA_BASE_URL}/fine-tunes/${encodeURIComponent(fineTuneId)}/voices`,
          {
            timeout: 10000,
            headers: {
              'Cartesia-Version': CARTESIA_VERSION,
              'Authorization': `Bearer ${apiKey}`,
            },
          },
        );
        const voices = Array.isArray(list.data?.voices)
          ? list.data.voices
          : Array.isArray(list.data)
            ? list.data
            : [];
        const match = voices.find((v) => safeString(v?.id) === voiceId);
        if (match) {
          return {
            valid: true,
            status: 200,
            voice_id: voiceId,
            name: match.name || null,
            source: 'fine_tune',
          };
        }
      } catch (fineTuneError) {
        logger.warn('[cartesia:verify] fine-tune voice lookup failed', {
          fineTuneId,
          error: fineTuneError.message,
        });
      }
    }

    logger.warn('[cartesia:verify] voice self-check failed', {
      voiceId,
      status,
    });
    return {
      valid: false,
      status,
      voice_id: voiceId,
      reason: error.response?.data?.error || error.message,
    };
  }
}

exports.verifyVoice = functions
  .runWith({ secrets: [CARTESIA_API_SECRET, CARTESIA_VOICE_ID_SECRET] })
  .https.onCall(verifyVoiceImpl);
