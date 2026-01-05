import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class MindcoachTemplatesRecord extends FirestoreRecord {
  MindcoachTemplatesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "schemaVersion" field.
  String? _schemaVersion;
  String get schemaVersion => _schemaVersion ?? '';
  bool hasSchemaVersion() => _schemaVersion != null;

  // "templateId" field.
  String? _templateId;
  String get templateId => _templateId ?? '';
  bool hasTemplateId() => _templateId != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "allowedRoutineTypes" field.
  List<String>? _allowedRoutineTypes;
  List<String> get allowedRoutineTypes => _allowedRoutineTypes ?? const [];
  bool hasAllowedRoutineTypes() => _allowedRoutineTypes != null;

  // "allowedCues" field.
  List<String>? _allowedCues;
  List<String> get allowedCues => _allowedCues ?? const [];
  bool hasAllowedCues() => _allowedCues != null;

  // "deliveryLengths" field.
  List<String>? _deliveryLengths;
  List<String> get deliveryLengths => _deliveryLengths ?? const [];
  bool hasDeliveryLengths() => _deliveryLengths != null;

  // "primaryPillar" field.
  String? _primaryPillar;
  String get primaryPillar => _primaryPillar ?? '';
  bool hasPrimaryPillar() => _primaryPillar != null;

  // "triggerMoments" field.
  List<String>? _triggerMoments;
  List<String> get triggerMoments => _triggerMoments ?? const [];
  bool hasTriggerMoments() => _triggerMoments != null;

  // "description" field (optional).
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  void _initializeFields() {
    _schemaVersion = snapshotData['schemaVersion'] as String?;
    _templateId = snapshotData['templateId'] as String?;
    _name = snapshotData['name'] as String?;
    _allowedRoutineTypes = getDataList(snapshotData['allowedRoutineTypes']);
    _allowedCues = getDataList(snapshotData['allowedCues']);
    _deliveryLengths = getDataList(snapshotData['deliveryLengths']);
    _primaryPillar = snapshotData['primaryPillar'] as String?;
    _triggerMoments = getDataList(snapshotData['triggerMoments']);
    _description = snapshotData['description'] as String?;
    _isActive = snapshotData['isActive'] as bool?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mindcoach_templates');

  static Stream<MindcoachTemplatesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MindcoachTemplatesRecord.fromSnapshot(s));

  static Future<MindcoachTemplatesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MindcoachTemplatesRecord.fromSnapshot(s));

  static MindcoachTemplatesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MindcoachTemplatesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MindcoachTemplatesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MindcoachTemplatesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MindcoachTemplatesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MindcoachTemplatesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}






