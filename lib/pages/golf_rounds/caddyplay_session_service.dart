import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'caddyplay_models.dart';

class CaddyPlaySessionService {
  CaddyPlaySessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('caddyplay_sessions');

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('caddyplay_logs');

  CollectionReference<Map<String, dynamic>> get _roundLogs =>
      _firestore.collection('round_logs');

  CollectionReference<Map<String, dynamic>> get _golfRounds =>
      _firestore.collection('golf_rounds');

  String get _userId {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User must be authenticated');
    }
    return userId;
  }

  Future<CaddyPlaySession> startSession({
    required CaddyPlayMode mode,
    required String? courseName,
    required String? courseId,
    required String? teeName,
    required int? teeDistance,
    required int holesTotal,
    double? courseRating,
    double? slopeRating,
  }) async {
    if (mode == CaddyPlayMode.play) {
      if ((courseName ?? '').trim().isEmpty || (teeName ?? '').trim().isEmpty) {
        throw Exception(
            'Play mode requires course and tee setup before logging.');
      }
    }

    final sessionRef = _sessions.doc();
    final now = DateTime.now();
    final uid = _userId;
    final gpsStart = await _captureGpsStart();
    final weatherStart = await _captureWeatherStart(gpsStart);

    final roundLogRef = _roundLogs.doc();

    final sessionPayload = <String, dynamic>{
      'userId': uid,
      'mode': mode.name,
      'status': CaddyPlaySessionStatus.active.name,
      'courseName': courseName,
      'courseId': courseId,
      'teeName': teeName,
      'teeDistance': teeDistance,
      'holesTotal': holesTotal,
      'startTime': Timestamp.fromDate(now),
      'currentHole': 1,
      'holesPlayed': 0,
      'elapsedSeconds': 0,
      'gpsStart': gpsStart,
      'weatherStart': weatherStart,
      'lockedContext': true,
      'linkedRoundLogId': roundLogRef.id,
      'linkedGolfRoundId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (courseRating != null) 'courseRating': courseRating,
      if (slopeRating != null) 'slopeRating': slopeRating,
    };

    final holeBatch = _firestore.batch();
    for (var hole = 1; hole <= holesTotal; hole++) {
      holeBatch.set(sessionRef.collection('holes').doc('$hole'), {
        'holeNumber': hole,
        'par': null,
        'distance': null,
        'score': null,
        'isComplete': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await sessionRef.set(sessionPayload);
    await holeBatch.commit();

    await roundLogRef.set({
      'userId': uid,
      'roundId': sessionRef.id,
      'date': Timestamp.fromDate(now),
      'courseName':
          courseName ?? (mode == CaddyPlayMode.practice ? 'Practice' : ''),
      'courseType': mode == CaddyPlayMode.play ? 'play' : 'practice',
      'coordinates': gpsStart != null
          ? GeoPoint(
              (gpsStart['lat'] as num).toDouble(),
              (gpsStart['lng'] as num).toDouble(),
            )
          : null,
      'mindsetFocus': 65,
      'mindsetConfidence': 60,
      'mindsetControl': 62,
      'bestCue': 'Routine First',
      'recoveryHoles': <String>[],
      'overallMindsetEmoji': '😐',
      'technicalSummary': 'Session started',
      'aiRoundSummary': mode == CaddyPlayMode.play
          ? 'Play round capture in progress.'
          : 'Practice capture in progress.',
      'voiceTranscription': '',
      'nlpProcessed': true,
      'isLive': true,
      'mindsetColor': '#FFC107',
      'linkedGolfRoundId': null,
      'createdTime': FieldValue.serverTimestamp(),
      'updatedTime': FieldValue.serverTimestamp(),
    });

    final snap = await sessionRef.get();
    return CaddyPlaySession.fromDoc(snap);
  }

  Future<CaddyPlaySession?> resumeActiveSession(String userId) async {
    final query = await _sessions
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: CaddyPlaySessionStatus.active.name)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return CaddyPlaySession.fromDoc(query.docs.first);
  }

  Future<void> saveLog(CaddyPlayLog log) async {
    await _logs.doc(log.id).set({
      ...log.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _sessions.doc(log.sessionId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await syncRoundLogsCompatibility(log.sessionId);
  }

  Future<void> updateHole({
    required String sessionId,
    required int holeNumber,
    int? par,
    int? distance,
    int? score,
    bool? isComplete,
  }) async {
    await _sessions.doc(sessionId).collection('holes').doc('$holeNumber').set({
      'holeNumber': holeNumber,
      'par': par,
      'distance': distance,
      'score': score,
      'isComplete': isComplete ?? (score != null),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _sessions.doc(sessionId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> advanceHole(String sessionId) async {
    final snap = await _sessions.doc(sessionId).get();
    if (!snap.exists) return false;

    final map = snap.data() ?? <String, dynamic>{};
    final currentHole = (map['currentHole'] as num?)?.toInt() ?? 1;
    final holesTotal = (map['holesTotal'] as num?)?.toInt() ?? 9;
    final nextHole = clampHole(currentHole + 1, holesTotal);
    final holesPlayed = (map['holesPlayed'] as num?)?.toInt() ?? 0;

    await _sessions.doc(sessionId).update({
      'currentHole': nextHole,
      'holesPlayed': mathMin(holesTotal, holesPlayed + 1),
      'elapsedSeconds': _elapsedSeconds(map['startTime']),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return currentHole >= holesTotal;
  }

  Future<void> completePlaySession(String sessionId) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    if (!sessionDoc.exists) return;

    final session = CaddyPlaySession.fromDoc(sessionDoc);

    await upsertGolfRoundSummary(sessionId);

    await _sessions.doc(sessionId).update({
      'status': CaddyPlaySessionStatus.completed.name,
      'holesPlayed': session.holesTotal,
      'elapsedSeconds': _elapsedSeconds(sessionDoc.data()?['startTime']),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
    });

    await syncRoundLogsCompatibility(sessionId, markNotLive: true);
  }

  Future<void> completePracticeSession(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': CaddyPlaySessionStatus.completed.name,
      'elapsedSeconds': _elapsedSeconds(
          (await _sessions.doc(sessionId).get()).data()?['startTime']),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
    });

    await syncRoundLogsCompatibility(sessionId, markNotLive: true);
  }

  Future<void> syncRoundLogsCompatibility(
    String sessionId, {
    bool markNotLive = false,
  }) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    if (!sessionDoc.exists) return;

    final session = CaddyPlaySession.fromDoc(sessionDoc);
    final logsQuery = await _logs
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('capturedAt', descending: false)
        .get();

    final logs = logsQuery.docs
        .map((doc) => CaddyPlayLog.fromDoc(doc))
        .toList(growable: false);

    final aggregate = aggregateMindset(logs);
    final recoveryHoles = recoveryHolesFromLogs(logs);
    final bestCue = bestCueFromLogs(logs);
    final allTranscript = logs
        .where((e) => e.transcription.trim().isNotEmpty)
        .map((e) => e.transcription.trim())
        .join(' | ');

    final targetId = session.linkedRoundLogId ?? session.id;

    await _roundLogs.doc(targetId).set({
      'userId': session.userId,
      'roundId': session.id,
      'date': Timestamp.fromDate(session.startTime),
      'courseName':
          session.courseName ?? (session.isPractice ? 'Practice' : ''),
      'courseType': session.mode.name,
      'mindsetFocus': aggregate.mindsetFocus,
      'mindsetConfidence': aggregate.mindsetConfidence,
      'mindsetControl': aggregate.mindsetControl,
      'bestCue': bestCue,
      'recoveryHoles': recoveryHoles,
      'overallMindsetEmoji': aggregate.overallEmoji,
      'technicalSummary':
          'Captured ${logs.length} moments. Hole ${session.currentHole}/${session.holesTotal}.',
      'aiRoundSummary': session.isPlay
          ? 'Play round capture summary is ready for deeper review in the WebApp.'
          : 'Practice capture summary is ready for deeper review in the WebApp.',
      'voiceTranscription': allTranscript,
      'nlpProcessed': true,
      'isLive': !markNotLive && session.status == CaddyPlaySessionStatus.active,
      'mindsetColor': aggregate.mindsetColor,
      'linkedGolfRoundId': session.linkedGolfRoundId,
      'updatedTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertGolfRoundSummary(String sessionId) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    if (!sessionDoc.exists) return;
    final session = CaddyPlaySession.fromDoc(sessionDoc);
    if (!session.isPlay) return;

    final holesSnapshot = await _sessions
        .doc(sessionId)
        .collection('holes')
        .orderBy('holeNumber', descending: false)
        .get();

    final holes = holesSnapshot.docs
        .map((doc) => CaddyPlayHole.fromMap(doc.data()))
        .toList(growable: false);

    final validScores =
        holes.where((e) => e.score != null).toList(growable: false);
    final totalScore =
        validScores.fold<int>(0, (sum, hole) => sum + (hole.score ?? 0));
    final totalPar = holes.fold<int>(0, (sum, hole) => sum + (hole.par ?? 4));

    final golfRoundId = session.linkedGolfRoundId ?? _golfRounds.doc().id;

    await _golfRounds.doc(golfRoundId).set({
      'userId': session.userId,
      'date': Timestamp.fromDate(session.startTime),
      'courseName': session.courseName ?? '',
      'courseId': session.courseId,
      'teeBox': session.teeName ?? '',
      'score': totalScore,
      'parTotal': totalPar,
      'scoreToPar': totalScore - totalPar,
      'courseRating': (sessionDoc.data()?['courseRating'] as num?)?.toDouble(),
      'slopeRating': (sessionDoc.data()?['slopeRating'] as num?)?.toDouble(),
      'notes': 'Captured by CaddyPlay',
      'createdTime': FieldValue.serverTimestamp(),
      'updatedTime': FieldValue.serverTimestamp(),
      'isValid': true,
    }, SetOptions(merge: true));

    await _sessions.doc(sessionId).update({
      'linkedGolfRoundId': golfRoundId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await syncRoundLogsCompatibility(sessionId, markNotLive: true);
  }

  Future<Map<String, dynamic>?> _captureGpsStart() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'capturedAt': Timestamp.now(),
      };
    } catch (e) {
      debugPrint('CaddyPlay: GPS capture failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _captureWeatherStart(
    Map<String, dynamic>? gpsStart,
  ) async {
    if (gpsStart == null) return null;

    try {
      final lat = (gpsStart['lat'] as num).toDouble();
      final lng = (gpsStart['lng'] as num).toDouble();
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto',
      );

      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final body = response.body;
      if (body.isEmpty) return null;

      return {
        'provider': 'open-meteo',
        'raw': body,
        'capturedAt': Timestamp.now(),
      };
    } catch (e) {
      debugPrint('CaddyPlay: Weather capture failed: $e');
      return null;
    }
  }

  int _elapsedSeconds(dynamic timestamp) {
    final startTime = timestampToDate(timestamp);
    if (startTime == null) return 0;
    return DateTime.now().difference(startTime).inSeconds;
  }

  int mathMin(int a, int b) => a < b ? a : b;
}
