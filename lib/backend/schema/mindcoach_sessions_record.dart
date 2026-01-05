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

  // "coachingText" field.
  String? _coachingText;
  String get coachingText => _coachingText ?? '';
  bool hasCoachingText() => _coachingText != null;

  // "followUpQuestion" field.
  String? _followUpQuestion;
  String get followUpQuestion => _followUpQuestion ?? '';
  bool hasFollowUpQuestion() => _followUpQuestion != null;

  // "mindsetBefore" field.
  String? _mindsetBefore;
  String get mindsetBefore => _mindsetBefore ?? '';
  bool hasMindsetBefore() => _mindsetBefore != null;

  // "mindsetAfter" field.
  String? _mindsetAfter;
  String get mindsetAfter => _mindsetAfter ?? '';
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
    _mindsetBefore = snapshotData['mindsetBefore'] as String?;
    _mindsetAfter = snapshotData['mindsetAfter'] as String?;
    _context = snapshotData['context'] as Map<String, dynamic>?;
    _successSignalFlags = snapshotData['successSignalFlags'] as Map<String, dynamic>?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
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

