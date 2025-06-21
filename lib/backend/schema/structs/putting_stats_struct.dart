// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PuttingStatsStruct extends FFFirebaseStruct {
  PuttingStatsStruct({
    double? averagePuttsPerHole,
    int? oneputts,
    int? threeputts,
    double? longestPuttMade,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _averagePuttsPerHole = averagePuttsPerHole,
        _oneputts = oneputts,
        _threeputts = threeputts,
        _longestPuttMade = longestPuttMade,
        super(firestoreUtilData);

  // "averagePuttsPerHole" field.
  double? _averagePuttsPerHole;
  double get averagePuttsPerHole => _averagePuttsPerHole ?? 0.0;
  set averagePuttsPerHole(double? val) => _averagePuttsPerHole = val;

  bool hasAveragePuttsPerHole() => _averagePuttsPerHole != null;

  // "oneputts" field.
  int? _oneputts;
  int get oneputts => _oneputts ?? 0;
  set oneputts(int? val) => _oneputts = val;

  bool hasOneputts() => _oneputts != null;

  // "threeputts" field.
  int? _threeputts;
  int get threeputts => _threeputts ?? 0;
  set threeputts(int? val) => _threeputts = val;

  bool hasThreeputts() => _threeputts != null;

  // "longestPuttMade" field.
  double? _longestPuttMade;
  double get longestPuttMade => _longestPuttMade ?? 0.0;
  set longestPuttMade(double? val) => _longestPuttMade = val;

  bool hasLongestPuttMade() => _longestPuttMade != null;

  static PuttingStatsStruct fromMap(Map<String, dynamic> data) =>
      PuttingStatsStruct(
        averagePuttsPerHole: castToType<double>(data['averagePuttsPerHole']),
        oneputts: castToType<int>(data['oneputts']),
        threeputts: castToType<int>(data['threeputts']),
        longestPuttMade: castToType<double>(data['longestPuttMade']),
      );

  static PuttingStatsStruct? maybeFromMap(dynamic data) => data is Map
      ? PuttingStatsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'averagePuttsPerHole': _averagePuttsPerHole,
        'oneputts': _oneputts,
        'threeputts': _threeputts,
        'longestPuttMade': _longestPuttMade,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'averagePuttsPerHole': serializeParam(
          _averagePuttsPerHole,
          ParamType.double,
        ),
        'oneputts': serializeParam(
          _oneputts,
          ParamType.int,
        ),
        'threeputts': serializeParam(
          _threeputts,
          ParamType.int,
        ),
        'longestPuttMade': serializeParam(
          _longestPuttMade,
          ParamType.double,
        ),
      }.withoutNulls;

  static PuttingStatsStruct fromSerializableMap(Map<String, dynamic> data) =>
      PuttingStatsStruct(
        averagePuttsPerHole: deserializeParam(
          data['averagePuttsPerHole'],
          ParamType.double,
          false,
        ),
        oneputts: deserializeParam(
          data['oneputts'],
          ParamType.int,
          false,
        ),
        threeputts: deserializeParam(
          data['threeputts'],
          ParamType.int,
          false,
        ),
        longestPuttMade: deserializeParam(
          data['longestPuttMade'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'PuttingStatsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is PuttingStatsStruct &&
        averagePuttsPerHole == other.averagePuttsPerHole &&
        oneputts == other.oneputts &&
        threeputts == other.threeputts &&
        longestPuttMade == other.longestPuttMade;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([averagePuttsPerHole, oneputts, threeputts, longestPuttMade]);
}

PuttingStatsStruct createPuttingStatsStruct({
  double? averagePuttsPerHole,
  int? oneputts,
  int? threeputts,
  double? longestPuttMade,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    PuttingStatsStruct(
      averagePuttsPerHole: averagePuttsPerHole,
      oneputts: oneputts,
      threeputts: threeputts,
      longestPuttMade: longestPuttMade,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

PuttingStatsStruct? updatePuttingStatsStruct(
  PuttingStatsStruct? puttingStats, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    puttingStats
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addPuttingStatsStructData(
  Map<String, dynamic> firestoreData,
  PuttingStatsStruct? puttingStats,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (puttingStats == null) {
    return;
  }
  if (puttingStats.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && puttingStats.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final puttingStatsData =
      getPuttingStatsFirestoreData(puttingStats, forFieldValue);
  final nestedData =
      puttingStatsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = puttingStats.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getPuttingStatsFirestoreData(
  PuttingStatsStruct? puttingStats, [
  bool forFieldValue = false,
]) {
  if (puttingStats == null) {
    return {};
  }
  final firestoreData = mapToFirestore(puttingStats.toMap());

  // Add any Firestore field values
  puttingStats.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getPuttingStatsListFirestoreData(
  List<PuttingStatsStruct>? puttingStatss,
) =>
    puttingStatss
        ?.map((e) => getPuttingStatsFirestoreData(e, true))
        .toList() ??
    []; 