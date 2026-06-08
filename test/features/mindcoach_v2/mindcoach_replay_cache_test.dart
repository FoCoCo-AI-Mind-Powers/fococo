import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import 'package:fo_co_co/features/mindcoach_v2/services/mindcoach_replay_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('replay cache save and load roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final response = _fakeResponse('session_42');
    await MindCoachReplayCache.saveFromResponse(response);
    final loaded = await MindCoachReplayCache.load('session_42');
    expect(loaded?.sessionId, 'session_42');
    expect(loaded?.session.sessionName, 'Focus Reset');
  });
}
