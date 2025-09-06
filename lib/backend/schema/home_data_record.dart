import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class HomeDataRecord extends FirestoreRecord {
  HomeDataRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // Mental score data
  int? _mentalScore;
  int get mentalScore => _mentalScore ?? 0;
  bool hasMentalScore() => _mentalScore != null;

  String? _mentalScoreLabel;
  String get mentalScoreLabel => _mentalScoreLabel ?? 'Mental';
  bool hasMentalScoreLabel() => _mentalScoreLabel != null;

  // Golf statistics
  String? _teeDistance;
  String get teeDistance => _teeDistance ?? '0';
  bool hasTeeDistance() => _teeDistance != null;

  String? _teeDistanceUnit;
  String get teeDistanceUnit => _teeDistanceUnit ?? 'TEE';
  bool hasTeeDistanceUnit() => _teeDistanceUnit != null;

  String? _ebedScore;
  String get ebedScore => _ebedScore ?? '0';
  bool hasEbedScore() => _ebedScore != null;

  String? _ebedLabel;
  String get ebedLabel => _ebedLabel ?? 'EBED';
  bool hasEbedLabel() => _ebedLabel != null;

  String? _stiksaScore;
  String get stiksaScore => _stiksaScore ?? '0';
  bool hasStiksaScore() => _stiksaScore != null;

  String? _stiksaLabel;
  String get stiksaLabel => _stiksaLabel ?? 'STIKSA';
  bool hasStiksaLabel() => _stiksaLabel != null;

  // Performance data
  String? _performanceTrend;
  String get performanceTrend => _performanceTrend ?? 'Your performance is trending upward';
  bool hasPerformanceTrend() => _performanceTrend != null;

  List<double>? _performanceData;
  List<double> get performanceData => _performanceData ?? const [];
  bool hasPerformanceData() => _performanceData != null;

  // Round data
  String? _lastRoundScore;
  String get lastRoundScore => _lastRoundScore ?? '0';
  bool hasLastRoundScore() => _lastRoundScore != null;

  String? _lastRoundDiff;
  String get lastRoundDiff => _lastRoundDiff ?? '+0';
  bool hasLastRoundDiff() => _lastRoundDiff != null;

  String? _lastRoundStatus;
  String get lastRoundStatus => _lastRoundStatus ?? 'Bonus';
  bool hasLastRoundStatus() => _lastRoundStatus != null;

  String? _lastRoundType;
  String get lastRoundType => _lastRoundType ?? 'GOLD';
  bool hasLastRoundType() => _lastRoundType != null;

  // User info
  String? _userName;
  String get userName => _userName ?? 'User';
  bool hasUserName() => _userName != null;

  String? _welcomeMessage;
  String get welcomeMessage => _welcomeMessage ?? 'Welcome to FoCoCo';
  bool hasWelcomeMessage() => _welcomeMessage != null;

  String? _coachMessage;
  String get coachMessage => _coachMessage ?? 'Personates your mental game with expert guides travingic';
  bool hasCoachMessage() => _coachMessage != null;

  // Premium status
  bool? _isPremium;
  bool get isPremium => _isPremium ?? false;
  bool hasIsPremium() => _isPremium != null;

  // AI Insights
  String? _aiInsightTitle;
  String get aiInsightTitle => _aiInsightTitle ?? 'AQ insights';
  bool hasAiInsightTitle() => _aiInsightTitle != null;

  String? _aiInsightContent;
  String get aiInsightContent => _aiInsightContent ?? '';
  bool hasAiInsightContent() => _aiInsightContent != null;

  void _initializeFields() {
    _mentalScore = castToType<int>(snapshotData['mentalScore']);
    _mentalScoreLabel = snapshotData['mentalScoreLabel'] as String?;
    _teeDistance = snapshotData['teeDistance'] as String?;
    _teeDistanceUnit = snapshotData['teeDistanceUnit'] as String?;
    _ebedScore = snapshotData['ebedScore'] as String?;
    _ebedLabel = snapshotData['ebedLabel'] as String?;
    _stiksaScore = snapshotData['stiksaScore'] as String?;
    _stiksaLabel = snapshotData['stiksaLabel'] as String?;
    _performanceTrend = snapshotData['performanceTrend'] as String?;
    _performanceData = getDataList(snapshotData['performanceData']);
    _lastRoundScore = snapshotData['lastRoundScore'] as String?;
    _lastRoundDiff = snapshotData['lastRoundDiff'] as String?;
    _lastRoundStatus = snapshotData['lastRoundStatus'] as String?;
    _lastRoundType = snapshotData['lastRoundType'] as String?;
    _userName = snapshotData['userName'] as String?;
    _welcomeMessage = snapshotData['welcomeMessage'] as String?;
    _coachMessage = snapshotData['coachMessage'] as String?;
    _isPremium = snapshotData['isPremium'] as bool?;
    _aiInsightTitle = snapshotData['aiInsightTitle'] as String?;
    _aiInsightContent = snapshotData['aiInsightContent'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('home_data');

  static Stream<HomeDataRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => HomeDataRecord.fromSnapshot(s));

  static Future<HomeDataRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => HomeDataRecord.fromSnapshot(s));

  static HomeDataRecord fromSnapshot(DocumentSnapshot snapshot) =>
      HomeDataRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static HomeDataRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      HomeDataRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'HomeDataRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is HomeDataRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createHomeDataRecordData({
  int? mentalScore,
  String? mentalScoreLabel,
  String? teeDistance,
  String? teeDistanceUnit,
  String? ebedScore,
  String? ebedLabel,
  String? stiksaScore,
  String? stiksaLabel,
  String? performanceTrend,
  String? lastRoundScore,
  String? lastRoundDiff,
  String? lastRoundStatus,
  String? lastRoundType,
  String? userName,
  String? welcomeMessage,
  String? coachMessage,
  bool? isPremium,
  String? aiInsightTitle,
  String? aiInsightContent,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'mentalScore': mentalScore,
      'mentalScoreLabel': mentalScoreLabel,
      'teeDistance': teeDistance,
      'teeDistanceUnit': teeDistanceUnit,
      'ebedScore': ebedScore,
      'ebedLabel': ebedLabel,
      'stiksaScore': stiksaScore,
      'stiksaLabel': stiksaLabel,
      'performanceTrend': performanceTrend,
      'lastRoundScore': lastRoundScore,
      'lastRoundDiff': lastRoundDiff,
      'lastRoundStatus': lastRoundStatus,
      'lastRoundType': lastRoundType,
      'userName': userName,
      'welcomeMessage': welcomeMessage,
      'coachMessage': coachMessage,
      'isPremium': isPremium,
      'aiInsightTitle': aiInsightTitle,
      'aiInsightContent': aiInsightContent,
    }.withoutNulls,
  );

  return firestoreData;
}

