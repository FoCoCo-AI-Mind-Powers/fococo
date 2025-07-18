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

  // "googleSubscriptionId" field.
  String? _googleSubscriptionId;
  String get googleSubscriptionId => _googleSubscriptionId ?? '';
  bool hasGoogleSubscriptionId() => _googleSubscriptionId != null;

  // "tokensRemaining" field.
  int? _tokensRemaining;
  int get tokensRemaining => _tokensRemaining ?? 0;
  bool hasTokensRemaining() => _tokensRemaining != null;

  // "totalAIInsightsGenerated" field.
  int? _totalAIInsightsGenerated;
  int get totalAIInsightsGenerated => _totalAIInsightsGenerated ?? 0;
  bool hasTotalAIInsightsGenerated() => _totalAIInsightsGenerated != null;

  // "mentalPerformanceScore" field.
  double? _mentalPerformanceScore;
  double get mentalPerformanceScore => _mentalPerformanceScore ?? 0.0;
  bool hasMentalPerformanceScore() => _mentalPerformanceScore != null;

  // "coachingStreak" field.
  int? _coachingStreak;
  int get coachingStreak => _coachingStreak ?? 0;
  bool hasCoachingStreak() => _coachingStreak != null;

  // "totalModulesCompleted" field.
  int? _totalModulesCompleted;
  int get totalModulesCompleted => _totalModulesCompleted ?? 0;
  bool hasTotalModulesCompleted() => _totalModulesCompleted != null;

  // "notificationSettings" field.
  NotificationSettingsStruct? _notificationSettings;
  NotificationSettingsStruct get notificationSettings =>
      _notificationSettings ?? NotificationSettingsStruct();
  bool hasNotificationSettings() => _notificationSettings != null;

  // "audioPreferences" field.
  AudioPreferencesStruct? _audioPreferences;
  AudioPreferencesStruct get audioPreferences =>
      _audioPreferences ?? AudioPreferencesStruct();
  bool hasAudioPreferences() => _audioPreferences != null;

  // "timezone" field.
  String? _timezone;
  String get timezone => _timezone ?? '';
  bool hasTimezone() => _timezone != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "lastActive" field.
  DateTime? _lastActive;
  DateTime? get lastActive => _lastActive;
  bool hasLastActive() => _lastActive != null;

  // "notificationTokens" field.
  List<String>? _notificationTokens;
  List<String> get notificationTokens => _notificationTokens ?? const [];
  bool hasNotificationTokens() => _notificationTokens != null;

  // "dataProcessingConsent" field.
  bool? _dataProcessingConsent;
  bool get dataProcessingConsent => _dataProcessingConsent ?? false;
  bool hasDataProcessingConsent() => _dataProcessingConsent != null;

  // "marketingConsent" field.
  bool? _marketingConsent;
  bool get marketingConsent => _marketingConsent ?? false;
  bool hasMarketingConsent() => _marketingConsent != null;

  // "lastPrivacyPolicyAccepted" field.
  DateTime? _lastPrivacyPolicyAccepted;
  DateTime? get lastPrivacyPolicyAccepted => _lastPrivacyPolicyAccepted;
  bool hasLastPrivacyPolicyAccepted() => _lastPrivacyPolicyAccepted != null;

  // "appVersion" field.
  String? _appVersion;
  String get appVersion => _appVersion ?? '';
  bool hasAppVersion() => _appVersion != null;

  // "platform" field.
  String? _platform;
  String get platform => _platform ?? '';
  bool hasPlatform() => _platform != null;

  // "referralSource" field.
  String? _referralSource;
  String get referralSource => _referralSource ?? '';
  bool hasReferralSource() => _referralSource != null;

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
    _googleSubscriptionId = snapshotData['googleSubscriptionId'] as String?;
    _tokensRemaining = castToType<int>(snapshotData['tokensRemaining']);
    _totalAIInsightsGenerated = castToType<int>(snapshotData['totalAIInsightsGenerated']);
    _mentalPerformanceScore = castToType<double>(snapshotData['mentalPerformanceScore']);
    _coachingStreak = castToType<int>(snapshotData['coachingStreak']);
    _totalModulesCompleted = castToType<int>(snapshotData['totalModulesCompleted']);
    _notificationSettings = snapshotData['notificationSettings'] is NotificationSettingsStruct
        ? snapshotData['notificationSettings']
        : NotificationSettingsStruct.maybeFromMap(snapshotData['notificationSettings']);
    _audioPreferences = snapshotData['audioPreferences'] is AudioPreferencesStruct
        ? snapshotData['audioPreferences']
        : AudioPreferencesStruct.maybeFromMap(snapshotData['audioPreferences']);
    _timezone = snapshotData['timezone'] as String?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _lastActive = snapshotData['lastActive'] as DateTime?;
    _notificationTokens = getDataList(snapshotData['notificationTokens']);
    _dataProcessingConsent = snapshotData['dataProcessingConsent'] as bool?;
    _marketingConsent = snapshotData['marketingConsent'] as bool?;
    _lastPrivacyPolicyAccepted = snapshotData['lastPrivacyPolicyAccepted'] as DateTime?;
    _appVersion = snapshotData['appVersion'] as String?;
    _platform = snapshotData['platform'] as String?;
    _referralSource = snapshotData['referralSource'] as String?;
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
  AudioPreferencesStruct? audioPreferences,
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
      'audioPreferences': AudioPreferencesStruct().toMap(),
      'currentMembershipTier': currentMembershipTier,
      'appleSubscriptionId': appleSubscriptionId,
    }.withoutNulls,
  );

  // Handle nested data for "varkPreferences" field.
  addVarkPreferencesStructData(
      firestoreData, varkPreferences, 'varkPreferences');

  // Handle nested data for "audioPreferences" field.
  addAudioPreferencesStructData(
      firestoreData, audioPreferences, 'audioPreferences');

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
