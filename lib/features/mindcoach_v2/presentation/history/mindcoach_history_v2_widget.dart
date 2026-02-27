import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachHistoryV2Widget extends StatelessWidget {
  const MindCoachHistoryV2Widget({
    super.key,
    required this.repository,
    required this.onRepeat,
  });

  final MindCoachV2Repository repository;
  final Future<void> Function(MindCoachV2Session session) onRepeat;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MindCoachV2Session>>(
      stream: repository.streamHistory(limit: 50),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <MindCoachV2Session>[];

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FluentIcons.history_24_regular,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No saved MindCoach v2 sessions yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<Set<String>>(
          stream: repository.streamFavoriteSessionIds(),
          builder: (context, favoritesSnapshot) {
            final favorites = favoritesSnapshot.data ?? const <String>{};

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isFavorite = favorites.contains(session.sessionId);
                return _SessionCard(
                  session: session,
                  isFavorite: isFavorite,
                  onRepeat: () => onRepeat(session),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isFavorite,
    required this.onRepeat,
  });

  final MindCoachV2Session session;
  final bool isFavorite;
  final VoidCallback onRepeat;

  IconData _contextIcon() {
    switch (session.contextMode) {
      case MindCoachV2ContextMode.beforeRound:
        return FluentIcons.flag_24_regular;
      case MindCoachV2ContextMode.duringRound:
        return FluentIcons.target_24_regular;
      case MindCoachV2ContextMode.afterRound:
        return FluentIcons.checkmark_circle_24_regular;
      case MindCoachV2ContextMode.offDay:
        return FluentIcons.brain_circuit_24_regular;
      case MindCoachV2ContextMode.auto:
        return FluentIcons.sparkle_24_regular;
    }
  }

  Color _contextAccentColor(ThemeData theme) {
    switch (session.contextMode) {
      case MindCoachV2ContextMode.beforeRound:
        return const Color(0xFF2196F3);
      case MindCoachV2ContextMode.duringRound:
        return const Color(0xFF0A6BB8);
      case MindCoachV2ContextMode.afterRound:
        return const Color(0xFF166B4A);
      case MindCoachV2ContextMode.offDay:
        return const Color(0xFF7C4DFF);
      case MindCoachV2ContextMode.auto:
        return theme.colorScheme.primary;
    }
  }

  String _formatContextMode() {
    return session.contextMode.wireValue
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  String _formatDeliveryLength() {
    switch (session.deliveryLength.toLowerCase()) {
      case 'micro':
        return '30s';
      case 'standard':
        return '3-5 min';
      case 'extended':
        return '8-12 min';
      default:
        return session.deliveryLength;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = _contextAccentColor(theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFavorite
              ? Colors.amber.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.12),
          width: isFavorite ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onRepeat,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _contextIcon(),
                        size: 22,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.routineType,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _InfoChip(
                                icon: FluentIcons.clock_12_regular,
                                label: _formatDeliveryLength(),
                              ),
                              const SizedBox(width: 8),
                              _InfoChip(
                                icon: FluentIcons.location_12_regular,
                                label: _formatContextMode(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isFavorite)
                      Icon(
                        FluentIcons.star_24_filled,
                        color: Colors.amber,
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (session.validatorStatus.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: session.validatorStatus == 'valid'
                              ? const Color(0xFF166B4A).withValues(alpha: 0.12)
                              : colorScheme.errorContainer
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              session.validatorStatus == 'valid'
                                  ? FluentIcons.checkmark_circle_12_filled
                                  : FluentIcons.warning_12_filled,
                              size: 14,
                              color: session.validatorStatus == 'valid'
                                  ? const Color(0xFF166B4A)
                                  : colorScheme.error,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              session.validatorStatus == 'valid'
                                  ? 'Validated'
                                  : session.validatorStatus,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: session.validatorStatus == 'valid'
                                    ? const Color(0xFF166B4A)
                                    : colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    FilledButton.icon(
                      onPressed: onRepeat,
                      icon: const Icon(FluentIcons.play_20_filled, size: 18),
                      label: const Text('Play'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
