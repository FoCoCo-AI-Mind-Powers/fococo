import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class MindcoachSessionsRecord extends FirestoreRecord {
  MindcoachSessionsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "templateId" field.
  String? _templateId;
  String get templateId => _templateId ?? '';
  bool hasTemplateId() => _templateId != null;

  // "routineType" field.
  String? _routineType;
  String get routineType => _routineType ?? '';
  bool hasRoutineType() => _routineType != null;

  // "cueUsed" field.
  String? _cueUsed;
  String get cueUsed => _cueUsed ?? '';
  bool hasCueUsed() => _cueUsed != null;

  // "deliveryLength" field.
  String? _deliveryLength;
  String get deliveryLength => _deliveryLength ?? '';
  bool hasDeliveryLength() => _deliveryLength != null;

  // "contentId" field.
  String? _contentId;
  String get contentId => _contentId ?? '';
  bool hasContentId() => _contentId != null;

  // "scenarioTag" field.
  String? _scenarioTag;
  String get scenarioTag => _scenarioTag ?? '';
  bool hasScenarioTag() => _scenarioTag != null;

  // "varkMode" field.
  String? _varkMode;
  String get varkMode => _varkMode ?? 'ReadWrite';
  bool hasVarkMode() => _varkMode != null;

  // "level" field.
  String? _level;
  String get level => _level ?? 'Foundation';
  bool hasLevel() => _level != null;

  // "length" field (alternative to deliveryLength).
  String? _length;
  String get length => _length ?? _deliveryLength ?? 'standard';
  bool hasLength() => _length != null;

  // "sessionType" field.
  String? _sessionType;
  String get sessionType => _sessionType ?? 'coaching';
  bool hasSessionType() => _sessionType != null;

  // "userResponse" field.
  String? _userResponse;
  String get userResponse => _userResponse ?? '';
  bool hasUserResponse() => _userResponse != null;

  // "coachingText" field.
  String? _coachingText;
  String get coachingText => _coachingText ?? '';
  bool hasCoachingText() => _coachingText != null;

  // "followUpQuestion" field.
  String? _followUpQuestion;
  String get followUpQuestion => _followUpQuestion ?? '';
  bool hasFollowUpQuestion() => _followUpQuestion != null;

  // "mindsetBefore" field - now supports both int and String for migration
  dynamic _mindsetBefore;
  int get mindsetBeforeInt {
    if (_mindsetBefore is int) return _mindsetBefore as int;
    if (_mindsetBefore is String) {
      final parsed = int.tryParse(_mindsetBefore);
      return parsed ?? 3; // Default to 3
    }
    return 3;
  }
  String get mindsetBefore => _mindsetBefore?.toString() ?? '3';
  bool hasMindsetBefore() => _mindsetBefore != null;

  // "mindsetAfter" field - now supports both int and String for migration
  dynamic _mindsetAfter;
  int? get mindsetAfterInt {
    if (_mindsetAfter == null) return null;
    if (_mindsetAfter is int) return _mindsetAfter as int;
    if (_mindsetAfter is String) {
      return int.tryParse(_mindsetAfter);
    }
    return null;
  }
  String get mindsetAfter => _mindsetAfter?.toString() ?? '';
  bool hasMindsetAfter() => _mindsetAfter != null;

  // "context" field - stored as Map
  Map<String, dynamic>? _context;
  Map<String, dynamic> get context => _context ?? {};
  bool hasContext() => _context != null;

  // "successSignalFlags" field - stored as Map
  Map<String, dynamic>? _successSignalFlags;
  Map<String, dynamic> get successSignalFlags => _successSignalFlags ?? {};
  bool hasSuccessSignalFlags() => _successSignalFlags != null;

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
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _templateId = snapshotData['templateId'] as String?;
    _routineType = snapshotData['routineType'] as String?;
    _cueUsed = snapshotData['cueUsed'] as String?;
    _deliveryLength = snapshotData['deliveryLength'] as String?;
    _coachingText = snapshotData['coachingText'] as String?;
    _followUpQuestion = snapshotData['followUpQuestion'] as String?;
    // Support both int and String for mindsetBefore/After during migration
    _mindsetBefore = snapshotData['mindsetBefore'];
    _mindsetAfter = snapshotData['mindsetAfter'];
    _context = snapshotData['context'] as Map<String, dynamic>?;
    _successSignalFlags = snapshotData['successSignalFlags'] as Map<String, dynamic>?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
    // New fields
    _contentId = snapshotData['contentId'] as String?;
    _scenarioTag = snapshotData['scenarioTag'] as String?;
    _varkMode = snapshotData['varkMode'] as String?;
    _level = snapshotData['level'] as String?;
    _length = snapshotData['length'] as String?;
    _sessionType = snapshotData['sessionType'] as String?;
    _userResponse = snapshotData['userResponse'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mindcoach_sessions');

  static Stream<MindcoachSessionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MindcoachSessionsRecord.fromSnapshot(s));

  static Future<MindcoachSessionsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MindcoachSessionsRecord.fromSnapshot(s));

  static MindcoachSessionsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MindcoachSessionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MindcoachSessionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MindcoachSessionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MindcoachSessionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MindcoachSessionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

