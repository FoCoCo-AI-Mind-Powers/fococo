import 'package:flutter/material.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/config/mindcoach_v2_flags.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/builder/mindcoach_builder_v2_widget.dart';
import '/features/mindcoach_v2/presentation/history/mindcoach_history_v2_widget.dart';
import '/features/mindcoach_v2/presentation/home/mindcoach_home_v2_widget.dart';
import '/features/mindcoach_v2/presentation/player/mindcoach_session_player_v2_widget.dart';
import '/features/mindcoach_v2/presentation/results/mindcoach_results_v2_widget.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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

class _MindCoachV2EntryWidgetState extends State<MindCoachV2EntryWidget>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'ENTRY';
  final MindCoachV2Repository _repository = MindCoachV2Repository.instance;
  final MindCoachV2DebugLogger _logger = MindCoachV2DebugLogger.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate session: $e')),
      );
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

  Future<void> _repeatSession(MindCoachV2Session session) {
    _logger.log(_tag, '_repeatSession', {
      'originalSessionId': session.sessionId,
      'templateId': session.templateId,
    });
    return _runGenerationRequest(
      MindCoachV2GenerateRequest(
        contextMode: session.contextMode,
        entrySource: 'history_repeat',
        preferredDeliveryLength: session.deliveryLength,
      ),
    );
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
    });

    if (response.uiMode == MindCoachV2UiMode.guidedExtended &&
        playerResult.completed &&
        playerResult.completionStatus ==
            MindCoachV2CompletionStatus.completed) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MindCoachResultsV2Widget(
            session: response.session,
            playerResult: playerResult,
            onRepeat: () {
              Navigator.of(context).pop();
              _repeatSession(response.session);
            },
            onOpenHistory: () {
              Navigator.of(context).pop();
              _setTabIndex(2);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MindCoachV2Flags.mindCoachV2Enabled) {
      return const MindCoachWidget();
    }

    final pages = <Widget>[
      MindCoachHomeV2Widget(
        repository: _repository,
        onGenerateRequested: _runGenerationRequest,
        onResumeRequested: _resume,
        onOpenBuilder: () {
          _setTabIndex(1);
        },
        onOpenHistory: () {
          _setTabIndex(2);
        },
      ),
      MindCoachBuilderV2Widget(
        onGenerateRequested: _runGenerationRequest,
      ),
      MindCoachHistoryV2Widget(
        repository: _repository,
        onRepeat: _repeatSession,
      ),
    ];

    return StreamBuilder<UserRecord>(
      stream: loggedIn
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/$currentUserUid'))
          : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        return FoCoCoAdaptiveScaffold(
          title: 'MindCoach',
          currentRoute: 'mind_coach',
          onTap: (route) => context.goNamed(route),
          drawer: user != null
              ? FoCoCoDrawer(
                  currentUser: user,
                  currentRoute: 'mind_coach',
                  onNavigate: (route) => context.goNamed(route),
                )
              : null,
          body: Column(
            children: [
              _buildTopTabSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: pages,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabSelector() {
    return Builder(
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return SafeArea(
          top: false,
          bottom: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.secondaryBackground.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.alternate.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                height: 42,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Home'),
                    Tab(text: 'Builder'),
                    Tab(text: 'History'),
                  ],
                  indicator: MaterialIndicator(
                    height: 4,
                    topLeftRadius: 8,
                    topRightRadius: 8,
                    bottomLeftRadius: 0,
                    bottomRightRadius: 0,
                    color: theme.primary,
                    horizontalPadding: 16,
                    tabPosition: TabPosition.bottom,
                  ),
                  labelColor: theme.primaryText,
                  unselectedLabelColor: theme.secondaryText,
                  labelStyle: theme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: theme.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setTabIndex(int index) {
    _tabController.animateTo(index);
  }
}
