import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class TrainingPlansRecord extends FirestoreRecord {
  TrainingPlansRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "planId" field.
  String? _planId;
  String get planId => _planId ?? '';
  bool hasPlanId() => _planId != null;

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "modules" field.
  List<String>? _modules;
  List<String> get modules => _modules ?? const [];
  bool hasModules() => _modules != null;

  // "currentModuleIndex" field.
  int? _currentModuleIndex;
  int get currentModuleIndex => _currentModuleIndex ?? 0;
  bool hasCurrentModuleIndex() => _currentModuleIndex != null;

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

  // "completedModules" field.
  List<String>? _completedModules;
  List<String> get completedModules => _completedModules ?? const [];
  bool hasCompletedModules() => _completedModules != null;

  // "totalModules" field.
  int? _totalModules;
  int get totalModules => _totalModules ?? 0;
  bool hasTotalModules() => _totalModules != null;

  // "estimatedDuration" field.
  int? _estimatedDuration;
  int get estimatedDuration => _estimatedDuration ?? 0;
  bool hasEstimatedDuration() => _estimatedDuration != null;

  void _initializeFields() {
    _planId = snapshotData['planId'] as String?;
    _userId = snapshotData['userId'] as String?;
    _title = snapshotData['title'] as String?;
    _description = snapshotData['description'] as String?;
    _modules = getDataList(snapshotData['modules']);
    _currentModuleIndex = castToType<int>(snapshotData['currentModuleIndex']);
    _isActive = snapshotData['isActive'] as bool?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
    _completedModules = getDataList(snapshotData['completedModules']);
    _totalModules = castToType<int>(snapshotData['totalModules']);
    _estimatedDuration = castToType<int>(snapshotData['estimatedDuration']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('training_plans');

  static Stream<TrainingPlansRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TrainingPlansRecord.fromSnapshot(s));

  static Future<TrainingPlansRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TrainingPlansRecord.fromSnapshot(s));

  static TrainingPlansRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TrainingPlansRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TrainingPlansRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TrainingPlansRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TrainingPlansRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TrainingPlansRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

