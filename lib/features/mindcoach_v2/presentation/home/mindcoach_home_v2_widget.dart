import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_context_resolver.dart';

class MindCoachHomeV2Widget extends StatefulWidget {
  const MindCoachHomeV2Widget({
    super.key,
    required this.repository,
    required this.onGenerateRequested,
    required this.onResumeRequested,
    required this.onOpenBuilder,
    required this.onOpenHistory,
  });

  final MindCoachV2Repository repository;
  final Future<void> Function(MindCoachV2GenerateRequest request)
      onGenerateRequested;
  final Future<void> Function(MindCoachV2ResumePayload payload)
      onResumeRequested;
  final VoidCallback onOpenBuilder;
  final VoidCallback onOpenHistory;

  @override
  State<MindCoachHomeV2Widget> createState() => _MindCoachHomeV2WidgetState();
}

class _MindCoachHomeV2WidgetState extends State<MindCoachHomeV2Widget> {
  final MindCoachV2ContextResolver _contextResolver =
      MindCoachV2ContextResolver();

  MindCoachV2ContextMode _contextMode = MindCoachV2ContextMode.offDay;
  bool _loadingContext = true;
  bool _starting = false;
  MindCoachV2ResumePayload? _resumePayload;

  @override
  void initState() {
    super.initState();
    _loadContextAndResume();
  }

  Future<void> _loadContextAndResume() async {
    setState(() {
      _loadingContext = true;
    });

    final inferred =
        await _contextResolver.inferContextMode(currentUserUidOrEmpty());
    final resume = await widget.repository.getResumePayload();

    if (!mounted) {
      return;
    }

    setState(() {
      _contextMode = inferred;
      _resumePayload = resume;
      _loadingContext = false;
    });
  }

  String currentUserUidOrEmpty() {
    try {
      return currentUserUid;
    } catch (_) {
      return '';
    }
  }

  String _primaryActionTitle() {
    switch (_contextMode) {
      case MindCoachV2ContextMode.beforeRound:
        return 'Calm First Tee';
      case MindCoachV2ContextMode.duringRound:
        return 'Quick Reset (30s)';
      case MindCoachV2ContextMode.afterRound:
        return 'Round Reflection';
      case MindCoachV2ContextMode.offDay:
      case MindCoachV2ContextMode.auto:
        return 'Build Today\'s MindCoach';
    }
  }

  Future<void> _start({
    required MindCoachV2ContextMode contextMode,
    required String entrySource,
  }) async {
    if (_starting) {
      return;
    }

    setState(() {
      _starting = true;
    });

    try {
      await widget.onGenerateRequested(
        MindCoachV2GenerateRequest(
          contextMode: contextMode,
          entrySource: entrySource,
          preferredDeliveryLength:
              contextMode == MindCoachV2ContextMode.duringRound
                  ? 'micro'
                  : 'standard',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
        });
      }
      _loadContextAndResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadContextAndResume,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'MindCoach',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Reset • Focus • Control',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_loadingContext)
            const LinearProgressIndicator()
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primaryActionTitle(),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suggested for ${_contextMode.wireValue.replaceAll('_', ' ')}',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _starting
                            ? null
                            : () => _start(
                                  contextMode: _contextMode,
                                  entrySource: 'home_primary',
                                ),
                        child: _starting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Start Session'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Before Round'),
                onPressed: () => _start(
                  contextMode: MindCoachV2ContextMode.beforeRound,
                  entrySource: 'home_chip',
                ),
              ),
              ActionChip(
                label: const Text('During Round'),
                onPressed: () => _start(
                  contextMode: MindCoachV2ContextMode.duringRound,
                  entrySource: 'home_chip',
                ),
              ),
              ActionChip(
                label: const Text('After Round'),
                onPressed: () => _start(
                  contextMode: MindCoachV2ContextMode.afterRound,
                  entrySource: 'home_chip',
                ),
              ),
            ],
          ),
          if (_resumePayload != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.shade50,
              child: ListTile(
                title: const Text('Resume last session'),
                subtitle: Text(_resumePayload!.session.routineType),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => widget.onResumeRequested(_resumePayload!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onOpenBuilder,
                  child: const Text('Custom Builder'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onOpenHistory,
                  child: const Text('History'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Recent sessions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<MindCoachV2Session>>(
            stream: widget.repository.streamHistory(limit: 5),
            builder: (context, snapshot) {
              final sessions = snapshot.data ?? const <MindCoachV2Session>[];
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No MindCoach v2 sessions yet.'),
                );
              }

              return Column(
                children: sessions
                    .map(
                      (session) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(session.routineType),
                        subtitle: Text(
                          '${session.deliveryLength} • ${session.validatorStatus}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
