# MindCoach Content Library — Selection Rules v1.0

Purpose: Select a single best-fit coaching script from MindCoach_Content_Library_v1.csv, without inventing new structures.

## Inputs (minimum)
- template_id (one of the 8)
- user VARK preference (Visual/Aural/ReadWrite/Kinesthetic) if known; else default ReadWrite
- user level (Foundation/Build/Compete/Maintain) if known; else Foundation
- desired length (micro/standard/deep) based on context (in-round = micro/standard; post-round = standard/deep)
- scenario_tag(s) if detected (optional)

## Selection algorithm (deterministic)
1) Filter rows by template_id.
2) If scenario_tag detected, prioritize rows where scenario_tags contains it (substring match on ';' delimited list).
3) Filter by vark_mode (if unknown, use ReadWrite).
4) Filter by level (if unknown, use Foundation).
5) Filter by length (if unknown, use standard).
6) If multiple remain, pick the lowest content_id (stable).
7) If none remain at any step, relax in this order:
   - scenario_tag
   - level
   - vark_mode
   - length (standard fallback)
8) Return exactly ONE row.

## Personalization boundaries
Allowed:
- Insert user's name (optional)
- Reference last logged cue or routine (optional)
- Minor wording tweaks for clarity and tone

Forbidden:
- Creating new templates, cues, routine types, pillars
- Medical/therapeutic language or claims
- Promising outcomes

## Logging (recommended)
Store for each delivery:
- content_id
- template_id
- vark_mode
- level
- length
- scenario_tag_used (if any)
- user feedback rating (optional)