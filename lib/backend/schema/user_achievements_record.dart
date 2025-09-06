import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class UserAchievementsRecord extends FirestoreRecord {
  UserAchievementsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "achievementId" field.
  String? _achievementId;
  String get achievementId => _achievementId ?? '';
  bool hasAchievementId() => _achievementId != null;

  // "earnedDate" field.
  DateTime? _earnedDate;
  DateTime? get earnedDate => _earnedDate;
  bool hasEarnedDate() => _earnedDate != null;

  // "progress" field.
  double? _progress;
  double get progress => _progress ?? 0.0;
  bool hasProgress() => _progress != null;

  // "currentValue" field.
  double? _currentValue;
  double get currentValue => _currentValue ?? 0.0;
  bool hasCurrentValue() => _currentValue != null;

  // "targetValue" field.
  double? _targetValue;
  double get targetValue => _targetValue ?? 0.0;
  bool hasTargetValue() => _targetValue != null;

  // "isCompleted" field.
  bool? _isCompleted;
  bool get isCompleted => _isCompleted ?? false;
  bool hasIsCompleted() => _isCompleted != null;

  // "notificationSent" field.
  bool? _notificationSent;
  bool get notificationSent => _notificationSent ?? false;
  bool hasNotificationSent() => _notificationSent != null;

  // "relatedRoundId" field.
  String? _relatedRoundId;
  String get relatedRoundId => _relatedRoundId ?? '';
  bool hasRelatedRoundId() => _relatedRoundId != null;

  // "relatedSessionId" field.
  String? _relatedSessionId;
  String get relatedSessionId => _relatedSessionId ?? '';
  bool hasRelatedSessionId() => _relatedSessionId != null;

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
    _achievementId = snapshotData['achievementId'] as String?;
    _earnedDate = snapshotData['earnedDate'] as DateTime?;
    _progress = castToType<double>(snapshotData['progress']);
    _currentValue = castToType<double>(snapshotData['currentValue']);
    _targetValue = castToType<double>(snapshotData['targetValue']);
    _isCompleted = snapshotData['isCompleted'] as bool?;
    _notificationSent = snapshotData['notificationSent'] as bool?;
    _relatedRoundId = snapshotData['relatedRoundId'] as String?;
    _relatedSessionId = snapshotData['relatedSessionId'] as String?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user_achievements');

  static Stream<UserAchievementsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserAchievementsRecord.fromSnapshot(s));

  static Future<UserAchievementsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => UserAchievementsRecord.fromSnapshot(s));

  static UserAchievementsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UserAchievementsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserAchievementsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserAchievementsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserAchievementsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserAchievementsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
