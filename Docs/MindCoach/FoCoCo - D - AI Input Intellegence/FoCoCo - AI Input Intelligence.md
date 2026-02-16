# FoCoCo Input Intelligence (Separate Systems) — Manifest v1.9

This folder contains *input understanding* assets (voice/NLP, tone variants, VARK delivery variants, error handling, and logging intents).
These assets help FoCoCo understand what the user says and how to respond, but they do NOT define MindCoach coaching structures.

## Purpose
- Map natural language (voice or typed) into structured FoCoCo events
- Detect intent and route it to the correct subsystem:
  - MindMap (mental)
  - ShotMap (technical)
  - SyncMap (combined)
  - Log Round flows
  - Microphone / capture status
- Support age-appropriate phrasing (13+) and VARK delivery variations

## Expected asset categories (examples)
- Intent Voice Commands (mental / performance / combined)
- Golf slang & indirect phrasing
- Error handling & clarification prompts
- Conversational loops & follow-up responses
- Mindset ratings, cues, routine types detection
- Technical shot logs and round start/stop phrases
- VARK delivery style variants
- Youth tone variants (13+)

## Important separation
- Documentation/spec (rules): FoCoCo_MindCoach_AI_Specification_v1_1.pdf
- Authoritative templates (data): MindCoach_Templates_v1.json
- Input Intelligence assets (this folder): CSVs / prompt libraries / corpora

## Versioning
Keep version numbers aligned with your release process (e.g., v1.9, v2.0).
Do not embed these datasets inside PDFs.
