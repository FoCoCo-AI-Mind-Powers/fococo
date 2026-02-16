const String kMindCoachV2SchemaVersion = 'mindcoach_session_v2';
const String kMindCoachPromptVersion = 'mindcoach_system_v1';

const Set<String> kMindCoachTemplateIds = {
  'MC_T01_PRE_ROUND_CLARITY',
  'MC_T02_PRE_SHOT_FOCUS',
  'MC_T03_BETWEEN_SHOTS_RESET',
  'MC_T04_POST_SHOT_LETTING_GO',
  'MC_T05_MISTAKE_RECOVERY',
  'MC_T06_PRESSURE_MOMENTS',
  'MC_T07_MOMENTUM_PROTECTION',
  'MC_T08_END_OF_ROUND_REFLECTION',
};

const Set<String> kMindCoachContextModes = {
  'auto',
  'before_round',
  'during_round',
  'after_round',
  'off_day',
};

const Set<String> kMindCoachEntrySources = {
  'home_primary',
  'home_chip',
  'builder',
  'history_repeat',
};

const Set<String> kMindCoachUiModes = {
  'live_minimal',
  'guided_extended',
};

const Set<String> kMindCoachDeliveryLengths = {
  'auto',
  'micro',
  'standard',
  'deep',
};
