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
          return const Center(
            child: Text('No saved MindCoach v2 sessions yet.'),
          );
        }

        return StreamBuilder<Set<String>>(
          stream: repository.streamFavoriteSessionIds(),
          builder: (context, favoritesSnapshot) {
            final favorites = favoritesSnapshot.data ?? const <String>{};

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isFavorite = favorites.contains(session.sessionId);
                return ListTile(
                  title: Text(session.routineType),
                  subtitle: Text(
                    '${session.contextMode.wireValue.replaceAll('_', ' ')} • ${session.deliveryLength}',
                  ),
                  leading: Icon(
                    isFavorite ? Icons.star : Icons.history,
                    color: isFavorite ? Colors.amber : null,
                  ),
                  trailing: IconButton(
                    onPressed: () => onRepeat(session),
                    icon: const Icon(Icons.play_arrow_rounded),
                    tooltip: 'Repeat',
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
