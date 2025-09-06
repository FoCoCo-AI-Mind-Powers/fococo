// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Individual conversation turn for AI memory system
class ConversationTurnStruct extends FFFirebaseStruct {
  ConversationTurnStruct({
    String? id,
    String? userMessage,
    String? aiResponse,
    DateTime? timestamp,
    String? messageType,
    Map<String, dynamic>? sentiment,
    List<String>? extractedTopics,
    double? confidenceScore,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _id = id,
        _userMessage = userMessage,
        _aiResponse = aiResponse,
        _timestamp = timestamp,
        _messageType = messageType,
        _sentiment = sentiment,
        _extractedTopics = extractedTopics,
        _confidenceScore = confidenceScore,
        super(firestoreUtilData);

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;
  bool hasId() => _id != null;

  // "userMessage" field.
  String? _userMessage;
  String get userMessage => _userMessage ?? '';
  set userMessage(String? val) => _userMessage = val;
  bool hasUserMessage() => _userMessage != null;

  // "aiResponse" field.
  String? _aiResponse;
  String get aiResponse => _aiResponse ?? '';
  set aiResponse(String? val) => _aiResponse = val;
  bool hasAiResponse() => _aiResponse != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  set timestamp(DateTime? val) => _timestamp = val;
  bool hasTimestamp() => _timestamp != null;

  // "messageType" field - 'text', 'voice', 'system'
  String? _messageType;
  String get messageType => _messageType ?? 'text';
  set messageType(String? val) => _messageType = val;
  bool hasMessageType() => _messageType != null;

  // "sentiment" field - NLP sentiment analysis
  Map<String, dynamic>? _sentiment;
  Map<String, dynamic> get sentiment => _sentiment ?? {};
  set sentiment(Map<String, dynamic>? val) => _sentiment = val;
  bool hasSentiment() => _sentiment != null;

  // "extractedTopics" field - NLP topic extraction
  List<String>? _extractedTopics;
  List<String> get extractedTopics => _extractedTopics ?? const [];
  set extractedTopics(List<String>? val) => _extractedTopics = val;
  void updateExtractedTopics(Function(List<String>) updateFn) =>
      updateFn(_extractedTopics ??= []);
  bool hasExtractedTopics() => _extractedTopics != null;

  // "confidenceScore" field - AI confidence in response
  double? _confidenceScore;
  double get confidenceScore => _confidenceScore ?? 0.0;
  set confidenceScore(double? val) => _confidenceScore = val;
  bool hasConfidenceScore() => _confidenceScore != null;

  static ConversationTurnStruct fromMap(Map<String, dynamic> data) =>
      ConversationTurnStruct(
        id: data['id'] as String?,
        userMessage: data['userMessage'] as String?,
        aiResponse: data['aiResponse'] as String?,
        timestamp: data['timestamp'] is Timestamp
            ? (data['timestamp'] as Timestamp).toDate()
            : data['timestamp'] as DateTime?,
        messageType: data['messageType'] as String?,
        sentiment: data['sentiment'] as Map<String, dynamic>?,
        extractedTopics:
            (data['extractedTopics'] as List<dynamic>?)?.cast<String>() ?? [],
        confidenceScore: castToType<double>(data['confidenceScore']),
      );

  static ConversationTurnStruct? maybeFromMap(dynamic data) => data is Map
      ? ConversationTurnStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'userMessage': _userMessage,
        'aiResponse': _aiResponse,
        'timestamp': _timestamp,
        'messageType': _messageType,
        'sentiment': _sentiment,
        'extractedTopics': _extractedTopics,
        'confidenceScore': _confidenceScore,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'userMessage': serializeParam(
          _userMessage,
          ParamType.String,
        ),
        'aiResponse': serializeParam(
          _aiResponse,
          ParamType.String,
        ),
        'timestamp': serializeParam(
          _timestamp,
          ParamType.DateTime,
        ),
        'messageType': serializeParam(
          _messageType,
          ParamType.String,
        ),
        'sentiment': serializeParam(
          _sentiment,
          ParamType.JSON,
        ),
        'extractedTopics': _extractedTopics,
        'confidenceScore': serializeParam(
          _confidenceScore,
          ParamType.double,
        ),
      }.withoutNulls;

  static ConversationTurnStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ConversationTurnStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        userMessage: deserializeParam(
          data['userMessage'],
          ParamType.String,
          false,
        ),
        aiResponse: deserializeParam(
          data['aiResponse'],
          ParamType.String,
          false,
        ),
        timestamp: deserializeParam(
          data['timestamp'],
          ParamType.DateTime,
          false,
        ),
        messageType: deserializeParam(
          data['messageType'],
          ParamType.String,
          false,
        ),
        sentiment: deserializeParam(
          data['sentiment'],
          ParamType.JSON,
          false,
        ),
        extractedTopics:
            (data['extractedTopics'] as List<dynamic>?)?.cast<String>() ?? [],
        confidenceScore: deserializeParam(
          data['confidenceScore'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'ConversationTurnStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ConversationTurnStruct &&
        id == other.id &&
        userMessage == other.userMessage &&
        aiResponse == other.aiResponse &&
        timestamp == other.timestamp &&
        messageType == other.messageType &&
        const MapEquality().equals(sentiment, other.sentiment) &&
        const ListEquality().equals(extractedTopics, other.extractedTopics) &&
        confidenceScore == other.confidenceScore;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userMessage,
        aiResponse,
        timestamp,
        messageType,
        const MapEquality().hash(sentiment),
        const ListEquality().hash(extractedTopics),
        confidenceScore,
      );
}

ConversationTurnStruct createConversationTurnStruct({
  String? id,
  String? userMessage,
  String? aiResponse,
  DateTime? timestamp,
  String? messageType,
  Map<String, dynamic>? sentiment,
  double? confidenceScore,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ConversationTurnStruct(
      id: id,
      userMessage: userMessage,
      aiResponse: aiResponse,
      timestamp: timestamp,
      messageType: messageType,
      sentiment: sentiment,
      confidenceScore: confidenceScore,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ConversationTurnStruct? updateConversationTurnStruct(
  ConversationTurnStruct? conversationTurn, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    conversationTurn
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addConversationTurnStructData(
  Map<String, dynamic> firestoreData,
  ConversationTurnStruct? conversationTurn,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (conversationTurn == null) {
    return;
  }
  if (conversationTurn.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && conversationTurn.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final conversationTurnData =
      getConversationTurnFirestoreData(conversationTurn, forFieldValue);
  final nestedData =
      conversationTurnData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = conversationTurn.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getConversationTurnFirestoreData(
  ConversationTurnStruct? conversationTurn, [
  bool forFieldValue = false,
]) {
  if (conversationTurn == null) {
    return {};
  }
  final firestoreData = mapToFirestore(conversationTurn.toMap());

  // Add any Firestore field values
  conversationTurn.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getConversationTurnListFirestoreData(
  List<ConversationTurnStruct>? conversationTurns,
) =>
    conversationTurns
        ?.map((e) => getConversationTurnFirestoreData(e, true))
        .toList() ??
    [];
