import 'dart:async';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/backend/schema/util/schema_util.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class MentalSessionsRecord extends FirestoreRecord {
  MentalSessionsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "moduleId" field.
  String? _moduleId;
  String get moduleId => _moduleId ?? '';
  bool hasModuleId() => _moduleId != null;

  // "moduleTitle" field.
  String? _moduleTitle;
  String get moduleTitle => _moduleTitle ?? '';
  bool hasModuleTitle() => _moduleTitle != null;

  // "dateStarted" field.
  DateTime? _dateStarted;
  DateTime? get dateStarted => _dateStarted;
  bool hasDateStarted() => _dateStarted != null;

  // "dateCompleted" field.
  DateTime? _dateCompleted;
  DateTime? get dateCompleted => _dateCompleted;
  bool hasDateCompleted() => _dateCompleted != null;

  // "duration" field.
  int? _duration;
  int get duration => _duration ?? 0;
  bool hasDuration() => _duration != null;

  // "completionStatus" field.
  String? _completionStatus;
  String get completionStatus => _completionStatus ?? '';
  bool hasCompletionStatus() => _completionStatus != null;

  // "sectionsCompleted" field.
  List<String>? _sectionsCompleted;
  List<String> get sectionsCompleted => _sectionsCompleted ?? const [];
  bool hasSectionsCompleted() => _sectionsCompleted != null;

  // "totalSections" field.
  int? _totalSections;
  int get totalSections => _totalSections ?? 0;
  bool hasTotalSections() => _totalSections != null;

  // "progressPercentage" field.
  double? _progressPercentage;
  double get progressPercentage => _progressPercentage ?? 0.0;
  bool hasProgressPercentage() => _progressPercentage != null;

  // "userMoodBefore" field.
  String? _userMoodBefore;
  String get userMoodBefore => _userMoodBefore ?? '';
  bool hasUserMoodBefore() => _userMoodBefore != null;

  // "userMoodAfter" field.
  String? _userMoodAfter;
  String get userMoodAfter => _userMoodAfter ?? '';
  bool hasUserMoodAfter() => _userMoodAfter != null;

  // "perceivedValue" field.
  int? _perceivedValue;
  int get perceivedValue => _perceivedValue ?? 0;
  bool hasPerceivedValue() => _perceivedValue != null;

  // "journalEntry" field.
  String? _journalEntry;
  String get journalEntry => _journalEntry ?? '';
  bool hasJournalEntry() => _journalEntry != null;

  // "keyTakeaways" field.
  List<String>? _keyTakeaways;
  List<String> get keyTakeaways => _keyTakeaways ?? const [];
  bool hasKeyTakeaways() => _keyTakeaways != null;

  // "actionItems" field.
  List<String>? _actionItems;
  List<String> get actionItems => _actionItems ?? const [];
  bool hasActionItems() => _actionItems != null;

  // "linkedToRound" field.
  String? _linkedToRound;
  String get linkedToRound => _linkedToRound ?? '';
  bool hasLinkedToRound() => _linkedToRound != null;

  // "sessionContext" field.
  String? _sessionContext;
  String get sessionContext => _sessionContext ?? '';
  bool hasSessionContext() => _sessionContext != null;

  // "aiFeedbackReceived" field.
  bool? _aiFeedbackReceived;
  bool get aiFeedbackReceived => _aiFeedbackReceived ?? false;
  bool hasAiFeedbackReceived() => _aiFeedbackReceived != null;

  // "aiProcessingStatus" field.
  String? _aiProcessingStatus;
  String get aiProcessingStatus => _aiProcessingStatus ?? '';
  bool hasAiProcessingStatus() => _aiProcessingStatus != null;

  // "interruptions" field.
  int? _interruptions;
  int get interruptions => _interruptions ?? 0;
  bool hasInterruptions() => _interruptions != null;

  // "environment" field.
  String? _environment;
  String get environment => _environment ?? '';
  bool hasEnvironment() => _environment != null;

  // "isPartOfStreak" field.
  bool? _isPartOfStreak;
  bool get isPartOfStreak => _isPartOfStreak ?? false;
  bool hasIsPartOfStreak() => _isPartOfStreak != null;

  // "streakDay" field.
  int? _streakDay;
  int get streakDay => _streakDay ?? 0;
  bool hasStreakDay() => _streakDay != null;

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
    _moduleId = snapshotData['moduleId'] as String?;
    _moduleTitle = snapshotData['moduleTitle'] as String?;
    _dateStarted = snapshotData['dateStarted'] as DateTime?;
    _dateCompleted = snapshotData['dateCompleted'] as DateTime?;
    _duration = castToType<int>(snapshotData['duration']);
    _completionStatus = snapshotData['completionStatus'] as String?;
    _sectionsCompleted = getDataList(snapshotData['sectionsCompleted']);
    _totalSections = castToType<int>(snapshotData['totalSections']);
    _progressPercentage = castToType<double>(snapshotData['progressPercentage']);
    _userMoodBefore = snapshotData['userMoodBefore'] as String?;
    _userMoodAfter = snapshotData['userMoodAfter'] as String?;
    _perceivedValue = castToType<int>(snapshotData['perceivedValue']);
    _journalEntry = snapshotData['journalEntry'] as String?;
    _keyTakeaways = getDataList(snapshotData['keyTakeaways']);
    _actionItems = getDataList(snapshotData['actionItems']);
    _linkedToRound = snapshotData['linkedToRound'] as String?;
    _sessionContext = snapshotData['sessionContext'] as String?;
    _aiFeedbackReceived = snapshotData['aiFeedbackReceived'] as bool?;
    _aiProcessingStatus = snapshotData['aiProcessingStatus'] as String?;
    _interruptions = castToType<int>(snapshotData['interruptions']);
    _environment = snapshotData['environment'] as String?;
    _isPartOfStreak = snapshotData['isPartOfStreak'] as bool?;
    _streakDay = castToType<int>(snapshotData['streakDay']);
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mental_sessions');

  static Stream<MentalSessionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MentalSessionsRecord.fromSnapshot(s));

  static Future<MentalSessionsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MentalSessionsRecord.fromSnapshot(s));

  static MentalSessionsRecord fromSnapshot(DocumentSnapshot snapshot) => MentalSessionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MentalSessionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MentalSessionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MentalSessionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MentalSessionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
} 