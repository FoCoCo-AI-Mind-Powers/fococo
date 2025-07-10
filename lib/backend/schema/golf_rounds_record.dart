import 'dart:async';


import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GolfRoundsRecord extends FirestoreRecord {
  GolfRoundsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "courseName" field.
  String? _courseName;
  String get courseName => _courseName ?? '';
  bool hasCourseName() => _courseName != null;

  // "courseId" field.
  String? _courseId;
  String get courseId => _courseId ?? '';
  bool hasCourseId() => _courseId != null;

  // "teeBox" field.
  String? _teeBox;
  String get teeBox => _teeBox ?? '';
  bool hasTeeBox() => _teeBox != null;

  // "courseRating" field.
  double? _courseRating;
  double get courseRating => _courseRating ?? 0.0;
  bool hasCourseRating() => _courseRating != null;

  // "slopeRating" field.
  double? _slopeRating;
  double get slopeRating => _slopeRating ?? 0.0;
  bool hasSlopeRating() => _slopeRating != null;

  // "score" field.
  int? _score;
  int get score => _score ?? 0;
  bool hasScore() => _score != null;

  // "parTotal" field.
  int? _parTotal;
  int get parTotal => _parTotal ?? 0;
  bool hasParTotal() => _parTotal != null;

  // "scoreToPar" field.
  int? _scoreToPar;
  int get scoreToPar => _scoreToPar ?? 0;
  bool hasScoreToPar() => _scoreToPar != null;

  // "totalPutts" field.
  int? _totalPutts;
  int get totalPutts => _totalPutts ?? 0;
  bool hasTotalPutts() => _totalPutts != null;

  // "fairwaysHit" field.
  int? _fairwaysHit;
  int get fairwaysHit => _fairwaysHit ?? 0;
  bool hasFairwaysHit() => _fairwaysHit != null;

  // "fairwaysTotal" field.
  int? _fairwaysTotal;
  int get fairwaysTotal => _fairwaysTotal ?? 0;
  bool hasFairwaysTotal() => _fairwaysTotal != null;

  // "greensInRegulation" field.
  int? _greensInRegulation;
  int get greensInRegulation => _greensInRegulation ?? 0;
  bool hasGreensInRegulation() => _greensInRegulation != null;

  // "greensTotal" field.
  int? _greensTotal;
  int get greensTotal => _greensTotal ?? 0;
  bool hasGreensTotal() => _greensTotal != null;

  // "penalties" field.
  int? _penalties;
  int get penalties => _penalties ?? 0;
  bool hasPenalties() => _penalties != null;

  // "sandSaves" field.
  int? _sandSaves;
  int get sandSaves => _sandSaves ?? 0;
  bool hasSandSaves() => _sandSaves != null;

  // "sandSaveOpportunities" field.
  int? _sandSaveOpportunities;
  int get sandSaveOpportunities => _sandSaveOpportunities ?? 0;
  bool hasSandSaveOpportunities() => _sandSaveOpportunities != null;

  // "upAndDowns" field.
  int? _upAndDowns;
  int get upAndDowns => _upAndDowns ?? 0;
  bool hasUpAndDowns() => _upAndDowns != null;

  // "upAndDownOpportunities" field.
  int? _upAndDownOpportunities;
  int get upAndDownOpportunities => _upAndDownOpportunities ?? 0;
  bool hasUpAndDownOpportunities() => _upAndDownOpportunities != null;

  // "driving" field.
  DrivingStatsStruct? _driving;
  DrivingStatsStruct get driving => _driving ?? DrivingStatsStruct();
  bool hasDriving() => _driving != null;

  // "approach" field.
  ApproachStatsStruct? _approach;
  ApproachStatsStruct get approach => _approach ?? ApproachStatsStruct();
  bool hasApproach() => _approach != null;

  // "shortGame" field.
  ShortGameStatsStruct? _shortGame;
  ShortGameStatsStruct get shortGame => _shortGame ?? ShortGameStatsStruct();
  bool hasShortGame() => _shortGame != null;

  // "putting" field.
  PuttingStatsStruct? _putting;
  PuttingStatsStruct get putting => _putting ?? PuttingStatsStruct();
  bool hasPutting() => _putting != null;

  // "preRoundMood" field.
  String? _preRoundMood;
  String get preRoundMood => _preRoundMood ?? '';
  bool hasPreRoundMood() => _preRoundMood != null;

  // "postRoundMood" field.
  String? _postRoundMood;
  String get postRoundMood => _postRoundMood ?? '';
  bool hasPostRoundMood() => _postRoundMood != null;

  // "mentalFocus" field.
  int? _mentalFocus;
  int get mentalFocus => _mentalFocus ?? 0;
  bool hasMentalFocus() => _mentalFocus != null;

  // "courseManagement" field.
  int? _courseManagement;
  int get courseManagement => _courseManagement ?? 0;
  bool hasCourseManagement() => _courseManagement != null;

  // "emotionalControl" field.
  int? _emotionalControl;
  int get emotionalControl => _emotionalControl ?? 0;
  bool hasEmotionalControl() => _emotionalControl != null;

  // "weather" field.
  WeatherStruct? _weather;
  WeatherStruct get weather => _weather ?? WeatherStruct();
  bool hasWeather() => _weather != null;

  // "courseCondition" field.
  String? _courseCondition;
  String get courseCondition => _courseCondition ?? '';
  bool hasCourseCondition() => _courseCondition != null;

  // "notes" field.
  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  // "lessonsLearned" field.
  String? _lessonsLearned;
  String get lessonsLearned => _lessonsLearned ?? '';
  bool hasLessonsLearned() => _lessonsLearned != null;

  // "keyMoments" field.
  String? _keyMoments;
  String get keyMoments => _keyMoments ?? '';
  bool hasKeyMoments() => _keyMoments != null;

  // "aiInsightsGenerated" field.
  bool? _aiInsightsGenerated;
  bool get aiInsightsGenerated => _aiInsightsGenerated ?? false;
  bool hasAiInsightsGenerated() => _aiInsightsGenerated != null;

  // "aiProcessingStatus" field.
  String? _aiProcessingStatus;
  String get aiProcessingStatus => _aiProcessingStatus ?? '';
  bool hasAiProcessingStatus() => _aiProcessingStatus != null;

  // "journalEntries" field.
  List<String>? _journalEntries;
  List<String> get journalEntries => _journalEntries ?? const [];
  bool hasJournalEntries() => _journalEntries != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  // "isValid" field.
  bool? _isValid;
  bool get isValid => _isValid ?? false;
  bool hasIsValid() => _isValid != null;

  // "validationErrors" field.
  List<String>? _validationErrors;
  List<String> get validationErrors => _validationErrors ?? const [];
  bool hasValidationErrors() => _validationErrors != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _date = snapshotData['date'] as DateTime?;
    _courseName = snapshotData['courseName'] as String?;
    _courseId = snapshotData['courseId'] as String?;
    _teeBox = snapshotData['teeBox'] as String?;
    _courseRating = castToType<double>(snapshotData['courseRating']);
    _slopeRating = castToType<double>(snapshotData['slopeRating']);
    _score = castToType<int>(snapshotData['score']);
    _parTotal = castToType<int>(snapshotData['parTotal']);
    _scoreToPar = castToType<int>(snapshotData['scoreToPar']);
    _totalPutts = castToType<int>(snapshotData['totalPutts']);
    _fairwaysHit = castToType<int>(snapshotData['fairwaysHit']);
    _fairwaysTotal = castToType<int>(snapshotData['fairwaysTotal']);
    _greensInRegulation = castToType<int>(snapshotData['greensInRegulation']);
    _greensTotal = castToType<int>(snapshotData['greensTotal']);
    _penalties = castToType<int>(snapshotData['penalties']);
    _sandSaves = castToType<int>(snapshotData['sandSaves']);
    _sandSaveOpportunities = castToType<int>(snapshotData['sandSaveOpportunities']);
    _upAndDowns = castToType<int>(snapshotData['upAndDowns']);
    _upAndDownOpportunities = castToType<int>(snapshotData['upAndDownOpportunities']);
    _driving = snapshotData['driving'] is DrivingStatsStruct
        ? snapshotData['driving']
        : DrivingStatsStruct.maybeFromMap(snapshotData['driving']);
    _approach = snapshotData['approach'] is ApproachStatsStruct
        ? snapshotData['approach']
        : ApproachStatsStruct.maybeFromMap(snapshotData['approach']);
    _shortGame = snapshotData['shortGame'] is ShortGameStatsStruct
        ? snapshotData['shortGame']
        : ShortGameStatsStruct.maybeFromMap(snapshotData['shortGame']);
    _putting = snapshotData['putting'] is PuttingStatsStruct
        ? snapshotData['putting']
        : PuttingStatsStruct.maybeFromMap(snapshotData['putting']);
    _preRoundMood = snapshotData['preRoundMood'] as String?;
    _postRoundMood = snapshotData['postRoundMood'] as String?;
    _mentalFocus = castToType<int>(snapshotData['mentalFocus']);
    _courseManagement = castToType<int>(snapshotData['courseManagement']);
    _emotionalControl = castToType<int>(snapshotData['emotionalControl']);
    _weather = snapshotData['weather'] is WeatherStruct
        ? snapshotData['weather']
        : WeatherStruct.maybeFromMap(snapshotData['weather']);
    _courseCondition = snapshotData['courseCondition'] as String?;
    _notes = snapshotData['notes'] as String?;
    _lessonsLearned = snapshotData['lessonsLearned'] as String?;
    _keyMoments = snapshotData['keyMoments'] as String?;
    _aiInsightsGenerated = snapshotData['aiInsightsGenerated'] as bool?;
    _aiProcessingStatus = snapshotData['aiProcessingStatus'] as String?;
    _journalEntries = getDataList(snapshotData['journalEntries']);
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
    _isValid = snapshotData['isValid'] as bool?;
    _validationErrors = getDataList(snapshotData['validationErrors']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('golf_rounds');

  static Stream<GolfRoundsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GolfRoundsRecord.fromSnapshot(s));

  static Future<GolfRoundsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => GolfRoundsRecord.fromSnapshot(s));

  static GolfRoundsRecord fromSnapshot(DocumentSnapshot snapshot) => GolfRoundsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GolfRoundsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GolfRoundsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GolfRoundsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GolfRoundsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
} 