import 'dart:async';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/structs/recommendation_struct.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class AiInsightsRecord extends FirestoreRecord {
  AiInsightsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "sourceId" field.
  String? _sourceId;
  String get sourceId => _sourceId ?? '';
  bool hasSourceId() => _sourceId != null;

  // "sourceType" field.
  String? _sourceType;
  String get sourceType => _sourceType ?? '';
  bool hasSourceType() => _sourceType != null;

  // "insightType" field.
  String? _insightType;
  String get insightType => _insightType ?? '';
  bool hasInsightType() => _insightType != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "priority" field.
  String? _priority;
  String get priority => _priority ?? '';
  bool hasPriority() => _priority != null;

  // "insightTitle" field.
  String? _insightTitle;
  String get insightTitle => _insightTitle ?? '';
  bool hasInsightTitle() => _insightTitle != null;

  // "insightContent" field.
  String? _insightContent;
  String get insightContent => _insightContent ?? '';
  bool hasInsightContent() => _insightContent != null;

  // "keyPoints" field.
  List<String>? _keyPoints;
  List<String> get keyPoints => _keyPoints ?? const [];
  bool hasKeyPoints() => _keyPoints != null;

  // "recommendations" field.
  List<RecommendationStruct>? _recommendations;
  List<RecommendationStruct> get recommendations => _recommendations ?? const [];
  bool hasRecommendations() => _recommendations != null;

  // "personalizedElements" field.
  List<String>? _personalizedElements;
  List<String> get personalizedElements => _personalizedElements ?? const [];
  bool hasPersonalizedElements() => _personalizedElements != null;

  // "isRead" field.
  bool? _isRead;
  bool get isRead => _isRead ?? false;
  bool hasIsRead() => _isRead != null;

  // "userRating" field.
  int? _userRating;
  int get userRating => _userRating ?? 0;
  bool hasUserRating() => _userRating != null;

  // "userFeedback" field.
  String? _userFeedback;
  String get userFeedback => _userFeedback ?? '';
  bool hasUserFeedback() => _userFeedback != null;

  // "actionsTaken" field.
  List<String>? _actionsTaken;
  List<String> get actionsTaken => _actionsTaken ?? const [];
  bool hasActionsTaken() => _actionsTaken != null;

  // "generatedTime" field.
  DateTime? _generatedTime;
  DateTime? get generatedTime => _generatedTime;
  bool hasGeneratedTime() => _generatedTime != null;

  // "aiModel" field.
  String? _aiModel;
  String get aiModel => _aiModel ?? '';
  bool hasAiModel() => _aiModel != null;

  // "promptUsed" field.
  String? _promptUsed;
  String get promptUsed => _promptUsed ?? '';
  bool hasPromptUsed() => _promptUsed != null;

  // "rawAiResponse" field.
  String? _rawAiResponse;
  String get rawAiResponse => _rawAiResponse ?? '';
  bool hasRawAiResponse() => _rawAiResponse != null;

  // "processingTime" field.
  int? _processingTime;
  int get processingTime => _processingTime ?? 0;
  bool hasProcessingTime() => _processingTime != null;

  // "tokensUsed" field.
  int? _tokensUsed;
  int get tokensUsed => _tokensUsed ?? 0;
  bool hasTokensUsed() => _tokensUsed != null;

  // "costPerInsight" field.
  double? _costPerInsight;
  double get costPerInsight => _costPerInsight ?? 0.0;
  bool hasCostPerInsight() => _costPerInsight != null;

  // "generationVersion" field.
  String? _generationVersion;
  String get generationVersion => _generationVersion ?? '';
  bool hasGenerationVersion() => _generationVersion != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "expiryDate" field.
  DateTime? _expiryDate;
  DateTime? get expiryDate => _expiryDate;
  bool hasExpiryDate() => _expiryDate != null;

  // "viewCount" field.
  int? _viewCount;
  int get viewCount => _viewCount ?? 0;
  bool hasViewCount() => _viewCount != null;

  // "shareCount" field.
  int? _shareCount;
  int get shareCount => _shareCount ?? 0;
  bool hasShareCount() => _shareCount != null;

  // "relatedInsights" field.
  List<String>? _relatedInsights;
  List<String> get relatedInsights => _relatedInsights ?? const [];
  bool hasRelatedInsights() => _relatedInsights != null;

  // "followUpGenerated" field.
  bool? _followUpGenerated;
  bool get followUpGenerated => _followUpGenerated ?? false;
  bool hasFollowUpGenerated() => _followUpGenerated != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _sourceId = snapshotData['sourceId'] as String?;
    _sourceType = snapshotData['sourceType'] as String?;
    _insightType = snapshotData['insightType'] as String?;
    _category = snapshotData['category'] as String?;
    _priority = snapshotData['priority'] as String?;
    _insightTitle = snapshotData['insightTitle'] as String?;
    _insightContent = snapshotData['insightContent'] as String?;
    _keyPoints = getDataList(snapshotData['keyPoints']);
    _recommendations = getStructList(
      snapshotData['recommendations'],
      RecommendationStruct.fromMap,
    );
    _personalizedElements = getDataList(snapshotData['personalizedElements']);
    _isRead = snapshotData['isRead'] as bool?;
    _userRating = castToType<int>(snapshotData['userRating']);
    _userFeedback = snapshotData['userFeedback'] as String?;
    _actionsTaken = getDataList(snapshotData['actionsTaken']);
    _generatedTime = snapshotData['generatedTime'] as DateTime?;
    _aiModel = snapshotData['aiModel'] as String?;
    _promptUsed = snapshotData['promptUsed'] as String?;
    _rawAiResponse = snapshotData['rawAiResponse'] as String?;
    _processingTime = castToType<int>(snapshotData['processingTime']);
    _tokensUsed = castToType<int>(snapshotData['tokensUsed']);
    _costPerInsight = castToType<double>(snapshotData['costPerInsight']);
    _generationVersion = snapshotData['generationVersion'] as String?;
    _status = snapshotData['status'] as String?;
    _expiryDate = snapshotData['expiryDate'] as DateTime?;
    _viewCount = castToType<int>(snapshotData['viewCount']);
    _shareCount = castToType<int>(snapshotData['shareCount']);
    _relatedInsights = getDataList(snapshotData['relatedInsights']);
    _followUpGenerated = snapshotData['followUpGenerated'] as bool?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ai_insights');

  static Stream<AiInsightsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AiInsightsRecord.fromSnapshot(s));

  static Future<AiInsightsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AiInsightsRecord.fromSnapshot(s));

  static AiInsightsRecord fromSnapshot(DocumentSnapshot snapshot) => AiInsightsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AiInsightsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AiInsightsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AiInsightsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AiInsightsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
} 