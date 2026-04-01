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

  Stream<List<MindCoachV2Favorite>> streamFavorites({
    required String userId,
    MindCoachV2Pillar? pillar,
  }) {
    return _firestore
        .collection('mindcoach_favorites')
        .where('user_id', isEqualTo: userId)
        .orderBy('saved_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final favorites = snapshot.docs
          .map((doc) => MindCoachV2Favorite.fromFirestore(doc.id, doc.data()))
          .where((favorite) => pillar == null || favorite.pillar == pillar)
          .toList(growable: false);
      return favorites;
    });
  }

  Future<List<MindCoachV2Favorite>> fetchFavorites({
    required String userId,
    MindCoachV2Pillar? pillar,
  }) async {
    final snapshot = await _firestore
        .collection('mindcoach_favorites')
        .where('user_id', isEqualTo: userId)
        .orderBy('saved_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MindCoachV2Favorite.fromFirestore(doc.id, doc.data()))
        .where((favorite) => pillar == null || favorite.pillar == pillar)
        .toList(growable: false);
  }

  Future<String> upsertFavorite({
    required String userId,
    required MindCoachV2Session session,
    String? replaceFavoriteId,
    int maxPerPillar = 5,
  }) async {
    final favoritesRef = _firestore.collection('mindcoach_favorites');
    final existing = await fetchFavorites(
      userId: userId,
      pillar: session.pillar,
    );

    final matchingSession = existing
        .where((favorite) => favorite.sessionKey == session.sessionKey)
        .toList(growable: false);
    final targetId = matchingSession.isNotEmpty
        ? matchingSession.first.favoriteId
        : replaceFavoriteId;

    if (matchingSession.isEmpty &&
        replaceFavoriteId == null &&
        existing.length >= maxPerPillar) {
      throw StateError('favorite_replacement_required');
    }

    final targetRef =
        targetId == null ? favoritesRef.doc() : favoritesRef.doc(targetId);
    final payload = <String, dynamic>{
      'user_id': userId,
      'pillar': session.pillar.wireValue,
      'context_mode': session.contextMode.wireValue,
      'session_id': session.sessionId,
      'session_key': session.sessionKey,
      'session_name': session.sessionName,
      'session_descriptor': session.sessionDescriptor,
      'duration_sec': session.durationSec,
      'template_id': session.templateId,
      'session_payload': <String, dynamic>{
        ...session.toMap(),
        'session_id': session.sessionId,
      },
      'saved_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await targetRef.set(
      {
        ...payload,
        'created_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return targetRef.id;
  }
}
