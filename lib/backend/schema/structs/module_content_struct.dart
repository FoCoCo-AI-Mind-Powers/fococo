// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ModuleContentStruct extends FFFirebaseStruct {
  ModuleContentStruct({
    String? contentUrl,
    String? format,
    int? duration,
    String? transcript,
    List<String>? sections,
    String? thumbnailUrl,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _contentUrl = contentUrl,
        _format = format,
        _duration = duration,
        _transcript = transcript,
        _sections = sections,
        _thumbnailUrl = thumbnailUrl,
        super(firestoreUtilData);

  // "contentUrl" field.
  String? _contentUrl;
  String get contentUrl => _contentUrl ?? '';
  set contentUrl(String? val) => _contentUrl = val;
  bool hasContentUrl() => _contentUrl != null;

  // "format" field.
  String? _format;
  String get format => _format ?? '';
  set format(String? val) => _format = val;
  bool hasFormat() => _format != null;

  // "duration" field.
  int? _duration;
  int get duration => _duration ?? 0;
  set duration(int? val) => _duration = val;
  bool hasDuration() => _duration != null;

  // "transcript" field.
  String? _transcript;
  String get transcript => _transcript ?? '';
  set transcript(String? val) => _transcript = val;
  bool hasTranscript() => _transcript != null;

  // "sections" field.
  List<String>? _sections;
  List<String> get sections => _sections ?? const [];
  set sections(List<String>? val) => _sections = val;
  bool hasSections() => _sections != null;

  // "thumbnailUrl" field.
  String? _thumbnailUrl;
  String get thumbnailUrl => _thumbnailUrl ?? '';
  set thumbnailUrl(String? val) => _thumbnailUrl = val;
  bool hasThumbnailUrl() => _thumbnailUrl != null;

  static ModuleContentStruct fromMap(Map<String, dynamic> data) =>
      ModuleContentStruct(
        contentUrl: data['contentUrl'] as String?,
        format: data['format'] as String?,
        duration: castToType<int>(data['duration']),
        transcript: data['transcript'] as String?,
        sections: (data['sections'] as List<dynamic>?)?.cast<String>(),
        thumbnailUrl: data['thumbnailUrl'] as String?,
      );

  static ModuleContentStruct? maybeFromMap(dynamic data) => data is Map
      ? ModuleContentStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'contentUrl': _contentUrl,
        'format': _format,
        'duration': _duration,
        'transcript': _transcript,
        'sections': _sections,
        'thumbnailUrl': _thumbnailUrl,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'contentUrl': serializeParam(
          _contentUrl,
          ParamType.String,
        ),
        'format': serializeParam(
          _format,
          ParamType.String,
        ),
        'duration': serializeParam(
          _duration,
          ParamType.int,
        ),
        'transcript': serializeParam(
          _transcript,
          ParamType.String,
        ),
        'sections': _sections,
        'thumbnailUrl': serializeParam(
          _thumbnailUrl,
          ParamType.String,
        ),
      }.withoutNulls;

  static ModuleContentStruct fromSerializableMap(Map<String, dynamic> data) =>
      ModuleContentStruct(
        contentUrl: deserializeParam(
          data['contentUrl'],
          ParamType.String,
          false,
        ),
        format: deserializeParam(
          data['format'],
          ParamType.String,
          false,
        ),
        duration: deserializeParam(
          data['duration'],
          ParamType.int,
          false,
        ),
        transcript: deserializeParam(
          data['transcript'],
          ParamType.String,
          false,
        ),
        sections: (data['sections'] as List<dynamic>?)?.cast<String>(),
        thumbnailUrl: deserializeParam(
          data['thumbnailUrl'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ModuleContentStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is ModuleContentStruct &&
        contentUrl == other.contentUrl &&
        format == other.format &&
        duration == other.duration &&
        transcript == other.transcript &&
        listEquality.equals(sections, other.sections) &&
        thumbnailUrl == other.thumbnailUrl;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([contentUrl, format, duration, transcript, sections, thumbnailUrl]);
}

ModuleContentStruct createModuleContentStruct({
  String? contentUrl,
  String? format,
  int? duration,
  String? transcript,
  String? thumbnailUrl,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ModuleContentStruct(
      contentUrl: contentUrl,
      format: format,
      duration: duration,
      transcript: transcript,
      thumbnailUrl: thumbnailUrl,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ModuleContentStruct? updateModuleContentStruct(
  ModuleContentStruct? moduleContent, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    moduleContent
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addModuleContentStructData(
  Map<String, dynamic> firestoreData,
  ModuleContentStruct? moduleContent,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (moduleContent == null) {
    return;
  }
  if (moduleContent.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && moduleContent.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final moduleContentData =
      getModuleContentFirestoreData(moduleContent, forFieldValue);
  final nestedData =
      moduleContentData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = moduleContent.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getModuleContentFirestoreData(
  ModuleContentStruct? moduleContent, [
  bool forFieldValue = false,
]) {
  if (moduleContent == null) {
    return {};
  }
  final firestoreData = mapToFirestore(moduleContent.toMap());

  // Add any Firestore field values
  moduleContent.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getModuleContentListFirestoreData(
  List<ModuleContentStruct>? moduleContents,
) =>
    moduleContents
        ?.map((e) => getModuleContentFirestoreData(e, true))
        .toList() ??
    [];
