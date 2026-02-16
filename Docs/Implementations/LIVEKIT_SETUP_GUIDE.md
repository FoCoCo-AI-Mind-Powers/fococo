# LiveKit Agent Setup Guide (JustTalk)

## Overview
JustTalk now uses a **Session-based LiveKit agent flow** with automatic fallback.

Primary runtime path:
- `lib/services/just_talk_livekit_agent_service.dart`
- `lib/ai_integration/config/just_talk_livekit_config.dart`
- `lib/pages/just_talk/just_talk_widget.dart`

Token backend:
- `firebase/functions/livekit_token.js` (`generateLiveKitToken`)

## Runtime model
1. JustTalk starts a LiveKit `Session.withAgent(...)`.
2. The app calls Firebase callable `generateLiveKitToken`.
3. Backend returns `participant_token` + `server_url` (and legacy `token`).
4. Session connects to LiveKit room and waits for agent.
5. Chat/transcripts stream through LiveKit (`lk.chat`, `lk.transcription`).
6. If connection/agent fails, JustTalk automatically switches to fallback voice mode.

## Config (`--dart-define`)
Defined in `lib/ai_integration/config/just_talk_livekit_config.dart`:

- `LIVEKIT_URL`
- `LIVEKIT_JUST_TALK_AGENT_NAME`
- `JUST_TALK_CARTESIA_VOICE_ID`
- `JUST_TALK_LIVEKIT_FALLBACK_ENABLED`
- `JUST_TALK_LIVEKIT_AGENT_TIMEOUT_SECONDS`

Defaults:
- URL: `wss://fococo-45unq6sj.livekit.cloud`
- Agent: `justtalk-cartesia`
- Voice ID: `7442d6b8-ff51-4477-bd30-0c0d16df84eb`
- Fallback: `true`
- Timeout: `20s`

## Firebase callable contract
`generateLiveKitToken` accepts both legacy and modern fields.

Request fields:
- Legacy: `room`, `identity`, `name`
- Modern: `room_name`, `participant_identity`, `participant_name`
- Optional: `agentName`, `agentMetadata`, `participantAttributes`

Response fields:
- Legacy: `token`, `room`, `identity`, `name`
- Modern: `participant_token`, `server_url`, `room_name`, `participant_identity`, `participant_name`

## Deploy

```bash
cd firebase/functions
npm install

cd ..
firebase deploy --only functions:generateLiveKitToken --project fo-co-co-89gnf5
```

## Verification checklist
- `generateLiveKitToken` is deployed.
- Authenticated user can open JustTalk.
- Live mode connects and receives agent transcripts.
- Typed messages in Live mode route through LiveKit agent.
- If agent is unavailable, fallback mode activates without crashing.

## Security notes
- LiveKit API secret remains server-side only.
- Client should never store/sign JWTs.
- Tokens expire after 6 hours.

## References
- [LiveKit docs](https://docs.livekit.io/)
- [livekit_client on pub.dev](https://pub.dev/packages/livekit_client)
- [LiveKit text streams](https://docs.livekit.io/home/client/data/text-streams/)
