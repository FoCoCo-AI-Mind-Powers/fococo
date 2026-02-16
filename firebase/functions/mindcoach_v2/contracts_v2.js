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

const TEMPLATE_IDS = [
  'MC_T01_PRE_ROUND_CLARITY',
  'MC_T02_PRE_SHOT_FOCUS',
  'MC_T03_BETWEEN_SHOTS_RESET',
  'MC_T04_POST_SHOT_LETTING_GO',
  'MC_T05_MISTAKE_RECOVERY',
  'MC_T06_PRESSURE_MOMENTS',
  'MC_T07_MOMENTUM_PROTECTION',
  'MC_T08_END_OF_ROUND_REFLECTION',
];

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

const MINDCOACH_DATA_PATH = path.join(
  __dirname,
  '..',
  '..',
  '..',
  'Docs',
  'MindCoach',
  'FoCoCo - B - AI Data',
);

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
  TEMPLATE_IDS,
  FORBIDDEN_LANGUAGE_PATTERNS,
  MINDCOACH_DATA_PATH,
  TEMPLATES_JSON_PATH,
  CONTENT_LIBRARY_CSV_PATH,
  SCENARIO_TAGS_CSV_PATH,
};
