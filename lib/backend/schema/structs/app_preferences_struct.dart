// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AppPreferencesStruct extends FFFirebaseStruct {
  AppPreferencesStruct({
    String? themeMode,
    bool? hapticFeedbackEnabled,
    String? language,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    String? preferredUnits,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _themeMode = themeMode,
        _hapticFeedbackEnabled = hapticFeedbackEnabled,
        _language = language,
        _analyticsEnabled = analyticsEnabled,
        _crashReportingEnabled = crashReportingEnabled,
        _preferredUnits = preferredUnits,
        super(firestoreUtilData);

  // "themeMode" field.
  String? _themeMode;
  String get themeMode => _themeMode ?? 'system';
  set themeMode(String? val) => _themeMode = val;

  bool hasThemeMode() => _themeMode != null;

  // "hapticFeedbackEnabled" field.
  bool? _hapticFeedbackEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled ?? true;
  set hapticFeedbackEnabled(bool? val) => _hapticFeedbackEnabled = val;

  bool hasHapticFeedbackEnabled() => _hapticFeedbackEnabled != null;

  // "language" field.
  String? _language;
  String get language => _language ?? 'en_US';
  set language(String? val) => _language = val;

  bool hasLanguage() => _language != null;

  // "analyticsEnabled" field.
  bool? _analyticsEnabled;
  bool get analyticsEnabled => _analyticsEnabled ?? true;
  set analyticsEnabled(bool? val) => _analyticsEnabled = val;

  bool hasAnalyticsEnabled() => _analyticsEnabled != null;

  // "crashReportingEnabled" field.
  bool? _crashReportingEnabled;
  bool get crashReportingEnabled => _crashReportingEnabled ?? true;
  set crashReportingEnabled(bool? val) => _crashReportingEnabled = val;

  bool hasCrashReportingEnabled() => _crashReportingEnabled != null;

  // "preferredUnits" field.
  String? _preferredUnits;
  String get preferredUnits => _preferredUnits ?? 'metric';
  set preferredUnits(String? val) => _preferredUnits = val;

  bool hasPreferredUnits() => _preferredUnits != null;

  static AppPreferencesStruct fromMap(Map<String, dynamic> data) =>
      AppPreferencesStruct(
        themeMode: data['themeMode'] as String?,
        hapticFeedbackEnabled: data['hapticFeedbackEnabled'] as bool?,
        language: data['language'] as String?,
        analyticsEnabled: data['analyticsEnabled'] as bool?,
        crashReportingEnabled: data['crashReportingEnabled'] as bool?,
        preferredUnits: data['preferredUnits'] as String?,
      );

  static AppPreferencesStruct? maybeFromMap(dynamic data) => data is Map
      ? AppPreferencesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'themeMode': _themeMode,
        'hapticFeedbackEnabled': _hapticFeedbackEnabled,
        'language': _language,
        'analyticsEnabled': _analyticsEnabled,
        'crashReportingEnabled': _crashReportingEnabled,
        'preferredUnits': _preferredUnits,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'themeMode': serializeParam(
          _themeMode,
          ParamType.String,
        ),
        'hapticFeedbackEnabled': serializeParam(
          _hapticFeedbackEnabled,
          ParamType.bool,
        ),
        'language': serializeParam(
          _language,
          ParamType.String,
        ),
        'analyticsEnabled': serializeParam(
          _analyticsEnabled,
          ParamType.bool,
        ),
        'crashReportingEnabled': serializeParam(
          _crashReportingEnabled,
          ParamType.bool,
        ),
        'preferredUnits': serializeParam(
          _preferredUnits,
          ParamType.String,
        ),
      }.withoutNulls;

  static AppPreferencesStruct fromSerializableMap(Map<String, dynamic> data) =>
      AppPreferencesStruct(
        themeMode: deserializeParam(
          data['themeMode'],
          ParamType.String,
          false,
        ),
        hapticFeedbackEnabled: deserializeParam(
          data['hapticFeedbackEnabled'],
          ParamType.bool,
          false,
        ),
        language: deserializeParam(
          data['language'],
          ParamType.String,
          false,
        ),
        analyticsEnabled: deserializeParam(
          data['analyticsEnabled'],
          ParamType.bool,
          false,
        ),
        crashReportingEnabled: deserializeParam(
          data['crashReportingEnabled'],
          ParamType.bool,
          false,
        ),
        preferredUnits: deserializeParam(
          data['preferredUnits'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AppPreferencesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AppPreferencesStruct &&
        themeMode == other.themeMode &&
        hapticFeedbackEnabled == other.hapticFeedbackEnabled &&
        language == other.language &&
        analyticsEnabled == other.analyticsEnabled &&
        crashReportingEnabled == other.crashReportingEnabled &&
        preferredUnits == other.preferredUnits;
  }

  @override
  int get hashCode => const ListEquality().hash([
        themeMode,
        hapticFeedbackEnabled,
        language,
        analyticsEnabled,
        crashReportingEnabled,
        preferredUnits
      ]);
}

AppPreferencesStruct createAppPreferencesStruct({
  String? themeMode,
  bool? hapticFeedbackEnabled,
  String? language,
  bool? analyticsEnabled,
  bool? crashReportingEnabled,
  String? preferredUnits,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AppPreferencesStruct(
      themeMode: themeMode,
      hapticFeedbackEnabled: hapticFeedbackEnabled,
      language: language,
      analyticsEnabled: analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled,
      preferredUnits: preferredUnits,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AppPreferencesStruct? updateAppPreferencesStruct(
  AppPreferencesStruct? appPreferences, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    appPreferences
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );
