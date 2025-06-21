// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ApproachStatsStruct extends FFFirebaseStruct {
  ApproachStatsStruct({
    double? averageProximity,
    int? insideTenFeet,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _averageProximity = averageProximity,
        _insideTenFeet = insideTenFeet,
        super(firestoreUtilData);

  // "averageProximity" field.
  double? _averageProximity;
  double get averageProximity => _averageProximity ?? 0.0;
  set averageProximity(double? val) => _averageProximity = val;

  bool hasAverageProximity() => _averageProximity != null;

  // "insideTenFeet" field.
  int? _insideTenFeet;
  int get insideTenFeet => _insideTenFeet ?? 0;
  set insideTenFeet(int? val) => _insideTenFeet = val;

  bool hasInsideTenFeet() => _insideTenFeet != null;

  static ApproachStatsStruct fromMap(Map<String, dynamic> data) =>
      ApproachStatsStruct(
        averageProximity: castToType<double>(data['averageProximity']),
        insideTenFeet: castToType<int>(data['insideTenFeet']),
      );

  static ApproachStatsStruct? maybeFromMap(dynamic data) => data is Map
      ? ApproachStatsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'averageProximity': _averageProximity,
        'insideTenFeet': _insideTenFeet,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'averageProximity': serializeParam(
          _averageProximity,
          ParamType.double,
        ),
        'insideTenFeet': serializeParam(
          _insideTenFeet,
          ParamType.int,
        ),
      }.withoutNulls;

  static ApproachStatsStruct fromSerializableMap(Map<String, dynamic> data) =>
      ApproachStatsStruct(
        averageProximity: deserializeParam(
          data['averageProximity'],
          ParamType.double,
          false,
        ),
        insideTenFeet: deserializeParam(
          data['insideTenFeet'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'ApproachStatsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ApproachStatsStruct &&
        averageProximity == other.averageProximity &&
        insideTenFeet == other.insideTenFeet;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([averageProximity, insideTenFeet]);
}

ApproachStatsStruct createApproachStatsStruct({
  double? averageProximity,
  int? insideTenFeet,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ApproachStatsStruct(
      averageProximity: averageProximity,
      insideTenFeet: insideTenFeet,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ApproachStatsStruct? updateApproachStatsStruct(
  ApproachStatsStruct? approachStats, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    approachStats
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addApproachStatsStructData(
  Map<String, dynamic> firestoreData,
  ApproachStatsStruct? approachStats,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (approachStats == null) {
    return;
  }
  if (approachStats.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && approachStats.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final approachStatsData =
      getApproachStatsFirestoreData(approachStats, forFieldValue);
  final nestedData =
      approachStatsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = approachStats.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getApproachStatsFirestoreData(
  ApproachStatsStruct? approachStats, [
  bool forFieldValue = false,
]) {
  if (approachStats == null) {
    return {};
  }
  final firestoreData = mapToFirestore(approachStats.toMap());

  // Add any Firestore field values
  approachStats.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getApproachStatsListFirestoreData(
  List<ApproachStatsStruct>? approachStatss,
) =>
    approachStatss
        ?.map((e) => getApproachStatsFirestoreData(e, true))
        .toList() ??
    []; 