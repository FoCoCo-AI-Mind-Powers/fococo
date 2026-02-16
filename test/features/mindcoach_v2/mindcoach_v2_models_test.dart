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
}
