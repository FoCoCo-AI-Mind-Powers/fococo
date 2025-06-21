// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class VarkPreferencesStruct extends FFFirebaseStruct {
  VarkPreferencesStruct({
    bool? visual,
    bool? aural,
    bool? readWrite,
    bool? kinesthetic,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _visual = visual,
        _aural = aural,
        _readWrite = readWrite,
        _kinesthetic = kinesthetic,
        super(firestoreUtilData);

  // "visual" field.
  bool? _visual;
  bool get visual => _visual ?? false;
  set visual(bool? val) => _visual = val;

  bool hasVisual() => _visual != null;

  // "aural" field.
  bool? _aural;
  bool get aural => _aural ?? false;
  set aural(bool? val) => _aural = val;

  bool hasAural() => _aural != null;

  // "readWrite" field.
  bool? _readWrite;
  bool get readWrite => _readWrite ?? false;
  set readWrite(bool? val) => _readWrite = val;

  bool hasReadWrite() => _readWrite != null;

  // "kinesthetic" field.
  bool? _kinesthetic;
  bool get kinesthetic => _kinesthetic ?? false;
  set kinesthetic(bool? val) => _kinesthetic = val;

  bool hasKinesthetic() => _kinesthetic != null;

  static VarkPreferencesStruct fromMap(Map<String, dynamic> data) =>
      VarkPreferencesStruct(
        visual: data['visual'] as bool?,
        aural: data['aural'] as bool?,
        readWrite: data['readWrite'] as bool?,
        kinesthetic: data['kinesthetic'] as bool?,
      );

  static VarkPreferencesStruct? maybeFromMap(dynamic data) => data is Map
      ? VarkPreferencesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'visual': _visual,
        'aural': _aural,
        'readWrite': _readWrite,
        'kinesthetic': _kinesthetic,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'visual': serializeParam(
          _visual,
          ParamType.bool,
        ),
        'aural': serializeParam(
          _aural,
          ParamType.bool,
        ),
        'readWrite': serializeParam(
          _readWrite,
          ParamType.bool,
        ),
        'kinesthetic': serializeParam(
          _kinesthetic,
          ParamType.bool,
        ),
      }.withoutNulls;

  static VarkPreferencesStruct fromSerializableMap(Map<String, dynamic> data) =>
      VarkPreferencesStruct(
        visual: deserializeParam(
          data['visual'],
          ParamType.bool,
          false,
        ),
        aural: deserializeParam(
          data['aural'],
          ParamType.bool,
          false,
        ),
        readWrite: deserializeParam(
          data['readWrite'],
          ParamType.bool,
          false,
        ),
        kinesthetic: deserializeParam(
          data['kinesthetic'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'VarkPreferencesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is VarkPreferencesStruct &&
        visual == other.visual &&
        aural == other.aural &&
        readWrite == other.readWrite &&
        kinesthetic == other.kinesthetic;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([visual, aural, readWrite, kinesthetic]);
}

VarkPreferencesStruct createVarkPreferencesStruct({
  bool? visual,
  bool? aural,
  bool? readWrite,
  bool? kinesthetic,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    VarkPreferencesStruct(
      visual: visual,
      aural: aural,
      readWrite: readWrite,
      kinesthetic: kinesthetic,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

VarkPreferencesStruct? updateVarkPreferencesStruct(
  VarkPreferencesStruct? varkPreferences, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    varkPreferences
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addVarkPreferencesStructData(
  Map<String, dynamic> firestoreData,
  VarkPreferencesStruct? varkPreferences,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (varkPreferences == null) {
    return;
  }
  if (varkPreferences.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && varkPreferences.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final varkPreferencesData =
      getVarkPreferencesFirestoreData(varkPreferences, forFieldValue);
  final nestedData =
      varkPreferencesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = varkPreferences.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getVarkPreferencesFirestoreData(
  VarkPreferencesStruct? varkPreferences, [
  bool forFieldValue = false,
]) {
  if (varkPreferences == null) {
    return {};
  }
  final firestoreData = mapToFirestore(varkPreferences.toMap());

  // Add any Firestore field values
  varkPreferences.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getVarkPreferencesListFirestoreData(
  List<VarkPreferencesStruct>? varkPreferencess,
) =>
    varkPreferencess
        ?.map((e) => getVarkPreferencesFirestoreData(e, true))
        .toList() ??
    [];
