// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class NotificationSettingsStruct extends FFFirebaseStruct {
  NotificationSettingsStruct({
    bool? dailyReminders,
    bool? insightNotifications,
    bool? achievementAlerts,
    bool? weeklyProgress,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _dailyReminders = dailyReminders,
        _insightNotifications = insightNotifications,
        _achievementAlerts = achievementAlerts,
        _weeklyProgress = weeklyProgress,
        super(firestoreUtilData);

  // "dailyReminders" field.
  bool? _dailyReminders;
  bool get dailyReminders => _dailyReminders ?? false;
  set dailyReminders(bool? val) => _dailyReminders = val;

  bool hasDailyReminders() => _dailyReminders != null;

  // "insightNotifications" field.
  bool? _insightNotifications;
  bool get insightNotifications => _insightNotifications ?? false;
  set insightNotifications(bool? val) => _insightNotifications = val;

  bool hasInsightNotifications() => _insightNotifications != null;

  // "achievementAlerts" field.
  bool? _achievementAlerts;
  bool get achievementAlerts => _achievementAlerts ?? false;
  set achievementAlerts(bool? val) => _achievementAlerts = val;

  bool hasAchievementAlerts() => _achievementAlerts != null;

  // "weeklyProgress" field.
  bool? _weeklyProgress;
  bool get weeklyProgress => _weeklyProgress ?? false;
  set weeklyProgress(bool? val) => _weeklyProgress = val;

  bool hasWeeklyProgress() => _weeklyProgress != null;

  static NotificationSettingsStruct fromMap(Map<String, dynamic> data) =>
      NotificationSettingsStruct(
        dailyReminders: data['dailyReminders'] as bool?,
        insightNotifications: data['insightNotifications'] as bool?,
        achievementAlerts: data['achievementAlerts'] as bool?,
        weeklyProgress: data['weeklyProgress'] as bool?,
      );

  static NotificationSettingsStruct? maybeFromMap(dynamic data) => data is Map
      ? NotificationSettingsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'dailyReminders': _dailyReminders,
        'insightNotifications': _insightNotifications,
        'achievementAlerts': _achievementAlerts,
        'weeklyProgress': _weeklyProgress,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'dailyReminders': serializeParam(
          _dailyReminders,
          ParamType.bool,
        ),
        'insightNotifications': serializeParam(
          _insightNotifications,
          ParamType.bool,
        ),
        'achievementAlerts': serializeParam(
          _achievementAlerts,
          ParamType.bool,
        ),
        'weeklyProgress': serializeParam(
          _weeklyProgress,
          ParamType.bool,
        ),
      }.withoutNulls;

  static NotificationSettingsStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      NotificationSettingsStruct(
        dailyReminders: deserializeParam(
          data['dailyReminders'],
          ParamType.bool,
          false,
        ),
        insightNotifications: deserializeParam(
          data['insightNotifications'],
          ParamType.bool,
          false,
        ),
        achievementAlerts: deserializeParam(
          data['achievementAlerts'],
          ParamType.bool,
          false,
        ),
        weeklyProgress: deserializeParam(
          data['weeklyProgress'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'NotificationSettingsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is NotificationSettingsStruct &&
        dailyReminders == other.dailyReminders &&
        insightNotifications == other.insightNotifications &&
        achievementAlerts == other.achievementAlerts &&
        weeklyProgress == other.weeklyProgress;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([dailyReminders, insightNotifications, achievementAlerts, weeklyProgress]);
}

NotificationSettingsStruct createNotificationSettingsStruct({
  bool? dailyReminders,
  bool? insightNotifications,
  bool? achievementAlerts,
  bool? weeklyProgress,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    NotificationSettingsStruct(
      dailyReminders: dailyReminders,
      insightNotifications: insightNotifications,
      achievementAlerts: achievementAlerts,
      weeklyProgress: weeklyProgress,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

NotificationSettingsStruct? updateNotificationSettingsStruct(
  NotificationSettingsStruct? notificationSettings, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    notificationSettings
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addNotificationSettingsStructData(
  Map<String, dynamic> firestoreData,
  NotificationSettingsStruct? notificationSettings,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (notificationSettings == null) {
    return;
  }
  if (notificationSettings.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && notificationSettings.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final notificationSettingsData =
      getNotificationSettingsFirestoreData(notificationSettings, forFieldValue);
  final nestedData =
      notificationSettingsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = notificationSettings.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getNotificationSettingsFirestoreData(
  NotificationSettingsStruct? notificationSettings, [
  bool forFieldValue = false,
]) {
  if (notificationSettings == null) {
    return {};
  }
  final firestoreData = mapToFirestore(notificationSettings.toMap());

  // Add any Firestore field values
  notificationSettings.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getNotificationSettingsListFirestoreData(
  List<NotificationSettingsStruct>? notificationSettingss,
) =>
    notificationSettingss
        ?.map((e) => getNotificationSettingsFirestoreData(e, true))
        .toList() ??
    []; 