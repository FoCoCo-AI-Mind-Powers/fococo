import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

enum CaddyPlayMode { play, practice }

enum CaddyPlaySessionStatus { active, completed, cancelled }

enum CaddyPlayResultChip { good, ok, poor }

enum CaddyPlayFocusChip { clear, neutral, distracted }

enum CaddyPlayRoutineChip { yes, partial, no }

enum CaddyPlayEmotionChip { calm, pressured, frustrated }

class CaddyPlayChipSelection {
  final CaddyPlayResultChip? result;
  final CaddyPlayFocusChip? focus;
  final CaddyPlayRoutineChip? routine;
  final CaddyPlayEmotionChip? emotion;

  const CaddyPlayChipSelection({
    this.result,
    this.focus,
    this.routine,
    this.emotion,
  });

  bool get hasRequired => result != null && focus != null;

  CaddyPlayChipSelection copyWith({
    CaddyPlayResultChip? result,
    CaddyPlayFocusChip? focus,
    CaddyPlayRoutineChip? routine,
    CaddyPlayEmotionChip? emotion,
  }) {
    return CaddyPlayChipSelection(
      result: result ?? this.result,
      focus: focus ?? this.focus,
      routine: routine ?? this.routine,
      emotion: emotion ?? this.emotion,
    );
  }
}

class CaddyPlayHole {
  final int holeNumber;
  final int? par;
  final int? distance;
  final int? score;
  final bool isComplete;
  final DateTime? lastUpdated;

  const CaddyPlayHole({
    required this.holeNumber,
    this.par,
    this.distance,
    this.score,
    this.isComplete = false,
    this.lastUpdated,
  });

