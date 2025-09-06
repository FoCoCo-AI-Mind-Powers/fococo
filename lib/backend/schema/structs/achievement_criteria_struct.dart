// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:collection/collection.dart';

class AchievementCriteriaStruct extends FFFirebaseStruct {
  AchievementCriteriaStruct({
    String? type,
    String? metric,
    double? targetValue,
    String? comparison,
    int? timeframe,
    String? timeframeUnit,
    Map<String, dynamic>? conditions,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _type = type,
        _metric = metric,
        _targetValue = targetValue,
        _comparison = comparison,
        _timeframe = timeframe,
        _timeframeUnit = timeframeUnit,
        _conditions = conditions,
        super(firestoreUtilData);

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  set type(String? val) => _type = val;
  bool hasType() => _type != null;

  // "metric" field.
  String? _metric;
  String get metric => _metric ?? '';
  set metric(String? val) => _metric = val;
  bool hasMetric() => _metric != null;

  // "targetValue" field.
  double? _targetValue;
  double get targetValue => _targetValue ?? 0.0;
  set targetValue(double? val) => _targetValue = val;
  bool hasTargetValue() => _targetValue != null;

  // "comparison" field.
  String? _comparison;
  String get comparison => _comparison ?? '';
  set comparison(String? val) => _comparison = val;
  bool hasComparison() => _comparison != null;

  // "timeframe" field.
  int? _timeframe;
  int get timeframe => _timeframe ?? 0;
  set timeframe(int? val) => _timeframe = val;
  bool hasTimeframe() => _timeframe != null;

  // "timeframeUnit" field.
  String? _timeframeUnit;
  String get timeframeUnit => _timeframeUnit ?? '';
  set timeframeUnit(String? val) => _timeframeUnit = val;
  bool hasTimeframeUnit() => _timeframeUnit != null;

  // "conditions" field.
  Map<String, dynamic>? _conditions;
  Map<String, dynamic> get conditions => _conditions ?? {};
  set conditions(Map<String, dynamic>? val) => _conditions = val;
  bool hasConditions() => _conditions != null;

  static AchievementCriteriaStruct fromMap(Map<String, dynamic> data) =>
      AchievementCriteriaStruct(
        type: data['type'] as String?,
        metric: data['metric'] as String?,
        targetValue: castToType<double>(data['targetValue']),
        comparison: data['comparison'] as String?,
        timeframe: castToType<int>(data['timeframe']),
        timeframeUnit: data['timeframeUnit'] as String?,
        conditions: data['conditions'] as Map<String, dynamic>?,
      );

  static AchievementCriteriaStruct? maybeFromMap(dynamic data) => data is Map
      ? AchievementCriteriaStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'type': _type,
        'metric': _metric,
        'targetValue': _targetValue,
        'comparison': _comparison,
        'timeframe': _timeframe,
        'timeframeUnit': _timeframeUnit,
        'conditions': _conditions,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'type': serializeParam(
          _type,
          ParamType.String,
        ),
        'metric': serializeParam(
          _metric,
          ParamType.String,
        ),
        'targetValue': serializeParam(
          _targetValue,
          ParamType.double,
        ),
        'comparison': serializeParam(
          _comparison,
          ParamType.String,
        ),
        'timeframe': serializeParam(
          _timeframe,
          ParamType.int,
        ),
        'timeframeUnit': serializeParam(
          _timeframeUnit,
          ParamType.String,
        ),
        'conditions': serializeParam(
          _conditions,
          ParamType.JSON,
        ),
      }.withoutNulls;

  static AchievementCriteriaStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      AchievementCriteriaStruct(
        type: deserializeParam(
          data['type'],
          ParamType.String,
          false,
        ),
        metric: deserializeParam(
          data['metric'],
          ParamType.String,
          false,
        ),
        targetValue: deserializeParam(
          data['targetValue'],
          ParamType.double,
          false,
        ),
        comparison: deserializeParam(
          data['comparison'],
          ParamType.String,
          false,
        ),
        timeframe: deserializeParam(
          data['timeframe'],
          ParamType.int,
          false,
        ),
        timeframeUnit: deserializeParam(
          data['timeframeUnit'],
          ParamType.String,
          false,
        ),
        conditions: deserializeParam(
          data['conditions'],
          ParamType.JSON,
          false,
        ),
      );

  @override
  String toString() => 'AchievementCriteriaStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AchievementCriteriaStruct &&
        type == other.type &&
        metric == other.metric &&
        targetValue == other.targetValue &&
        comparison == other.comparison &&
        timeframe == other.timeframe &&
        timeframeUnit == other.timeframeUnit &&
        const MapEquality().equals(conditions, other.conditions);
  }

  @override
  int get hashCode => const ListEquality().hash([
        type,
        metric,
        targetValue,
        comparison,
        timeframe,
        timeframeUnit,
        conditions
      ]);
}

AchievementCriteriaStruct createAchievementCriteriaStruct({
  String? type,
  String? metric,
  double? targetValue,
  String? comparison,
  int? timeframe,
  String? timeframeUnit,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AchievementCriteriaStruct(
      type: type,
      metric: metric,
      targetValue: targetValue,
      comparison: comparison,
      timeframe: timeframe,
      timeframeUnit: timeframeUnit,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AchievementCriteriaStruct? updateAchievementCriteriaStruct(
  AchievementCriteriaStruct? achievementCriteria, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    achievementCriteria
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAchievementCriteriaStructData(
  Map<String, dynamic> firestoreData,
  AchievementCriteriaStruct? achievementCriteria,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (achievementCriteria == null) {
    return;
  }
  if (achievementCriteria.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && achievementCriteria.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final achievementCriteriaData =
      getAchievementCriteriaFirestoreData(achievementCriteria, forFieldValue);
  final nestedData =
      achievementCriteriaData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields =
      achievementCriteria.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAchievementCriteriaFirestoreData(
  AchievementCriteriaStruct? achievementCriteria, [
  bool forFieldValue = false,
]) {
  if (achievementCriteria == null) {
    return {};
  }
  final firestoreData = mapToFirestore(achievementCriteria.toMap());

  // Add any Firestore field values
  achievementCriteria.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAchievementCriteriaListFirestoreData(
  List<AchievementCriteriaStruct>? achievementCriterias,
) =>
    achievementCriterias
        ?.map((e) => getAchievementCriteriaFirestoreData(e, true))
        .toList() ??
    [];
