import 'package:flutter_test/flutter_test.dart';

import 'package:fo_co_co/features/mindcoach_v2/data/mappers/mindcoach_v2_mappers.dart';
import 'package:fo_co_co/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

void main() {
  test('parse generate response maps session contract correctly', () {
    final response = MindCoachV2Mappers.parseGenerateResponse(
      {
        'session_id': 's1',
        'context_mode': 'during_round',
        'ui_mode': 'live_minimal',
        'run_id': 'r1',
        'session': {
          'schema_version': 'mindcoach_session_v2',
          'template_id': 'MC_T03_BETWEEN_SHOTS_RESET',
          'routine_type': '🚶 Between Shots',
          'recommended_cue': '🔄 Reset',
          'delivery_length': 'micro_10s',
          'coaching_text': 'Pause. Breathe. Next target.',
          'follow_up_question': null,
          'validator_status': 'PASS',
          'model_version': 'gemini-2.5-flash',
          'prompt_version': 'mindcoach_system_v1',
          'vark_mode_selected': 'Visual',
          'level_selected': 'Build',
          'total_duration_sec': 10,
          'lines': [
            {
              'text': 'Pause.',
              'startMs': 0,
              'durationMs': 2400,
              'endMs': 2400,
            },
          ],
        },
      },
      userId: 'u1',
    );

    expect(response.sessionId, 's1');
    expect(response.runId, 'r1');
    expect(response.contextMode, MindCoachV2ContextMode.duringRound);
    expect(response.uiMode, MindCoachV2UiMode.liveMinimal);
    expect(response.session.templateId, 'MC_T03_BETWEEN_SHOTS_RESET');
    expect(response.session.validatorStatus, 'PASS');
    expect(response.session.varkModeSelected, 'Visual');
    expect(response.session.levelSelected, 'Build');
    expect(response.session.lines, isNotNull);
    expect(response.session.lines!.first.endMs, 2400);
  });

  test('session model parses firestore compatibility fields', () {
    final session = MindCoachV2Session.fromFirestore('doc_1', {
      'schema_version': 'mindcoach_session_v2',
      'userId': 'user_1',
      'context_mode': 'after_round',
      'templateId': 'MC_T08_END_OF_ROUND_REFLECTION',
      'routineType': '⏳ Pre-Round',
      'cueUsed': '💬 Self-Talk',
      'deliveryLength': 'standard_3m',
      'coachingText': 'Reflect and choose one next step.',
      'validator_status': 'FAIL_CORRECTED',
      'model_version': 'gemini_generation_failed',
      'prompt_version': 'mindcoach_system_v1',
      'scenario_tags': ['post_round_learn'],
    });

    expect(session.sessionId, 'doc_1');
    expect(session.userId, 'user_1');
    expect(session.contextMode, MindCoachV2ContextMode.afterRound);
    expect(session.templateId, 'MC_T08_END_OF_ROUND_REFLECTION');
    expect(session.recommendedCue, '💬 Self-Talk');
    expect(session.validatorStatus, 'FAIL_CORRECTED');
    expect(session.scenarioTags, ['post_round_learn']);
  });

  test('generate request keeps locked session metadata for catalog launches',
      () {
    final request = MindCoachV2GenerateRequest(
      contextMode: MindCoachV2ContextMode.beforeRound,
      entrySource: 'session_list',
      pillar: MindCoachV2Pillar.focus,
      sessionKey: 'focus_clear_start',
      sessionName: 'Clear Start',
      sessionDescriptor: 'Settle before the first tee.',
      targetDurationSec: 30,
      preferredDeliveryLength: 'standard',
    );

    expect(request.toMap(), {
      'context_mode': 'before_round',
      'entry_source': 'session_list',
      'pillar': 'focus',
      'session_key': 'focus_clear_start',
      'session_name': 'Clear Start',
      'session_descriptor': 'Settle before the first tee.',
      'target_duration_sec': 30,
      'preferred_delivery_length': 'standard',
      'customization': {
        'tone': 'auto',
        'vark_mode': 'auto',
      },
    });
  });

  test('session top bar title uses context label and duration', () {
    final session = MindCoachV2Session.fromApi(
      {
        'template_id': 'MC_T01_PRE_ROUND_CLARITY',
        'routine_type': 'Clear Start',
        'recommended_cue': 'Breathe',
        'delivery_length': 'standard_30s',
        'coaching_text': 'Settle into the round.',
        'duration_sec': 45,
        'validator_status': 'PASS',
        'model_version': 'gemini',
        'prompt_version': 'mindcoach_system_v1',
      },
      sessionId: 'session_1',
      userId: 'user_1',
      contextMode: MindCoachV2ContextMode.beforeRound,
    );

    expect(session.topBarTitle, 'Before Round · 45 sec');
  });
}
