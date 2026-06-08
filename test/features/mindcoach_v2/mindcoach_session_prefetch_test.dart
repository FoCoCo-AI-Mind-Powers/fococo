import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import 'package:fo_co_co/features/mindcoach_v2/services/mindcoach_session_prefetch.dart';

MindCoachV2GenerateResponse _fakeResponse(String id) {
  return MindCoachV2GenerateResponse(
    sessionId: id,
    contextMode: MindCoachV2ContextMode.offDay,
    uiMode: MindCoachV2UiMode.guidedExtended,
    session: MindCoachV2Session(
      sessionId: id,
      schemaVersion: '2',
      userId: 'user',
      pillar: MindCoachV2Pillar.focus,
      contextMode: MindCoachV2ContextMode.offDay,
      templateId: 'MC_T01',
      sessionKey: 'focus_reset',
      sessionName: 'Focus Reset',
      sessionDescriptor: 'Quick reset',
      durationSec: 45,
      routineType: 'breath',
      recommendedCue: 'Breathe',
      deliveryLength: 'standard',
      coachingText: 'Breathe in. Breathe out.',
      validatorStatus: 'valid',
      modelVersion: 'test',
      promptVersion: 'test',
    ),
  );
}

void main() {
  test('prefetch store and take is single-use', () {
    MindCoachSessionPrefetch.clear();
    final response = _fakeResponse('sess_1');
    MindCoachSessionPrefetch.store(response);

    final taken = MindCoachSessionPrefetch.take();
    expect(taken?.sessionId, 'sess_1');
    expect(MindCoachSessionPrefetch.take(), isNull);
  });
}
