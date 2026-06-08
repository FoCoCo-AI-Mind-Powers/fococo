import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/ai_integration/widgets/navbar_widget.dart'
    show
        FoCoCoAdaptiveScaffold,
        setFoCoCoNavBarBackgroundOverride,
        setFoCoCoNavSelectedColorOverride;
import '/features/mindcoach_v2/config/mindcoach_v2_flags.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/home/mindcoach_home_v2_widget.dart';
import '/features/mindcoach_v2/presentation/player/mindcoach_session_player_v2_widget.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_session_prep_overlay.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';
import '/features/mindcoach_v2/services/mindcoach_replay_cache.dart';
import '/features/mindcoach_v2/services/mindcoach_session_prefetch.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/coaching_modules/mind_coach_widget.dart';

class MindCoachV2EntryWidget extends StatefulWidget {
  const MindCoachV2EntryWidget({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<MindCoachV2EntryWidget> createState() => _MindCoachV2EntryWidgetState();
}

class _MindCoachV2EntryWidgetState extends State<MindCoachV2EntryWidget> {
  static const String _tag = 'ENTRY';
  final MindCoachV2Repository _repository = MindCoachV2Repository.instance;
  final MindCoachV2DebugLogger _logger = MindCoachV2DebugLogger.instance;

  Future<void> _runGenerationRequest(MindCoachV2GenerateRequest request) async {
    _logger.log(_tag, '_runGenerationRequest', {
      'contextMode': request.contextMode.wireValue,
      'entrySource': request.entrySource,
      'deliveryLength': request.preferredDeliveryLength,
    });

    final accent = request.pillar == null
        ? MindCoachV2Visuals.homeNavAccent
        : MindCoachV2Visuals.accentForPillar(request.pillar!);

    final response = await runMindCoachSessionPrep<MindCoachV2GenerateResponse>(
      context: context,
      accentColor: accent,
      sessionTitle: request.sessionName,
      work: () async {
        final prefetched = MindCoachSessionPrefetch.take();
        if (prefetched != null) {
          return prefetched;
        }
        return _repository.generateSession(request);
      },
    );

    if (!mounted || response == null) {
      return;
    }

    final monthlyCount = response.monthlySessionCount;
    if (monthlyCount != null && monthlyCount >= 80) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'You\'ve had a strong month of MindCoach sessions. '
            'Take a breath when you need one.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }

    try {
      _logger.log(_tag, 'generation succeeded, opening player', {
        'sessionId': response.sessionId,
        'uiMode': response.uiMode.wireValue,
      });
      await _openPlayer(response);
    } catch (e, s) {
      _logger.error(_tag, '_openPlayer after generation failed', null, e, s);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Failed to open session: $e')),
      );
    }
  }

  Future<void> _openPlayer(MindCoachV2GenerateResponse response) async {
    _logger.log(_tag, '_openPlayer', {
      'sessionId': response.sessionId,
      'uiMode': response.uiMode.wireValue,
      'templateId': response.session.templateId,
    });
    final pillar = response.session.pillar;
    final accent = MindCoachV2Visuals.accentForPillar(pillar);
    setFoCoCoNavBarBackgroundOverride(
      MindCoachV2Visuals.shellBackgroundForPillar(pillar),
    );
    setFoCoCoNavSelectedColorOverride('mind_coach', accent);

    final shellBg = MindCoachV2Visuals.shellBackgroundForPillar(pillar);
    final playerResult =
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

    if (!mounted || playerResult == null) {
      _logger.log(_tag, 'player returned null or widget unmounted');
      return;
    }

    _logger.log(_tag, 'player result received', {
      'completed': playerResult.completed.toString(),
      'status': playerResult.completionStatus.wireValue,
      'favoriteSaved': playerResult.favoriteSaved.toString(),
      'runId': playerResult.runId ?? 'null',
      'nextAction': playerResult.nextAction.name,
    });

    if (playerResult.nextAction == MindCoachV2PlayerNextAction.playAgain) {
      final cached = await MindCoachReplayCache.load(response.sessionId);
      if (cached != null && mounted) {
        final replayPillar = cached.session.pillar;
        final replayAccent =
            MindCoachV2Visuals.accentForPillar(replayPillar);
        setFoCoCoNavBarBackgroundOverride(
          MindCoachV2Visuals.shellBackgroundForPillar(replayPillar),
        );
        setFoCoCoNavSelectedColorOverride('mind_coach', replayAccent);
        await Navigator.of(context, rootNavigator: true)
            .push<MindCoachV2PlayerResult>(
          PageRouteBuilder(
            opaque: true,
            barrierColor:
                MindCoachV2Visuals.shellBackgroundForPillar(replayPillar),
            pageBuilder: (_, __, ___) => MindCoachSessionPlayerV2Widget(
              generateResponse: cached,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 220),
          ),
        );
        return;
      }
      final delivery = response.session.deliveryLength;
      const valid = {'auto', 'micro', 'standard', 'deep'};
      await _runGenerationRequest(
        MindCoachV2GenerateRequest(
          contextMode: response.session.contextMode,
          entrySource: 'play_again',
          pillar: response.session.pillar,
          sessionKey: response.session.sessionKey,
          sessionName: response.session.sessionName,
          sessionDescriptor: response.session.sessionDescriptor,
          targetDurationSec: response.session.durationSec,
          preferredDeliveryLength:
              valid.contains(delivery) ? delivery : 'standard',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MindCoachV2Flags.mindCoachV2Enabled) {
      return const MindCoachWidget();
    }
    final isVisible =
        GoRouterState.of(context).uri.toString().contains(MindCoachWidget.routePath);

    return StreamBuilder<UserRecord>(
      stream: isVisible && loggedIn
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/$currentUserUid'))
          : null,
      builder: (context, _) {
        return FoCoCoAdaptiveScaffold(
          backgroundColor: MindCoachV2Visuals.shellBackgroundForPillar(null),
          currentRoute: 'mind_coach',
          onTap: (route) => context.goNamed(route),
          showBottomNav: false,
          enableVoiceButton: false,
          appBarForegroundColor: Colors.white,
          showAppBarGlowDivider: false,
          // Always mount the drawer so the auto-injected hamburger is
          // reachable even before the user record stream resolves.
          drawer: null,
          body: isVisible
              ? MindCoachHomeV2Widget(
                  repository: _repository,
                  onGenerateRequested: _runGenerationRequest,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