  CaddyPlayHole copyWith({
    int? par,
    int? distance,
    int? score,
    bool? isComplete,
    DateTime? lastUpdated,
  }) {
    return CaddyPlayHole(
      holeNumber: holeNumber,
      par: par ?? this.par,
      distance: distance ?? this.distance,
      score: score ?? this.score,
      isComplete: isComplete ?? this.isComplete,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'holeNumber': holeNumber,
        'par': par,
        'distance': distance,
        'score': score,
        'isComplete': isComplete,
        'lastUpdated': lastUpdated != null
            ? Timestamp.fromDate(lastUpdated!)
            : FieldValue.serverTimestamp(),
      };

  factory CaddyPlayHole.fromMap(Map<String, dynamic> map) {
    return CaddyPlayHole(
      holeNumber: (map['holeNumber'] as num?)?.toInt() ?? 0,
      par: (map['par'] as num?)?.toInt(),
      distance: (map['distance'] as num?)?.toInt(),
      score: (map['score'] as num?)?.toInt(),
      isComplete: map['isComplete'] == true,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

class CaddyPlaySession {
  final String id;
  final String userId;
  final CaddyPlayMode mode;
  final CaddyPlaySessionStatus status;
  final String? courseName;
  final String? courseId;
  final String? teeName;
  final int? teeDistance;
  final int holesTotal;
  final DateTime startTime;
  final int currentHole;
  final int holesPlayed;
  final int elapsedSeconds;
  final Map<String, dynamic>? gpsStart;
  final Map<String, dynamic>? weatherStart;
  final bool lockedContext;
  final String? linkedRoundLogId;
  final String? linkedGolfRoundId;

  const CaddyPlaySession({
    required this.id,
    required this.userId,
    required this.mode,
    required this.status,
    required this.courseName,
    required this.courseId,
    required this.teeName,
    required this.teeDistance,
    required this.holesTotal,
    required this.startTime,
    required this.currentHole,
    required this.holesPlayed,
    required this.elapsedSeconds,
    required this.gpsStart,
    required this.weatherStart,
    required this.lockedContext,
    required this.linkedRoundLogId,
    required this.linkedGolfRoundId,
  });

  bool get isPlay => mode == CaddyPlayMode.play;
  bool get isPractice => mode == CaddyPlayMode.practice;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'mode': mode.name,
        'status': status.name,
        'courseName': courseName,
        'courseId': courseId,
        'teeName': teeName,
        'teeDistance': teeDistance,
        'holesTotal': holesTotal,
        'startTime': Timestamp.fromDate(startTime),
        'currentHole': currentHole,
        'holesPlayed': holesPlayed,
        'elapsedSeconds': elapsedSeconds,
        'gpsStart': gpsStart,
        'weatherStart': weatherStart,
        'lockedContext': lockedContext,
        'linkedRoundLogId': linkedRoundLogId,
        'linkedGolfRoundId': linkedGolfRoundId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory CaddyPlaySession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};
    return CaddyPlaySession(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      mode: _modeFromString(map['mode'] as String?),
      status: _statusFromString(map['status'] as String?),
      courseName: map['courseName'] as String?,
      courseId: map['courseId'] as String?,
      teeName: map['teeName'] as String?,
      teeDistance: (map['teeDistance'] as num?)?.toInt(),
      holesTotal: (map['holesTotal'] as num?)?.toInt() ?? 9,
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentHole: (map['currentHole'] as num?)?.toInt() ?? 1,
      holesPlayed: (map['holesPlayed'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (map['elapsedSeconds'] as num?)?.toInt() ?? 0,
      gpsStart: map['gpsStart'] as Map<String, dynamic>?,
      weatherStart: map['weatherStart'] as Map<String, dynamic>?,
      lockedContext: map['lockedContext'] == true,
      linkedRoundLogId: map['linkedRoundLogId'] as String?,
      linkedGolfRoundId: map['linkedGolfRoundId'] as String?,
    );
  }
}

class CaddyPlayLog {
  final String id;
  final String sessionId;
  final String userId;
  final CaddyPlayMode mode;
  final int? holeNumber;
  final String inputMethod;
  final String transcription;
  final CaddyPlayResultChip? result;
  final CaddyPlayFocusChip? focus;
  final CaddyPlayRoutineChip? routine;
  final CaddyPlayEmotionChip? emotion;
  final DateTime capturedAt;
  final DateTime? editedAt;

  const CaddyPlayLog({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.mode,
    required this.holeNumber,
    required this.inputMethod,
    required this.transcription,
    required this.result,
    required this.focus,
    required this.routine,
    required this.emotion,
    required this.capturedAt,
    required this.editedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'sessionId': sessionId,
        'userId': userId,
        'mode': mode.name,
        'holeNumber': holeNumber,
        'inputMethod': inputMethod,
        'transcription': transcription,
        'result': result?.name,
        'focus': focus?.name,
        'routine': routine?.name,
        'emotion': emotion?.name,
        'capturedAt': Timestamp.fromDate(capturedAt),
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      };

  factory CaddyPlayLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};
    return CaddyPlayLog(
      id: doc.id,
      sessionId: map['sessionId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      mode: _modeFromString(map['mode'] as String?),
      holeNumber: (map['holeNumber'] as num?)?.toInt(),
      inputMethod: map['inputMethod'] as String? ?? 'tap',
      transcription: map['transcription'] as String? ?? '',
      result: _resultFromString(map['result'] as String?),
      focus: _focusFromString(map['focus'] as String?),
      routine: _routineFromString(map['routine'] as String?),
      emotion: _emotionFromString(map['emotion'] as String?),
      capturedAt: (map['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class CaddyPlayMindsetAggregate {
  final int mindsetFocus;
  final int mindsetConfidence;
  final int mindsetControl;
  final String overallEmoji;
  final String mindsetColor;

  const CaddyPlayMindsetAggregate({
    required this.mindsetFocus,
    required this.mindsetConfidence,
    required this.mindsetControl,
    required this.overallEmoji,
    required this.mindsetColor,
  });
}

int focusScore(CaddyPlayFocusChip? chip) {
  switch (chip) {
    case CaddyPlayFocusChip.clear:
      return 90;
    case CaddyPlayFocusChip.neutral:
      return 65;
    case CaddyPlayFocusChip.distracted:
      return 35;
    case null:
      return 65;
  }
}

int resultScore(CaddyPlayResultChip? chip) {
  switch (chip) {
    case CaddyPlayResultChip.good:
      return 85;
    case CaddyPlayResultChip.ok:
      return 60;
    case CaddyPlayResultChip.poor:
      return 35;
    case null:
      return 60;
  }
}

int routineScore(CaddyPlayRoutineChip? chip) {
  switch (chip) {
    case CaddyPlayRoutineChip.yes:
      return 85;
    case CaddyPlayRoutineChip.partial:
      return 60;
    case CaddyPlayRoutineChip.no:
      return 40;
    case null:
      return 60;
  }
}

int emotionScore(CaddyPlayEmotionChip? chip) {
  switch (chip) {
    case CaddyPlayEmotionChip.calm:
      return 85;
    case CaddyPlayEmotionChip.pressured:
      return 55;
    case CaddyPlayEmotionChip.frustrated:
      return 35;
    case null:
      return 55;
  }
}

CaddyPlayMindsetAggregate aggregateMindset(List<CaddyPlayLog> logs) {
  if (logs.isEmpty) {
    return const CaddyPlayMindsetAggregate(
      mindsetFocus: 65,
      mindsetConfidence: 60,
      mindsetControl: 62,
      overallEmoji: '😐',
      mindsetColor: '#FFC107',
    );
  }

  final focusValues = logs.map((e) => focusScore(e.focus)).toList();
  final confidenceValues = logs
      .map((e) =>
          ((resultScore(e.result) + emotionScore(e.emotion)) / 2).round())
      .toList();
  final controlValues = logs
      .map((e) => ((focusScore(e.focus) + routineScore(e.routine)) / 2).round())
      .toList();

  final focus = _avg(focusValues);
  final confidence = _avg(confidenceValues);
  final control = _avg(controlValues);
  final overall = ((focus + confidence + control) / 3).round();

  return CaddyPlayMindsetAggregate(
    mindsetFocus: focus,
    mindsetConfidence: confidence,
    mindsetControl: control,
    overallEmoji: _emojiForScore(overall),
    mindsetColor: _colorForScore(overall),
  );
}

int _avg(List<int> values) {
  if (values.isEmpty) return 0;
  final sum = values.fold<int>(0, (prev, curr) => prev + curr);
  return (sum / values.length).round();
}

String _emojiForScore(int score) {
  if (score >= 80) return '😌';
  if (score >= 60) return '🙂';
  if (score >= 45) return '😐';
  return '😟';
}

String _colorForScore(int score) {
  if (score >= 80) return '#4CAF50';
  if (score >= 60) return '#8BC34A';
  if (score >= 45) return '#FFC107';
  return '#EF5350';
}

String bestCueFromLogs(List<CaddyPlayLog> logs) {
  if (logs.isEmpty) return 'Routine First';
  final counters = <String, int>{};
  for (final log in logs) {
    final label = log.routine?.name ?? 'partial';
    counters[label] = (counters[label] ?? 0) + 1;
  }
  return counters.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key
      .replaceAll('_', ' ');
}

List<String> recoveryHolesFromLogs(List<CaddyPlayLog> logs) {
  final grouped = <int, List<CaddyPlayLog>>{};
  for (final log in logs) {
    final hole = log.holeNumber;
    if (hole == null) continue;
    grouped.putIfAbsent(hole, () => <CaddyPlayLog>[]).add(log);
  }

  final recoveryHoles = <String>[];
  final sortedHoles = grouped.keys.toList()..sort();
  for (final hole in sortedHoles) {
    final holeLogs = grouped[hole]!;
    final start = holeLogs.first;
    final end = holeLogs.last;
    final startScore =
        (resultScore(start.result) + emotionScore(start.emotion)) / 2;
    final endScore = (resultScore(end.result) + emotionScore(end.emotion)) / 2;
    if (endScore - startScore >= 20) {
      recoveryHoles.add('H$hole');
    }
  }

  return recoveryHoles;
}

CaddyPlayChipSelection inferChipSelectionFromTranscript(String transcript) {
  final text = transcript.toLowerCase();

  CaddyPlayResultChip? result;
  if (text.contains('good') ||
      text.contains('solid') ||
      text.contains('great')) {
    result = CaddyPlayResultChip.good;
  } else if (text.contains('ok') ||
      text.contains('fine') ||
      text.contains('average')) {
    result = CaddyPlayResultChip.ok;
  } else if (text.contains('poor') ||
      text.contains('bad') ||
      text.contains('miss')) {
    result = CaddyPlayResultChip.poor;
  }

  CaddyPlayFocusChip? focus;
  if (text.contains('clear') ||
      text.contains('locked in') ||
      text.contains('focused')) {
    focus = CaddyPlayFocusChip.clear;
  } else if (text.contains('neutral') || text.contains('steady')) {
    focus = CaddyPlayFocusChip.neutral;
  } else if (text.contains('rushed') ||
      text.contains('distracted') ||
      text.contains('lost focus')) {
    focus = CaddyPlayFocusChip.distracted;
  }

  CaddyPlayRoutineChip? routine;
  if (text.contains('routine') &&
      (text.contains('yes') ||
          text.contains('full') ||
          text.contains('complete'))) {
    routine = CaddyPlayRoutineChip.yes;
  } else if (text.contains('partial') || text.contains('almost')) {
    routine = CaddyPlayRoutineChip.partial;
  } else if (text.contains('no routine') || text.contains('skipped routine')) {
    routine = CaddyPlayRoutineChip.no;
  }

  CaddyPlayEmotionChip? emotion;
  if (text.contains('calm') || text.contains('composed')) {
    emotion = CaddyPlayEmotionChip.calm;
  } else if (text.contains('pressure') || text.contains('tense')) {
    emotion = CaddyPlayEmotionChip.pressured;
  } else if (text.contains('frustrated') || text.contains('angry')) {
    emotion = CaddyPlayEmotionChip.frustrated;
  }

  return CaddyPlayChipSelection(
    result: result,
    focus: focus,
    routine: routine,
    emotion: emotion,
  );
}

String chipLabel(Enum? value) {
  if (value == null) return 'Unknown';
  final label = value.name.replaceAll('_', ' ');
  return label.substring(0, 1).toUpperCase() + label.substring(1);
}

CaddyPlayMode _modeFromString(String? value) {
  if (value == CaddyPlayMode.practice.name) return CaddyPlayMode.practice;
  return CaddyPlayMode.play;
}

CaddyPlaySessionStatus _statusFromString(String? value) {
  if (value == CaddyPlaySessionStatus.completed.name) {
    return CaddyPlaySessionStatus.completed;
  }
  if (value == CaddyPlaySessionStatus.cancelled.name) {
    return CaddyPlaySessionStatus.cancelled;
  }
  return CaddyPlaySessionStatus.active;
}

CaddyPlayResultChip? _resultFromString(String? value) {
  for (final chip in CaddyPlayResultChip.values) {
    if (chip.name == value) return chip;
  }
  return null;
}

CaddyPlayFocusChip? _focusFromString(String? value) {
  for (final chip in CaddyPlayFocusChip.values) {
    if (chip.name == value) return chip;
  }
  return null;
}

CaddyPlayRoutineChip? _routineFromString(String? value) {
  for (final chip in CaddyPlayRoutineChip.values) {
    if (chip.name == value) return chip;
  }
  return null;
}

CaddyPlayEmotionChip? _emotionFromString(String? value) {
  for (final chip in CaddyPlayEmotionChip.values) {
    if (chip.name == value) return chip;
  }
  return null;
}

DateTime? timestampToDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

int clampHole(int hole, int total) {
  return math.max(1, math.min(total, hole));
}
