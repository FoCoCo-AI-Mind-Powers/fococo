const path = require('path');

const SCHEMA_VERSION = 'mindcoach_session_v2';
const PROMPT_VERSION = 'mindcoach_system_v1';
const FALLBACK_TEMPLATE_ID = 'MC_T02_PRE_SHOT_FOCUS';

const VALID_CONTEXT_MODES = new Set([
  'auto',
  'before_round',
  'during_round',
  'after_round',
  'off_day',
]);

const VALID_ENTRY_SOURCES = new Set([
  'session_list',
  'during_round_overlay',
  'resume_restart',
  'play_again',
  'favorite_replay',
  'home_primary',
  'home_chip',
  'builder',
  'history_repeat',
]);

const VALID_UI_MODES = new Set(['live_minimal', 'guided_extended']);

const VALID_MINDSET_VALUES = new Set([
  'peak_focus',
  'calm_in_control',
  'neutral',
  'distracted',
  'scattered',
]);

const VALID_DELIVERY_LENGTHS = new Set(['auto', 'micro', 'standard', 'deep']);
const VALID_TONES = new Set(['auto', 'calm', 'directive', 'reassuring']);
const VALID_VARK = new Set(['auto', 'Visual', 'Aural', 'ReadWrite', 'Kinesthetic']);
const CONTENT_LIBRARY_EXPECTED_ROWS = 384;
const SPEECH_TIMING_FIELDS = ['startMs', 'durationMs', 'endMs'];

const TEMPLATE_IDS = [
  'MC_T01_PRE_ROUND_CLARITY',
  'MC_T02_PRE_SHOT_FOCUS',
  'MC_T03_BETWEEN_SHOTS_RESET',
  'MC_T04_POST_SHOT_LETTING_GO',
  'MC_T05_MISTAKE_RECOVERY',
  'MC_T06_PRESSURE_MOMENTS',
  'MC_T07_MOMENTUM_PROTECTION',
  'MC_T08_END_OF_ROUND_REFLECTION',
  'MC_T09_POST_ROUND_INSIGHT',
];

const PILLAR_KEYS = ['focus', 'confidence', 'control'];

const FORBIDDEN_LANGUAGE_PATTERNS = [
  /\bdiagnos(e|is|tic)\b/i,
  /\btreat(ment|ing)?\b/i,
  /\btherapy|therapist|counsel(l)?ing\b/i,
  /\bclinical|disorder|psychiatric|psychological\b/i,
  /\bdepression|anxiety disorder|adhd|ocd\b/i,
  /\bcure|guaranteed?|definitely\b/i,
  /\bthis will fix\b/i,
  /\bnew cue\b/i,
  /\bfourth pillar\b/i,
  /\bnew routine type\b/i,
];

// MindCoach reference data ships with the Cloud Functions bundle so the
// runtime never has to reach into the Flutter `Docs/` tree (which isn't
// deployed). Local emulator runs from the repo root fall back to the
// canonical authoring path under `Docs/MindCoach/FoCoCo - B - AI Data/`.
const BUNDLED_MINDCOACH_DATA_PATH = path.join(__dirname, 'data');
const LEGACY_MINDCOACH_DATA_PATH = path.join(
  __dirname,
  '..',
  '..',
  '..',
  'Docs',
  'MindCoach',
  'FoCoCo - B - AI Data',
);
const MINDCOACH_DATA_PATH = require('fs').existsSync(BUNDLED_MINDCOACH_DATA_PATH)
  ? BUNDLED_MINDCOACH_DATA_PATH
  : LEGACY_MINDCOACH_DATA_PATH;

const TEMPLATES_JSON_PATH = path.join(
  MINDCOACH_DATA_PATH,
  'FoCoCo - AI Templates.json',
);

const CONTENT_LIBRARY_CSV_PATH = path.join(
  MINDCOACH_DATA_PATH,
  'FoCoCo - AI Content Library.csv',
);

const SCENARIO_TAGS_CSV_PATH = path.join(
  MINDCOACH_DATA_PATH,
  'FoCoCo - AI Scenario Tags.csv',
);

module.exports = {
  SCHEMA_VERSION,
  PROMPT_VERSION,
  FALLBACK_TEMPLATE_ID,
  VALID_CONTEXT_MODES,
  VALID_ENTRY_SOURCES,
  VALID_UI_MODES,
  VALID_MINDSET_VALUES,
  VALID_DELIVERY_LENGTHS,
  VALID_TONES,
  VALID_VARK,
  CONTENT_LIBRARY_EXPECTED_ROWS,
  SPEECH_TIMING_FIELDS,
  TEMPLATE_IDS,
  PILLAR_KEYS,
  FORBIDDEN_LANGUAGE_PATTERNS,
  MINDCOACH_DATA_PATH,
  TEMPLATES_JSON_PATH,
  CONTENT_LIBRARY_CSV_PATH,
  SCENARIO_TAGS_CSV_PATH,
};
