import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'caddyplay_models.dart';

class CaddyPlaySessionService {
  CaddyPlaySessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  static const String activeRoundKey = 'caddyplay.active_round';
  static const String advancedDefaultsKey = 'caddyplay.advanced_defaults';
  static const String completedRoundsKey = 'caddyplay.completed_rounds';

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

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<CaddyPlayAdvancedDefaults> loadAdvancedDefaults() async {
    final prefs = await _prefs;
    final raw = prefs.getString(advancedDefaultsKey);
    if (raw == null || raw.isEmpty) {
      return const CaddyPlayAdvancedDefaults();
    }

    try {
      return CaddyPlayAdvancedDefaults.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const CaddyPlayAdvancedDefaults();
    }
  }

  Future<void> saveAdvancedDefaults(CaddyPlayAdvancedDefaults defaults) async {
    final prefs = await _prefs;
    await prefs.setString(
      advancedDefaultsKey,
      jsonEncode(defaults.toJson()),
    );
  }

  Future<CaddyPlayActiveRound?> loadLocalActiveRound() async {
    final prefs = await _prefs;
    final raw = prefs.getString(activeRoundKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return CaddyPlayActiveRound.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (error) {
      debugPrint('CaddyPlay: failed to decode local round: $error');
      await prefs.remove(activeRoundKey);
      return null;
    }
  }

  Future<void> clearLocalActiveRound() async {
    final prefs = await _prefs;
    await prefs.remove(activeRoundKey);
  }

  Future<List<CaddyPlayActiveRound>> loadCompletedRounds() async {
    final prefs = await _prefs;
    final rawList = prefs.getStringList(completedRoundsKey) ?? const <String>[];
    final rounds = <CaddyPlayActiveRound>[];

    for (final raw in rawList) {
      try {
        rounds.add(
          CaddyPlayActiveRound.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Ignore malformed archive entries.
      }
    }

    return rounds;
  }

  Future<void> cleanupExpiredLocalArtifacts() async {
    final rounds = await loadCompletedRounds();
    if (rounds.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final retained = <CaddyPlayActiveRound>[];

    for (final round in rounds) {
      final retainUntil = round.retainLocalUntil;
      if (retainUntil != null && retainUntil.isBefore(now)) {
        for (final path in round.allMoments
            .map((moment) => moment.audioPath)
            .whereType<String>()) {
          await _deleteLocalFile(path);
        }
        continue;
      }
      retained.add(round);
    }

    final prefs = await _prefs;
    await prefs.setStringList(
      completedRoundsKey,
      retained
          .map((round) => jsonEncode(round.toJson()))
          .toList(growable: false),
    );
  }

  Future<CaddyPlayActiveRound?> restoreRemoteActiveRound() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      return null;
    }

    try {
      final query = await _sessions
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: CaddyPlaySessionStatus.active.name)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final sessionDoc = query.docs.first;
      final holesSnapshot = await _sessions
          .doc(sessionDoc.id)
          .collection('holes')
          .orderBy('holeNumber', descending: false)
          .get();
      final logsSnapshot = await _logs
          .where('sessionId', isEqualTo: sessionDoc.id)
          .orderBy('capturedAt', descending: false)
          .get();

      final round = CaddyPlayActiveRound.fromRemote(
        sessionDoc: sessionDoc,
        holes: holesSnapshot.docs
            .map((doc) => CaddyPlayHole.fromFirestore(doc.data()))
            .toList(growable: false),
        moments: logsSnapshot.docs
            .map(CaddyPlayMoment.fromFirestore)
            .toList(growable: false),
      );

      await _writeLocalActiveRound(round);
      return round;
    } catch (error) {
      debugPrint('CaddyPlay: failed to restore remote round: $error');
      return null;
    }
  }

  Future<CaddyPlayActiveRound> saveRound(
    CaddyPlayActiveRound round, {
    bool sync = true,
  }) async {
    await _writeLocalActiveRound(round);
    if (!sync) {
      return round;
    }

    final synced = await syncRound(round);
    await _writeLocalActiveRound(synced);
    return synced;
  }

