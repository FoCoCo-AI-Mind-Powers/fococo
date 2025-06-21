// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ShortGameStatsStruct extends FFFirebaseStruct {
  ShortGameStatsStruct({
    int? chipsAndPitches,
    int? chipsHoled,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _chipsAndPitches = chipsAndPitches,
        _chipsHoled = chipsHoled,
        super(firestoreUtilData);

  // "chipsAndPitches" field.
  int? _chipsAndPitches;
  int get chipsAndPitches => _chipsAndPitches ?? 0;
  set chipsAndPitches(int? val) => _chipsAndPitches = val;

  bool hasChipsAndPitches() => _chipsAndPitches != null;

  // "chipsHoled" field.
  int? _chipsHoled;
  int get chipsHoled => _chipsHoled ?? 0;
  set chipsHoled(int? val) => _chipsHoled = val;

  bool hasChipsHoled() => _chipsHoled != null;

  static ShortGameStatsStruct fromMap(Map<String, dynamic> data) =>
      ShortGameStatsStruct(
        chipsAndPitches: castToType<int>(data['chipsAndPitches']),
        chipsHoled: castToType<int>(data['chipsHoled']),
      );

  static ShortGameStatsStruct? maybeFromMap(dynamic data) => data is Map
      ? ShortGameStatsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'chipsAndPitches': _chipsAndPitches,
        'chipsHoled': _chipsHoled,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'chipsAndPitches': serializeParam(
          _chipsAndPitches,
          ParamType.int,
        ),
        'chipsHoled': serializeParam(
          _chipsHoled,
          ParamType.int,
        ),
      }.withoutNulls;

  static ShortGameStatsStruct fromSerializableMap(Map<String, dynamic> data) =>
      ShortGameStatsStruct(
        chipsAndPitches: deserializeParam(
          data['chipsAndPitches'],
          ParamType.int,
          false,
        ),
        chipsHoled: deserializeParam(
          data['chipsHoled'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'ShortGameStatsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ShortGameStatsStruct &&
        chipsAndPitches == other.chipsAndPitches &&
        chipsHoled == other.chipsHoled;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([chipsAndPitches, chipsHoled]);
}

ShortGameStatsStruct createShortGameStatsStruct({
  int? chipsAndPitches,
  int? chipsHoled,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ShortGameStatsStruct(
      chipsAndPitches: chipsAndPitches,
      chipsHoled: chipsHoled,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ShortGameStatsStruct? updateShortGameStatsStruct(
  ShortGameStatsStruct? shortGameStats, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    shortGameStats
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addShortGameStatsStructData(
  Map<String, dynamic> firestoreData,
  ShortGameStatsStruct? shortGameStats,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (shortGameStats == null) {
    return;
  }
  if (shortGameStats.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && shortGameStats.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final shortGameStatsData =
      getShortGameStatsFirestoreData(shortGameStats, forFieldValue);
  final nestedData =
      shortGameStatsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = shortGameStats.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getShortGameStatsFirestoreData(
  ShortGameStatsStruct? shortGameStats, [
  bool forFieldValue = false,
]) {
  if (shortGameStats == null) {
    return {};
  }
  final firestoreData = mapToFirestore(shortGameStats.toMap());

  // Add any Firestore field values
  shortGameStats.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getShortGameStatsListFirestoreData(
  List<ShortGameStatsStruct>? shortGameStatss,
) =>
    shortGameStatss
        ?.map((e) => getShortGameStatsFirestoreData(e, true))
        .toList() ??
    []; 