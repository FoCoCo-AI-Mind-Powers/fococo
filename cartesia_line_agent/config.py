"""Pinned Cartesia/agent constants — single source of truth for this service.

Mirrors the Flutter client's CartesiaConfig
(lib/ai_integration/config/cartesia_config.dart). Keep the two in sync so the
spoken agent voice matches plain TTS (§8 of the migration guide).
"""

import os

# Voice — loaded from Secret Manager / env (`CARTESIA_VOICE_ID`). Fallback only
# for local dev before secrets are wired.
CARTESIA_VOICE_ID = os.getenv(
    "CARTESIA_VOICE_ID", "fee439a9-751d-4d14-9974-a09de45bd053"
).strip()

# Gemini does the reasoning/generation; Cartesia provides STT (Ink) + voice.
GEMINI_MODEL = "gemini/gemini-2.5-flash"

# `Cartesia-Version` header — pinned (§7). Only the weekly sync job may bump it.
CARTESIA_VERSION = "2025-04-16"


def gemini_api_key() -> str:
    # Prefer GEMINI_KEY_APP (same Secret Manager name as Cloud Functions).
    key = os.getenv("GEMINI_KEY_APP", "") or os.getenv("GEMINI_API_KEY", "")
    if not key:
        raise RuntimeError(
            "GEMINI_KEY_APP (or GEMINI_API_KEY) is not set — run "
            "`cartesia env set --from .env` before starting the agent."
        )
    return key
