# Cursor Prompt — Migrate All Voice (TTS + Conversational AI) to Cartesia

## 0. Before you start — fill these in
- **Target app / stack:** `<app name + stack, e.g. Flutter + Riverpod client, Python backend>`
- **Secrets (never hardcode — use env / secret manager):**
  - `CARTESIA_API_KEY`
  - `GEMINI_API_KEY` (Google AI Studio / Vertex)
- **Pinned constants (single source of truth, one config file):**
  - `CARTESIA_TTS_MODEL = "sonic-3-2026-01-12"`
  - `CARTESIA_VOICE_ID  = "fee439a9-751d-4d14-9974-a09de45bd0530"`  ⚠️ *verify — see §9.1*
  - `CARTESIA_FINE_TUNE_ID = "fine_tune_WyfawYF7uFdFJdRTia8rG5"`
  - `CARTESIA_VERSION = "2025-04-16"`  *(the `Cartesia-Version` date header; treat as pinned, see §7)*

## 1. Objective
Make **Cartesia the single voice provider across the entire app** for both:
1. **Plain TTS** — reading static UI strings and AI-generated text aloud.
2. **Conversational AI voice** — real-time speech-to-speech, where **Gemini does the reasoning/generation** and **Cartesia provides STT + the spoken voice** (Cartesia "Line" agent experience).

Remove or fully replace any existing TTS/voice provider. No other voice backend should remain reachable from the app.

## 2. Voice configuration (do this first)
- Create one config module exposing the constants in §0. Every voice call — TTS and agent — must read from it; no inline model/voice strings anywhere.
- Use **`CARTESIA_VOICE_ID`** at synthesis time. The **`fine_tune_id`** is for provenance/management only (listing voices produced by the fine-tune via `GET /fine-tunes/{id}/voices`); it is **not** passed on every TTS call.
- Add a startup self-check: on boot, hit `GET https://api.cartesia.ai/api/voices/{CARTESIA_VOICE_ID}` (List/Get Voice) and fail fast with a clear log if the voice ID is invalid.

## 3. Plain TTS layer (static + AI text)
Implement a single `CartesiaTts` service used by the whole app:
- **Endpoints** (pick per use case):
  - Streaming playback (in-app, low latency) → **TTS WebSocket** (`wss://api.cartesia.ai/tts/websocket`) or **SSE**.
  - One-shot file / cache → **TTS Bytes** (`POST /tts/bytes`).
- Always send: `model_id = CARTESIA_TTS_MODEL`, `voice = { mode: "id", id: CARTESIA_VOICE_ID }`, the `Cartesia-Version` header, and an explicit `output_format` (sample rate / encoding) matching your audio pipeline.
- Cache synthesized audio for **static, unchanging strings** (key by text + voice + model) so repeated reads don't re-bill or re-stream.
- Centralize: no screen should call Cartesia directly — all through `CartesiaTts`.

## 4. Conversational agent — Cartesia Line (Gemini reasoning + Cartesia voice)
Stand up a Cartesia Line agent as a backend service:
- Scaffold with the CLI: `cartesia auth login`, `uv init`, `uv add cartesia-line`.
- Define `get_agent(...)` returning an `LlmAgent`:
  - `model="gemini/gemini-2.5-flash"` (Gemini does thinking + generation)
  - `api_key=os.getenv("GEMINI_API_KEY")`
  - Voice is Cartesia's — set the agent/call `voice_id = CARTESIA_VOICE_ID` so the spoken output matches the TTS voice in §3.
  - `config=LlmConfig(system_prompt=..., introduction=...)`
  - `tools=[...]` (see §6)
- STT is handled by Cartesia (Ink) inside Line — no separate STT integration needed. Confirm the flow is: **user speech → Cartesia STT → Gemini → Cartesia TTS (CARTESIA_VOICE_ID)**.
- Deploy: `cartesia init` → `cartesia deploy`; set secrets via `cartesia env set --from .env`. Note the resulting `agent_id`.
- Test locally with `cartesia chat <port>` before wiring the client.

