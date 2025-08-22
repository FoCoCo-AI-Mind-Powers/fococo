import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DashboardDataRecord extends FirestoreRecord {
  DashboardDataRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // User metrics
  int? _currentStreak;
  int get currentStreak => _currentStreak ?? 0;
  bool hasCurrentStreak() => _currentStreak != null;

  int? _longestStreak;
  int get longestStreak => _longestStreak ?? 0;
  bool hasLongestStreak() => _longestStreak != null;

  String? _streakType;
  String get streakType => _streakType ?? 'Training';
  bool hasStreakType() => _streakType != null;

  bool? _isStreakActive;
  bool get isStreakActive => _isStreakActive ?? true;
  bool hasIsStreakActive() => _isStreakActive != null;

  // Performance metrics
  double? _mentalFocusScore;
  double get mentalFocusScore => _mentalFocusScore ?? 0.0;
  bool hasMentalFocusScore() => _mentalFocusScore != null;

  double? _mentalFocusTrend;
  double get mentalFocusTrend => _mentalFocusTrend ?? 0.0;
  bool hasMentalFocusTrend() => _mentalFocusTrend != null;

  double? _confidenceScore;
  double get confidenceScore => _confidenceScore ?? 0.0;
  bool hasConfidenceScore() => _confidenceScore != null;

  double? _confidenceTrend;
  double get confidenceTrend => _confidenceTrend ?? 0.0;
  bool hasConfidenceTrend() => _confidenceTrend != null;

  double? _controlScore;
  double get controlScore => _controlScore ?? 0.0;
  bool hasControlScore() => _controlScore != null;

  double? _controlTrend;
  double get controlTrend => _controlTrend ?? 0.0;
  bool hasControlTrend() => _controlTrend != null;

  // Weekly progress data
  List<double>? _weeklyProgress;
  List<double> get weeklyProgress => _weeklyProgress ?? const [0, 0, 0, 0, 0, 0, 0];
  bool hasWeeklyProgress() => _weeklyProgress != null;

  // Recent activities
  List<DocumentReference>? _recentActivities;
  List<DocumentReference> get recentActivities => _recentActivities ?? const [];
  bool hasRecentActivities() => _recentActivities != null;

  // Mindfulness data
  int? _totalMindfulMinutes;
  int get totalMindfulMinutes => _totalMindfulMinutes ?? 0;
  bool hasTotalMindfulMinutes() => _totalMindfulMinutes != null;

  int? _weeklyMindfulSessions;
  int get weeklyMindfulSessions => _weeklyMindfulSessions ?? 0;
  bool hasWeeklyMindfulSessions() => _weeklyMindfulSessions != null;

  String? _currentMindfulnessGoal;
  String get currentMindfulnessGoal => _currentMindfulnessGoal ?? 'Daily meditation';
  bool hasCurrentMindfulnessGoal() => _currentMindfulnessGoal != null;

  // Golf performance
  double? _averageScore;
  double get averageScore => _averageScore ?? 0.0;
  bool hasAverageScore() => _averageScore != null;

  double? _handicap;
  double get handicap => _handicap ?? 0.0;
  bool hasHandicap() => _handicap != null;

  int? _roundsThisMonth;
  int get roundsThisMonth => _roundsThisMonth ?? 0;
  bool hasRoundsThisMonth() => _roundsThisMonth != null;

  // Goals and achievements
  List<String>? _activeGoals;
  List<String> get activeGoals => _activeGoals ?? const [];
  bool hasActiveGoals() => _activeGoals != null;

  List<String>? _recentAchievements;
  List<String> get recentAchievements => _recentAchievements ?? const [];
  bool hasRecentAchievements() => _recentAchievements != null;

  // User preferences
  String? _preferredTrainingTime;
  String get preferredTrainingTime => _preferredTrainingTime ?? 'Morning';
  bool hasPreferredTrainingTime() => _preferredTrainingTime != null;

  List<String>? _focusAreas;
  List<String> get focusAreas => _focusAreas ?? const ['Mental Game', 'Putting', 'Course Management'];
  bool hasFocusAreas() => _focusAreas != null;

  // AI insights
  String? _dailyInsight;
  String get dailyInsight => _dailyInsight ?? 'Focus on your pre-shot routine today';
  bool hasDailyInsight() => _dailyInsight != null;

  String? _weeklyChallenge;
  String get weeklyChallenge => _weeklyChallenge ?? 'Complete 5 mindfulness sessions';
  bool hasWeeklyChallenge() => _weeklyChallenge != null;

  void _initializeFields() {
    _currentStreak = castToType<int>(snapshotData['currentStreak']);
    _longestStreak = castToType<int>(snapshotData['longestStreak']);
    _streakType = snapshotData['streakType'] as String?;
    _isStreakActive = snapshotData['isStreakActive'] as bool?;
    _mentalFocusScore = castToType<double>(snapshotData['mentalFocusScore']);
    _mentalFocusTrend = castToType<double>(snapshotData['mentalFocusTrend']);
    _confidenceScore = castToType<double>(snapshotData['confidenceScore']);
    _confidenceTrend = castToType<double>(snapshotData['confidenceTrend']);
    _controlScore = castToType<double>(snapshotData['controlScore']);
    _controlTrend = castToType<double>(snapshotData['controlTrend']);
    _weeklyProgress = getDataList(snapshotData['weeklyProgress']);
    _recentActivities = getDataList(snapshotData['recentActivities']);
    _totalMindfulMinutes = castToType<int>(snapshotData['totalMindfulMinutes']);
    _weeklyMindfulSessions = castToType<int>(snapshotData['weeklyMindfulSessions']);
    _currentMindfulnessGoal = snapshotData['currentMindfulnessGoal'] as String?;
    _averageScore = castToType<double>(snapshotData['averageScore']);
    _handicap = castToType<double>(snapshotData['handicap']);
    _roundsThisMonth = castToType<int>(snapshotData['roundsThisMonth']);
    _activeGoals = getDataList(snapshotData['activeGoals']);
    _recentAchievements = getDataList(snapshotData['recentAchievements']);
    _preferredTrainingTime = snapshotData['preferredTrainingTime'] as String?;
    _focusAreas = getDataList(snapshotData['focusAreas']);
    _dailyInsight = snapshotData['dailyInsight'] as String?;
    _weeklyChallenge = snapshotData['weeklyChallenge'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('dashboard_data');

  static Stream<DashboardDataRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DashboardDataRecord.fromSnapshot(s));

  static Future<DashboardDataRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DashboardDataRecord.fromSnapshot(s));

  static DashboardDataRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DashboardDataRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DashboardDataRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DashboardDataRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DashboardDataRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DashboardDataRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDashboardDataRecordData({
  int? currentStreak,
  int? longestStreak,
  String? streakType,
  bool? isStreakActive,
  double? mentalFocusScore,
  double? mentalFocusTrend,
  double? confidenceScore,
  double? confidenceTrend,
  double? controlScore,
  double? controlTrend,
  int? totalMindfulMinutes,
  int? weeklyMindfulSessions,
  String? currentMindfulnessGoal,
  double? averageScore,
  double? handicap,
  int? roundsThisMonth,
  String? preferredTrainingTime,
  String? dailyInsight,
  String? weeklyChallenge,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'streakType': streakType,
      'isStreakActive': isStreakActive,
      'mentalFocusScore': mentalFocusScore,
      'mentalFocusTrend': mentalFocusTrend,
      'confidenceScore': confidenceScore,
      'confidenceTrend': confidenceTrend,
      'controlScore': controlScore,
      'controlTrend': controlTrend,
      'totalMindfulMinutes': totalMindfulMinutes,
      'weeklyMindfulSessions': weeklyMindfulSessions,
      'currentMindfulnessGoal': currentMindfulnessGoal,
      'averageScore': averageScore,
      'handicap': handicap,
      'roundsThisMonth': roundsThisMonth,
      'preferredTrainingTime': preferredTrainingTime,
      'dailyInsight': dailyInsight,
      'weeklyChallenge': weeklyChallenge,
    }.withoutNulls,
  );

  return firestoreData;
}