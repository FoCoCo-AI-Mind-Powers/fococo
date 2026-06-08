import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/config/mindcoach_v2_flags.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/home/mindcoach_home_v2_widget.dart';
import '/features/mindcoach_v2/presentation/player/mindcoach_session_player_v2_widget.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';
import '/features/mindcoach_v2/services/mindcoach_replay_cache.dart';
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
    try {
      final response = await _repository.generateSession(request);
      if (!mounted) {
        return;
      }
      _logger.log(_tag, 'generation succeeded, opening player', {
        'sessionId': response.sessionId,
        'uiMode': response.uiMode.wireValue,
      });
      await _openPlayer(response);
    } catch (e, s) {
      _logger.error(_tag, '_runGenerationRequest failed', null, e, s);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to generate session: $e')),
        );
      } else {
        debugPrint('Failed to generate session (no ScaffoldMessenger): $e');
      }
    }
  }

  Future<void> _resume(MindCoachV2ResumePayload payload) async {
    _logger.log(_tag, '_resume', {
      'sessionId': payload.session.sessionId,
      'runId': payload.run.runId,
      'contextMode': payload.session.contextMode.wireValue,
    });

    final uiMode =
        payload.session.contextMode == MindCoachV2ContextMode.duringRound
            ? MindCoachV2UiMode.liveMinimal
            : MindCoachV2UiMode.guidedExtended;

    final response = MindCoachV2GenerateResponse(
      sessionId: payload.session.sessionId,
      contextMode: payload.session.contextMode,
      uiMode: uiMode,
      session: payload.session,
      runId: payload.run.runId,
    );

    await _openPlayer(response);
  }

  Future<void> _openPlayer(MindCoachV2GenerateResponse response) async {
    _logger.log(_tag, '_openPlayer', {
      'sessionId': response.sessionId,
      'uiMode': response.uiMode.wireValue,
      'templateId': response.session.templateId,
    });
    final playerResult =
        await Navigator.of(context).push<MindCoachV2PlayerResult>(
      MaterialPageRoute(
        builder: (_) => MindCoachSessionPlayerV2Widget(
          generateResponse: response,
        ),
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
        await Navigator.of(context).push<MindCoachV2PlayerResult>(
          MaterialPageRoute(
            builder: (_) => MindCoachSessionPlayerV2Widget(
              generateResponse: cached,
            ),
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
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        return FoCoCoAdaptiveScaffold(
          backgroundColor: MindCoachV2Visuals.shellBackgroundForPillar(null),
          currentRoute: 'mind_coach',
          onTap: (route) => context.goNamed(route),
          showBottomNav: false,
          appBarForegroundColor: Colors.white,
          showAppBarGlowDivider: false,
          // Always mount the drawer so the auto-injected hamburger is
          // reachable even before the user record stream resolves.
          drawer: null,
          body: isVisible
              ? MindCoachHomeV2Widget(
                  repository: _repository,
                  onGenerateRequested: _runGenerationRequest,
                  onResumeRequested: _resume,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