class HomeDataRecordDocumentEquality implements Equality<HomeDataRecord> {
  const HomeDataRecordDocumentEquality();

  @override
  bool equals(HomeDataRecord? e1, HomeDataRecord? e2) {
    const listEquality = ListEquality();
    return e1?.mentalScore == e2?.mentalScore &&
        e1?.mentalScoreLabel == e2?.mentalScoreLabel &&
        e1?.teeDistance == e2?.teeDistance &&
        e1?.teeDistanceUnit == e2?.teeDistanceUnit &&
        e1?.ebedScore == e2?.ebedScore &&
        e1?.ebedLabel == e2?.ebedLabel &&
        e1?.stiksaScore == e2?.stiksaScore &&
        e1?.stiksaLabel == e2?.stiksaLabel &&
        e1?.performanceTrend == e2?.performanceTrend &&
        listEquality.equals(e1?.performanceData, e2?.performanceData) &&
        e1?.lastRoundScore == e2?.lastRoundScore &&
        e1?.lastRoundDiff == e2?.lastRoundDiff &&
        e1?.lastRoundStatus == e2?.lastRoundStatus &&
        e1?.lastRoundType == e2?.lastRoundType &&
        e1?.userName == e2?.userName &&
        e1?.welcomeMessage == e2?.welcomeMessage &&
        e1?.coachMessage == e2?.coachMessage &&
        e1?.isPremium == e2?.isPremium &&
        e1?.aiInsightTitle == e2?.aiInsightTitle &&
        e1?.aiInsightContent == e2?.aiInsightContent;
  }

  @override
  int hash(HomeDataRecord? e) => const ListEquality().hash([
        e?.mentalScore,
        e?.mentalScoreLabel,
        e?.teeDistance,
        e?.teeDistanceUnit,
        e?.ebedScore,
        e?.ebedLabel,
        e?.stiksaScore,
        e?.stiksaLabel,
        e?.performanceTrend,
        e?.performanceData,
        e?.lastRoundScore,
        e?.lastRoundDiff,
        e?.lastRoundStatus,
        e?.lastRoundType,
        e?.userName,
        e?.welcomeMessage,
        e?.coachMessage,
        e?.isPremium,
        e?.aiInsightTitle,
        e?.aiInsightContent
      ]);

  @override
  bool isValidKey(Object? o) => o is HomeDataRecord;
}

