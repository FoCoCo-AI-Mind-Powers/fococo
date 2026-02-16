/// Voice Backend Service
/// Handles Firestore logging and session persistence

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/models/voice_session_model.dart';

/// Voice Backend Service for Firestore operations
class VoiceBackendService {
  static final VoiceBackendService _instance = VoiceBackendService._internal();
  factory VoiceBackendService() => _instance;
  VoiceBackendService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save voice session to Firestore
  Future<void> saveVoiceSession(VoiceSession session) async {
    try {
      final user = currentUser;
      if (user?.uid == null) {
        debugPrint('⚠️ VoiceBackendService: No authenticated user');
        return;
      }

      final sessionData = {
        ...session.toJson(),
        'userId': user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('voice_sessions')
          .doc(session.sessionId)
          .set(sessionData, SetOptions(merge: true));

      // Also save individual interactions
      for (final interaction in session.interactions) {
        await _firestore
            .collection('voice_sessions')
            .doc(session.sessionId)
            .collection('interactions')
            .add(interaction.toJson());
      }

      debugPrint('✅ VoiceBackendService: Saved session ${session.sessionId}');
    } catch (e) {
      debugPrint('❌ VoiceBackendService: Error saving session: $e');
      rethrow;
    }
  }

  /// Get location-based context for Gemini
  Future<Map<String, dynamic>> getLocationContext({
    required double latitude,
    required double longitude,
    double radiusMeters = 1000,
  }) async {
    try {
      final user = currentUser;
      if (user?.uid == null) {
        return {};
      }

      // Get nearby round logs
      final nearbyRounds = await _firestore
          .collection('round_logs')
          .where('userId', isEqualTo: user!.uid)
          .where('coordinates',
              isGreaterThan: GeoPoint(latitude - 0.01, longitude - 0.01))
          .where('coordinates',
              isLessThan: GeoPoint(latitude + 0.01, longitude + 0.01))
          .limit(10)
          .get();

      // Get nearby shot logs
      final nearbyShots = await _firestore
          .collection('shot_logs')
          .where('userId', isEqualTo: user.uid)
          .where('coordinates',
              isGreaterThan: GeoPoint(latitude - 0.01, longitude - 0.01))
          .where('coordinates',
              isLessThan: GeoPoint(latitude + 0.01, longitude + 0.01))
          .limit(10)
          .get();

      return {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'nearbyRounds': nearbyRounds.docs.length,
        'nearbyShots': nearbyShots.docs.length,
        'userHistory': {
          'rounds': nearbyRounds.docs.map((doc) => doc.data()).toList(),
          'shots': nearbyShots.docs.map((doc) => doc.data()).toList(),
        },
      };
    } catch (e) {
      debugPrint('❌ VoiceBackendService: Error getting location context: $e');
      return {};
    }
  }

  /// Log voice interaction to Firestore
  Future<void> logVoiceInteraction({
    required String sessionId,
    required VoiceInteraction interaction,
  }) async {
    try {
      final user = currentUser;
      if (user?.uid == null) {
        return;
      }

      await _firestore
          .collection('voice_sessions')
          .doc(sessionId)
          .collection('interactions')
          .add({
        ...interaction.toJson(),
        'userId': user!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ VoiceBackendService: Logged interaction for session $sessionId');
    } catch (e) {
      debugPrint('❌ VoiceBackendService: Error logging interaction: $e');
    }
  }

  /// Fetch historical voice sessions for map display
  Future<List<VoiceSession>> getHistoricalSessions({
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      final user = currentUser;
      if (user?.uid == null) {
        return [];
      }

      var query = _firestore
          .collection('voice_sessions')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('startTime', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('startTime', isGreaterThan: since);
      }

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Fetch interactions separately
        return VoiceSession.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ VoiceBackendService: Error fetching sessions: $e');
      return [];
    }
  }
}