# FoCoCo Line Agent (§4–§6)

Conversational coach: **Gemini reasons, Cartesia speaks + transcribes.** Deployed
on Cartesia's runtime (not Firebase). Voice matches plain TTS via the shared
`CARTESIA_VOICE_ID`.

```
cartesia_line_agent/
├── agent.py      # get_agent(): English LlmAgent + FR/Darija/ES handoffs
├── tools.py      # end_call, web_search, loopback (player context), passthrough (safety)
├── config.py     # pinned constants — mirror of the Flutter CartesiaConfig
├── .env.example  # CARTESIA_API + GEMINI_API_KEY
└── pyproject.toml
```

## ⚠️ Before relying on this code

The SDK symbols (`LlmAgent`, `LlmConfig`, `agent_as_handoff`, `UpdateCallConfig`,
`loopback_tool`, `passthrough_tool`, `end_call`, `web_search`) follow the
migration guide and the Cartesia Line docs. The package isn't installed in this
repo yet, so the **exact import paths are unverified**. After `uv sync`, run:

```bash
uv run python -c "import line; print(dir(line))"
```

and reconcile the imports in `agent.py` / `tools.py` with what the installed
version actually exports.

## Local setup & test

```bash
cd cartesia_line_agent
cartesia auth login            # one-time
uv sync                        # installs cartesia-line from pyproject
cp .env.example .env           # fill in CARTESIA_API + GEMINI_API_KEY
cartesia chat 8000             # local speech-to-speech test before wiring the client
```

## Deploy

```bash
cartesia init                  # one-time, links this dir to a Cartesia app
cartesia env set --from .env   # push secrets to the runtime
cartesia deploy                # → prints the agent_id
```

Record the resulting **`agent_id`** — the Flutter client needs it for the
WebSocket connection (§5: `wss://api.cartesia.ai/agents/stream/{agent_id}`,
short-lived access token via `POST /access-token`, never the raw key).

## Open items (from guide §9)

- **§9.1 Voice ID** — `fee439a9-…-0530` last block is 13 chars. The plain-TTS
  boot self-check (`verifyVoice` callable) will tell you if it's valid; fix in
  `config.py` if it 4xxs.
- **§9.4 Languages** — EN/FR/Darija(ar)/ES all reuse one voice ID. Give a
  language its own voice in `LANGUAGE_VOICES` (config in `agent.py`) if needed.
- **`fetch_player_context`** — currently returns an empty-but-valid shape. Wire
  it to the FoCoCo backend (Firebase callable or read-only Firestore service
  account) to ground coaching in the player's real recent sessions.
