import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';
import '/backend/schema/mental_sessions_record.dart';
import '/ai_integration/models/mind_coach_models.dart';
import '/ai_integration/services/ai_coaching_service.dart';

/// Service for analyzing user data and generating personalized Mind Coach insights
class MindCoachAnalysisService {
  MindCoachAnalysisService._();
  static final MindCoachAnalysisService instance = MindCoachAnalysisService._();

  final AICoachingService _aiCoachingService = AICoachingService.instance;

  /// Generate personalized suggestions based on user's training and round data
  Future<List<MindCoachInsight>> generatePersonalizedSuggestions(
      String userId) async {
    try {
      final insights = <MindCoachInsight>[];

      // Analyze training consistency
      final consistencyInsight = await analyzeTrainingConsistency(userId);
      if (consistencyInsight != null) {
        insights.add(consistencyInsight);
      }

      // Analyze recovery patterns
      final recoveryInsight = await analyzeRecoveryPatterns(userId);
      if (recoveryInsight != null) {
        insights.add(recoveryInsight);
      }

      // Sort by priority
      insights.sort((a, b) => b.priority.compareTo(a.priority));

      return insights.take(2).toList(); // Return top 2 insights
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating personalized suggestions: $e');
      }
      return [];
    }
  }

  /// Analyze training consistency (focus routines, etc.)
  Future<MindCoachInsight?> analyzeTrainingConsistency(String userId) async {
    try {
      // Guard against empty userId - would cause permission denied
      if (userId.isEmpty) return null;
      
      // Get recent training sessions (last 14 days)
      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('dateStarted',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 14)),
              ))
          .orderBy('dateStarted', descending: true)
          .get();

      if (sessions.docs.isEmpty) return null;

      // Count focus-related sessions
      final focusSessions = sessions.docs.where((doc) {
        final session = MentalSessionsRecord.fromSnapshot(doc);
        return session.pillar.toLowerCase() == 'focus' && session.isCompleted;
      }).length;

      // If user has been consistent with focus routines
      if (focusSessions >= 3) {
        return MindCoachInsight(
          insightText: "You've been consistent in your focus routines.",
          suggestionType: 'consistency',
          priority: 8,
          actionText: "Continue Training",
        );
      }

      return null;
    } catch (e) {
      // Handle permission errors gracefully - don't log them as errors
      final errorStr = e.toString();
      if (errorStr.contains('permission-denied')) {
        // Permission denied is expected in some cases, silently return null
        return null;
      }
      if (kDebugMode) {
        print('❌ Error analyzing training consistency: $e');
      }
      return null;
    }
  }

  /// Analyze recovery patterns (resets after tough shots)
  Future<MindCoachInsight?> analyzeRecoveryPatterns(String userId) async {
    try {
      // Guard against empty userId - would cause permission denied
      if (userId.isEmpty) return null;
      
      // Get recent round logs
      final rounds = await RoundLogsRecord.collection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      if (rounds.docs.isEmpty) return null;

      // Analyze recovery holes
      int totalRecoveryHoles = 0;
      for (var doc in rounds.docs) {
        final round = RoundLogsRecord.fromSnapshot(doc);
        if (round.hasRecoveryHoles()) {
          totalRecoveryHoles += round.recoveryHoles.length;
        }
      }

      // If user has many recovery holes, suggest reset routine practice
      if (totalRecoveryHoles >= 5) {
        // Try to find a control module for reset routines
        final controlModules = await _findControlModules();
        final resetModule =
            controlModules.isNotEmpty ? controlModules.first : null;

        return MindCoachInsight(
          insightText: "Let's practice quicker resets after tough shots.",
          suggestionType: 'recovery',
          priority: 9,
          recommendedModuleId: resetModule?['moduleId'],
          recommendedModuleTitle: resetModule?['title'],
          actionText: "Continue Training",
        );
      }

      return null;
    } catch (e) {
      // Handle permission errors gracefully - don't log them as errors
      final errorStr = e.toString();
      if (errorStr.contains('permission-denied')) {
        // Permission denied is expected in some cases, silently return null
        return null;
      }
      if (kDebugMode) {
        print('❌ Error analyzing recovery patterns: $e');
      }
      return null;
    }
  }

  /// Generate AI-powered insight using Gemini
  Future<MindCoachInsight?> generateAIInsight(String userId) async {
    try {
      // Get user data for context
      final recentRounds = await _getRecentRounds(userId, limit: 5);
      final recentSessions = await _getRecentSessions(userId, limit: 10);
      // Note: recentShots available for future use
      await _getRecentShots(userId, limit: 20);

      if (recentRounds.isEmpty && recentSessions.isEmpty) {
        return null;
      }

      // Use AI coaching service to generate recommendation
      final recommendation =
          await _aiCoachingService.generateCoachingRecommendations(
        userId: userId,
        includeWeeklyPlan: false,
      );

      if (recommendation.recommendations.isNotEmpty) {
        final topRecommendation = recommendation.recommendations.first;
        return MindCoachInsight(
          insightText: recommendation.motivationalMessage.isNotEmpty
              ? recommendation.motivationalMessage
              : topRecommendation.moduleTitle,
          suggestionType: 'exploration',
          priority: 7,
          actionText: "Continue Training",
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating AI insight: $e');
      }
      return null;
    }
  }

  /// Find control modules related to reset routines
  Future<List<Map<String, String>>> _findControlModules() async {
    try {
      final modules = await FirebaseFirestore.instance
          .collection('coaching_modules')
          .where('pillar', isEqualTo: 'control')
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();

      return modules.docs.map<Map<String, String>>((doc) {
        final data = doc.data();
        return <String, String>{
          'moduleId': doc.id,
          'title': (data['title'] ?? '').toString(),
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error finding control modules: $e');
      }
      return [];
    }
  }

  /// Get recent round logs
  Future<List<RoundLogsRecord>> _getRecentRounds(String userId,
      {int limit = 5}) async {
    try {
      final rounds = await RoundLogsRecord.collection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return rounds.docs
          .map((doc) => RoundLogsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent training sessions
  Future<List<MentalSessionsRecord>> _getRecentSessions(String userId,
      {int limit = 10}) async {
    try {
      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .orderBy('dateStarted', descending: true)
          .limit(limit)
          .get();

      return sessions.docs
          .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent shot logs
  Future<List<ShotLogsRecord>> _getRecentShots(String userId,
      {int limit = 20}) async {
    try {
      final shots = await ShotLogsRecord.collection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return shots.docs.map((doc) => ShotLogsRecord.fromSnapshot(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}


