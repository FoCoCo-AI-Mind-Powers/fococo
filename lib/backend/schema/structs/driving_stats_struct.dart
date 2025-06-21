// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DrivingStatsStruct extends FFFirebaseStruct {
  DrivingStatsStruct({
    double? averageDistance,
    double? accuracy,
    double? longestDrive,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _averageDistance = averageDistance,
        _accuracy = accuracy,
        _longestDrive = longestDrive,
        super(firestoreUtilData);

  // "averageDistance" field.
  double? _averageDistance;
  double get averageDistance => _averageDistance ?? 0.0;
  set averageDistance(double? val) => _averageDistance = val;

  bool hasAverageDistance() => _averageDistance != null;

  // "accuracy" field.
  double? _accuracy;
  double get accuracy => _accuracy ?? 0.0;
  set accuracy(double? val) => _accuracy = val;

  bool hasAccuracy() => _accuracy != null;

  // "longestDrive" field.
  double? _longestDrive;
  double get longestDrive => _longestDrive ?? 0.0;
  set longestDrive(double? val) => _longestDrive = val;

  bool hasLongestDrive() => _longestDrive != null;

  static DrivingStatsStruct fromMap(Map<String, dynamic> data) =>
      DrivingStatsStruct(
        averageDistance: castToType<double>(data['averageDistance']),
        accuracy: castToType<double>(data['accuracy']),
        longestDrive: castToType<double>(data['longestDrive']),
      );

  static DrivingStatsStruct? maybeFromMap(dynamic data) => data is Map
      ? DrivingStatsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'averageDistance': _averageDistance,
        'accuracy': _accuracy,
        'longestDrive': _longestDrive,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'averageDistance': serializeParam(
          _averageDistance,
          ParamType.double,
        ),
        'accuracy': serializeParam(
          _accuracy,
          ParamType.double,
        ),
        'longestDrive': serializeParam(
          _longestDrive,
          ParamType.double,
        ),
      }.withoutNulls;

  static DrivingStatsStruct fromSerializableMap(Map<String, dynamic> data) =>
      DrivingStatsStruct(
        averageDistance: deserializeParam(
          data['averageDistance'],
          ParamType.double,
          false,
        ),
        accuracy: deserializeParam(
          data['accuracy'],
          ParamType.double,
          false,
        ),
        longestDrive: deserializeParam(
          data['longestDrive'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'DrivingStatsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DrivingStatsStruct &&
        averageDistance == other.averageDistance &&
        accuracy == other.accuracy &&
        longestDrive == other.longestDrive;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([averageDistance, accuracy, longestDrive]);
}

DrivingStatsStruct createDrivingStatsStruct({
  double? averageDistance,
  double? accuracy,
  double? longestDrive,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DrivingStatsStruct(
      averageDistance: averageDistance,
      accuracy: accuracy,
      longestDrive: longestDrive,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DrivingStatsStruct? updateDrivingStatsStruct(
  DrivingStatsStruct? drivingStats, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    drivingStats
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDrivingStatsStructData(
  Map<String, dynamic> firestoreData,
  DrivingStatsStruct? drivingStats,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (drivingStats == null) {
    return;
  }
  if (drivingStats.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && drivingStats.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final drivingStatsData =
      getDrivingStatsFirestoreData(drivingStats, forFieldValue);
  final nestedData =
      drivingStatsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = drivingStats.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDrivingStatsFirestoreData(
  DrivingStatsStruct? drivingStats, [
  bool forFieldValue = false,
]) {
  if (drivingStats == null) {
    return {};
  }
  final firestoreData = mapToFirestore(drivingStats.toMap());

  // Add any Firestore field values
  drivingStats.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDrivingStatsListFirestoreData(
  List<DrivingStatsStruct>? drivingStatss,
) =>
    drivingStatss
        ?.map((e) => getDrivingStatsFirestoreData(e, true))
        .toList() ??
    []; 