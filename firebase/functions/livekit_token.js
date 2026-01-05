const functions = require("firebase-functions");
const admin = require("firebase-admin");
const jwt = require("jsonwebtoken");

/**
 * Generate LiveKit Access Token
 * This function generates JWT tokens for LiveKit room access
 * 
 * LiveKit Credentials (from your LiveKit dashboard):
 * - API Key: APIhqsNFhwph9pU
 * - API Secret: ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F
 * - Server URL: wss://fococo-45unq6sj.livekit.cloud
 */
exports.generateLiveKitToken = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to generate LiveKit token'
    );
  }

  const { room, identity, name } = data;

  if (!room || !identity || !name) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required parameters: room, identity, name'
    );
  }

  try {
    // LiveKit Configuration
    // Get from Firebase config or use hardcoded values
    const LIVEKIT_API_KEY = functions.config().livekit?.api_key || 'APIhqsNFhwph9pU';
    const LIVEKIT_API_SECRET = functions.config().livekit?.api_secret || 'ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F';

    // Token expiration (6 hours)
    const ttl = '6h';
    const exp = Math.floor(Date.now() / 1000) + (6 * 60 * 60);

    // Create JWT token for LiveKit
    const token = jwt.sign(
      {
        iss: LIVEKIT_API_KEY,
        sub: identity,
        iat: Math.floor(Date.now() / 1000),
        exp: exp,
        video: {
          room: room,
          roomJoin: true,
          canPublish: true,
          canSubscribe: true,
          canPublishData: true,
        },
        name: name,
      },
      LIVEKIT_API_SECRET,
      {
        algorithm: 'HS256',
      }
    );

    console.log(`Generated LiveKit token for user: ${context.auth.uid}, room: ${room}`);

    return {
      token: token,
      room: room,
      identity: identity,
      name: name,
    };

  } catch (error) {
    console.error('Error generating LiveKit token:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to generate LiveKit token: ${error.message}`
    );
  }
});
