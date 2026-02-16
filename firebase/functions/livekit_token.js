const functions = require("firebase-functions/v1");
const { defineString } = require("firebase-functions/params");
const jwt = require("jsonwebtoken");

const LIVEKIT_API_KEY_PARAM = defineString("LIVEKIT_API_KEY", {
  default: "APIhqsNFhwph9pU",
});
const LIVEKIT_API_SECRET_PARAM = defineString("LIVEKIT_API_SECRET", {
  default: "ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F",
});

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

  const room = data.room || data.room_name;
  const identity = data.identity || data.participant_identity;
  const name = data.name || data.participant_name;
  const agentName = data.agentName || data.agent_name || null;
  const agentMetadata = data.agentMetadata || data.agent_metadata || null;
  const participantAttributesRaw =
    data.participantAttributes || data.participant_attributes || {};

  const participantAttributes = {};
  if (participantAttributesRaw && typeof participantAttributesRaw === "object") {
    for (const [key, value] of Object.entries(participantAttributesRaw)) {
      if (value !== undefined && value !== null) {
        participantAttributes[String(key)] = String(value);
      }
    }
  }

  if (!room || !identity || !name) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required parameters: room/room_name, identity/participant_identity, name/participant_name'
    );
  }

  try {
    // LiveKit Configuration
    // Get from function params with env/default fallback.
    const LIVEKIT_API_KEY =
      LIVEKIT_API_KEY_PARAM.value() ||
      process.env.LIVEKIT_API_KEY ||
      "APIhqsNFhwph9pU";
    const LIVEKIT_API_SECRET =
      LIVEKIT_API_SECRET_PARAM.value() ||
      process.env.LIVEKIT_API_SECRET ||
      "ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F";
    const LIVEKIT_URL =
      process.env.LIVEKIT_URL || "wss://fococo-45unq6sj.livekit.cloud";

    // Token expiration (6 hours)
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
        metadata: agentMetadata ? String(agentMetadata) : '',
        attributes: participantAttributes,
      },
      LIVEKIT_API_SECRET,
      {
        algorithm: 'HS256',
      }
    );

    console.log(
      `Generated LiveKit token for user: ${context.auth.uid}, room: ${room}, agent: ${agentName || "default"}`
    );

    return {
      token: token,
      participant_token: token,
      server_url: LIVEKIT_URL,
      room: room,
      room_name: room,
      identity: identity,
      participant_identity: identity,
      name: name,
      participant_name: name,
      agentName: agentName,
      agentMetadata: agentMetadata,
      participantAttributes: participantAttributes,
    };

  } catch (error) {
    console.error('Error generating LiveKit token:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to generate LiveKit token: ${error.message}`
    );
  }
});
