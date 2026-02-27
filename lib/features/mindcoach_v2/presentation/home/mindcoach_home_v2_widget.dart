import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '/adaptive_ui/adaptive_ui.dart';
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

  String _heroDescription() {
    switch (_contextMode) {
      case MindCoachV2ContextMode.beforeRound:
        return 'Prime your attention and settle into one clear plan before the opening shot.';
      case MindCoachV2ContextMode.duringRound:
        return 'Short in-round coaching to reset breathing, focus, and next-shot commitment.';
      case MindCoachV2ContextMode.afterRound:
        return 'Capture one win and one adjustment so tomorrow starts sharper.';
      case MindCoachV2ContextMode.offDay:
      case MindCoachV2ContextMode.auto:
        return 'Train your mental routines with guided sessions tailored to your moment.';
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

    return Material(
      type: MaterialType.transparency,
      child: RefreshIndicator(
        onRefresh: _loadContextAndResume,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _buildHeroCard(theme),
            const SizedBox(height: 14),
            _buildQuickModeCards(theme),
            if (_resumePayload != null) ...[
              const SizedBox(height: 14),
              _buildResumeCard(theme),
            ],
            const SizedBox(height: 14),
            _buildStudioActions(theme),
            const SizedBox(height: 18),
            Text('Recent Sessions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildRecentSessions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final baseColor = _contextMode == MindCoachV2ContextMode.duringRound
        ? const Color(0xFF0A6BB8)
        : _contextMode == MindCoachV2ContextMode.afterRound
            ? const Color(0xFF166B4A)
            : const Color(0xFF1A2F55);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            Color.alphaBlend(baseColor.withValues(alpha: 0.35), Colors.black),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MindCoach Studio',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _primaryActionTitle(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _heroDescription(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingContext)
            const LinearProgressIndicator(minHeight: 2)
          else
            SizedBox(
              width: double.infinity,
              child: FoCoCoAdaptiveButton(
                onPressed: _starting
                    ? null
                    : () => _start(
                          contextMode: _contextMode,
                          entrySource: 'home_primary',
                        ),
                label: _starting ? 'Starting...' : 'Start Session',
                enabled: !_starting,
                color: colorScheme.secondary,
                textColor: colorScheme.onSecondary,
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildHeroChip(
                  label:
                      'Mode: ${_contextMode.wireValue.replaceAll('_', ' ')}'),
              _buildHeroChip(label: 'Runtime Validator Active'),
              _buildHeroChip(label: 'Cartesia Voice Ready'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickModeCards(ThemeData theme) {
    final items = <({
      String title,
      IconData icon,
      MindCoachV2ContextMode mode,
      String subtitle,
    })>[
      (
        title: 'Before Round',
        icon: FluentIcons.flag_24_regular,
        mode: MindCoachV2ContextMode.beforeRound,
        subtitle: 'Settle and commit',
      ),
      (
        title: 'During Round',
        icon: FluentIcons.target_24_regular,
        mode: MindCoachV2ContextMode.duringRound,
        subtitle: 'Fast pressure reset',
      ),
      (
        title: 'After Round',
        icon: FluentIcons.checkmark_circle_24_regular,
        mode: MindCoachV2ContextMode.afterRound,
        subtitle: 'Review and adapt',
      ),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item.title == 'After Round' ? 0 : 8,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _starting
                      ? null
                      : () => _start(
                            contextMode: item.mode,
                            entrySource: 'home_chip',
                          ),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildResumeCard(ThemeData theme) {
    final payload = _resumePayload!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        title: const Text('Resume Last Session'),
        subtitle: Text(payload.session.routineType),
        trailing: const Icon(FluentIcons.play_circle_24_filled),
        onTap: () => widget.onResumeRequested(payload),
      ),
    );
  }

  Widget _buildStudioActions(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.toolbox_20_regular,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Build & Review',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StudioActionCard(
                  icon: FluentIcons.wand_24_regular,
                  title: 'Custom Builder',
                  subtitle: 'Create your session',
                  gradientColors: const [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                  onTap: widget.onOpenBuilder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StudioActionCard(
                  icon: FluentIcons.history_24_regular,
                  title: 'History',
                  subtitle: 'Past sessions',
                  gradientColors: const [
                    Color(0xFF0EA5E9),
                    Color(0xFF06B6D4),
                  ],
                  onTap: widget.onOpenHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(ThemeData theme) {
    return StreamBuilder<List<MindCoachV2Session>>(
      stream: widget.repository.streamHistory(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Could not load history: ${snapshot.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          );
        }

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
                (session) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      FluentIcons.play_circle_24_regular,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(session.routineType),
                    subtitle: Text(
                      '${session.deliveryLength} • ${session.validatorStatus}',
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _StudioActionCard extends StatelessWidget {
  const _StudioActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors[0].withValues(alpha: 0.15),
                gradientColors[1].withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradientColors[0].withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
