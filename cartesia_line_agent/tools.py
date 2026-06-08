"""Tools for the FoCoCo Line agent (§6 of the migration guide).

Import paths follow the cartesia-line SDK as described in the docs
(https://docs.cartesia.ai/line/sdk/tools). After `uv add cartesia-line`,
confirm the exact symbols with `uv run python -c "import line; help(line)"`
and adjust the imports below if the installed version differs.

Every tool's first parameter is `ctx` (the call context).
"""

from line import loopback_tool, passthrough_tool
from line.tools import end_call, web_search  # built-ins


# ── Built-ins ──────────────────────────────────────────────────────────────
# `end_call` with an app-scoped "done" description so the model knows when a
# coaching conversation is actually complete.
end_session = end_call(
    description=(
        "End the call when the player says goodbye, confirms they feel ready "
        "to play, or explicitly asks to stop. Do NOT end while they are still "
        "working through a thought or asking questions."
    )
)

# Live info lookups (rules, tournament conditions, general questions).
search_web = web_search()


# ── Loopback: app data lookup (result returns to Gemini) ─────────────────────
@loopback_tool(
    description=(
        "Look up the player's recent FoCoCo context — last MindCoach session "
        "focus, recent round summary, and current mental-game goal. Use this "
        "to ground coaching in what they've actually been working on."
    ),
    is_background=True,  # may hit Firestore / a report endpoint — let them keep talking
)
async def fetch_player_context(ctx, user_id: str) -> dict:
    """Return a compact dict of the player's recent coaching context.

    TODO: wire to the FoCoCo backend. Options:
      - call the Firebase callable that already serves session summaries, or
      - read Firestore with a service account scoped to read-only.
    Returning an empty-but-valid shape is safe — Gemini will coach generally.
    """
    # Placeholder shape until the backend call is wired:
    return {
        "user_id": user_id,
        "last_session_focus": None,
        "recent_round_summary": None,
        "current_goal": None,
    }


# ── Passthrough: deterministic spoken response (bypasses the LLM) ────────────
@passthrough_tool(
    description=(
        "Speak a fixed, careful response when the player expresses serious "
        "distress or mentions self-harm. This must NOT be paraphrased by the "
        "model."
    )
)
async def safety_handoff(ctx) -> str:
    return (
        "I'm really glad you told me. I'm a golf coach, not a crisis "
        "counselor, so I want to make sure you get the right support. If "
        "you're in immediate danger please contact local emergency services. "
        "You don't have to go through this alone."
    )
