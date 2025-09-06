import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class RoundLogsRecord extends FirestoreRecord {
  RoundLogsRecord._(
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

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "courseName" field.
  String? _courseName;
  String get courseName => _courseName ?? '';
  bool hasCourseName() => _courseName != null;

  // "courseType" field.
  String? _courseType;
  String get courseType => _courseType ?? '';
  bool hasCourseType() => _courseType != null;

  // "coordinates" field.
  LatLng? _coordinates;
  LatLng? get coordinates => _coordinates;
  bool hasCoordinates() => _coordinates != null;

  // "mindsetFocus" field.
  int? _mindsetFocus;
  int get mindsetFocus => _mindsetFocus ?? 0;
  bool hasMindsetFocus() => _mindsetFocus != null;

  // "mindsetConfidence" field.
  int? _mindsetConfidence;
  int get mindsetConfidence => _mindsetConfidence ?? 0;
  bool hasMindsetConfidence() => _mindsetConfidence != null;

  // "mindsetControl" field.
  int? _mindsetControl;
  int get mindsetControl => _mindsetControl ?? 0;
  bool hasMindsetControl() => _mindsetControl != null;

  // "bestCue" field.
  String? _bestCue;
  String get bestCue => _bestCue ?? '';
  bool hasBestCue() => _bestCue != null;

  // "recoveryHoles" field.
  List<String>? _recoveryHoles;
  List<String> get recoveryHoles => _recoveryHoles ?? const [];
  bool hasRecoveryHoles() => _recoveryHoles != null;

  // "overallMindsetEmoji" field.
  String? _overallMindsetEmoji;
  String get overallMindsetEmoji => _overallMindsetEmoji ?? '';
  bool hasOverallMindsetEmoji() => _overallMindsetEmoji != null;

  // "technicalSummary" field.
  String? _technicalSummary;
  String get technicalSummary => _technicalSummary ?? '';
  bool hasTechnicalSummary() => _technicalSummary != null;

  // "aiRoundSummary" field.
  String? _aiRoundSummary;
  String get aiRoundSummary => _aiRoundSummary ?? '';
  bool hasAiRoundSummary() => _aiRoundSummary != null;

  // "voiceTranscription" field.
  String? _voiceTranscription;
  String get voiceTranscription => _voiceTranscription ?? '';
  bool hasVoiceTranscription() => _voiceTranscription != null;

  // "nlpProcessed" field.
  bool? _nlpProcessed;
  bool get nlpProcessed => _nlpProcessed ?? false;
  bool hasNlpProcessed() => _nlpProcessed != null;

  // "isLive" field.
  bool? _isLive;
  bool get isLive => _isLive ?? false;
  bool hasIsLive() => _isLive != null;

  // "mindsetColor" field.
  String? _mindsetColor;
  String get mindsetColor => _mindsetColor ?? '';
  bool hasMindsetColor() => _mindsetColor != null;

  // "linkedGolfRoundId" field.
  String? _linkedGolfRoundId;
  String get linkedGolfRoundId => _linkedGolfRoundId ?? '';
  bool hasLinkedGolfRoundId() => _linkedGolfRoundId != null;

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
    _date = snapshotData['date'] as DateTime?;
    _courseName = snapshotData['courseName'] as String?;
    _courseType = snapshotData['courseType'] as String?;
    _coordinates = snapshotData['coordinates'] as LatLng?;
    _mindsetFocus = castToType<int>(snapshotData['mindsetFocus']);
    _mindsetConfidence = castToType<int>(snapshotData['mindsetConfidence']);
    _mindsetControl = castToType<int>(snapshotData['mindsetControl']);
    _bestCue = snapshotData['bestCue'] as String?;
    _recoveryHoles = getDataList(snapshotData['recoveryHoles']);
    _overallMindsetEmoji = snapshotData['overallMindsetEmoji'] as String?;
    _technicalSummary = snapshotData['technicalSummary'] as String?;
    _aiRoundSummary = snapshotData['aiRoundSummary'] as String?;
    _voiceTranscription = snapshotData['voiceTranscription'] as String?;
    _nlpProcessed = snapshotData['nlpProcessed'] as bool?;
    _isLive = snapshotData['isLive'] as bool?;
    _mindsetColor = snapshotData['mindsetColor'] as String?;
    _linkedGolfRoundId = snapshotData['linkedGolfRoundId'] as String?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('round_logs');

  static Stream<RoundLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => RoundLogsRecord.fromSnapshot(s));

  static Future<RoundLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => RoundLogsRecord.fromSnapshot(s));

  static RoundLogsRecord fromSnapshot(DocumentSnapshot snapshot) => RoundLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static RoundLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      RoundLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'RoundLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is RoundLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

