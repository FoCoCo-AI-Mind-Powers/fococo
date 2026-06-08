"""FoCoCo conversational coach — Cartesia Line agent.

Flow (§4): user speech → Cartesia STT (Ink) → Gemini reasoning → Cartesia TTS
(CARTESIA_VOICE_ID). STT is handled inside Line; no separate STT wiring.

Import paths follow the cartesia-line SDK docs
(https://docs.cartesia.ai/line/start-building/quickstart). Confirm exact
symbols with `uv run python -c "import line; help(line)"` after install.
"""

from line import LlmAgent, LlmConfig, agent_as_handoff
from line.config import UpdateCallConfig

from config import CARTESIA_VOICE_ID, GEMINI_MODEL, gemini_api_key
from tools import end_session, fetch_player_context, safety_handoff, search_web

# §9.4 open item: each language reuses the one CARTESIA_VOICE_ID for now. If a
# language needs its own voice, set it per-entry here and the handoff below
# switches voice + language together via UpdateCallConfig.
LANGUAGE_VOICES = {
    "en": CARTESIA_VOICE_ID,
    "fr": CARTESIA_VOICE_ID,
    "ar": CARTESIA_VOICE_ID,  # Darija (Moroccan Arabic)
    "es": CARTESIA_VOICE_ID,
}

_BASE_PERSONA = (
    "You are FoCoCo, a calm, encouraging golf mental-performance coach. You "
    "reflect back what the player says, ask short focused questions, and keep "
    "a warm, unhurried tone. You are not a therapist. Keep replies brief and "
    "conversational — this is spoken, not written. End complete thoughts with "
    "terminal punctuation (. ? !) so Cartesia TTS can pace naturally. "
    "No markdown, bullets, or JSON in spoken output. No swing-mechanics coaching. "
    "Use fetch_player_context to ground advice in the player's recent work when relevant."
)

_INTROS = {
    "en": "Hey, it's FoCoCo. How are you feeling about your game today?",
    "fr": "Salut, c'est FoCoCo. Comment te sens-tu par rapport à ton jeu aujourd'hui ?",
    "ar": "أهلا، أنا فوكوكو. كيف كتحس براسك ف اللعب اليوم؟",
    "es": "Hola, soy FoCoCo. ¿Cómo te sientes con tu juego hoy?",
}

_SHARED_TOOLS = [search_web, fetch_player_context, safety_handoff, end_session]


def _language_agent(lang: str) -> LlmAgent:
    return LlmAgent(
        model=GEMINI_MODEL,
        api_key=gemini_api_key(),
        voice_id=LANGUAGE_VOICES[lang],
        config=LlmConfig(
            system_prompt=f"{_BASE_PERSONA}\nRespond only in this language: {lang}.",
            introduction=_INTROS[lang],
        ),
        tools=_SHARED_TOOLS,
    )


def get_agent() -> LlmAgent:
    """Entry point Cartesia Line calls to build the agent for each session.

    English is the primary agent; FR/Darija/ES are reachable via handoff so the
    voice and language switch together when the player changes language.
    """
    en = _language_agent("en")

    handoffs = []
    for lang in ("fr", "ar", "es"):
        target = _language_agent(lang)
        handoffs.append(
            agent_as_handoff(
                agent=target,
                description=f"Hand off when the player speaks {lang}.",
                on_handoff=UpdateCallConfig(
                    voice_id=LANGUAGE_VOICES[lang],
                    language=lang,
                ),
            )
        )

    en.tools = _SHARED_TOOLS + handoffs
    return en