  Future<CaddyPlayActiveRound> syncRound(CaddyPlayActiveRound round) async {
    if (round.userId.isEmpty || currentUserId.isEmpty) {
      return round.copyWith(
        syncState: CaddyPlaySyncState.localOnly,
        lastSyncError: 'Not authenticated.',
        snapshot: (round.snapshot ?? buildRoundSnapshot(round)).copyWith(
          syncedToWebApp: false,
          availableInWebApp: false,
        ),
      );
    }

    final snapshot = round.snapshot ?? buildRoundSnapshot(round);
    final gpsStart = await _captureGpsStart();
    final weatherStart =
        gpsStart != null ? await _captureWeatherStart(gpsStart) : null;

    try {
      final sessionRef = _sessions.doc(round.roundId);
      final isFirstRemoteSync = round.lastRemoteSyncAt == null;

      await sessionRef.set(
        <String, dynamic>{
          ...round.toFirestoreSession(),
          if (isFirstRemoteSync) 'createdAt': FieldValue.serverTimestamp(),
          if (gpsStart != null) 'gpsStart': gpsStart,
          if (weatherStart != null) 'weatherStart': weatherStart,
        },
        SetOptions(merge: true),
      );

      final batch = _firestore.batch();
      for (final hole in round.holes) {
        batch.set(
          sessionRef.collection('holes').doc('${hole.holeNumber}'),
          hole.toFirestore(),
          SetOptions(merge: true),
        );
      }

      final syncedMoments = <CaddyPlayMoment>[];
      for (final hole in round.holes) {
        for (final moment in hole.moments) {
          final syncedMoment = moment.copyWith(
            syncState: CaddyPlaySyncState.synced,
            pendingProcessing: false,
          );
          syncedMoments.add(syncedMoment);
          batch.set(
            _logs.doc(moment.id),
            syncedMoment.toFirestore(
              sessionId: round.roundId,
              userId: round.userId,
              mode: round.mode,
            ),
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();

      final syncedRound = _replaceAllMoments(
        round.copyWith(
          syncState: CaddyPlaySyncState.synced,
          lastSyncError: null,
          lastRemoteSyncAt: DateTime.now(),
          snapshot: snapshot.copyWith(
            syncedToWebApp: true,
            availableInWebApp: true,
          ),
        ),
        syncedMoments,
      );

      await _roundLogs.doc(round.linkedRoundLogId ?? round.roundId).set(
            _buildRoundLogPayload(syncedRound),
            SetOptions(merge: true),
          );

      if (syncedRound.isCompleted) {
        await _golfRounds.doc(round.linkedGolfRoundId ?? round.roundId).set(
              _buildGolfRoundPayload(syncedRound),
              SetOptions(merge: true),
            );
      }

      return syncedRound;
    } catch (error) {
      debugPrint('CaddyPlay: sync failed: $error');
      return round.copyWith(
        syncState: CaddyPlaySyncState.localOnly,
        lastSyncError: error.toString(),
        snapshot: snapshot.copyWith(
          syncedToWebApp: false,
          availableInWebApp: false,
        ),
      );
    }
  }

  Future<CaddyPlayActiveRound> completeRound(CaddyPlayActiveRound round) async {
    final snapshot = buildRoundSnapshot(round);
    var completed = round.markCompleted(snapshot);
    completed = await syncRound(completed);
    await _archiveCompletedRound(completed);
    await clearLocalActiveRound();
    return completed;
  }

  Future<void> cancelRound(CaddyPlayActiveRound round) async {
    await clearLocalActiveRound();
    final userId = currentUserId;
    if (userId.isEmpty) {
      return;
    }

    try {
      await _sessions.doc(round.roundId).set(
        <String, dynamic>{
          'status': CaddyPlaySessionStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await _roundLogs.doc(round.linkedRoundLogId ?? round.roundId).set(
        <String, dynamic>{
          'isLive': false,
          'updatedTime': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('CaddyPlay: failed to cancel remote round: $error');
    }
  }

  Future<CaddyPlayTalkAnalysis> analyzeTalkTranscript({
    required String transcript,
    required Duration recordingDuration,
    String? audioPath,
  }) async {
    final normalized = transcript.trim();
    await Future<void>.delayed(const Duration(milliseconds: 850));

    if (normalized.isEmpty) {
      return CaddyPlayTalkAnalysis(
        transcript: normalized,
        recordingDuration: recordingDuration,
        audioPath: audioPath,
      );
    }

    final text = normalized.toLowerCase();
    final pillarTags = <CaddyPlayPillarTag>{};

    if (text.contains('focus') ||
        text.contains('routine') ||
        text.contains('target') ||
        text.contains('rush')) {
      pillarTags.add(CaddyPlayPillarTag.focus);
    }
    if (text.contains('commit') ||
        text.contains('trust') ||
        text.contains('confident') ||
        text.contains('solid')) {
      pillarTags.add(CaddyPlayPillarTag.confidence);
    }
    if (text.contains('calm') ||
        text.contains('breath') ||
        text.contains('steady') ||
        text.contains('control')) {
      pillarTags.add(CaddyPlayPillarTag.control);
    }

    String? interpretation;
    if (text.contains('rushed')) {
      interpretation = 'Routine speed affected the shot.';
    } else if (text.contains('push') || text.contains('block')) {
      interpretation = 'Commitment was there, direction leaked right.';
    } else if (text.contains('pull') || text.contains('left')) {
      interpretation = 'The strike reacted quickly left of target.';
    } else if (text.contains('calm') || text.contains('steady')) {
      interpretation = 'The language suggests a calmer, steadier shot pattern.';
    } else if (text.contains('good') || text.contains('solid')) {
      interpretation = 'The reflection points to a useful, repeatable moment.';
    } else if (normalized.isNotEmpty) {
      interpretation = _shortInterpretationFromTranscript(normalized);
    }

    return CaddyPlayTalkAnalysis(
      transcript: normalized,
      recordingDuration: recordingDuration,
      aiInterpretation: interpretation,
      pillarTags: pillarTags.toList(growable: false),
      audioPath: audioPath,
    );
  }

  CaddyPlayMindSnapSequence nextMindSnapSequence(CaddyPlayActiveRound round) {
    return deriveMindSnapSequence(round);
  }

  CaddyPlayRoundSnapshot buildSnapshot(CaddyPlayActiveRound round) {
    final snapshot = buildRoundSnapshot(
      round,
      syncedToWebApp: round.syncState == CaddyPlaySyncState.synced,
      availableInWebApp: round.syncState == CaddyPlaySyncState.synced,
    );
    return snapshot;
  }

  Future<String> createTalkAudioPath(String roundId) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/caddyplay_${roundId}_$stamp.m4a';
  }

  Future<void> _writeLocalActiveRound(CaddyPlayActiveRound round) async {
    final prefs = await _prefs;
    await prefs.setString(
      activeRoundKey,
      jsonEncode(round.toJson()),
    );
  }

  Future<void> _archiveCompletedRound(CaddyPlayActiveRound round) async {
    final rounds = await loadCompletedRounds();
    final next = <CaddyPlayActiveRound>[
      round,
      ...rounds.where((item) => item.roundId != round.roundId),
    ];
    final prefs = await _prefs;
    await prefs.setStringList(
      completedRoundsKey,
      next.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }

  Future<Map<String, dynamic>?> _captureGpsStart() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return null;
      }

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

      return <String, dynamic>{
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'capturedAt': Timestamp.now(),
      };
    } catch (error) {
      debugPrint('CaddyPlay: GPS capture failed: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _captureWeatherStart(
    Map<String, dynamic> gpsStart,
  ) async {
    try {
      final lat = (gpsStart['lat'] as num).toDouble();
      final lng = (gpsStart['lng'] as num).toDouble();
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto',
      );

      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }

      return <String, dynamic>{
        'provider': 'open-meteo',
        'raw': response.body,
        'capturedAt': Timestamp.now(),
      };
    } catch (error) {
      debugPrint('CaddyPlay: Weather capture failed: $error');
      return null;
    }
  }

  Future<void> _deleteLocalFile(String path) async {
    if (path.trim().isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  CaddyPlayActiveRound _replaceAllMoments(
    CaddyPlayActiveRound round,
    List<CaddyPlayMoment> syncedMoments,
  ) {
    final byHole = <int, List<CaddyPlayMoment>>{};
    for (final moment in syncedMoments) {
      byHole.putIfAbsent(moment.holeNumber, () => <CaddyPlayMoment>[]);
      byHole[moment.holeNumber]!.add(moment);
    }

    return round.copyWith(
      holes: round.holes
          .map(
            (hole) => hole.copyWith(
              moments: byHole[hole.holeNumber] ?? hole.moments,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> _buildRoundLogPayload(CaddyPlayActiveRound round) {
    final snapshot = round.snapshot ?? buildRoundSnapshot(round);
    final aggregate = aggregateMindset(round);
    final voiceTranscription = round.allMoments
        .where((moment) => moment.isTalk)
        .map((moment) => moment.transcript?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(' | ');

    return <String, dynamic>{
      'userId': round.userId,
      'roundId': round.roundId,
      'date': Timestamp.fromDate(round.startedAt),
      'courseName': round.courseName,
      'courseType': round.mode.name,
      'mindsetFocus': aggregate.focus,
      'mindsetConfidence': aggregate.confidence,
      'mindsetControl': aggregate.control,
      'bestCue': _bestCue(round),
      'recoveryHoles': _recoveryHoles(round),
      'overallMindsetEmoji': _emojiForScore(aggregate.overall),
      'technicalSummary':
          'Captured ${round.totalMoments} moments. Hole ${round.currentHole}/${round.holesTotal}.',
      'aiRoundSummary': snapshot.mindsetSummary,
      'voiceTranscription': voiceTranscription,
      'nlpProcessed': true,
      'isLive': !round.isCompleted,
      'mindsetColor': _colorForScore(aggregate.overall),
      'linkedGolfRoundId': round.linkedGolfRoundId ?? round.roundId,
      'updatedTime': FieldValue.serverTimestamp(),
      if (round.lastRemoteSyncAt == null)
        'createdTime': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildGolfRoundPayload(CaddyPlayActiveRound round) {
    final snapshot = round.snapshot ?? buildRoundSnapshot(round);
    return <String, dynamic>{
      'userId': round.userId,
      'date': Timestamp.fromDate(round.startedAt),
      'courseName': round.courseName,
      'courseId': null,
      'teeBox': round.teeName ?? '',
      'score': round.totalScore,
      'parTotal': round.totalPar,
      'scoreToPar': round.scoreToPar,
      'courseRating': round.courseRating,
      'slopeRating': round.slopeRating,
      'preRoundMood': enumLabel(round.preRoundMindset),
      'notes': snapshot.evaluationPhrase,
      'lessonsLearned': snapshot.completionInsight,
      'keyMoments': snapshot.momentumShift,
      'mentalFocus': aggregateMindset(round).focus,
      'courseManagement': aggregateMindset(round).control,
      'emotionalControl': aggregateMindset(round).confidence,
      'createdTime': FieldValue.serverTimestamp(),
      'updatedTime': FieldValue.serverTimestamp(),
      'isValid': true,
    };
  }

  String _bestCue(CaddyPlayActiveRound round) {
    final counts = <String, int>{};
    for (final moment in round.allMoments) {
      for (final tag in moment.pillarTags) {
        final label = enumLabel(tag);
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return 'Routine First';
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<String> _recoveryHoles(CaddyPlayActiveRound round) {
    return round.holes
        .where((hole) => hole.mindSnapCount > 0)
        .map((hole) => 'H${hole.holeNumber}')
        .toList(growable: false);
  }

  String _shortInterpretationFromTranscript(String transcript) {
    final clean = transcript.replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = clean.split(' ');
    final excerpt = words.take(6).join(' ');
    if (excerpt.isEmpty) {
      return '';
    }
    return '$excerpt.';
  }

  String _emojiForScore(int score) {
    if (score >= 80) {
      return '😌';
    }
    if (score >= 60) {
      return '🙂';
    }
    if (score >= 45) {
      return '😐';
    }
    return '😟';
  }

  String _colorForScore(int score) {
    if (score >= 80) {
      return '#66BB6A';
    }
    if (score >= 60) {
      return '#8BC34A';
    }
    if (score >= 45) {
      return '#FFA726';
    }
    return '#EF5350';
  }
}
