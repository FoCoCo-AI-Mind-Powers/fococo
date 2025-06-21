import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "displayName" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "profileImageUrl" field.
  String? _profileImageUrl;
  String get profileImageUrl => _profileImageUrl ?? '';
  bool hasProfileImageUrl() => _profileImageUrl != null;

  // "handicap" field.
  double? _handicap;
  double get handicap => _handicap ?? 0.0;
  bool hasHandicap() => _handicap != null;

  // "golfExperience" field.
  String? _golfExperience;
  String get golfExperience => _golfExperience ?? '';
  bool hasGolfExperience() => _golfExperience != null;

  // "homeClub" field.
  String? _homeClub;
  String get homeClub => _homeClub ?? '';
  bool hasHomeClub() => _homeClub != null;

  // "varkPreferences" field.
  VarkPreferencesStruct? _varkPreferences;
  VarkPreferencesStruct get varkPreferences =>
      _varkPreferences ?? VarkPreferencesStruct();
  bool hasVarkPreferences() => _varkPreferences != null;

  // "currentMembershipTier" field.
  String? _currentMembershipTier;
  String get currentMembershipTier => _currentMembershipTier ?? '';
  bool hasCurrentMembershipTier() => _currentMembershipTier != null;

  // "appleSubscriptionId" field.
  String? _appleSubscriptionId;
  String get appleSubscriptionId => _appleSubscriptionId ?? '';
  bool hasAppleSubscriptionId() => _appleSubscriptionId != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['displayName'] as String?;
    _profileImageUrl = snapshotData['profileImageUrl'] as String?;
    _handicap = castToType<double>(snapshotData['handicap']);
    _golfExperience = snapshotData['golfExperience'] as String?;
    _homeClub = snapshotData['homeClub'] as String?;
    _varkPreferences = snapshotData['varkPreferences'] is VarkPreferencesStruct
        ? snapshotData['varkPreferences']
        : VarkPreferencesStruct.maybeFromMap(snapshotData['varkPreferences']);
    _currentMembershipTier = snapshotData['currentMembershipTier'] as String?;
    _appleSubscriptionId = snapshotData['appleSubscriptionId'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) => UserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserRecordData({
  String? email,
  String? displayName,
  String? profileImageUrl,
  double? handicap,
  String? golfExperience,
  String? homeClub,
  VarkPreferencesStruct? varkPreferences,
  String? currentMembershipTier,
  String? appleSubscriptionId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'handicap': handicap,
      'golfExperience': golfExperience,
      'homeClub': homeClub,
      'varkPreferences': VarkPreferencesStruct().toMap(),
      'currentMembershipTier': currentMembershipTier,
      'appleSubscriptionId': appleSubscriptionId,
    }.withoutNulls,
  );

  // Handle nested data for "varkPreferences" field.
  addVarkPreferencesStructData(
      firestoreData, varkPreferences, 'varkPreferences');

  return firestoreData;
}

class UserRecordDocumentEquality implements Equality<UserRecord> {
  const UserRecordDocumentEquality();

  @override
  bool equals(UserRecord? e1, UserRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.profileImageUrl == e2?.profileImageUrl &&
        e1?.handicap == e2?.handicap &&
        e1?.golfExperience == e2?.golfExperience &&
        e1?.homeClub == e2?.homeClub &&
        e1?.varkPreferences == e2?.varkPreferences &&
        e1?.currentMembershipTier == e2?.currentMembershipTier &&
        e1?.appleSubscriptionId == e2?.appleSubscriptionId;
  }

  @override
  int hash(UserRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.profileImageUrl,
        e?.handicap,
        e?.golfExperience,
        e?.homeClub,
        e?.varkPreferences,
        e?.currentMembershipTier,
        e?.appleSubscriptionId
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}
