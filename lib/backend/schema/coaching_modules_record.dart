import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/structs/module_content_versions_struct.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class CoachingModulesRecord extends FirestoreRecord {
  CoachingModulesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "moduleId" field.
  String? _moduleId;
  String get moduleId => _moduleId ?? '';
  bool hasModuleId() => _moduleId != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "pillar" field.
  String? _pillar;
  String get pillar => _pillar ?? '';
  bool hasPillar() => _pillar != null;

  // "difficulty" field.
  String? _difficulty;
  String get difficulty => _difficulty ?? '';
  bool hasDifficulty() => _difficulty != null;

  // "duration" field.
  int? _duration;
  int get duration => _duration ?? 0;
  bool hasDuration() => _duration != null;

  // "varkTags" field.
  List<String>? _varkTags;
  List<String> get varkTags => _varkTags ?? const [];
  bool hasVarkTags() => _varkTags != null;

  // "primaryVarkStyle" field.
  String? _primaryVarkStyle;
  String get primaryVarkStyle => _primaryVarkStyle ?? '';
  bool hasPrimaryVarkStyle() => _primaryVarkStyle != null;

  // "tierRequirement" field.
  String? _tierRequirement;
  String get tierRequirement => _tierRequirement ?? '';
  bool hasTierRequirement() => _tierRequirement != null;

  // "contentVersions" field.
  ModuleContentVersionsStruct? _contentVersions;
  ModuleContentVersionsStruct get contentVersions =>
      _contentVersions ?? ModuleContentVersionsStruct();
  bool hasContentVersions() => _contentVersions != null;

  // "prerequisites" field.
  List<String>? _prerequisites;
  List<String> get prerequisites => _prerequisites ?? const [];
  bool hasPrerequisites() => _prerequisites != null;

  // "learningObjectives" field.
  List<String>? _learningObjectives;
  List<String> get learningObjectives => _learningObjectives ?? const [];
  bool hasLearningObjectives() => _learningObjectives != null;

  // "tags" field.
  List<String>? _tags;
  List<String> get tags => _tags ?? const [];
  bool hasTags() => _tags != null;

  // "thumbnailUrl" field.
  String? _thumbnailUrl;
  String get thumbnailUrl => _thumbnailUrl ?? '';
  bool hasThumbnailUrl() => _thumbnailUrl != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "order" field.
  int? _order;
  int get order => _order ?? 0;
  bool hasOrder() => _order != null;

  // "completionCount" field.
  int? _completionCount;
  int get completionCount => _completionCount ?? 0;
  bool hasCompletionCount() => _completionCount != null;

  // "averageRating" field.
  double? _averageRating;
  double get averageRating => _averageRating ?? 0.0;
  bool hasAverageRating() => _averageRating != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  void _initializeFields() {
    _moduleId = snapshotData['moduleId'] as String?;
    _title = snapshotData['title'] as String?;
    _description = snapshotData['description'] as String?;
    _category = snapshotData['category'] as String?;
    _pillar = snapshotData['pillar'] as String?;
    _difficulty = snapshotData['difficulty'] as String?;
    _duration = castToType<int>(snapshotData['duration']);
    _varkTags = getDataList(snapshotData['varkTags']);
    _primaryVarkStyle = snapshotData['primaryVarkStyle'] as String?;
    _tierRequirement = snapshotData['tierRequirement'] as String?;
    _contentVersions =
        snapshotData['contentVersions'] is ModuleContentVersionsStruct
            ? snapshotData['contentVersions']
            : ModuleContentVersionsStruct.maybeFromMap(
                snapshotData['contentVersions']);
    _prerequisites = getDataList(snapshotData['prerequisites']);
    _learningObjectives = getDataList(snapshotData['learningObjectives']);
    _tags = getDataList(snapshotData['tags']);
    _thumbnailUrl = snapshotData['thumbnailUrl'] as String?;
    _isActive = snapshotData['isActive'] as bool?;
    _order = castToType<int>(snapshotData['order']);
    _completionCount = castToType<int>(snapshotData['completionCount']);
    _averageRating = castToType<double>(snapshotData['averageRating']);
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('coaching_modules');

  static Stream<CoachingModulesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CoachingModulesRecord.fromSnapshot(s));

  static Future<CoachingModulesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CoachingModulesRecord.fromSnapshot(s));

  static CoachingModulesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CoachingModulesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CoachingModulesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CoachingModulesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CoachingModulesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CoachingModulesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
