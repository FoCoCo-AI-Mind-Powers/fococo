import 'package:cloud_firestore/cloud_firestore.dart';

enum CaddyPlayMode { play, practice }

enum CaddyPlaySessionStatus { active, completed, cancelled }

enum CaddyPlayRoundType { practice, casual, tournament }

enum CaddyPlayPlayingPartners { solo, friends, competitive }

enum CaddyPlayPreRoundMindset { positive, neutral, negative }

enum CaddyPlayWeather { good, ok, bad }

enum CaddyPlayMomentType { tap, talk, mindsnap }

enum CaddyPlaySyncState { localOnly, synced }

enum CaddyPlayCommitmentLevel { high, mid, low }

enum CaddyPlayFocusLevel { high, mid, low }

enum CaddyPlayShotResult { good, ok, bad }

enum CaddyPlayRoutineStatus { yes, partly, no }

enum CaddyPlayPillarTag { focus, confidence, control }

enum CaddyPlayMindSnapSequence { general, recovery, refocus, composure }

class CaddyPlayAdvancedDefaults {
  const CaddyPlayAdvancedDefaults({
    this.roundType = CaddyPlayRoundType.practice,
    this.playingPartners = CaddyPlayPlayingPartners.friends,
    this.preRoundMindset = CaddyPlayPreRoundMindset.positive,
    this.weather = CaddyPlayWeather.good,
  });

  final CaddyPlayRoundType roundType;
  final CaddyPlayPlayingPartners playingPartners;
  final CaddyPlayPreRoundMindset preRoundMindset;
  final CaddyPlayWeather weather;

  CaddyPlayAdvancedDefaults copyWith({
    CaddyPlayRoundType? roundType,
    CaddyPlayPlayingPartners? playingPartners,
    CaddyPlayPreRoundMindset? preRoundMindset,
    CaddyPlayWeather? weather,
  }) {
    return CaddyPlayAdvancedDefaults(
      roundType: roundType ?? this.roundType,
      playingPartners: playingPartners ?? this.playingPartners,
      preRoundMindset: preRoundMindset ?? this.preRoundMindset,
      weather: weather ?? this.weather,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roundType': roundType.name,
        'playingPartners': playingPartners.name,
        'preRoundMindset': preRoundMindset.name,
        'weather': weather.name,
      };

  factory CaddyPlayAdvancedDefaults.fromJson(Map<String, dynamic> json) {
    return CaddyPlayAdvancedDefaults(
      roundType: enumFromName(
        CaddyPlayRoundType.values,
        json['roundType'],
        CaddyPlayRoundType.practice,
      ),
      playingPartners: enumFromName(
        CaddyPlayPlayingPartners.values,
        json['playingPartners'],
        CaddyPlayPlayingPartners.friends,
      ),
      preRoundMindset: enumFromName(
        CaddyPlayPreRoundMindset.values,
        json['preRoundMindset'],
        CaddyPlayPreRoundMindset.positive,
      ),
      weather: enumFromName(
        CaddyPlayWeather.values,
        json['weather'],
        CaddyPlayWeather.good,
      ),
    );
  }
}

class CaddyPlayTalkAnalysis {
  const CaddyPlayTalkAnalysis({
    required this.transcript,
    required this.recordingDuration,
    this.aiInterpretation,
    this.pillarTags = const <CaddyPlayPillarTag>[],
    this.audioPath,
  });

  final String transcript;
  final Duration recordingDuration;
  final String? aiInterpretation;
  final List<CaddyPlayPillarTag> pillarTags;
  final String? audioPath;

  bool get hasInterpretation =>
      (aiInterpretation ?? '').trim().isNotEmpty || pillarTags.isNotEmpty;
}

class CaddyPlayMoment {
  const CaddyPlayMoment({
    required this.id,
    required this.holeNumber,
    required this.type,
    required this.timestamp,
    this.commitment,
    this.focusLevel,
    this.shotResult,
    this.preShotRoutine,
    this.transcript,
    this.aiInterpretation,
    this.pillarTags = const <CaddyPlayPillarTag>[],
    this.recordingDurationSeconds,
    this.audioPath,
    this.pendingProcessing = false,
    this.mindSnapSequence,
    this.syncState = CaddyPlaySyncState.localOnly,
  });

  final String id;
  final int holeNumber;
  final CaddyPlayMomentType type;
  final DateTime timestamp;
  final CaddyPlayCommitmentLevel? commitment;
  final CaddyPlayFocusLevel? focusLevel;
  final CaddyPlayShotResult? shotResult;
  final CaddyPlayRoutineStatus? preShotRoutine;
  final String? transcript;
  final String? aiInterpretation;
  final List<CaddyPlayPillarTag> pillarTags;
  final int? recordingDurationSeconds;
  final String? audioPath;
  final bool pendingProcessing;
  final CaddyPlayMindSnapSequence? mindSnapSequence;
  final CaddyPlaySyncState syncState;

  bool get isTalk => type == CaddyPlayMomentType.talk;
  bool get isTap => type == CaddyPlayMomentType.tap;
  bool get isMindSnap => type == CaddyPlayMomentType.mindsnap;

