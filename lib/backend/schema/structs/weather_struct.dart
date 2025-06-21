// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class WeatherStruct extends FFFirebaseStruct {
  WeatherStruct({
    String? condition,
    double? temperature,
    double? windSpeed,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _condition = condition,
        _temperature = temperature,
        _windSpeed = windSpeed,
        super(firestoreUtilData);

  // "condition" field.
  String? _condition;
  String get condition => _condition ?? '';
  set condition(String? val) => _condition = val;

  bool hasCondition() => _condition != null;

  // "temperature" field.
  double? _temperature;
  double get temperature => _temperature ?? 0.0;
  set temperature(double? val) => _temperature = val;

  bool hasTemperature() => _temperature != null;

  // "windSpeed" field.
  double? _windSpeed;
  double get windSpeed => _windSpeed ?? 0.0;
  set windSpeed(double? val) => _windSpeed = val;

  bool hasWindSpeed() => _windSpeed != null;

  static WeatherStruct fromMap(Map<String, dynamic> data) => WeatherStruct(
        condition: data['condition'] as String?,
        temperature: castToType<double>(data['temperature']),
        windSpeed: castToType<double>(data['windSpeed']),
      );

  static WeatherStruct? maybeFromMap(dynamic data) => data is Map
      ? WeatherStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'condition': _condition,
        'temperature': _temperature,
        'windSpeed': _windSpeed,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'condition': serializeParam(_condition, ParamType.String),
        'temperature': serializeParam(_temperature, ParamType.double),
        'windSpeed': serializeParam(_windSpeed, ParamType.double),
      }.withoutNulls;

  static WeatherStruct fromSerializableMap(Map<String, dynamic> data) =>
      WeatherStruct(
        condition: deserializeParam(data['condition'], ParamType.String, false),
        temperature: deserializeParam(data['temperature'], ParamType.double, false),
        windSpeed: deserializeParam(data['windSpeed'], ParamType.double, false),
      );

  @override
  String toString() => 'WeatherStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is WeatherStruct &&
        condition == other.condition &&
        temperature == other.temperature &&
        windSpeed == other.windSpeed;
  }

  @override
  int get hashCode => const ListEquality().hash([condition, temperature, windSpeed]);
}

WeatherStruct createWeatherStruct({
  String? condition,
  double? temperature,
  double? windSpeed,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    WeatherStruct(
      condition: condition,
      temperature: temperature,
      windSpeed: windSpeed,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

WeatherStruct? updateWeatherStruct(
  WeatherStruct? weather, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    weather
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addWeatherStructData(
  Map<String, dynamic> firestoreData,
  WeatherStruct? weather,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (weather == null) {
    return;
  }
  if (weather.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && weather.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final weatherData = getWeatherFirestoreData(weather, forFieldValue);
  final nestedData = weatherData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = weather.firestoreUtilData.create || clearFields;
  firestoreData.addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getWeatherFirestoreData(
  WeatherStruct? weather, [
  bool forFieldValue = false,
]) {
  if (weather == null) {
    return {};
  }
  final firestoreData = mapToFirestore(weather.toMap());

  // Add any Firestore field values
  weather.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getWeatherListFirestoreData(
  List<WeatherStruct>? weathers,
) =>
    weathers?.map((e) => getWeatherFirestoreData(e, true)).toList() ?? []; 