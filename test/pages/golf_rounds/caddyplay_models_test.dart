import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/pages/golf_rounds/caddyplay_models.dart';

void main() {
  test('chip score mapping defaults match contract', () {
    expect(focusScore(CaddyPlayFocusChip.clear), 90);
    expect(focusScore(CaddyPlayFocusChip.neutral), 65);
    expect(focusScore(CaddyPlayFocusChip.distracted), 35);

    expect(resultScore(CaddyPlayResultChip.good), 85);
    expect(resultScore(CaddyPlayResultChip.ok), 60);
    expect(resultScore(CaddyPlayResultChip.poor), 35);

    expect(routineScore(CaddyPlayRoutineChip.yes), 85);
    expect(routineScore(CaddyPlayRoutineChip.partial), 60);
    expect(routineScore(CaddyPlayRoutineChip.no), 40);

    expect(emotionScore(CaddyPlayEmotionChip.calm), 85);
    expect(emotionScore(CaddyPlayEmotionChip.pressured), 55);
    expect(emotionScore(CaddyPlayEmotionChip.frustrated), 35);
  });

  test('aggregate mindset computes deterministic pillar scores', () {
    final logs = <CaddyPlayLog>[
      CaddyPlayLog(
        id: '1',
        sessionId: 's',
        userId: 'u',
        mode: CaddyPlayMode.play,
        holeNumber: 1,
        inputMethod: 'tap',
        transcription: '',
        result: CaddyPlayResultChip.good,
        focus: CaddyPlayFocusChip.clear,
        routine: CaddyPlayRoutineChip.yes,
        emotion: CaddyPlayEmotionChip.calm,
        capturedAt: DateTime(2026, 2, 16),
        editedAt: null,
      ),
      CaddyPlayLog(
        id: '2',
        sessionId: 's',
        userId: 'u',
        mode: CaddyPlayMode.play,
        holeNumber: 2,
        inputMethod: 'voice',
        transcription: '',
        result: CaddyPlayResultChip.poor,
        focus: CaddyPlayFocusChip.distracted,
        routine: CaddyPlayRoutineChip.no,
        emotion: CaddyPlayEmotionChip.frustrated,
        capturedAt: DateTime(2026, 2, 16),
        editedAt: null,
      ),
    ];

    final aggregate = aggregateMindset(logs);

    expect(aggregate.mindsetFocus, 63);
    expect(aggregate.mindsetConfidence, 60);
    expect(aggregate.mindsetControl, 63);
    expect(aggregate.overallEmoji, isNotEmpty);
    expect(aggregate.mindsetColor, isNotEmpty);
  });

  test('voice inference triggers required fallback when partial data', () {
    final inferred = inferChipSelectionFromTranscript(
      'Felt rushed and distracted after that tee shot',
    );

    expect(inferred.focus, CaddyPlayFocusChip.distracted);
    expect(inferred.result, isNull);
    expect(inferred.hasRequired, isFalse);
  });
}
