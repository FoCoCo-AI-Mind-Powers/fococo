import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/structs/achievement_criteria_struct.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class AchievementsRecord extends FirestoreRecord {
  AchievementsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "achievementId" field.
  String? _achievementId;
  String get achievementId => _achievementId ?? '';
  bool hasAchievementId() => _achievementId != null;

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

  // "tier" field.
  String? _tier;
  String get tier => _tier ?? '';
  bool hasTier() => _tier != null;

  // "iconName" field.
  String? _iconName;
  String get iconName => _iconName ?? '';
  bool hasIconName() => _iconName != null;

  // "iconUrl" field.
  String? _iconUrl;
  String get iconUrl => _iconUrl ?? '';
  bool hasIconUrl() => _iconUrl != null;

  // "criteria" field.
  AchievementCriteriaStruct? _criteria;
  AchievementCriteriaStruct get criteria =>
      _criteria ?? AchievementCriteriaStruct();
  bool hasCriteria() => _criteria != null;

  // "points" field.
  int? _points;
  int get points => _points ?? 0;
  bool hasPoints() => _points != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "isSecret" field.
  bool? _isSecret;
  bool get isSecret => _isSecret ?? false;
  bool hasIsSecret() => _isSecret != null;

  // "order" field.
  int? _order;
  int get order => _order ?? 0;
  bool hasOrder() => _order != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  void _initializeFields() {
    _achievementId = snapshotData['achievementId'] as String?;
    _title = snapshotData['title'] as String?;
    _description = snapshotData['description'] as String?;
    _category = snapshotData['category'] as String?;
    _tier = snapshotData['tier'] as String?;
    _iconName = snapshotData['iconName'] as String?;
    _iconUrl = snapshotData['iconUrl'] as String?;
    _criteria = snapshotData['criteria'] is AchievementCriteriaStruct
        ? snapshotData['criteria']
        : AchievementCriteriaStruct.maybeFromMap(snapshotData['criteria']);
    _points = castToType<int>(snapshotData['points']);
    _isActive = snapshotData['isActive'] as bool?;
    _isSecret = snapshotData['isSecret'] as bool?;
    _order = castToType<int>(snapshotData['order']);
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('achievements');

  static Stream<AchievementsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AchievementsRecord.fromSnapshot(s));

  static Future<AchievementsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AchievementsRecord.fromSnapshot(s));

  static AchievementsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AchievementsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AchievementsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AchievementsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AchievementsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AchievementsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
