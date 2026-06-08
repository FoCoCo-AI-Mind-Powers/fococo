import 'package:flutter_test/flutter_test.dart';
import 'package:fo_co_co/pages/golf_rounds/caddyplay_models.dart';

void main() {
  test('score helpers preserve spec weighting', () {
    expect(focusScore(CaddyPlayFocusLevel.high), 90);
    expect(focusScore(CaddyPlayFocusLevel.mid), 65);
    expect(focusScore(CaddyPlayFocusLevel.low), 35);

    expect(resultScore(CaddyPlayShotResult.good), 85);
    expect(resultScore(CaddyPlayShotResult.ok), 60);
    expect(resultScore(CaddyPlayShotResult.bad), 35);

    expect(routineScore(CaddyPlayRoutineStatus.yes), 85);
    expect(routineScore(CaddyPlayRoutineStatus.partly), 60);
    expect(routineScore(CaddyPlayRoutineStatus.no), 35);
  });

  test('aggregate mindset and snapshot derive deterministic values', () {
    final round = CaddyPlayActiveRound.newRound(
      roundId: 'round_1',
      userId: 'user_1',
      courseName: 'San Lorenzo GC',
      holesTotal: 18,
      roundType: CaddyPlayRoundType.practice,
      playingPartners: CaddyPlayPlayingPartners.friends,
      preRoundMindset: CaddyPlayPreRoundMindset.positive,
      weather: CaddyPlayWeather.good,
    ).copyWith(
      holes: [
        CaddyPlayHole(
          holeNumber: 1,
          par: 4,
          score: 5,
          moments: [
            CaddyPlayMoment(
              id: 'tap_1',
              holeNumber: 1,
              type: CaddyPlayMomentType.tap,
              timestamp: DateTime(2026, 3, 16, 9),
              commitment: CaddyPlayCommitmentLevel.high,
              focusLevel: CaddyPlayFocusLevel.high,
              shotResult: CaddyPlayShotResult.good,
              preShotRoutine: CaddyPlayRoutineStatus.yes,
            ),
          ],
        ),
        CaddyPlayHole(
          holeNumber: 2,
          par: 4,
          score: 6,
          moments: [
            CaddyPlayMoment(
              id: 'talk_1',
              holeNumber: 2,
              type: CaddyPlayMomentType.talk,
              timestamp: DateTime(2026, 3, 16, 9, 8),
              focusLevel: CaddyPlayFocusLevel.low,
              shotResult: CaddyPlayShotResult.bad,
              transcript: 'Focus dropped and I rushed the routine.',
              pillarTags: const [CaddyPlayPillarTag.focus],
            ),
            CaddyPlayMoment(
              id: 'mind_1',
              holeNumber: 2,
              type: CaddyPlayMomentType.mindsnap,
              timestamp: DateTime(2026, 3, 16, 9, 12),
              mindSnapSequence: CaddyPlayMindSnapSequence.recovery,
            ),
          ],
        ),
        for (var hole = 3; hole <= 18; hole++) CaddyPlayHole(holeNumber: hole),
      ],
      currentHole: 2,
      lastUpdatedAt: DateTime(2026, 3, 16, 9, 15),
    );

    final aggregate = aggregateMindset(round);
    final snapshot = buildRoundSnapshot(round);

    expect(aggregate.focus, greaterThan(0));
    expect(aggregate.confidence, greaterThan(0));
    expect(aggregate.control, greaterThan(0));
    expect(snapshot.courseName, 'San Lorenzo GC');
    expect(snapshot.scoreToPar, 3);
    expect(snapshot.scoreToParIsApproximate, isFalse);
    expect(snapshot.holesPlayed, 2);
    expect(snapshot.totalMoments, 3);
    expect(snapshot.tapCount, 1);
    expect(snapshot.talkCount, 1);
    expect(snapshot.mindSnapCount, 1);
    expect(snapshot.momentumShift, isNotEmpty);
    expect(snapshot.completionInsight, isNotEmpty);
  });

  test('mind snap selection prefers recovery when recent hole slipped', () {
    final round = CaddyPlayActiveRound.newRound(
      roundId: 'round_2',
      userId: 'user_2',
      courseName: 'San Lorenzo GC',
      holesTotal: 9,
      roundType: CaddyPlayRoundType.casual,
      playingPartners: CaddyPlayPlayingPartners.solo,
      preRoundMindset: CaddyPlayPreRoundMindset.neutral,
      weather: CaddyPlayWeather.ok,
    ).copyWith(
      holes: [
        CaddyPlayHole(
          holeNumber: 1,
          moments: [
            CaddyPlayMoment(
              id: 'talk_recent',
              holeNumber: 1,
              type: CaddyPlayMomentType.talk,
              timestamp: DateTime(2026, 3, 16, 10),
              focusLevel: CaddyPlayFocusLevel.low,
              shotResult: CaddyPlayShotResult.bad,
              transcript: 'I felt tense and rushed over the ball.',
            ),
          ],
        ),
        for (var hole = 2; hole <= 9; hole++) CaddyPlayHole(holeNumber: hole),
      ],
      currentHole: 1,
      lastUpdatedAt: DateTime(2026, 3, 16, 10, 1),
    );

    expect(
      deriveMindSnapSequence(round),
      CaddyPlayMindSnapSequence.composure,
    );
    expect(
      buildTapMicroInsight(
        CaddyPlayMoment(
          id: 'tap_recent',
          holeNumber: 1,
          type: CaddyPlayMomentType.tap,
          timestamp: DateTime(2026, 3, 16, 10, 2),
          preShotRoutine: CaddyPlayRoutineStatus.no,
        ),
      ),
      'Routine first.',
    );
  });

  test('partial round score to par uses scored holes only (5+4+6 on par 4s = +3)', () {
    final round = CaddyPlayActiveRound.newRound(
      roundId: 'round_partial',
      userId: 'user_1',
      courseName: 'Test GC',
      holesTotal: 18,
      roundType: CaddyPlayRoundType.casual,
      playingPartners: CaddyPlayPlayingPartners.solo,
      preRoundMindset: CaddyPlayPreRoundMindset.positive,
      weather: CaddyPlayWeather.good,
    ).copyWith(
      holes: [
        CaddyPlayHole(holeNumber: 1, par: 4, score: 5),
        CaddyPlayHole(holeNumber: 2, par: 4, score: 4),
        CaddyPlayHole(holeNumber: 3, par: 4, score: 6),
        for (var hole = 4; hole <= 18; hole++) CaddyPlayHole(holeNumber: hole),
      ],
      currentHole: 3,
    );

    expect(round.scoreToPar, 3);
    expect(round.scoreToParUsesDefaultedPar, isFalse);
    final snap = buildRoundSnapshot(round);
    expect(snap.scoreToPar, 3);
    expect(snap.scoreToParIsApproximate, isFalse);
  });

  test('defaulted par when score set and par null yields approximate flag', () {
    final round = CaddyPlayActiveRound.newRound(
      roundId: 'round_approx',
      userId: 'user_1',
      courseName: 'Test GC',
      holesTotal: 9,
      roundType: CaddyPlayRoundType.practice,
      playingPartners: CaddyPlayPlayingPartners.solo,
      preRoundMindset: CaddyPlayPreRoundMindset.positive,
      weather: CaddyPlayWeather.good,
    ).copyWith(
      holes: [
        CaddyPlayHole(holeNumber: 1, score: 5),
        CaddyPlayHole(holeNumber: 2, score: 4),
        CaddyPlayHole(holeNumber: 3, score: 5),
        for (var hole = 4; hole <= 9; hole++) CaddyPlayHole(holeNumber: hole),
      ],
    );

    expect(round.totalPar, 12);
    expect(round.totalScore, 14);
    expect(round.scoreToPar, 2);
    expect(round.scoreToParUsesDefaultedPar, isTrue);
    expect(
      formatCaddyPlayScoreToParLabel(round.scoreToPar, approximate: true),
      '~+2',
    );
    final snap = buildRoundSnapshot(round);
    expect(snap.scoreToParIsApproximate, isTrue);
  });
}