  CaddyPlayMoment copyWith({
    int? holeNumber,
    CaddyPlayMomentType? type,
    DateTime? timestamp,
    CaddyPlayCommitmentLevel? commitment,
    CaddyPlayFocusLevel? focusLevel,
    CaddyPlayShotResult? shotResult,
    CaddyPlayRoutineStatus? preShotRoutine,
    String? transcript,
    String? aiInterpretation,
    List<CaddyPlayPillarTag>? pillarTags,
    int? recordingDurationSeconds,
    String? audioPath,
    bool? pendingProcessing,
    CaddyPlayMindSnapSequence? mindSnapSequence,
    CaddyPlaySyncState? syncState,
  }) {
    return CaddyPlayMoment(
      id: id,
      holeNumber: holeNumber ?? this.holeNumber,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      commitment: commitment ?? this.commitment,
      focusLevel: focusLevel ?? this.focusLevel,
      shotResult: shotResult ?? this.shotResult,
      preShotRoutine: preShotRoutine ?? this.preShotRoutine,
      transcript: transcript ?? this.transcript,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      pillarTags: pillarTags ?? this.pillarTags,
      recordingDurationSeconds:
          recordingDurationSeconds ?? this.recordingDurationSeconds,
      audioPath: audioPath ?? this.audioPath,
      pendingProcessing: pendingProcessing ?? this.pendingProcessing,
      mindSnapSequence: mindSnapSequence ?? this.mindSnapSequence,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'holeNumber': holeNumber,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'commitment': commitment?.name,
        'focusLevel': focusLevel?.name,
        'shotResult': shotResult?.name,
        'preShotRoutine': preShotRoutine?.name,
        'transcript': transcript,
        'aiInterpretation': aiInterpretation,
        'pillarTags': pillarTags.map((tag) => tag.name).toList(growable: false),
        'recordingDurationSeconds': recordingDurationSeconds,
        'audioPath': audioPath,
        'pendingProcessing': pendingProcessing,
        'mindSnapSequence': mindSnapSequence?.name,
        'syncState': syncState.name,
      };

  factory CaddyPlayMoment.fromJson(Map<String, dynamic> json) {
    return CaddyPlayMoment(
      id: (json['id'] ?? '').toString(),
      holeNumber: (json['holeNumber'] as num?)?.toInt() ?? 1,
      type: enumFromName(
        CaddyPlayMomentType.values,
        json['type'],
        CaddyPlayMomentType.tap,
      ),
      timestamp: dateTimeFromValue(json['timestamp']) ?? DateTime.now(),
      commitment:
          enumOrNull(CaddyPlayCommitmentLevel.values, json['commitment']),
      focusLevel: enumOrNull(CaddyPlayFocusLevel.values, json['focusLevel']),
      shotResult: enumOrNull(CaddyPlayShotResult.values, json['shotResult']),
      preShotRoutine:
          enumOrNull(CaddyPlayRoutineStatus.values, json['preShotRoutine']),
      transcript: json['transcript'] as String?,
      aiInterpretation: json['aiInterpretation'] as String?,
      pillarTags: ((json['pillarTags'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => enumOrNull(CaddyPlayPillarTag.values, value))
          .whereType<CaddyPlayPillarTag>()
          .toList(growable: false),
      recordingDurationSeconds:
          (json['recordingDurationSeconds'] as num?)?.toInt(),
      audioPath: json['audioPath'] as String?,
      pendingProcessing: json['pendingProcessing'] == true,
      mindSnapSequence: enumOrNull(
          CaddyPlayMindSnapSequence.values, json['mindSnapSequence']),
      syncState: enumFromName(
        CaddyPlaySyncState.values,
        json['syncState'],
        CaddyPlaySyncState.localOnly,
      ),
    );
  }

  factory CaddyPlayMoment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? <String, dynamic>{};
    final legacyInput = (map['inputMethod'] as String?)?.toLowerCase().trim();
    final storedType = (map['type'] as String?)?.toLowerCase().trim();
    final type = storedType == CaddyPlayMomentType.mindsnap.name
        ? CaddyPlayMomentType.mindsnap
        : legacyInput == 'voice' || legacyInput == CaddyPlayMomentType.talk.name
            ? CaddyPlayMomentType.talk
            : legacyInput == CaddyPlayMomentType.mindsnap.name
                ? CaddyPlayMomentType.mindsnap
                : CaddyPlayMomentType.tap;

    return CaddyPlayMoment(
      id: doc.id,
      holeNumber: (map['holeNumber'] as num?)?.toInt() ?? 1,
      type: type,
      timestamp: dateTimeFromValue(map['capturedAt']) ?? DateTime.now(),
      commitment: enumOrNull(
        CaddyPlayCommitmentLevel.values,
        map['commitment'],
      ),
      focusLevel: enumOrNull(
            CaddyPlayFocusLevel.values,
            map['focusLevel'],
          ) ??
          legacyFocusLevel(map['focus']),
      shotResult: enumOrNull(
            CaddyPlayShotResult.values,
            map['shotResult'],
          ) ??
          legacyShotResult(map['result']),
      preShotRoutine: enumOrNull(
            CaddyPlayRoutineStatus.values,
            map['preShotRoutine'],
          ) ??
          legacyRoutineStatus(map['routine']),
      transcript:
          (map['transcript'] as String?) ?? (map['transcription'] as String?),
      aiInterpretation: map['aiInterpretation'] as String?,
      pillarTags: ((map['pillarTags'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => enumOrNull(CaddyPlayPillarTag.values, value))
          .whereType<CaddyPlayPillarTag>()
          .toList(growable: false),
      recordingDurationSeconds:
          (map['recordingDurationSeconds'] as num?)?.toInt(),
      audioPath: map['audioPath'] as String?,
      pendingProcessing: map['pendingProcessing'] == true,
      mindSnapSequence:
          enumOrNull(CaddyPlayMindSnapSequence.values, map['mindSnapSequence']),
      syncState: map['syncedAt'] != null
          ? CaddyPlaySyncState.synced
          : CaddyPlaySyncState.localOnly,
    );
  }

  Map<String, dynamic> toFirestore({
    required String sessionId,
    required String userId,
    required CaddyPlayMode mode,
  }) {
    return <String, dynamic>{
      'sessionId': sessionId,
      'userId': userId,
      'mode': mode.name,
      'holeNumber': holeNumber,
      'type': type.name,
      'inputMethod': switch (type) {
        CaddyPlayMomentType.tap => 'tap',
        CaddyPlayMomentType.talk => 'voice',
        CaddyPlayMomentType.mindsnap => 'mindsnap',
      },
      'commitment': commitment?.name,
      'focusLevel': focusLevel?.name,
      'shotResult': shotResult?.name,
      'preShotRoutine': preShotRoutine?.name,
      'transcript': transcript,
      'transcription': transcript,
      'aiInterpretation': aiInterpretation,
      'pillarTags': pillarTags.map((tag) => tag.name).toList(growable: false),
      'recordingDurationSeconds': recordingDurationSeconds,
      'audioPath': audioPath,
      'pendingProcessing': pendingProcessing,
      'mindSnapSequence': mindSnapSequence?.name,
      'capturedAt': Timestamp.fromDate(timestamp),
      'editedAt': FieldValue.serverTimestamp(),
      'syncedAt': syncState == CaddyPlaySyncState.synced
          ? FieldValue.serverTimestamp()
          : null,
      // Legacy compatibility for existing derived summaries.
      'result': legacyResultName(shotResult),
      'focus': legacyFocusName(focusLevel),
      'routine': legacyRoutineName(preShotRoutine),
      'emotion': null,
    };
  }
}

class CaddyPlayHole {
  const CaddyPlayHole({
    required this.holeNumber,
    this.par = 4,
    this.distance,
    this.score,
    this.moments = const <CaddyPlayMoment>[],
    this.lastUpdated,
  });

  final int holeNumber;
  final int par;
  final int? distance;
  final int? score;
  final List<CaddyPlayMoment> moments;
  final DateTime? lastUpdated;

  bool get isComplete => score != null;
  int get tapCount => moments.where((moment) => moment.isTap).length;
  int get talkCount => moments.where((moment) => moment.isTalk).length;
  int get mindSnapCount => moments.where((moment) => moment.isMindSnap).length;

  CaddyPlayHole copyWith({
    int? par,
    int? distance,
    int? score,
    List<CaddyPlayMoment>? moments,
    DateTime? lastUpdated,
  }) {
    return CaddyPlayHole(
      holeNumber: holeNumber,
      par: par ?? this.par,
      distance: distance ?? this.distance,
      score: score ?? this.score,
      moments: moments ?? this.moments,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  CaddyPlayHole addMoment(CaddyPlayMoment moment) {
    return copyWith(
      moments: <CaddyPlayMoment>[...moments, moment],
      lastUpdated: moment.timestamp,
    );
  }

  CaddyPlayHole replaceMoment(CaddyPlayMoment updatedMoment) {
    return copyWith(
      moments: moments
          .map((moment) =>
              moment.id == updatedMoment.id ? updatedMoment : moment)
          .toList(growable: false),
      lastUpdated: updatedMoment.timestamp,
    );
  }

  CaddyPlayHole removeMoment(String momentId) {
    return copyWith(
      moments: moments
          .where((moment) => moment.id != momentId)
          .toList(growable: false),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'holeNumber': holeNumber,
        'par': par,
        'distance': distance,
        'score': score,
        'moments':
            moments.map((moment) => moment.toJson()).toList(growable: false),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory CaddyPlayHole.fromJson(Map<String, dynamic> json) {
    return CaddyPlayHole(
      holeNumber: (json['holeNumber'] as num?)?.toInt() ?? 1,
      par: (json['par'] as num?)?.toInt() ?? 4,
      distance: (json['distance'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt(),
      moments: ((json['moments'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CaddyPlayMoment.fromJson)
          .toList(growable: false),
      lastUpdated: dateTimeFromValue(json['lastUpdated']),
    );
  }

  factory CaddyPlayHole.fromFirestore(Map<String, dynamic> map) {
    return CaddyPlayHole(
      holeNumber: (map['holeNumber'] as num?)?.toInt() ?? 1,
      par: (map['par'] as num?)?.toInt() ?? 4,
      distance: (map['distance'] as num?)?.toInt(),
      score: (map['score'] as num?)?.toInt(),
      lastUpdated: dateTimeFromValue(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'holeNumber': holeNumber,
        'par': par,
        'distance': distance,
        'score': score,
        'isComplete': isComplete,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
}

class CaddyPlayRoundSnapshot {
  const CaddyPlayRoundSnapshot({
    required this.courseName,
    required this.date,
    required this.roundType,
    required this.evaluationPhrase,
    required this.focusLabel,
    required this.confidenceLabel,
    required this.controlLabel,
    required this.scoreToPar,
    required this.holesPlayed,
    required this.totalMoments,
    required this.tapCount,
    required this.talkCount,
    required this.mindSnapCount,
    required this.momentumShift,
    required this.mindsetSummary,
    required this.completionInsight,
    required this.syncedToWebApp,
    required this.availableInWebApp,
  });

  final String courseName;
  final DateTime date;
  final CaddyPlayRoundType roundType;
  final String evaluationPhrase;
  final String focusLabel;
  final String confidenceLabel;
  final String controlLabel;
  final int scoreToPar;
  final int holesPlayed;
  final int totalMoments;
  final int tapCount;
  final int talkCount;
  final int mindSnapCount;
  final String momentumShift;
  final String mindsetSummary;
  final String completionInsight;
  final bool syncedToWebApp;
  final bool availableInWebApp;

  CaddyPlayRoundSnapshot copyWith({
    bool? syncedToWebApp,
    bool? availableInWebApp,
  }) {
    return CaddyPlayRoundSnapshot(
      courseName: courseName,
      date: date,
      roundType: roundType,
      evaluationPhrase: evaluationPhrase,
      focusLabel: focusLabel,
      confidenceLabel: confidenceLabel,
      controlLabel: controlLabel,
      scoreToPar: scoreToPar,
      holesPlayed: holesPlayed,
      totalMoments: totalMoments,
      tapCount: tapCount,
      talkCount: talkCount,
      mindSnapCount: mindSnapCount,
      momentumShift: momentumShift,
      mindsetSummary: mindsetSummary,
      completionInsight: completionInsight,
      syncedToWebApp: syncedToWebApp ?? this.syncedToWebApp,
      availableInWebApp: availableInWebApp ?? this.availableInWebApp,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'courseName': courseName,
        'date': date.toIso8601String(),
        'roundType': roundType.name,
        'evaluationPhrase': evaluationPhrase,
        'focusLabel': focusLabel,
        'confidenceLabel': confidenceLabel,
        'controlLabel': controlLabel,
        'scoreToPar': scoreToPar,
        'holesPlayed': holesPlayed,
        'totalMoments': totalMoments,
        'tapCount': tapCount,
        'talkCount': talkCount,
        'mindSnapCount': mindSnapCount,
        'momentumShift': momentumShift,
        'mindsetSummary': mindsetSummary,
        'completionInsight': completionInsight,
        'syncedToWebApp': syncedToWebApp,
        'availableInWebApp': availableInWebApp,
      };

  factory CaddyPlayRoundSnapshot.fromJson(Map<String, dynamic> json) {
    return CaddyPlayRoundSnapshot(
      courseName: (json['courseName'] ?? '').toString(),
      date: dateTimeFromValue(json['date']) ?? DateTime.now(),
      roundType: enumFromName(
        CaddyPlayRoundType.values,
        json['roundType'],
        CaddyPlayRoundType.practice,
      ),
      evaluationPhrase: (json['evaluationPhrase'] ?? '').toString(),
      focusLabel: (json['focusLabel'] ?? 'Building').toString(),
      confidenceLabel: (json['confidenceLabel'] ?? 'Building').toString(),
      controlLabel: (json['controlLabel'] ?? 'Building').toString(),
      scoreToPar: (json['scoreToPar'] as num?)?.toInt() ?? 0,
      holesPlayed: (json['holesPlayed'] as num?)?.toInt() ?? 0,
      totalMoments: (json['totalMoments'] as num?)?.toInt() ?? 0,
      tapCount: (json['tapCount'] as num?)?.toInt() ?? 0,
      talkCount: (json['talkCount'] as num?)?.toInt() ?? 0,
      mindSnapCount: (json['mindSnapCount'] as num?)?.toInt() ?? 0,
      momentumShift: (json['momentumShift'] ?? '').toString(),
      mindsetSummary: (json['mindsetSummary'] ?? '').toString(),
      completionInsight: (json['completionInsight'] ?? '').toString(),
      syncedToWebApp: json['syncedToWebApp'] == true,
      availableInWebApp: json['availableInWebApp'] == true,
    );
  }
}

class CaddyPlayActiveRound {
  const CaddyPlayActiveRound({
    required this.roundId,
    required this.userId,
    required this.courseName,
    required this.holesTotal,
    required this.currentHole,
    required this.startedAt,
    required this.lastUpdatedAt,
    required this.roundType,
    required this.playingPartners,
    required this.preRoundMindset,
    required this.weather,
    required this.holes,
    this.completedAt,
    this.syncState = CaddyPlaySyncState.localOnly,
    this.lastSyncError,
    this.lastRemoteSyncAt,
    this.snapshot,
    this.linkedRoundLogId,
    this.linkedGolfRoundId,
    this.teeName,
    this.teeDistance,
    this.courseRating,
    this.slopeRating,
  });

  final String roundId;
  final String userId;
  final String courseName;
  final int holesTotal;
  final int currentHole;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final CaddyPlayRoundType roundType;
  final CaddyPlayPlayingPartners playingPartners;
  final CaddyPlayPreRoundMindset preRoundMindset;
  final CaddyPlayWeather weather;
  final List<CaddyPlayHole> holes;
  final DateTime? completedAt;
  final CaddyPlaySyncState syncState;
  final String? lastSyncError;
  final DateTime? lastRemoteSyncAt;
  final CaddyPlayRoundSnapshot? snapshot;
  final String? linkedRoundLogId;
  final String? linkedGolfRoundId;
  final String? teeName;
  final int? teeDistance;
  final double? courseRating;
  final double? slopeRating;

  factory CaddyPlayActiveRound.newRound({
    required String roundId,
    required String userId,
    required String courseName,
    required int holesTotal,
    required CaddyPlayRoundType roundType,
    required CaddyPlayPlayingPartners playingPartners,
    required CaddyPlayPreRoundMindset preRoundMindset,
    required CaddyPlayWeather weather,
  }) {
    return CaddyPlayActiveRound(
      roundId: roundId,
      userId: userId,
      courseName: courseName,
      holesTotal: holesTotal,
      currentHole: 1,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      roundType: roundType,
      playingPartners: playingPartners,
      preRoundMindset: preRoundMindset,
      weather: weather,
      holes: List<CaddyPlayHole>.generate(
        holesTotal,
        (index) => CaddyPlayHole(holeNumber: index + 1),
        growable: false,
      ),
      linkedRoundLogId: roundId,
      linkedGolfRoundId: roundId,
    );
  }

  factory CaddyPlayActiveRound.fromJson(Map<String, dynamic> json) {
    final holes = ((json['holes'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CaddyPlayHole.fromJson)
        .toList(growable: false);
    final holesTotal = (json['holesTotal'] as num?)?.toInt() ?? holes.length;

    return CaddyPlayActiveRound(
      roundId: (json['roundId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      courseName: (json['courseName'] ?? '').toString(),
      holesTotal: holesTotal == 0 ? 18 : holesTotal,
      currentHole: (json['currentHole'] as num?)?.toInt() ?? 1,
      startedAt: dateTimeFromValue(json['startedAt']) ?? DateTime.now(),
      lastUpdatedAt: dateTimeFromValue(json['lastUpdatedAt']) ?? DateTime.now(),
      roundType: enumFromName(
        CaddyPlayRoundType.values,
        json['roundType'],
        CaddyPlayRoundType.practice,
      ),
      playingPartners: enumFromName(
        CaddyPlayPlayingPartners.values,
        json['playingPartners'],
        CaddyPlayPlayingPartners.friends,
      ),
      preRoundMindset: enumFromName(
        CaddyPlayPreRoundMindset.values,
        json['preRoundMindset'],
        CaddyPlayPreRoundMindset.positive,
      ),
      weather: enumFromName(
        CaddyPlayWeather.values,
        json['weather'],
        CaddyPlayWeather.good,
      ),
      holes: holes.isEmpty
          ? List<CaddyPlayHole>.generate(
              holesTotal == 0 ? 18 : holesTotal,
              (index) => CaddyPlayHole(holeNumber: index + 1),
              growable: false,
            )
          : holes,
      completedAt: dateTimeFromValue(json['completedAt']),
      syncState: enumFromName(
        CaddyPlaySyncState.values,
        json['syncState'],
        CaddyPlaySyncState.localOnly,
      ),
      lastSyncError: json['lastSyncError'] as String?,
      lastRemoteSyncAt: dateTimeFromValue(json['lastRemoteSyncAt']),
      snapshot: (json['snapshot'] as Map<String, dynamic>?) != null
          ? CaddyPlayRoundSnapshot.fromJson(
              json['snapshot'] as Map<String, dynamic>,
            )
          : null,
      linkedRoundLogId: json['linkedRoundLogId'] as String?,
      linkedGolfRoundId: json['linkedGolfRoundId'] as String?,
      teeName: json['teeName'] as String?,
      teeDistance: (json['teeDistance'] as num?)?.toInt(),
      courseRating: (json['courseRating'] as num?)?.toDouble(),
      slopeRating: (json['slopeRating'] as num?)?.toDouble(),
    );
  }

  factory CaddyPlayActiveRound.fromRemote({
    required DocumentSnapshot<Map<String, dynamic>> sessionDoc,
    required List<CaddyPlayHole> holes,
    required List<CaddyPlayMoment> moments,
  }) {
    final data = sessionDoc.data() ?? <String, dynamic>{};
    final holesTotal = (data['holesTotal'] as num?)?.toInt() ?? holes.length;
    final groupedMoments = <int, List<CaddyPlayMoment>>{};
    for (final moment in moments) {
      groupedMoments.putIfAbsent(moment.holeNumber, () => <CaddyPlayMoment>[]);
      groupedMoments[moment.holeNumber]!.add(moment);
    }

    final normalizedHoles = List<CaddyPlayHole>.generate(
      holesTotal,
      (index) {
        final holeNumber = index + 1;
        final existing = holes.cast<CaddyPlayHole?>().firstWhere(
              (hole) => hole?.holeNumber == holeNumber,
              orElse: () => null,
            );
        return (existing ?? CaddyPlayHole(holeNumber: holeNumber)).copyWith(
          moments: groupedMoments[holeNumber] ??
              existing?.moments ??
              const <CaddyPlayMoment>[],
        );
      },
      growable: false,
    );

    return CaddyPlayActiveRound(
      roundId: sessionDoc.id,
      userId: (data['userId'] ?? '').toString(),
      courseName: (data['courseName'] ?? '').toString(),
      holesTotal: holesTotal == 0 ? 18 : holesTotal,
      currentHole: (data['currentHole'] as num?)?.toInt() ?? 1,
      startedAt: dateTimeFromValue(data['startTime']) ?? DateTime.now(),
      lastUpdatedAt: dateTimeFromValue(data['updatedAt']) ?? DateTime.now(),
      roundType: enumOrNull(CaddyPlayRoundType.values, data['roundType']) ??
          (((data['mode'] as String?) == CaddyPlayMode.practice.name)
              ? CaddyPlayRoundType.practice
              : CaddyPlayRoundType.casual),
      playingPartners: enumFromName(
        CaddyPlayPlayingPartners.values,
        data['playingPartners'],
        CaddyPlayPlayingPartners.friends,
      ),
      preRoundMindset: enumFromName(
        CaddyPlayPreRoundMindset.values,
        data['preRoundMindset'],
        CaddyPlayPreRoundMindset.positive,
      ),
      weather: enumFromName(
        CaddyPlayWeather.values,
        data['weather'],
        CaddyPlayWeather.good,
      ),
      holes: normalizedHoles,
      completedAt: dateTimeFromValue(data['completedAt']),
      syncState: CaddyPlaySyncState.synced,
      lastRemoteSyncAt: dateTimeFromValue(data['updatedAt']),
      linkedRoundLogId: data['linkedRoundLogId'] as String?,
      linkedGolfRoundId: data['linkedGolfRoundId'] as String?,
      teeName: data['teeName'] as String?,
      teeDistance: (data['teeDistance'] as num?)?.toInt(),
      courseRating: (data['courseRating'] as num?)?.toDouble(),
      slopeRating: (data['slopeRating'] as num?)?.toDouble(),
    );
  }

  CaddyPlayMode get mode => roundType == CaddyPlayRoundType.practice
      ? CaddyPlayMode.practice
      : CaddyPlayMode.play;
  bool get isPractice => mode == CaddyPlayMode.practice;
  bool get isCompleted => completedAt != null;
  List<CaddyPlayMoment> get allMoments =>
      holes.expand((hole) => hole.moments).toList(growable: false)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  int get holesPlayed => holes.where((hole) => hole.isComplete).length;
  int get totalScore =>
      holes.fold<int>(0, (sum, hole) => sum + (hole.score ?? 0));
  int get totalPar => holes.fold<int>(0, (sum, hole) => sum + hole.par);
  int get scoreToPar => totalScore - totalPar;
  int get totalMoments => allMoments.length;
  int get tapCount => allMoments.where((moment) => moment.isTap).length;
  int get talkCount => allMoments.where((moment) => moment.isTalk).length;
  int get mindSnapCount =>
      allMoments.where((moment) => moment.isMindSnap).length;
  DateTime? get retainLocalUntil => completedAt?.add(const Duration(hours: 72));
  CaddyPlayHole get currentHoleData => holes[currentHole - 1];

  int tapCountForHole(int holeNumber) {
    return holes
        .firstWhere(
          (hole) => hole.holeNumber == holeNumber,
          orElse: () => CaddyPlayHole(holeNumber: holeNumber),
        )
        .tapCount;
  }

  List<CaddyPlayMoment> momentsForHole(int holeNumber) {
    return holes
        .firstWhere(
          (hole) => hole.holeNumber == holeNumber,
          orElse: () => CaddyPlayHole(holeNumber: holeNumber),
        )
        .moments;
  }

  CaddyPlayActiveRound copyWith({
    String? courseName,
    int? holesTotal,
    int? currentHole,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    CaddyPlayRoundType? roundType,
    CaddyPlayPlayingPartners? playingPartners,
    CaddyPlayPreRoundMindset? preRoundMindset,
    CaddyPlayWeather? weather,
    List<CaddyPlayHole>? holes,
    DateTime? completedAt,
    CaddyPlaySyncState? syncState,
    String? lastSyncError,
    DateTime? lastRemoteSyncAt,
    CaddyPlayRoundSnapshot? snapshot,
    String? linkedRoundLogId,
    String? linkedGolfRoundId,
    String? teeName,
    int? teeDistance,
    double? courseRating,
    double? slopeRating,
  }) {
    return CaddyPlayActiveRound(
      roundId: roundId,
      userId: userId,
      courseName: courseName ?? this.courseName,
      holesTotal: holesTotal ?? this.holesTotal,
      currentHole: currentHole ?? this.currentHole,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      roundType: roundType ?? this.roundType,
      playingPartners: playingPartners ?? this.playingPartners,
      preRoundMindset: preRoundMindset ?? this.preRoundMindset,
      weather: weather ?? this.weather,
      holes: holes ?? this.holes,
      completedAt: completedAt ?? this.completedAt,
      syncState: syncState ?? this.syncState,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      lastRemoteSyncAt: lastRemoteSyncAt ?? this.lastRemoteSyncAt,
      snapshot: snapshot ?? this.snapshot,
      linkedRoundLogId: linkedRoundLogId ?? this.linkedRoundLogId,
      linkedGolfRoundId: linkedGolfRoundId ?? this.linkedGolfRoundId,
      teeName: teeName ?? this.teeName,
      teeDistance: teeDistance ?? this.teeDistance,
      courseRating: courseRating ?? this.courseRating,
      slopeRating: slopeRating ?? this.slopeRating,
    );
  }

  CaddyPlayActiveRound updateHole(CaddyPlayHole updatedHole) {
    final updatedHoles = holes
        .map((hole) =>
            hole.holeNumber == updatedHole.holeNumber ? updatedHole : hole)
        .toList(growable: false);
    return copyWith(
      holes: updatedHoles,
      lastUpdatedAt: DateTime.now(),
      syncState: CaddyPlaySyncState.localOnly,
      lastSyncError: null,
    );
  }

  CaddyPlayActiveRound addMoment(CaddyPlayMoment moment) {
    final targetHole = holes.firstWhere(
      (hole) => hole.holeNumber == moment.holeNumber,
      orElse: () => CaddyPlayHole(holeNumber: moment.holeNumber),
    );
    return updateHole(targetHole.addMoment(moment));
  }

  CaddyPlayActiveRound replaceMoment(CaddyPlayMoment updatedMoment) {
    final targetHole = holes.firstWhere(
      (hole) => hole.holeNumber == updatedMoment.holeNumber,
      orElse: () => CaddyPlayHole(holeNumber: updatedMoment.holeNumber),
    );
    return updateHole(targetHole.replaceMoment(updatedMoment));
  }

  CaddyPlayActiveRound removeMoment(String momentId, int holeNumber) {
    final targetHole = holes.firstWhere(
      (hole) => hole.holeNumber == holeNumber,
      orElse: () => CaddyPlayHole(holeNumber: holeNumber),
    );
    return updateHole(targetHole.removeMoment(momentId));
  }

  CaddyPlayActiveRound advanceHole() {
    return copyWith(
      currentHole: (currentHole + 1).clamp(1, holesTotal),
      lastUpdatedAt: DateTime.now(),
      syncState: CaddyPlaySyncState.localOnly,
      lastSyncError: null,
    );
  }

  CaddyPlayActiveRound retreatHole() {
    return copyWith(
      currentHole: (currentHole - 1).clamp(1, holesTotal),
      lastUpdatedAt: DateTime.now(),
      syncState: CaddyPlaySyncState.localOnly,
      lastSyncError: null,
    );
  }

  CaddyPlayActiveRound markCompleted(CaddyPlayRoundSnapshot snapshot) {
    return copyWith(
      completedAt: DateTime.now(),
      snapshot: snapshot,
      lastUpdatedAt: DateTime.now(),
      syncState: CaddyPlaySyncState.localOnly,
      lastSyncError: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roundId': roundId,
        'userId': userId,
        'courseName': courseName,
        'holesTotal': holesTotal,
        'currentHole': currentHole,
        'startedAt': startedAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'roundType': roundType.name,
        'playingPartners': playingPartners.name,
        'preRoundMindset': preRoundMindset.name,
        'weather': weather.name,
        'holes': holes.map((hole) => hole.toJson()).toList(growable: false),
        'completedAt': completedAt?.toIso8601String(),
        'syncState': syncState.name,
        'lastSyncError': lastSyncError,
        'lastRemoteSyncAt': lastRemoteSyncAt?.toIso8601String(),
        'snapshot': snapshot?.toJson(),
        'linkedRoundLogId': linkedRoundLogId,
        'linkedGolfRoundId': linkedGolfRoundId,
        'teeName': teeName,
        'teeDistance': teeDistance,
        'courseRating': courseRating,
        'slopeRating': slopeRating,
      };

  Map<String, dynamic> toFirestoreSession() {
    return <String, dynamic>{
      'userId': userId,
      'courseName': courseName,
      'mode': mode.name,
      'status': isCompleted
          ? CaddyPlaySessionStatus.completed.name
          : CaddyPlaySessionStatus.active.name,
      'holesTotal': holesTotal,
      'currentHole': currentHole,
      'holesPlayed': holesPlayed,
      'elapsedSeconds': DateTime.now().difference(startedAt).inSeconds,
      'startTime': Timestamp.fromDate(startedAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'roundType': roundType.name,
      'playingPartners': playingPartners.name,
      'preRoundMindset': preRoundMindset.name,
      'weather': weather.name,
      'lockedContext': true,
      'linkedRoundLogId': linkedRoundLogId ?? roundId,
      'linkedGolfRoundId': linkedGolfRoundId,
      'teeName': teeName,
      'teeDistance': teeDistance,
      'courseRating': courseRating,
      'slopeRating': slopeRating,
      'mindSnapCount': mindSnapCount,
    };
  }
}

class CaddyPlayMindsetAggregate {
  const CaddyPlayMindsetAggregate({
    required this.focus,
    required this.confidence,
    required this.control,
  });

  final int focus;
  final int confidence;
  final int control;

  int get overall => ((focus + confidence + control) / 3).round();
}

DateTime? dateTimeFromValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

T enumFromName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final normalized = raw?.toString().trim();
  for (final value in values) {
    if (value.name == normalized) {
      return value;
    }
  }
  return fallback;
}

T? enumOrNull<T extends Enum>(List<T> values, Object? raw) {
  final normalized = raw?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (value.name == normalized) {
      return value;
    }
  }
  return null;
}

String enumLabel(Enum value) {
  final parts = value.name.split('_');
  return parts
      .map(
        (part) => part.isEmpty
            ? part
            : '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

CaddyPlayFocusLevel? legacyFocusLevel(Object? raw) {
  return switch (raw?.toString()) {
    'clear' => CaddyPlayFocusLevel.high,
    'neutral' => CaddyPlayFocusLevel.mid,
    'distracted' => CaddyPlayFocusLevel.low,
    _ => null,
  };
}

CaddyPlayShotResult? legacyShotResult(Object? raw) {
  return switch (raw?.toString()) {
    'good' => CaddyPlayShotResult.good,
    'ok' => CaddyPlayShotResult.ok,
    'poor' => CaddyPlayShotResult.bad,
    _ => null,
  };
}

CaddyPlayRoutineStatus? legacyRoutineStatus(Object? raw) {
  return switch (raw?.toString()) {
    'yes' => CaddyPlayRoutineStatus.yes,
    'partial' => CaddyPlayRoutineStatus.partly,
    'no' => CaddyPlayRoutineStatus.no,
    _ => null,
  };
}

String? legacyResultName(CaddyPlayShotResult? result) {
  return switch (result) {
    CaddyPlayShotResult.good => 'good',
    CaddyPlayShotResult.ok => 'ok',
    CaddyPlayShotResult.bad => 'poor',
    null => null,
  };
}

String? legacyFocusName(CaddyPlayFocusLevel? focusLevel) {
  return switch (focusLevel) {
    CaddyPlayFocusLevel.high => 'clear',
    CaddyPlayFocusLevel.mid => 'neutral',
    CaddyPlayFocusLevel.low => 'distracted',
    null => null,
  };
}

String? legacyRoutineName(CaddyPlayRoutineStatus? routine) {
  return switch (routine) {
    CaddyPlayRoutineStatus.yes => 'yes',
    CaddyPlayRoutineStatus.partly => 'partial',
    CaddyPlayRoutineStatus.no => 'no',
    null => null,
  };
}

int commitmentScore(CaddyPlayCommitmentLevel? level) {
  return switch (level) {
    CaddyPlayCommitmentLevel.high => 90,
    CaddyPlayCommitmentLevel.mid => 65,
    CaddyPlayCommitmentLevel.low => 35,
    null => 60,
  };
}

int focusScore(CaddyPlayFocusLevel? level) {
  return switch (level) {
    CaddyPlayFocusLevel.high => 90,
    CaddyPlayFocusLevel.mid => 65,
    CaddyPlayFocusLevel.low => 35,
    null => 60,
  };
}

int resultScore(CaddyPlayShotResult? result) {
  return switch (result) {
    CaddyPlayShotResult.good => 85,
    CaddyPlayShotResult.ok => 60,
    CaddyPlayShotResult.bad => 35,
    null => 60,
  };
}

int routineScore(CaddyPlayRoutineStatus? status) {
  return switch (status) {
    CaddyPlayRoutineStatus.yes => 85,
    CaddyPlayRoutineStatus.partly => 60,
    CaddyPlayRoutineStatus.no => 35,
    null => 60,
  };
}

CaddyPlayMindsetAggregate aggregateMindset(CaddyPlayActiveRound round) {
  if (round.allMoments.isEmpty) {
    return const CaddyPlayMindsetAggregate(
      focus: 65,
      confidence: 60,
      control: 62,
    );
  }

  final focusValues = <int>[];
  final confidenceValues = <int>[];
  final controlValues = <int>[];

  for (final moment in round.allMoments) {
    if (moment.isMindSnap) {
      focusValues.add(72);
      confidenceValues.add(70);
      controlValues.add(78);
      continue;
    }

    var focus = focusScore(moment.focusLevel);
    var confidence =
        ((commitmentScore(moment.commitment) + resultScore(moment.shotResult)) /
                2)
            .round();
    var control =
        ((focusScore(moment.focusLevel) + routineScore(moment.preShotRoutine)) /
                2)
            .round();

    if (moment.pillarTags.contains(CaddyPlayPillarTag.focus)) {
      focus += 8;
    }
    if (moment.pillarTags.contains(CaddyPlayPillarTag.confidence)) {
      confidence += 8;
    }
    if (moment.pillarTags.contains(CaddyPlayPillarTag.control)) {
      control += 8;
    }

    focusValues.add(focus.clamp(0, 100));
    confidenceValues.add(confidence.clamp(0, 100));
    controlValues.add(control.clamp(0, 100));
  }

  return CaddyPlayMindsetAggregate(
    focus: averageScore(focusValues),
    confidence: averageScore(confidenceValues),
    control: averageScore(controlValues),
  );
}

int averageScore(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sum = values.fold<int>(0, (total, value) => total + value);
  return (sum / values.length).round();
}

String descriptorForScore(int value) {
  if (value >= 78) {
    return 'Strong';
  }
  if (value >= 55) {
    return 'Building';
  }
  return 'Weak';
}

String buildTapMicroInsight(CaddyPlayMoment moment) {
  if (moment.commitment == CaddyPlayCommitmentLevel.high &&
      moment.focusLevel == CaddyPlayFocusLevel.high) {
    return 'Strong moment.';
  }
  if (moment.preShotRoutine == CaddyPlayRoutineStatus.no) {
    return 'Routine first.';
  }
  if (moment.shotResult == CaddyPlayShotResult.good) {
    return 'Committed swing.';
  }
  if (moment.focusLevel == CaddyPlayFocusLevel.low) {
    return 'Focus dropped there.';
  }
  return 'Moment captured.';
}

CaddyPlayMindSnapSequence deriveMindSnapSequence(CaddyPlayActiveRound round) {
  final recentMoments = round.currentHoleData.moments;
  final lastMoment = recentMoments.isNotEmpty ? recentMoments.last : null;
  final recentTranscript = lastMoment?.transcript?.toLowerCase() ?? '';

  if (recentTranscript.contains('pressure') ||
      recentTranscript.contains('tense') ||
      recentTranscript.contains('nervous')) {
    return CaddyPlayMindSnapSequence.composure;
  }
  if (lastMoment?.shotResult == CaddyPlayShotResult.bad ||
      lastMoment?.focusLevel == CaddyPlayFocusLevel.low) {
    return CaddyPlayMindSnapSequence.recovery;
  }
  if (recentMoments.length >= 3) {
    return CaddyPlayMindSnapSequence.refocus;
  }
  return CaddyPlayMindSnapSequence.general;
}

CaddyPlayRoundSnapshot buildRoundSnapshot(
  CaddyPlayActiveRound round, {
  bool syncedToWebApp = false,
  bool availableInWebApp = false,
}) {
  final aggregate = aggregateMindset(round);
  final evaluationPhrase = _evaluationPhraseForRound(round, aggregate);

  return CaddyPlayRoundSnapshot(
    courseName: round.courseName,
    date: round.startedAt,
    roundType: round.roundType,
    evaluationPhrase: evaluationPhrase,
    focusLabel: descriptorForScore(aggregate.focus),
    confidenceLabel: descriptorForScore(aggregate.confidence),
    controlLabel: descriptorForScore(aggregate.control),
    scoreToPar: round.scoreToPar,
    holesPlayed: round.holesPlayed == 0 ? round.currentHole : round.holesPlayed,
    totalMoments: round.totalMoments,
    tapCount: round.tapCount,
    talkCount: round.talkCount,
    mindSnapCount: round.mindSnapCount,
    momentumShift: _momentumShift(round),
    mindsetSummary: _mindsetSummary(round, aggregate),
    completionInsight: _completionInsight(round, aggregate),
    syncedToWebApp: syncedToWebApp,
    availableInWebApp: availableInWebApp,
  );
}

String _evaluationPhraseForRound(
  CaddyPlayActiveRound round,
  CaddyPlayMindsetAggregate aggregate,
) {
  if (round.totalMoments == 0) {
    return 'Building - the round is still taking shape.';
  }
  if (round.mindSnapCount >= 2) {
    return 'Resilient - kept coming back.';
  }
  if (aggregate.overall >= 78 && round.scoreToPar <= 2) {
    return 'Composed - trusted the process.';
  }
  if (aggregate.focus >= 72) {
    return 'Present - attention stayed useful.';
  }
  if (round.scoreToPar <= 0) {
    return 'Steady - kept the round in front of you.';
  }
  return 'Building - awareness improved as the round went on.';
}

String _momentumShift(CaddyPlayActiveRound round) {
  if (round.holes.length <= 1) {
    return 'Momentum held steady through the round.';
  }

  final holeScores = <int, int>{};
  for (final hole in round.holes) {
    if (hole.moments.isEmpty) {
      holeScores[hole.holeNumber] = (hole.score ?? hole.par) - hole.par + 60;
      continue;
    }
    final values = hole.moments.map((moment) {
      if (moment.isMindSnap) {
        return 74;
      }
      return ((commitmentScore(moment.commitment) +
                  focusScore(moment.focusLevel) +
                  resultScore(moment.shotResult) +
                  routineScore(moment.preShotRoutine)) /
              4)
          .round();
    }).toList(growable: false);
    holeScores[hole.holeNumber] = averageScore(values);
  }

  int? targetHole;
  var biggestDrop = 0;
  for (var hole = 2; hole <= round.holesTotal; hole++) {
    final previous = holeScores[hole - 1] ?? 60;
    final current = holeScores[hole] ?? 60;
    final delta = previous - current;
    if (delta > biggestDrop) {
      biggestDrop = delta;
      targetHole = hole;
    }
  }

  if (targetHole != null && biggestDrop >= 8) {
    return 'Hole $targetHole - Focus dropped, score followed.';
  }
  if (round.mindSnapCount > 0) {
    return 'MindSnap resets helped steady the round.';
  }
  return 'Momentum held steady through the round.';
}

String _mindsetSummary(
  CaddyPlayActiveRound round,
  CaddyPlayMindsetAggregate aggregate,
) {
  if (round.mindSnapCount >= 2) {
    return 'Resilient - you kept finding your way back.';
  }
  if (aggregate.overall >= 78) {
    return 'Composed - the mental pattern stayed useful.';
  }
  if (aggregate.focus < 50) {
    return 'Awareness dipped, but the pattern is visible now.';
  }
  return 'Awareness grew as the round unfolded.';
}

String _completionInsight(
  CaddyPlayActiveRound round,
  CaddyPlayMindsetAggregate aggregate,
) {
  if (round.mindSnapCount > 0) {
    return 'You reset well when the round asked for it.';
  }
  if (aggregate.confidence >= 75) {
    return 'Confidence stayed close enough to your process.';
  }
  if (round.totalMoments >= 10) {
    return 'You gave yourself real signals to learn from.';
  }
  return 'A clearer reflection is starting to emerge.';
}
