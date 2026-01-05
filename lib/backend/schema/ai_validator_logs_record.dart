import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class AiValidatorLogsRecord extends FirestoreRecord {
  AiValidatorLogsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "templateIdRequested" field.
  String? _templateIdRequested;
  String get templateIdRequested => _templateIdRequested ?? '';
  bool hasTemplateIdRequested() => _templateIdRequested != null;

  // "templateIdReturned" field.
  String? _templateIdReturned;
  String get templateIdReturned => _templateIdReturned ?? '';
  bool hasTemplateIdReturned() => _templateIdReturned != null;

  // "validatorStatus" field.
  String? _validatorStatus;
  String get validatorStatus => _validatorStatus ?? '';
  bool hasValidatorStatus() => _validatorStatus != null;

  // "failedRules" field.
  List<String>? _failedRules;
  List<String> get failedRules => _failedRules ?? const [];
  bool hasFailedRules() => _failedRules != null;

  // "replacements" field - stored as Map
  Map<String, dynamic>? _replacements;
  Map<String, dynamic> get replacements => _replacements ?? {};
  bool hasReplacements() => _replacements != null;

  // "modelVersion" field.
  String? _modelVersion;
  String get modelVersion => _modelVersion ?? '';
  bool hasModelVersion() => _modelVersion != null;

  // "promptVersion" field.
  String? _promptVersion;
  String get promptVersion => _promptVersion ?? '';
  bool hasPromptVersion() => _promptVersion != null;

  // "contentFlags" field.
  List<String>? _contentFlags;
  List<String> get contentFlags => _contentFlags ?? const [];
  bool hasContentFlags() => _contentFlags != null;

  // "sessionId" field (optional - links to mindcoach_sessions).
  String? _sessionId;
  String get sessionId => _sessionId ?? '';
  bool hasSessionId() => _sessionId != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  void _initializeFields() {
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _userId = snapshotData['userId'] as String?;
    _templateIdRequested = snapshotData['templateIdRequested'] as String?;
    _templateIdReturned = snapshotData['templateIdReturned'] as String?;
    _validatorStatus = snapshotData['validatorStatus'] as String?;
    _failedRules = getDataList(snapshotData['failedRules']);
    _replacements = snapshotData['replacements'] as Map<String, dynamic>?;
    _modelVersion = snapshotData['modelVersion'] as String?;
    _promptVersion = snapshotData['promptVersion'] as String?;
    _contentFlags = getDataList(snapshotData['contentFlags']);
    _sessionId = snapshotData['sessionId'] as String?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ai_validator_logs');

  static Stream<AiValidatorLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AiValidatorLogsRecord.fromSnapshot(s));

  static Future<AiValidatorLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AiValidatorLogsRecord.fromSnapshot(s));

  static AiValidatorLogsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AiValidatorLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AiValidatorLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AiValidatorLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AiValidatorLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AiValidatorLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}






