import 'package:flutter/material.dart';

import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/player/mindcoach_session_player_v2_widget.dart';

class MindCoachResultsV2Widget extends StatelessWidget {
  const MindCoachResultsV2Widget({
    super.key,
    required this.session,
    required this.playerResult,
    required this.onRepeat,
    required this.onOpenHistory,
  });

  final MindCoachV2Session session;
  final MindCoachV2PlayerResult playerResult;
  final VoidCallback onRepeat;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindCoach Result'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            session.templateId,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            session.routineType,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Validator status: ${session.validatorStatus}'),
                  const SizedBox(height: 8),
                  if (playerResult.helpfulnessRating != null)
                    Text('Helpfulness: ${playerResult.helpfulnessRating}/5'),
                  const SizedBox(height: 8),
                  Text(
                    playerResult.favoriteSaved
                        ? 'Saved to favorites'
                        : 'Not saved to favorites',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Session complete.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRepeat,
              child: const Text('Run Again'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onOpenHistory,
              child: const Text('Open History'),
            ),
          ),
        ],
      ),
    );
  }
}
