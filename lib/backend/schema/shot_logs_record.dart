import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class ShotLogsRecord extends FirestoreRecord {
  ShotLogsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "roundId" field.
  String? _roundId;
  String get roundId => _roundId ?? '';
  bool hasRoundId() => _roundId != null;

  // "shotId" field.
  String? _shotId;
  String get shotId => _shotId ?? '';
  bool hasShotId() => _shotId != null;

  // "holeNumber" field.
  int? _holeNumber;
  int get holeNumber => _holeNumber ?? 0;
  bool hasHoleNumber() => _holeNumber != null;

  // "clubUsed" field.
  String? _clubUsed;
  String get clubUsed => _clubUsed ?? '';
  bool hasClubUsed() => _clubUsed != null;

  // "distanceAttempted" field.
  double? _distanceAttempted;
  double get distanceAttempted => _distanceAttempted ?? 0.0;
  bool hasDistanceAttempted() => _distanceAttempted != null;

  // "shotShape" field.
  String? _shotShape;
  String get shotShape => _shotShape ?? '';
  bool hasShotShape() => _shotShape != null;

  // "shotOutcome" field.
  String? _shotOutcome;
  String get shotOutcome => _shotOutcome ?? '';
  bool hasShotOutcome() => _shotOutcome != null;

  // "cueUsed" field.
  String? _cueUsed;
  String get cueUsed => _cueUsed ?? '';
  bool hasCueUsed() => _cueUsed != null;

  // "confidenceLevel" field.
  int? _confidenceLevel;
  int get confidenceLevel => _confidenceLevel ?? 0;
  bool hasConfidenceLevel() => _confidenceLevel != null;

  // "windCondition" field.
  String? _windCondition;
  String get windCondition => _windCondition ?? '';
  bool hasWindCondition() => _windCondition != null;

  // "coordinates" field.
  LatLng? _coordinates;
  LatLng? get coordinates => _coordinates;
  bool hasCoordinates() => _coordinates != null;

  // "aiShotInsight" field.
  String? _aiShotInsight;
  String get aiShotInsight => _aiShotInsight ?? '';
  bool hasAiShotInsight() => _aiShotInsight != null;

  // "voiceTranscription" field.
  String? _voiceTranscription;
  String get voiceTranscription => _voiceTranscription ?? '';
  bool hasVoiceTranscription() => _voiceTranscription != null;

  // "nlpProcessed" field.
  bool? _nlpProcessed;
  bool get nlpProcessed => _nlpProcessed ?? false;
  bool hasNlpProcessed() => _nlpProcessed != null;

  // "shotTrend" field.
  String? _shotTrend;
  String get shotTrend => _shotTrend ?? '';
  bool hasShotTrend() => _shotTrend != null;

  // "missPattern" field.
  String? _missPattern;
  String get missPattern => _missPattern ?? '';
  bool hasMissPattern() => _missPattern != null;

  // "performanceRating" field.
  int? _performanceRating;
  int get performanceRating => _performanceRating ?? 0;
  bool hasPerformanceRating() => _performanceRating != null;

  // "clubIcon" field.
  String? _clubIcon;
  String get clubIcon => _clubIcon ?? '';
  bool hasClubIcon() => _clubIcon != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _roundId = snapshotData['roundId'] as String?;
    _shotId = snapshotData['shotId'] as String?;
    _holeNumber = castToType<int>(snapshotData['holeNumber']);
    _clubUsed = snapshotData['clubUsed'] as String?;
    _distanceAttempted = castToType<double>(snapshotData['distanceAttempted']);
    _shotShape = snapshotData['shotShape'] as String?;
    _shotOutcome = snapshotData['shotOutcome'] as String?;
    _cueUsed = snapshotData['cueUsed'] as String?;
    _confidenceLevel = castToType<int>(snapshotData['confidenceLevel']);
    _windCondition = snapshotData['windCondition'] as String?;
    _coordinates = snapshotData['coordinates'] as LatLng?;
    _aiShotInsight = snapshotData['aiShotInsight'] as String?;
    _voiceTranscription = snapshotData['voiceTranscription'] as String?;
    _nlpProcessed = snapshotData['nlpProcessed'] as bool?;
    _shotTrend = snapshotData['shotTrend'] as String?;
    _missPattern = snapshotData['missPattern'] as String?;
    _performanceRating = castToType<int>(snapshotData['performanceRating']);
    _clubIcon = snapshotData['clubIcon'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('shot_logs');

  static Stream<ShotLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ShotLogsRecord.fromSnapshot(s));

  static Future<ShotLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ShotLogsRecord.fromSnapshot(s));

  static ShotLogsRecord fromSnapshot(DocumentSnapshot snapshot) => ShotLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ShotLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ShotLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ShotLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ShotLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

