// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'module_content_struct.dart';

class ModuleContentVersionsStruct extends FFFirebaseStruct {
  ModuleContentVersionsStruct({
    ModuleContentStruct? visual,
    ModuleContentStruct? aural,
    ModuleContentStruct? readWrite,
    ModuleContentStruct? kinesthetic,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _visual = visual,
        _aural = aural,
        _readWrite = readWrite,
        _kinesthetic = kinesthetic,
        super(firestoreUtilData);

  // "visual" field.
  ModuleContentStruct? _visual;
  ModuleContentStruct get visual => _visual ?? ModuleContentStruct();
  set visual(ModuleContentStruct? val) => _visual = val;
  bool hasVisual() => _visual != null;

  // "aural" field.
  ModuleContentStruct? _aural;
  ModuleContentStruct get aural => _aural ?? ModuleContentStruct();
  set aural(ModuleContentStruct? val) => _aural = val;
  bool hasAural() => _aural != null;

  // "readWrite" field.
  ModuleContentStruct? _readWrite;
  ModuleContentStruct get readWrite => _readWrite ?? ModuleContentStruct();
  set readWrite(ModuleContentStruct? val) => _readWrite = val;
  bool hasReadWrite() => _readWrite != null;

  // "kinesthetic" field.
  ModuleContentStruct? _kinesthetic;
  ModuleContentStruct get kinesthetic => _kinesthetic ?? ModuleContentStruct();
  set kinesthetic(ModuleContentStruct? val) => _kinesthetic = val;
  bool hasKinesthetic() => _kinesthetic != null;

  static ModuleContentVersionsStruct fromMap(Map<String, dynamic> data) =>
      ModuleContentVersionsStruct(
        visual: ModuleContentStruct.maybeFromMap(data['visual']),
        aural: ModuleContentStruct.maybeFromMap(data['aural']),
        readWrite: ModuleContentStruct.maybeFromMap(data['readWrite']),
        kinesthetic: ModuleContentStruct.maybeFromMap(data['kinesthetic']),
      );

  static ModuleContentVersionsStruct? maybeFromMap(dynamic data) => data is Map
      ? ModuleContentVersionsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'visual': _visual?.toMap(),
        'aural': _aural?.toMap(),
        'readWrite': _readWrite?.toMap(),
        'kinesthetic': _kinesthetic?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'visual': serializeParam(
          _visual,
          ParamType.DataStruct,
        ),
        'aural': serializeParam(
          _aural,
          ParamType.DataStruct,
        ),
        'readWrite': serializeParam(
          _readWrite,
          ParamType.DataStruct,
        ),
        'kinesthetic': serializeParam(
          _kinesthetic,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static ModuleContentVersionsStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ModuleContentVersionsStruct(
        visual: data['visual'] != null
            ? ModuleContentStruct.fromSerializableMap(data['visual'])
            : null,
        aural: data['aural'] != null
            ? ModuleContentStruct.fromSerializableMap(data['aural'])
            : null,
        readWrite: data['readWrite'] != null
            ? ModuleContentStruct.fromSerializableMap(data['readWrite'])
            : null,
        kinesthetic: data['kinesthetic'] != null
            ? ModuleContentStruct.fromSerializableMap(data['kinesthetic'])
            : null,
      );

  @override
  String toString() => 'ModuleContentVersionsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ModuleContentVersionsStruct &&
        visual == other.visual &&
        aural == other.aural &&
        readWrite == other.readWrite &&
        kinesthetic == other.kinesthetic;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([visual, aural, readWrite, kinesthetic]);
}

ModuleContentVersionsStruct createModuleContentVersionsStruct({
  ModuleContentStruct? visual,
  ModuleContentStruct? aural,
  ModuleContentStruct? readWrite,
  ModuleContentStruct? kinesthetic,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ModuleContentVersionsStruct(
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

ModuleContentVersionsStruct? updateModuleContentVersionsStruct(
  ModuleContentVersionsStruct? moduleContentVersions, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    moduleContentVersions
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addModuleContentVersionsStructData(
  Map<String, dynamic> firestoreData,
  ModuleContentVersionsStruct? moduleContentVersions,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (moduleContentVersions == null) {
    return;
  }
  if (moduleContentVersions.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue &&
      moduleContentVersions.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final moduleContentVersionsData = getModuleContentVersionsFirestoreData(
      moduleContentVersions, forFieldValue);
  final nestedData =
      moduleContentVersionsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields =
      moduleContentVersions.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getModuleContentVersionsFirestoreData(
  ModuleContentVersionsStruct? moduleContentVersions, [
  bool forFieldValue = false,
]) {
  if (moduleContentVersions == null) {
    return {};
  }
  final firestoreData = mapToFirestore(moduleContentVersions.toMap());

  // Add any Firestore field values
  moduleContentVersions.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getModuleContentVersionsListFirestoreData(
  List<ModuleContentVersionsStruct>? moduleContentVersionss,
) =>
    moduleContentVersionss
        ?.map((e) => getModuleContentVersionsFirestoreData(e, true))
        .toList() ??
    [];
