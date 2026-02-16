import 'package:cloud_firestore/cloud_firestore.dart';

import '/features/mindcoach_v2/domain/contracts/mindcoach_v2_contracts.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachV2FirestoreClient {
  MindCoachV2FirestoreClient({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MindCoachV2Session>> streamHistory({
    required String userId,
    int limit = 30,
  }) {
    final query = _firestore
        .collection('mindcoach_sessions')
        .where('schema_version', isEqualTo: kMindCoachV2SchemaVersion)
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MindCoachV2Session.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Future<MindCoachV2Session?> getSessionById(String sessionId) async {
    final doc =
        await _firestore.collection('mindcoach_sessions').doc(sessionId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return MindCoachV2Session.fromFirestore(doc.id, doc.data()!);
  }

  Future<MindCoachV2SessionRun?> getLatestInProgressRun(String userId) async {
    try {
      final query = await _firestore
          .collection('mindcoach_session_runs')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'in_progress')
          .orderBy('started_at', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return MindCoachV2SessionRun.fromFirestore(doc.id, doc.data());
    } catch (_) {
      return null;
    }
  }

  Stream<Set<String>> streamFavoriteSessionIds({required String userId}) {
    return _firestore
        .collection('mindcoach_favorites')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final ids = <String>{};
      for (final doc in snapshot.docs) {
        final sessionId = doc.data()['session_id']?.toString();
        if (sessionId != null && sessionId.isNotEmpty) {
          ids.add(sessionId);
        }
      }
      return ids;
    });
  }
}
