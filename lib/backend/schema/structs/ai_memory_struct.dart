// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// AI Memory Structure for storing user conversation context and insights
/// Enables the AI to remember user preferences, patterns, and conversation history
class AiMemoryStruct extends FFFirebaseStruct {
  AiMemoryStruct({
    String? sessionId,
    List<ConversationTurnStruct>? conversationHistory,
    Map<String, dynamic>? userInsights,
    Map<String, dynamic>? golfPatterns,
    Map<String, dynamic>? mentalPatterns,
    List<String>? keyTopics,
    DateTime? lastUpdated,
    int? totalInteractions,
    double? engagementScore,
    Map<String, dynamic>? personalityTraits,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _sessionId = sessionId,
        _conversationHistory = conversationHistory,
        _userInsights = userInsights,
        _golfPatterns = golfPatterns,
        _mentalPatterns = mentalPatterns,
        _keyTopics = keyTopics,
        _lastUpdated = lastUpdated,
        _totalInteractions = totalInteractions,
        _engagementScore = engagementScore,
        _personalityTraits = personalityTraits,
        super(firestoreUtilData);

  // "sessionId" field.
  String? _sessionId;
  String get sessionId => _sessionId ?? '';
  set sessionId(String? val) => _sessionId = val;
  bool hasSessionId() => _sessionId != null;

  // "conversationHistory" field.
  List<ConversationTurnStruct>? _conversationHistory;
  List<ConversationTurnStruct> get conversationHistory =>
      _conversationHistory ?? const [];
  set conversationHistory(List<ConversationTurnStruct>? val) =>
      _conversationHistory = val;
  void updateConversationHistory(
          Function(List<ConversationTurnStruct>) updateFn) =>
      updateFn(_conversationHistory ??= []);
  bool hasConversationHistory() => _conversationHistory != null;

  // "userInsights" field - NLP-derived insights about user
  Map<String, dynamic>? _userInsights;
  Map<String, dynamic> get userInsights => _userInsights ?? {};
  set userInsights(Map<String, dynamic>? val) => _userInsights = val;
  bool hasUserInsights() => _userInsights != null;

  // "golfPatterns" field - Golf-specific patterns and preferences
  Map<String, dynamic>? _golfPatterns;
  Map<String, dynamic> get golfPatterns => _golfPatterns ?? {};
  set golfPatterns(Map<String, dynamic>? val) => _golfPatterns = val;
  bool hasGolfPatterns() => _golfPatterns != null;

  // "mentalPatterns" field - Mental game patterns and challenges
  Map<String, dynamic>? _mentalPatterns;
  Map<String, dynamic> get mentalPatterns => _mentalPatterns ?? {};
  set mentalPatterns(Map<String, dynamic>? val) => _mentalPatterns = val;
  bool hasMentalPatterns() => _mentalPatterns != null;

  // "keyTopics" field - Frequently discussed topics
  List<String>? _keyTopics;
  List<String> get keyTopics => _keyTopics ?? const [];
  set keyTopics(List<String>? val) => _keyTopics = val;
  void updateKeyTopics(Function(List<String>) updateFn) =>
      updateFn(_keyTopics ??= []);
  bool hasKeyTopics() => _keyTopics != null;

  // "lastUpdated" field.
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;
  set lastUpdated(DateTime? val) => _lastUpdated = val;
  bool hasLastUpdated() => _lastUpdated != null;

  // "totalInteractions" field.
  int? _totalInteractions;
  int get totalInteractions => _totalInteractions ?? 0;
  set totalInteractions(int? val) => _totalInteractions = val;
  void incrementTotalInteractions(int amount) =>
      _totalInteractions = totalInteractions + amount;
  bool hasTotalInteractions() => _totalInteractions != null;

  // "engagementScore" field - AI-calculated engagement level
  double? _engagementScore;
  double get engagementScore => _engagementScore ?? 0.0;
  set engagementScore(double? val) => _engagementScore = val;
  bool hasEngagementScore() => _engagementScore != null;

  // "personalityTraits" field - AI-derived personality insights
  Map<String, dynamic>? _personalityTraits;
  Map<String, dynamic> get personalityTraits => _personalityTraits ?? {};
  set personalityTraits(Map<String, dynamic>? val) => _personalityTraits = val;
  bool hasPersonalityTraits() => _personalityTraits != null;

  static AiMemoryStruct fromMap(Map<String, dynamic> data) => AiMemoryStruct(
        sessionId: data['sessionId'] as String?,
        conversationHistory: (data['conversationHistory'] as List<dynamic>?)
                ?.map((e) =>
                    ConversationTurnStruct.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        userInsights: data['userInsights'] as Map<String, dynamic>?,
        golfPatterns: data['golfPatterns'] as Map<String, dynamic>?,
        mentalPatterns: data['mentalPatterns'] as Map<String, dynamic>?,
        keyTopics: (data['keyTopics'] as List<dynamic>?)?.cast<String>() ?? [],
        lastUpdated: data['lastUpdated'] is Timestamp
            ? (data['lastUpdated'] as Timestamp).toDate()
            : data['lastUpdated'] as DateTime?,
        totalInteractions: castToType<int>(data['totalInteractions']),
        engagementScore: castToType<double>(data['engagementScore']),
        personalityTraits: data['personalityTraits'] as Map<String, dynamic>?,
      );

  static AiMemoryStruct? maybeFromMap(dynamic data) =>
      data is Map ? AiMemoryStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'sessionId': _sessionId,
        'conversationHistory':
            _conversationHistory?.map((e) => e.toMap()).toList(),
        'userInsights': _userInsights,
        'golfPatterns': _golfPatterns,
        'mentalPatterns': _mentalPatterns,
        'keyTopics': _keyTopics,
        'lastUpdated': _lastUpdated,
        'totalInteractions': _totalInteractions,
        'engagementScore': _engagementScore,
        'personalityTraits': _personalityTraits,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'sessionId': serializeParam(
          _sessionId,
          ParamType.String,
        ),
        'conversationHistory':
            _conversationHistory?.map((e) => e.toSerializableMap()).toList(),
        'userInsights': serializeParam(
          _userInsights,
          ParamType.JSON,
        ),
        'golfPatterns': serializeParam(
          _golfPatterns,
          ParamType.JSON,
        ),
        'mentalPatterns': serializeParam(
          _mentalPatterns,
          ParamType.JSON,
        ),
        'keyTopics': _keyTopics,
        'lastUpdated': serializeParam(
          _lastUpdated,
          ParamType.DateTime,
        ),
        'totalInteractions': serializeParam(
          _totalInteractions,
          ParamType.int,
        ),
        'engagementScore': serializeParam(
          _engagementScore,
          ParamType.double,
        ),
        'personalityTraits': serializeParam(
          _personalityTraits,
          ParamType.JSON,
        ),
      }.withoutNulls;

  static AiMemoryStruct fromSerializableMap(Map<String, dynamic> data) =>
      AiMemoryStruct(
        sessionId: deserializeParam(
          data['sessionId'],
          ParamType.String,
          false,
        ),
        conversationHistory: (data['conversationHistory'] as List<dynamic>?)
                ?.map((e) => ConversationTurnStruct.fromSerializableMap(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
        userInsights: deserializeParam(
          data['userInsights'],
          ParamType.JSON,
          false,
        ),
        golfPatterns: deserializeParam(
          data['golfPatterns'],
          ParamType.JSON,
          false,
        ),
        mentalPatterns: deserializeParam(
          data['mentalPatterns'],
          ParamType.JSON,
          false,
        ),
        keyTopics: (data['keyTopics'] as List<dynamic>?)?.cast<String>() ?? [],
        lastUpdated: deserializeParam(
          data['lastUpdated'],
          ParamType.DateTime,
          false,
        ),
        totalInteractions: deserializeParam(
          data['totalInteractions'],
          ParamType.int,
          false,
        ),
        engagementScore: deserializeParam(
          data['engagementScore'],
          ParamType.double,
          false,
        ),
        personalityTraits: deserializeParam(
          data['personalityTraits'],
          ParamType.JSON,
          false,
        ),
      );

  @override
  String toString() => 'AiMemoryStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AiMemoryStruct &&
        sessionId == other.sessionId &&
        const ListEquality()
            .equals(conversationHistory, other.conversationHistory) &&
        const MapEquality().equals(userInsights, other.userInsights) &&
        const MapEquality().equals(golfPatterns, other.golfPatterns) &&
        const MapEquality().equals(mentalPatterns, other.mentalPatterns) &&
        const ListEquality().equals(keyTopics, other.keyTopics) &&
        lastUpdated == other.lastUpdated &&
        totalInteractions == other.totalInteractions &&
        engagementScore == other.engagementScore &&
        const MapEquality().equals(personalityTraits, other.personalityTraits);
  }

  @override
  int get hashCode => Object.hash(
        sessionId,
        const ListEquality().hash(conversationHistory),
        const MapEquality().hash(userInsights),
        const MapEquality().hash(golfPatterns),
        const MapEquality().hash(mentalPatterns),
        const ListEquality().hash(keyTopics),
        lastUpdated,
        totalInteractions,
        engagementScore,
        const MapEquality().hash(personalityTraits),
      );
}

AiMemoryStruct createAiMemoryStruct({
  String? sessionId,
  Map<String, dynamic>? userInsights,
  Map<String, dynamic>? golfPatterns,
  Map<String, dynamic>? mentalPatterns,
  DateTime? lastUpdated,
  int? totalInteractions,
  double? engagementScore,
  Map<String, dynamic>? personalityTraits,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AiMemoryStruct(
      sessionId: sessionId,
      userInsights: userInsights,
      golfPatterns: golfPatterns,
      mentalPatterns: mentalPatterns,
      lastUpdated: lastUpdated,
      totalInteractions: totalInteractions,
      engagementScore: engagementScore,
      personalityTraits: personalityTraits,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AiMemoryStruct? updateAiMemoryStruct(
  AiMemoryStruct? aiMemory, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    aiMemory
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAiMemoryStructData(
  Map<String, dynamic> firestoreData,
  AiMemoryStruct? aiMemory,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (aiMemory == null) {
    return;
  }
  if (aiMemory.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && aiMemory.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final aiMemoryData = getAiMemoryFirestoreData(aiMemory, forFieldValue);
  final nestedData = aiMemoryData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = aiMemory.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAiMemoryFirestoreData(
  AiMemoryStruct? aiMemory, [
  bool forFieldValue = false,
]) {
  if (aiMemory == null) {
    return {};
  }
  final firestoreData = mapToFirestore(aiMemory.toMap());

  // Add any Firestore field values
  aiMemory.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAiMemoryListFirestoreData(
  List<AiMemoryStruct>? aiMemorys,
) =>
    aiMemorys?.map((e) => getAiMemoryFirestoreData(e, true)).toList() ?? [];
