const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');

const GEMINI_KEY_SECRET = defineSecret('GEMINI_KEY_APP');
const axios = require('axios');

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function getDb() {
  return admin.firestore();
}

async function summarizeSessionMessages(sessionId, userId) {
  const db = getDb();
  const snap = await db
    .collection('voice_chat_messages')
    .where('sessionId', '==', sessionId)
    .where('userId', '==', userId)
    .orderBy('timestamp', 'asc')
    .limit(40)
    .get();

  const lines = snap.docs.map((doc) => {
    const data = doc.data();
    const role = data.isUser ? 'User' : 'Assistant';
    return `${role}: ${safeString(data.content).slice(0, 500)}`;
  });

  if (lines.length === 0) {
    return { preview: '', summary: '' };
  }

  const preview = lines[lines.length - 1].replace(/^(User|Assistant):\s*/, '');
  const apiKey = GEMINI_KEY_SECRET.value() || process.env.GEMINI_KEY_APP || '';
  if (!apiKey) {
    return {
      preview: preview.slice(0, 160),
      summary: lines.slice(-4).join('\n').slice(0, 400),
    };
  }

  try {
    const response = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      {
        generationConfig: { temperature: 0.4, maxOutputTokens: 256 },
        contents: [
          {
            role: 'user',
            parts: [
              {
                text:
                  'Summarize this GolfChat reflection in 2 short plain-text sentences. '
                  + 'No markdown.\n\n' +
                  lines.join('\n'),
              },
            ],
          },
        ],
      },
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
      },
    );
    const summary = safeString(
      response.data?.candidates?.[0]?.content?.parts?.[0]?.text,
    );
    return {
      preview: preview.slice(0, 160),
      summary: summary || preview.slice(0, 200),
    };
  } catch (error) {
    logger.warn('[golfChat:archive] summarize failed', { error: error.message });
    return {
      preview: preview.slice(0, 160),
      summary: preview.slice(0, 200),
    };
  }
}

async function archiveGolfChatSessionImpl(data, context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const sessionId = safeString(data.sessionId);
  if (!sessionId) {
    throw new functions.https.HttpsError('invalid-argument', 'sessionId is required');
  }

  const userId = context.auth.uid;
  const db = getDb();
  const ref = db.collection('voice_chat_sessions').doc(sessionId);
  const doc = await ref.get();
  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Session not found');
  }

  const session = doc.data();
  if (session.userId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Not your session');
  }

  const { preview, summary } = await summarizeSessionMessages(sessionId, userId);
  const messageCount = Number(session.messageCount) || 0;

  await ref.set(
    {
      preview,
      summary,
      messageCount,
      lifecycleStatus: 'archived',
      status: 'completed',
      endTime: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { sessionId, preview, summary, messageCount, lifecycleStatus: 'archived' };
}

exports.archiveGolfChatSession = functions
  .runWith({ secrets: [GEMINI_KEY_SECRET] })
  .https.onCall(archiveGolfChatSessionImpl);
