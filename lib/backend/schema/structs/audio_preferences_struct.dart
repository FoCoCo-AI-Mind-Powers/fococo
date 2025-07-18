// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class AudioPreferencesStruct extends FFFirebaseStruct {
  AudioPreferencesStruct({
    bool? enableTextToSpeech,
    double? speechRate,
    double? voicePitch,
    double? voiceVolume,
    bool? backgroundAudioEnabled,
    double? backgroundVolume,
    String? preferredVoiceGender,
    bool? audioFeedbackEnabled,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _enableTextToSpeech = enableTextToSpeech,
        _speechRate = speechRate,
        _voicePitch = voicePitch,
        _voiceVolume = voiceVolume,
        _backgroundAudioEnabled = backgroundAudioEnabled,
        _backgroundVolume = backgroundVolume,
        _preferredVoiceGender = preferredVoiceGender,
        _audioFeedbackEnabled = audioFeedbackEnabled,
        super(firestoreUtilData);

  // "enableTextToSpeech" field.
  bool? _enableTextToSpeech;
  bool get enableTextToSpeech => _enableTextToSpeech ?? false;
  set enableTextToSpeech(bool? val) => _enableTextToSpeech = val;
  bool hasEnableTextToSpeech() => _enableTextToSpeech != null;

  // "speechRate" field.
  double? _speechRate;
  double get speechRate => _speechRate ?? 0.7;
  set speechRate(double? val) => _speechRate = val;
  bool hasSpeechRate() => _speechRate != null;

  // "voicePitch" field.
  double? _voicePitch;
  double get voicePitch => _voicePitch ?? 1.0;
  set voicePitch(double? val) => _voicePitch = val;
  bool hasVoicePitch() => _voicePitch != null;

  // "voiceVolume" field.
  double? _voiceVolume;
  double get voiceVolume => _voiceVolume ?? 0.8;
  set voiceVolume(double? val) => _voiceVolume = val;
  bool hasVoiceVolume() => _voiceVolume != null;

  // "backgroundAudioEnabled" field.
  bool? _backgroundAudioEnabled;
  bool get backgroundAudioEnabled => _backgroundAudioEnabled ?? false;
  set backgroundAudioEnabled(bool? val) => _backgroundAudioEnabled = val;
  bool hasBackgroundAudioEnabled() => _backgroundAudioEnabled != null;

  // "backgroundVolume" field.
  double? _backgroundVolume;
  double get backgroundVolume => _backgroundVolume ?? 0.3;
  set backgroundVolume(double? val) => _backgroundVolume = val;
  bool hasBackgroundVolume() => _backgroundVolume != null;

  // "preferredVoiceGender" field.
  String? _preferredVoiceGender;
  String get preferredVoiceGender => _preferredVoiceGender ?? 'neutral';
  set preferredVoiceGender(String? val) => _preferredVoiceGender = val;
  bool hasPreferredVoiceGender() => _preferredVoiceGender != null;

  // "audioFeedbackEnabled" field.
  bool? _audioFeedbackEnabled;
  bool get audioFeedbackEnabled => _audioFeedbackEnabled ?? true;
  set audioFeedbackEnabled(bool? val) => _audioFeedbackEnabled = val;
  bool hasAudioFeedbackEnabled() => _audioFeedbackEnabled != null;

  static AudioPreferencesStruct fromMap(Map<String, dynamic> data) =>
      AudioPreferencesStruct(
        enableTextToSpeech: data['enable_text_to_speech'],
        speechRate: castToType<double>(data['speech_rate']),
        voicePitch: castToType<double>(data['voice_pitch']),
        voiceVolume: castToType<double>(data['voice_volume']),
        backgroundAudioEnabled: data['background_audio_enabled'],
        backgroundVolume: castToType<double>(data['background_volume']),
        preferredVoiceGender: data['preferred_voice_gender'],
        audioFeedbackEnabled: data['audio_feedback_enabled'],
      );

  static AudioPreferencesStruct? maybeFromMap(dynamic data) =>
      data is Map<String, dynamic> ? AudioPreferencesStruct.fromMap(data) : null;

  Map<String, dynamic> toMap() => {
        'enable_text_to_speech': _enableTextToSpeech,
        'speech_rate': _speechRate,
        'voice_pitch': _voicePitch,
        'voice_volume': _voiceVolume,
        'background_audio_enabled': _backgroundAudioEnabled,
        'background_volume': _backgroundVolume,
        'preferred_voice_gender': _preferredVoiceGender,
        'audio_feedback_enabled': _audioFeedbackEnabled,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'enable_text_to_speech': serializeParam(
          _enableTextToSpeech,
          ParamType.bool,
        ),
        'speech_rate': serializeParam(
          _speechRate,
          ParamType.double,
        ),
        'voice_pitch': serializeParam(
          _voicePitch,
          ParamType.double,
        ),
        'voice_volume': serializeParam(
          _voiceVolume,
          ParamType.double,
        ),
        'background_audio_enabled': serializeParam(
          _backgroundAudioEnabled,
          ParamType.bool,
        ),
        'background_volume': serializeParam(
          _backgroundVolume,
          ParamType.double,
        ),
        'preferred_voice_gender': serializeParam(
          _preferredVoiceGender,
          ParamType.String,
        ),
        'audio_feedback_enabled': serializeParam(
          _audioFeedbackEnabled,
          ParamType.bool,
        ),
      }.withoutNulls;

  static AudioPreferencesStruct fromSerializableMap(Map<String, dynamic> data) =>
      AudioPreferencesStruct(
        enableTextToSpeech: deserializeParam(
          data['enable_text_to_speech'],
          ParamType.bool,
          false,
        ),
        speechRate: deserializeParam(
          data['speech_rate'],
          ParamType.double,
          false,
        ),
        voicePitch: deserializeParam(
          data['voice_pitch'],
          ParamType.double,
          false,
        ),
        voiceVolume: deserializeParam(
          data['voice_volume'],
          ParamType.double,
          false,
        ),
        backgroundAudioEnabled: deserializeParam(
          data['background_audio_enabled'],
          ParamType.bool,
          false,
        ),
        backgroundVolume: deserializeParam(
          data['background_volume'],
          ParamType.double,
          false,
        ),
        preferredVoiceGender: deserializeParam(
          data['preferred_voice_gender'],
          ParamType.String,
          false,
        ),
        audioFeedbackEnabled: deserializeParam(
          data['audio_feedback_enabled'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'AudioPreferencesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AudioPreferencesStruct &&
        other.enableTextToSpeech == enableTextToSpeech &&
        other.speechRate == speechRate &&
        other.voicePitch == voicePitch &&
        other.voiceVolume == voiceVolume &&
        other.backgroundAudioEnabled == backgroundAudioEnabled &&
        other.backgroundVolume == backgroundVolume &&
        other.preferredVoiceGender == preferredVoiceGender &&
        other.audioFeedbackEnabled == audioFeedbackEnabled;
  }

  @override
  int get hashCode => const ListEquality().hash([
        enableTextToSpeech,
        speechRate,
        voicePitch,
        voiceVolume,
        backgroundAudioEnabled,
        backgroundVolume,
        preferredVoiceGender,
        audioFeedbackEnabled,
      ]);
}

AudioPreferencesStruct createAudioPreferencesStruct({
  bool? enableTextToSpeech,
  double? speechRate,
  double? voicePitch,
  double? voiceVolume,
  bool? backgroundAudioEnabled,
  double? backgroundVolume,
  String? preferredVoiceGender,
  bool? audioFeedbackEnabled,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AudioPreferencesStruct(
      enableTextToSpeech: enableTextToSpeech,
      speechRate: speechRate,
      voicePitch: voicePitch,
      voiceVolume: voiceVolume,
      backgroundAudioEnabled: backgroundAudioEnabled,
      backgroundVolume: backgroundVolume,
      preferredVoiceGender: preferredVoiceGender,
      audioFeedbackEnabled: audioFeedbackEnabled,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
                 fieldValues: fieldValues,
       ),
     );

void addAudioPreferencesStructData(
  Map<String, dynamic> firestoreData,
  AudioPreferencesStruct? audioPreferences,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (audioPreferences == null) {
    return;
  }
  if (audioPreferences.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && audioPreferences.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final audioPreferencesData =
      getAudioPreferencesFirestoreData(audioPreferences, forFieldValue);
  final nestedData =
      audioPreferencesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = audioPreferences.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAudioPreferencesFirestoreData(
  AudioPreferencesStruct? audioPreferences, [
  bool forFieldValue = false,
]) {
  if (audioPreferences == null) {
    return {};
  }
  final firestoreData = mapToFirestore(audioPreferences.toMap());

  // Add any Firestore field values
  audioPreferences.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAudioPreferencesListFirestoreData(
  List<AudioPreferencesStruct>? audioPreferencess,
) =>
    audioPreferencess
        ?.map((e) => getAudioPreferencesFirestoreData(e, true))
        .toList() ??
    []; 