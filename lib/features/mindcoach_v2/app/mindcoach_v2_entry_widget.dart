import 'package:flutter/material.dart';

import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/config/mindcoach_v2_flags.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/builder/mindcoach_builder_v2_widget.dart';
import '/features/mindcoach_v2/presentation/history/mindcoach_history_v2_widget.dart';
import '/features/mindcoach_v2/presentation/home/mindcoach_home_v2_widget.dart';
import '/features/mindcoach_v2/presentation/player/mindcoach_session_player_v2_widget.dart';
import '/features/mindcoach_v2/presentation/results/mindcoach_results_v2_widget.dart';
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
  final MindCoachV2Repository _repository = MindCoachV2Repository.instance;
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex.clamp(0, 2);
  }

  Future<void> _runGenerationRequest(MindCoachV2GenerateRequest request) async {
    try {
      final response = await _repository.generateSession(request);
      if (!mounted) {
        return;
      }
      await _openPlayer(response);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate session: $e')),
      );
    }
  }

  Future<void> _resume(MindCoachV2ResumePayload payload) async {
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
    return _runGenerationRequest(
      MindCoachV2GenerateRequest(
        contextMode: session.contextMode,
        entrySource: 'history_repeat',
        preferredDeliveryLength: session.deliveryLength,
      ),
    );
  }

  Future<void> _openPlayer(MindCoachV2GenerateResponse response) async {
    final playerResult =
        await Navigator.of(context).push<MindCoachV2PlayerResult>(
      MaterialPageRoute(
        builder: (_) => MindCoachSessionPlayerV2Widget(
          generateResponse: response,
        ),
      ),
    );

    if (!mounted || playerResult == null) {
      return;
    }

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
              setState(() {
                _tabIndex = 2;
              });
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
          setState(() {
            _tabIndex = 1;
          });
        },
        onOpenHistory: () {
          setState(() {
            _tabIndex = 2;
          });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindCoach'),
        actions: [
          if (MindCoachV2Flags.allowLegacyRoute)
            IconButton(
              tooltip: 'Legacy MindCoach',
              icon: const Icon(Icons.history_toggle_off_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MindCoachWidget(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTopTabSelector(),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: EnhancedFoCoCoNavBar(
        currentRoute: 'mind_coach',
        onTap: (route) => context.goNamed(route),
        currentUser: null,
      ),
    );
  }

  Widget _buildTopTabSelector() {
    final tabs = <({String label, IconData icon})>[
      (label: 'Home', icon: Icons.home_outlined),
      (label: 'Builder', icon: Icons.tune_outlined),
      (label: 'History', icon: Icons.library_books_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = _tabIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: ChoiceChip(
                selected: selected,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon, size: 16),
                    const SizedBox(width: 6),
                    Text(tab.label),
                  ],
                ),
                onSelected: (_) {
                  setState(() {
                    _tabIndex = index;
                  });
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
