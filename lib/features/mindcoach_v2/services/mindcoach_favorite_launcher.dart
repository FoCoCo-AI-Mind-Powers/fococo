import 'package:flutter/material.dart';

import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/player/mindcoach_session_player_v2_widget.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_session_prep_overlay.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_replay_cache.dart';

/// Opens a saved MindCoach favorite — replays stored session content when
/// available, otherwise regenerates via the MindCoach API.
class MindCoachFavoriteLauncher {
  MindCoachFavoriteLauncher._();

  static Future<void> openFavorite(
    BuildContext context,
    MindCoachV2Favorite favorite,
  ) async {
    final accent = MindCoachV2Visuals.accentForPillar(favorite.pillar);
    final session = favorite.session;

    MindCoachV2GenerateResponse? response =
        await MindCoachReplayCache.load(session.sessionId);

    if (response == null && session.coachingText.trim().isNotEmpty) {
      final uiMode = favorite.contextMode == MindCoachV2ContextMode.duringRound
          ? MindCoachV2UiMode.liveMinimal
          : MindCoachV2UiMode.guidedExtended;
      response = MindCoachV2GenerateResponse(
        sessionId: session.sessionId,
        contextMode: favorite.contextMode,
        uiMode: uiMode,
        session: session,
      );
    }

    if (response == null) {
      final repository = MindCoachV2Repository.instance;
      const valid = {'auto', 'micro', 'standard', 'deep'};
      final delivery = session.deliveryLength;
      response = await runMindCoachSessionPrep<MindCoachV2GenerateResponse>(
        context: context,
        accentColor: accent,
        sessionTitle: favorite.sessionName,
        work: () => repository.generateSession(
          MindCoachV2GenerateRequest(
            contextMode: favorite.contextMode,
            entrySource: 'favorite_replay',
            pillar: favorite.pillar,
            sessionKey: favorite.sessionKey,
            sessionName: favorite.sessionName,
            sessionDescriptor: favorite.sessionDescriptor,
            targetDurationSec:
                favorite.durationSec > 0 ? favorite.durationSec : null,
            preferredDeliveryLength:
                valid.contains(delivery) ? delivery : 'standard',
          ),
        ),
      );
      if (response == null || !context.mounted) {
        return;
      }
      await _openPlayer(context, response);
      return;
    }

    await _openPlayer(context, response);
  }

  static Future<void> _openPlayer(
    BuildContext context,
    MindCoachV2GenerateResponse response,
  ) async {
    final pillar = response.session.pillar;
    final accent = MindCoachV2Visuals.accentForPillar(pillar);
    setFoCoCoNavBarBackgroundOverride(
      MindCoachV2Visuals.shellBackgroundForPillar(pillar),
    );
    setFoCoCoNavSelectedColorOverride('mind_coach', accent);

    final shellBg = MindCoachV2Visuals.shellBackgroundForPillar(pillar);
    await Navigator.of(context, rootNavigator: true)
        .push<MindCoachV2PlayerResult>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: shellBg,
        pageBuilder: (_, __, ___) => MindCoachSessionPlayerV2Widget(
          generateResponse: response,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }
}