## 5. Client ↔ agent over WebSocket
Connect the app to the deployed agent:
- **Auth:** mint a short-lived access token from `POST /access-token` (grant scoped to the agent). **Never ship `CARTESIA_API_KEY` to the client** — tokens only.
- **Connect:** `wss://api.cartesia.ai/agents/stream/{agent_id}` with headers `Authorization: Bearer {token}` and `Cartesia-Version: {CARTESIA_VERSION}`.
- **Protocol:**
  1. Send `start` **first** (connection drops otherwise). Include `config.input_format` (`pcm_44100` for web/mobile, `mulaw_8000` for telephony) and `config.voice_id = CARTESIA_VOICE_ID` to guarantee the agent voice.
  2. Stream mic audio as `media_input` (base64) and play `media_output` (base64); honor `clear` events to interrupt playback (barge-in).
  3. **Keepalive:** send a WebSocket ping every **60–90s** (idle timeout is 180s). On close `1000 / connection idle timeout`, reconnect and resend `start`.
- Capture all close codes/reasons for debugging.

## 6. Tools (Line SDK)
Every tool's first parameter is `ctx`. Implement:
- **Built-in:** `end_call` (with a custom description scoped to this app's "done" condition), `web_search` for live info, `transfer_call`/`send_dtmf` only if telephony is in scope.
- **Loopback** (`@loopback_tool`) for app data lookups (result returns to Gemini). Use `is_background=True` for anything slow (DB/report calls) so the user can keep talking.
- **Passthrough** (`@passthrough_tool`) for deterministic spoken responses / call control that should bypass the LLM.
- **Multilingual handoff:** for EN/FR/Darija/ES support, define per-language `LlmAgent`s and route with `agent_as_handoff(...)`, using `UpdateCallConfig(voice_id=..., language=...)` so voice + language switch together.

## 7. Weekly Cartesia version sync job (detect-and-gate, not blind auto-bump)
Add a scheduled job (cron, **weekly**) that keeps the app aware of the latest API version **without silently breaking prod**:
1. `GET https://api.cartesia.ai/` → read `version` (date string, e.g. `2025-03-01`).
2. Compare to the stored `CARTESIA_VERSION`.
3. If unchanged → log "up to date" and exit.
4. If newer → **persist** the latest version to a config/feature-flag store, log the diff, and **alert** (Slack/email) so a human can review the changelog before adopting.
5. Adoption is **flag-gated**: only when an `auto_adopt_cartesia_version` flag is on does the job promote the new value to the live `Cartesia-Version` header; otherwise it stays pinned and the alert prompts a manual bump.

> Rationale: API versions are pinned precisely to avoid surprise breaking changes. The weekly job's job is *awareness + controlled rollout*, not auto-upgrade.

## 8. Definition of done
- [ ] Exactly one voice provider (Cartesia) is reachable; old provider code/keys removed.
- [ ] Every TTS call and the agent use the same `CARTESIA_VOICE_ID` and `CARTESIA_TTS_MODEL` from one config module.
- [ ] Static-string TTS is cached; AI text streams.
- [ ] Live conversation works end-to-end (Gemini reasoning, Cartesia voice) with barge-in and reconnect-on-idle.
- [ ] Client uses scoped access tokens only — no API key on device.
- [ ] Weekly version job logs, stores, alerts, and is flag-gated.
- [ ] Self-check on boot validates the voice ID.

## 9. Open items to confirm before/while building
1. **Voice ID:** `fee439a9-751d-4d14-9974-a09de45bd0530` — final block is 13 chars; Cartesia voice IDs are standard UUIDs (12). Re-copy from the dashboard and confirm.
2. **Input audio format** for the WebSocket (`pcm_44100` vs `pcm_24000`/`mulaw_8000`) — depends on the client's mic pipeline.
3. **Which surfaces** get plain TTS vs. the conversational agent (list the screens/flows).
4. **Languages** required for handoff agents and whether each needs a distinct voice ID.

### Reference docs
- Line quickstart: https://docs.cartesia.ai/line/start-building/quickstart
- Tools: https://docs.cartesia.ai/line/sdk/tools
- WebSocket API: https://docs.cartesia.ai/line/integrations/websocket-api
- API status/version: https://docs.cartesia.ai/api-reference/api-status/get
