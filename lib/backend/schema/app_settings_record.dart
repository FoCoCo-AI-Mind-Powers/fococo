import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

class AppSettingsRecord extends FirestoreRecord {
  AppSettingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "appVersion" field.
  String? _appVersion;
  String get appVersion => _appVersion ?? '';
  bool hasAppVersion() => _appVersion != null;

  // "buildNumber" field.
  String? _buildNumber;
  String get buildNumber => _buildNumber ?? '';
  bool hasBuildNumber() => _buildNumber != null;

  // "minSupportedVersion" field.
  String? _minSupportedVersion;
  String get minSupportedVersion => _minSupportedVersion ?? '';
  bool hasMinSupportedVersion() => _minSupportedVersion != null;

  // "forceUpdate" field.
  bool? _forceUpdate;
  bool get forceUpdate => _forceUpdate ?? false;
  bool hasForceUpdate() => _forceUpdate != null;

  // "maintenanceMode" field.
  bool? _maintenanceMode;
  bool get maintenanceMode => _maintenanceMode ?? false;
  bool hasMaintenanceMode() => _maintenanceMode != null;

  // "maintenanceMessage" field.
  String? _maintenanceMessage;
  String get maintenanceMessage => _maintenanceMessage ?? '';
  bool hasMaintenanceMessage() => _maintenanceMessage != null;

  // "featureFlags" field.
  Map<String, dynamic>? _featureFlags;
  Map<String, dynamic> get featureFlags => _featureFlags ?? {};
  bool hasFeatureFlags() => _featureFlags != null;

  // "aiTokenCosts" field.
  Map<String, dynamic>? _aiTokenCosts;
  Map<String, dynamic> get aiTokenCosts => _aiTokenCosts ?? {};
  bool hasAiTokenCosts() => _aiTokenCosts != null;

  // "subscriptionPricing" field.
  Map<String, dynamic>? _subscriptionPricing;
  Map<String, dynamic> get subscriptionPricing => _subscriptionPricing ?? {};
  bool hasSubscriptionPricing() => _subscriptionPricing != null;

  // "supportedPlatforms" field.
  List<String>? _supportedPlatforms;
  List<String> get supportedPlatforms => _supportedPlatforms ?? const [];
  bool hasSupportedPlatforms() => _supportedPlatforms != null;

  // "apiEndpoints" field.
  Map<String, dynamic>? _apiEndpoints;
  Map<String, dynamic> get apiEndpoints => _apiEndpoints ?? {};
  bool hasApiEndpoints() => _apiEndpoints != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  // "biometricSettings" field.
  Map<String, dynamic>? _biometricSettings;
  Map<String, dynamic> get biometricSettings => _biometricSettings ?? {};
  bool hasBiometricSettings() => _biometricSettings != null;

  // "securitySettings" field.
  Map<String, dynamic>? _securitySettings;
  Map<String, dynamic> get securitySettings => _securitySettings ?? {};
  bool hasSecuritySettings() => _securitySettings != null;

  void _initializeFields() {
    _appVersion = snapshotData['appVersion'] as String?;
    _buildNumber = snapshotData['buildNumber'] as String?;
    _minSupportedVersion = snapshotData['minSupportedVersion'] as String?;
    _forceUpdate = snapshotData['forceUpdate'] as bool?;
    _maintenanceMode = snapshotData['maintenanceMode'] as bool?;
    _maintenanceMessage = snapshotData['maintenanceMessage'] as String?;
    _featureFlags = snapshotData['featureFlags'] as Map<String, dynamic>?;
    _aiTokenCosts = snapshotData['aiTokenCosts'] as Map<String, dynamic>?;
    _subscriptionPricing =
        snapshotData['subscriptionPricing'] as Map<String, dynamic>?;
    _supportedPlatforms = getDataList(snapshotData['supportedPlatforms']);
    _apiEndpoints = snapshotData['apiEndpoints'] as Map<String, dynamic>?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
    _biometricSettings =
        snapshotData['biometricSettings'] as Map<String, dynamic>?;
    _securitySettings =
        snapshotData['securitySettings'] as Map<String, dynamic>?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('app_settings');

  static Stream<AppSettingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AppSettingsRecord.fromSnapshot(s));

  static Future<AppSettingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AppSettingsRecord.fromSnapshot(s));

  static AppSettingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AppSettingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AppSettingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AppSettingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AppSettingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AppSettingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}
