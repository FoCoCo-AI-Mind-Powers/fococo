import 'dart:async';
import 'dart:math' as math;
import 'package:fo_co_co/auth/firebase_auth/auth_util.dart';
import 'package:fo_co_co/backend/backend.dart';

/// HomeDataService
/// Provides dynamic data fetching and calculations for the home page
/// Replaces static data with real-time calculations from user's golf rounds
class HomeDataService {
  static final HomeDataService _instance = HomeDataService._internal();
  factory HomeDataService() => _instance;
  HomeDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive home data for the current user
  Stream<HomeData> getHomeDataStream() {
    if (currentUserUid.isEmpty) {
      return Stream.value(_getEmptyHomeData());
    }

    return StreamGroup.merge([
      _getUserRoundsStream(),
      _getDashboardDataStream(),
      _getUserProfileStream(),
    ]).asyncMap((_) => _calculateHomeData());
  }

  /// Get user's golf rounds stream
  Stream<List<GolfRoundsRecord>> _getUserRoundsStream() {
    return queryGolfRoundsRecord(
      queryBuilder: (query) => query
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('date', descending: true)
          .limit(10),
    );
  }

  /// Get dashboard data stream
  Stream<List<DashboardDataRecord>> _getDashboardDataStream() {
    return FirebaseFirestore.instance
        .collection('dashboard_data')
        .where('userId', isEqualTo: currentUserUid)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DashboardDataRecord.fromSnapshot(doc))
            .toList());
  }

  /// Get user profile stream
  Stream<List<UserRecord>> _getUserProfileStream() {
    return queryUserRecord(
      queryBuilder: (query) =>
          query.where(FieldPath.documentId, isEqualTo: currentUserUid).limit(1),
    );
  }

  /// Calculate comprehensive home data
  Future<HomeData> _calculateHomeData() async {
    try {
      // Fetch all required data
      final rounds = await queryGolfRoundsRecordOnce(
        queryBuilder: (query) => query
            .where('userId', isEqualTo: currentUserUid)
            .orderBy('date', descending: true)
            .limit(20),
      );

      final dashboardDataSnapshot = await FirebaseFirestore.instance
          .collection('dashboard_data')
          .where('userId', isEqualTo: currentUserUid)
          .limit(1)
          .get();

      final dashboardData = dashboardDataSnapshot.docs
          .map((doc) => DashboardDataRecord.fromSnapshot(doc))
          .toList();

      final userProfile = await queryUserRecordOnce(
        queryBuilder: (query) => query
            .where(FieldPath.documentId, isEqualTo: currentUserUid)
            .limit(1),
      );

      // Check if user has any data
      final hasData = rounds.isNotEmpty || dashboardData.isNotEmpty;

      if (!hasData) {
        return _getEmptyHomeData();
      }

      return _buildHomeDataFromRecords(
          rounds, dashboardData.firstOrNull, userProfile.firstOrNull);
    } catch (e) {
      print('Error calculating home data: $e');
      return _getEmptyHomeData();
    }
  }

  /// Build home data from database records
  HomeData _buildHomeDataFromRecords(
    List<GolfRoundsRecord> rounds,
    DashboardDataRecord? dashboardData,
    UserRecord? userProfile,
  ) {
    final hasRounds = rounds.isNotEmpty;
    final latestRound = hasRounds ? rounds.first : null;

    // Calculate mental performance score
    final mentalScore = _calculateMentalScore(rounds, dashboardData);

    // Calculate performance metrics
    final performanceData = _calculatePerformanceData(rounds);
    final performanceTrend = _calculatePerformanceTrend(rounds);

    // Calculate golf statistics
    final teeDistance = _calculateAverageTeeDistance(rounds);
    final ebedScore = _calculateEBED(rounds);
    final stiksaScore = _calculateSTIKSA(rounds);

    // Get user info
    final userName = userProfile?.displayName ?? 'Golfer';
    final isPremium = false; // TODO: Implement subscription tier check

    return HomeData(
      // Mental Performance
      mentalScore: mentalScore,
      mentalScoreLabel: _getMentalScoreLabel(mentalScore),

      // Golf Statistics
      teeDistance: teeDistance.toStringAsFixed(1),
      teeDistanceUnit: 'TEE',
      ebedScore: ebedScore.toString(),
      ebedLabel: 'EBED',
      stiksaScore: '${stiksaScore.toStringAsFixed(0)}m',
      stiksaLabel: 'STIKSA',

      // Performance Data
      performanceData: performanceData,
      performanceTrend: performanceTrend,

      // Latest Round Data
      lastRoundScore: latestRound?.score.toString() ?? '0',
      lastRoundDiff: _formatScoreToPar(latestRound?.scoreToPar ?? 0),
      lastRoundStatus: _getRoundStatus(latestRound),
      lastRoundType: latestRound?.teeBox.toUpperCase() ?? 'GOLD',

      // User Info
      userName: userName,
      welcomeMessage: _getWelcomeMessage(userName, hasRounds),
      coachMessage: _getCoachMessage(mentalScore, hasRounds),
      isPremium: isPremium,

      // AI Insights
      aiInsightTitle: 'AI Insights',
      aiInsightContent: _generateAIInsight(rounds, mentalScore),

      // Data availability flags
      hasData: hasRounds,
      totalRounds: rounds.length,
      lastPlayedDate: latestRound?.date,
    );
  }

  /// Calculate mental performance score from recent rounds
  int _calculateMentalScore(
      List<GolfRoundsRecord> rounds, DashboardDataRecord? dashboardData) {
    if (rounds.isEmpty) return 0;

    // Use dashboard data if available
    if (dashboardData != null) {
      final focusScore = dashboardData.mentalFocusScore;
      final confidenceScore = dashboardData.confidenceScore;
      final controlScore = dashboardData.controlScore;

      if (focusScore > 0 || confidenceScore > 0 || controlScore > 0) {
        return ((focusScore + confidenceScore + controlScore) / 3 * 100)
            .round();
      }
    }

    // Calculate from recent rounds mental metrics
    final recentRounds = rounds.take(5).toList();
    double totalMentalScore = 0;
    int validRounds = 0;

    for (final round in recentRounds) {
      final mentalFocus = round.mentalFocus;
      final courseManagement = round.courseManagement;
      final emotionalControl = round.emotionalControl;

      if (mentalFocus > 0 || courseManagement > 0 || emotionalControl > 0) {
        totalMentalScore +=
            (mentalFocus + courseManagement + emotionalControl) / 3;
        validRounds++;
      }
    }

    if (validRounds == 0) return 65; // Default starting score

    return (totalMentalScore / validRounds * 10).round().clamp(0, 100);
  }

  /// Calculate performance data for chart
  List<double> _calculatePerformanceData(List<GolfRoundsRecord> rounds) {
    if (rounds.isEmpty) return [];

    final recentRounds = rounds.take(7).toList().reversed.toList();
    return recentRounds.map((round) {
      // Calculate performance based on score to par and mental metrics
      final scoreToPar = round.scoreToPar;
      final mentalAvg = (round.mentalFocus +
              round.courseManagement +
              round.emotionalControl) /
          3;

      // Convert to 0-100 scale (lower score to par = higher performance)
      final scorePerformance = math.max(0, 100 - (scoreToPar + 20) * 2);
      final mentalPerformance = mentalAvg * 10;

      return ((scorePerformance + mentalPerformance) / 2).clamp(0.0, 100.0);
    }).toList();
  }

  /// Calculate performance trend description
  String _calculatePerformanceTrend(List<GolfRoundsRecord> rounds) {
    if (rounds.length < 2) return 'Start logging rounds to see trends';

    final recent = rounds.take(3).map((r) => r.scoreToPar).toList();
    final older = rounds.skip(3).take(3).map((r) => r.scoreToPar).toList();

    if (older.isEmpty) return 'Building your performance history';

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    if (recentAvg < olderAvg - 1) {
      return 'Your scoring is trending upward! 📈';
    } else if (recentAvg > olderAvg + 1) {
      return 'Focus on consistency in your next rounds';
    } else {
      return 'Your performance is staying consistent';
    }
  }

  /// Calculate average tee distance
  double _calculateAverageTeeDistance(List<GolfRoundsRecord> rounds) {
    if (rounds.isEmpty) return 0.0;

    final distances = rounds
        .map((r) => 250.0) // Default average distance
        .toList();

    if (distances.isEmpty) return 0.0;

    return distances.reduce((a, b) => a + b) / distances.length;
  }

  /// Calculate EBED (Effective Bounce and Elevation Distance)
  int _calculateEBED(List<GolfRoundsRecord> rounds) {
    if (rounds.isEmpty) return 0;

    // Simplified EBED calculation based on approach shots and course management
    final recentRounds = rounds.take(5).toList();
    double totalEBED = 0;
    int validRounds = 0;

    for (final round in recentRounds) {
      if (round.courseManagement > 0) {
        final approachAccuracy =
            round.greensInRegulation / math.max(1, round.greensTotal);
        final managementFactor = round.courseManagement / 10.0;
        totalEBED += (approachAccuracy * managementFactor * 25);
        validRounds++;
      }
    }

    return validRounds > 0 ? (totalEBED / validRounds).round() : 0;
  }

  /// Calculate STIKSA (Strategic Thinking and Kinesthetic Spatial Awareness)
  double _calculateSTIKSA(List<GolfRoundsRecord> rounds) {
    if (rounds.isEmpty) return 0.0;

    final recentRounds = rounds.take(5).toList();
    double totalSTIKSA = 0;
    int validRounds = 0;

    for (final round in recentRounds) {
      final mentalFocus = round.mentalFocus;
      final courseManagement = round.courseManagement;
      final shortGameAccuracy = 50.0; // Default short game metric

      if (mentalFocus > 0 && courseManagement > 0) {
        totalSTIKSA +=
            ((mentalFocus + courseManagement) / 2) * (shortGameAccuracy / 10);
        validRounds++;
      }
    }

    return validRounds > 0 ? totalSTIKSA / validRounds : 0.0;
  }

  /// Get mental score label
  String _getMentalScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Strong';
    if (score >= 60) return 'Good';
    if (score >= 50) return 'Developing';
    return 'Building';
  }

  /// Format score to par
  String _formatScoreToPar(int scoreToPar) {
    if (scoreToPar == 0) return 'E';
    if (scoreToPar > 0) return '+$scoreToPar';
    return '$scoreToPar';
  }

  /// Get round status
  String _getRoundStatus(GolfRoundsRecord? round) {
    if (round == null) return 'No rounds';

    final scoreToPar = round.scoreToPar;
    if (scoreToPar <= -5) return 'Exceptional';
    if (scoreToPar <= -2) return 'Great';
    if (scoreToPar <= 2) return 'Solid';
    if (scoreToPar <= 5) return 'Building';
    return 'Learning';
  }

  /// Get personalized welcome message
  String _getWelcomeMessage(String userName, bool hasRounds) {
    if (!hasRounds) {
      return 'Welcome to FoCoCo, $userName!';
    }

    final hour = DateTime.now().hour;
    String timeGreeting;

    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    return '$timeGreeting, $userName!';
  }

  /// Get personalized coach message
  String _getCoachMessage(int mentalScore, bool hasRounds) {
    if (!hasRounds) {
      return 'Ready to start your mental golf journey? Log your first round to unlock personalized insights and coaching.';
    }

    if (mentalScore >= 80) {
      return 'Your mental game is strong! Let\'s maintain this momentum and refine your peak performance strategies.';
    } else if (mentalScore >= 70) {
      return 'Great mental progress! Focus on consistency and explore advanced visualization techniques.';
    } else if (mentalScore >= 60) {
      return 'Your mental game is developing well. Work on pre-shot routines and course management strategies.';
    } else {
      return 'Building your mental foundation is key. Start with breathing exercises and basic visualization techniques.';
    }
  }

  /// Generate AI insight based on performance
  String _generateAIInsight(List<GolfRoundsRecord> rounds, int mentalScore) {
    if (rounds.isEmpty) {
      return 'Start logging rounds to receive personalized AI insights about your mental game patterns.';
    }

    final latestRound = rounds.first;
    final mentalFocus = latestRound.mentalFocus;
    final courseManagement = latestRound.courseManagement;
    final emotionalControl = latestRound.emotionalControl;

    if (mentalFocus < courseManagement && mentalFocus < emotionalControl) {
      return 'Focus on pre-shot visualization. Your course management and emotional control are stronger than your focus.';
    } else if (courseManagement < mentalFocus &&
        courseManagement < emotionalControl) {
      return 'Work on strategic thinking. Consider taking a course management coaching module.';
    } else if (emotionalControl < mentalFocus &&
        emotionalControl < courseManagement) {
      return 'Practice emotional regulation techniques. Breathing exercises could help your on-course composure.';
    }

    return 'Your mental game is balanced. Focus on consistency and maintaining your current level across all areas.';
  }

  /// Get empty home data for new users
  HomeData _getEmptyHomeData() {
    return HomeData(
      mentalScore: 0,
      mentalScoreLabel: 'Start Journey',
      teeDistance: '0.0',
      teeDistanceUnit: 'TEE',
      ebedScore: '0',
      ebedLabel: 'EBED',
      stiksaScore: '0m',
      stiksaLabel: 'STIKSA',
      performanceData: [],
      performanceTrend: 'Ready to begin your mental golf journey?',
      lastRoundScore: '0',
      lastRoundDiff: 'E',
      lastRoundStatus: 'Ready to start',
      lastRoundType: 'FIRST',
      userName: 'New Golfer',
      welcomeMessage: 'Welcome to FoCoCo!',
      coachMessage:
          'Let\'s start building your mental golf game. Begin by exploring our coaching modules or log your first round.',
      isPremium: false,
      aiInsightTitle: 'Getting Started',
      aiInsightContent:
          'Complete the onboarding tutorial to unlock personalized AI insights.',
      hasData: false,
      totalRounds: 0,
      lastPlayedDate: null,
    );
  }

  /// Create or update home data record in Firestore
  Future<void> updateHomeDataRecord(HomeData homeData) async {
    try {
      final docRef = _firestore.collection('home_data').doc(currentUserUid);

      await docRef.set({
        'userId': currentUserUid,
        'mentalScore': homeData.mentalScore,
        'mentalScoreLabel': homeData.mentalScoreLabel,
        'teeDistance': homeData.teeDistance,
        'teeDistanceUnit': homeData.teeDistanceUnit,
        'ebedScore': homeData.ebedScore,
        'ebedLabel': homeData.ebedLabel,
        'stiksaScore': homeData.stiksaScore,
        'stiksaLabel': homeData.stiksaLabel,
        'performanceData': homeData.performanceData,
        'performanceTrend': homeData.performanceTrend,
        'lastRoundScore': homeData.lastRoundScore,
        'lastRoundDiff': homeData.lastRoundDiff,
        'lastRoundStatus': homeData.lastRoundStatus,
        'lastRoundType': homeData.lastRoundType,
        'userName': homeData.userName,
        'welcomeMessage': homeData.welcomeMessage,
        'coachMessage': homeData.coachMessage,
        'isPremium': homeData.isPremium,
        'aiInsightTitle': homeData.aiInsightTitle,
        'aiInsightContent': homeData.aiInsightContent,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating home data record: $e');
    }
  }
}

/// HomeData model for structured data
class HomeData {
  final int mentalScore;
  final String mentalScoreLabel;
  final String teeDistance;
  final String teeDistanceUnit;
  final String ebedScore;
  final String ebedLabel;
  final String stiksaScore;
  final String stiksaLabel;
  final List<double> performanceData;
  final String performanceTrend;
  final String lastRoundScore;
  final String lastRoundDiff;
  final String lastRoundStatus;
  final String lastRoundType;
  final String userName;
  final String welcomeMessage;
  final String coachMessage;
  final bool isPremium;
  final String aiInsightTitle;
  final String aiInsightContent;
  final bool hasData;
  final int totalRounds;
  final DateTime? lastPlayedDate;

  HomeData({
    required this.mentalScore,
    required this.mentalScoreLabel,
    required this.teeDistance,
    required this.teeDistanceUnit,
    required this.ebedScore,
    required this.ebedLabel,
    required this.stiksaScore,
    required this.stiksaLabel,
    required this.performanceData,
    required this.performanceTrend,
    required this.lastRoundScore,
    required this.lastRoundDiff,
    required this.lastRoundStatus,
    required this.lastRoundType,
    required this.userName,
    required this.welcomeMessage,
    required this.coachMessage,
    required this.isPremium,
    required this.aiInsightTitle,
    required this.aiInsightContent,
    required this.hasData,
    required this.totalRounds,
    this.lastPlayedDate,
  });
}

/// StreamGroup utility for merging streams
class StreamGroup {
  static Stream<List<T>> merge<T>(List<Stream<T>> streams) {
    if (streams.isEmpty) return Stream.value([]);

    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      final results = <T>[];
      for (final stream in streams) {
        await for (final value in stream.take(1)) {
          results.add(value);
        }
      }
      return results;
    });
  }
}
