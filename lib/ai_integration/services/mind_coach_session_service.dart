import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/ai_integration/models/mind_coach_models.dart';

/// Service for managing MindCoach sessions in Firestore
class MindCoachSessionService {
  static MindCoachSessionService? _instance;
  static MindCoachSessionService get instance {
    _instance ??= MindCoachSessionService._();
    return _instance!;
  }

  MindCoachSessionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new session in Firestore
  Future<String> createSession(MindCoachSession session) async {
    try {
      if (!session.validate()) {
        throw Exception('Invalid session data');
      }

      final sessionId = session.sessionId.isEmpty ? _uuid.v4() : session.sessionId;
      final sessionData = session.toFirestoreMap();
      sessionData['sessionId'] = sessionId;

      await _firestore
          .collection('mindcoach_sessions')
          .doc(sessionId)
          .set(sessionData);

      return sessionId;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  /// Get user sessions with pagination
  Future<List<MindCoachSession>> getUserSessions({
    required String userId,
    int limit = 20,
    String? lastSessionId,
    String? sessionType,
  }) async {
    try {
      Query query = _firestore
          .collection('mindcoach_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (sessionType != null) {
        query = query.where('sessionType', isEqualTo: sessionType);
      }

      if (lastSessionId != null) {
        final lastDoc = await _firestore
            .collection('mindcoach_sessions')
            .doc(lastSessionId)
            .get();

        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['sessionType'] == 'breathing') {
          return BreathingSession.fromFirestore(data, doc.id);
        }
        return MindCoachSession.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user sessions: $e');
    }
  }

  /// Get session by ID
  Future<MindCoachSession?> getSessionById(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('mindcoach_sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['sessionType'] == 'breathing') {
        return BreathingSession.fromFirestore(data, doc.id);
      }
      return MindCoachSession.fromFirestore(data, doc.id);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  /// Update session
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedTime'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('mindcoach_sessions')
          .doc(sessionId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  /// Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore
          .collection('mindcoach_sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  /// Calculate success signals based on session data
  Map<String, bool> calculateSuccessSignals({
    required int mindsetBefore,
    int? mindsetAfter,
    required bool sessionCompleted,
    Map<String, dynamic>? additionalSignals,
  }) {
    final signals = <String, bool>{
      'session_completed': sessionCompleted,
      'mindset_improved': false,
    };

    if (mindsetAfter != null) {
      signals['mindset_improved'] = mindsetAfter > mindsetBefore;
      signals['mindset_maintained'] = mindsetAfter == mindsetBefore;
      signals['mindset_declined'] = mindsetAfter < mindsetBefore;
    }

    if (additionalSignals != null) {
      additionalSignals.forEach((key, value) {
        if (value is bool) {
          signals[key] = value;
        }
      });
    }

    return signals;
  }

  /// Stream user sessions for real-time updates
  Stream<List<MindCoachSession>> streamUserSessions({
    required String userId,
    int limit = 20,
    String? sessionType,
  }) {
    Query query = _firestore
        .collection('mindcoach_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (sessionType != null) {
      query = query.where('sessionType', isEqualTo: sessionType);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['sessionType'] == 'breathing') {
          return BreathingSession.fromFirestore(data, doc.id);
        }
        return MindCoachSession.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Get session count for user
  Future<int> getSessionCount(String userId, {String? sessionType}) async {
    try {
      Query query = _firestore
          .collection('mindcoach_sessions')
          .where('userId', isEqualTo: userId);

      if (sessionType != null) {
        query = query.where('sessionType', isEqualTo: sessionType);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get next incomplete session for user (session without mindsetAfter)
  Future<MindCoachSession?> getNextIncompleteSession(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('mindcoach_sessions')
          .where('userId', isEqualTo: userId)
          .where('mindsetAfter', isNull: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      
      if (data['sessionType'] == 'breathing') {
        return BreathingSession.fromFirestore(data, doc.id);
      }
      return MindCoachSession.fromFirestore(data, doc.id);
    } catch (e) {
      // If query fails (e.g., missing index), try without mindsetAfter filter
      try {
        final snapshot = await _firestore
            .collection('mindcoach_sessions')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          // Check if mindsetAfter is null or not set
          if (data['mindsetAfter'] == null) {
            if (data['sessionType'] == 'breathing') {
              return BreathingSession.fromFirestore(data, doc.id);
            }
            return MindCoachSession.fromFirestore(data, doc.id);
          }
        }
        return null;
      } catch (e2) {
        return null;
      }
    }
  }
}
