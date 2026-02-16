import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/mental_sessions_record.dart';
import '/ai_integration/models/mind_coach_models.dart';

/// Service for analyzing pillar balance from round logs and training sessions
class MindBalanceService {
  MindBalanceService._();
  static final MindBalanceService instance = MindBalanceService._();

  /// Analyze pillar balance and return status for each pillar
  Future<Map<String, PillarStatus>> analyzePillarBalance(String userId) async {
    try {
      // Get recent round logs (last 5 rounds)
      final recentRounds = await _getRecentRounds(userId, limit: 5);

      // Get recent training sessions (last 7 days)
      final recentSessions = await _getRecentSessions(userId, days: 7);

      // Calculate scores and trends for each pillar
      final focusStatus = _calculatePillarStatus(
        'focus',
        recentRounds,
        recentSessions,
      );
      final confidenceStatus = _calculatePillarStatus(
        'confidence',
        recentRounds,
        recentSessions,
      );
      final controlStatus = _calculatePillarStatus(
        'control',
        recentRounds,
        recentSessions,
      );

      // Determine which is strongest
      final allStatuses = [focusStatus, confidenceStatus, controlStatus];
      allStatuses.sort((a, b) => b.score.compareTo(a.score));

      // Mark highest score as strongest if trend is positive
      if (allStatuses.first.score > 60 && allStatuses.first.trend > 0) {
        allStatuses.first = PillarStatus(
          pillar: allStatuses.first.pillar,
          status: 'strongest_area',
          score: allStatuses.first.score,
          trend: allStatuses.first.trend,
        );
      }

      // Mark lowest score as needs attention if score < 50 or trend < 0
      if (allStatuses.last.score < 50 || allStatuses.last.trend < 0) {
        allStatuses.last = PillarStatus(
          pillar: allStatuses.last.pillar,
          status: 'needs_attention',
          score: allStatuses.last.score,
          trend: allStatuses.last.trend,
        );
      }

      return {
        'focus': focusStatus.pillar == 'focus'
            ? allStatuses.firstWhere((s) => s.pillar == 'focus')
            : focusStatus,
        'confidence': confidenceStatus.pillar == 'confidence'
            ? allStatuses.firstWhere((s) => s.pillar == 'confidence')
            : confidenceStatus,
        'control': controlStatus.pillar == 'control'
            ? allStatuses.firstWhere((s) => s.pillar == 'control')
            : controlStatus,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error analyzing pillar balance: $e');
      }
      // Return default statuses
      return {
        'focus': PillarStatus(
          pillar: 'focus',
          status: 'getting_sharper',
          score: 50.0,
          trend: 0.0,
        ),
        'confidence': PillarStatus(
          pillar: 'confidence',
          status: 'getting_sharper',
          score: 50.0,
          trend: 0.0,
        ),
        'control': PillarStatus(
          pillar: 'control',
          status: 'getting_sharper',
          score: 50.0,
          trend: 0.0,
        ),
      };
    }
  }

  /// Get pillar trends (positive/negative)
  Future<Map<String, double>> getPillarTrends(String userId) async {
    try {
      final balance = await analyzePillarBalance(userId);
      return {
        'focus': balance['focus']!.trend,
        'confidence': balance['confidence']!.trend,
        'control': balance['control']!.trend,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting pillar trends: $e');
      }
      return {
        'focus': 0.0,
        'confidence': 0.0,
        'control': 0.0,
      };
    }
  }

  /// Calculate status for a specific pillar
  PillarStatus _calculatePillarStatus(
    String pillar,
    List<RoundLogsRecord> rounds,
    List<MentalSessionsRecord> sessions,
  ) {
    // Calculate average score from round logs
    double roundScore = 0.0;
    if (rounds.isNotEmpty) {
      final scores = rounds.map((round) {
        switch (pillar) {
          case 'focus':
            return round.mindsetFocus.toDouble();
          case 'confidence':
            return round.mindsetConfidence.toDouble();
          case 'control':
            return round.mindsetControl.toDouble();
          default:
            return 0.0;
        }
      }).toList();
      roundScore = scores.reduce((a, b) => a + b) / scores.length;
    }

    // Calculate completion rate from training sessions
    final pillarSessions =
        sessions.where((s) => s.pillar.toLowerCase() == pillar).toList();
    final completionRate = pillarSessions.isEmpty
        ? 0.0
        : (pillarSessions.where((s) => s.isCompleted).length /
            pillarSessions.length *
            100);

    // Combined score (weighted: 70% round logs, 30% training sessions)
    final combinedScore = (roundScore * 0.7) + (completionRate * 0.3);

    // Calculate trend (compare first half vs second half of rounds)
    double trend = 0.0;
    if (rounds.length >= 4) {
      final firstHalf = rounds.take(rounds.length ~/ 2).toList();
      final secondHalf = rounds.skip(rounds.length ~/ 2).toList();

      final firstAvg = firstHalf.map((round) {
            switch (pillar) {
              case 'focus':
                return round.mindsetFocus.toDouble();
              case 'confidence':
                return round.mindsetConfidence.toDouble();
              case 'control':
                return round.mindsetControl.toDouble();
              default:
                return 0.0;
            }
          }).reduce((a, b) => a + b) /
          firstHalf.length;

      final secondAvg = secondHalf.map((round) {
            switch (pillar) {
              case 'focus':
                return round.mindsetFocus.toDouble();
              case 'confidence':
                return round.mindsetConfidence.toDouble();
              case 'control':
                return round.mindsetControl.toDouble();
              default:
                return 0.0;
            }
          }).reduce((a, b) => a + b) /
          secondHalf.length;

      trend = (secondAvg - firstAvg) / 10.0; // Normalize to -1 to 1 range
    }

    // Determine status
    String status = 'getting_sharper';
    if (combinedScore < 50 || trend < -0.1) {
      status = 'needs_attention';
    }

    return PillarStatus(
      pillar: pillar,
      status: status,
      score: combinedScore.clamp(0.0, 100.0),
      trend: trend.clamp(-1.0, 1.0),
    );
  }

  /// Get recent round logs
  Future<List<RoundLogsRecord>> _getRecentRounds(String userId,
      {int limit = 5}) async {
    // Guard against empty userId - would cause permission denied
    if (userId.isEmpty) return [];
    
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
      // Handle permission errors gracefully - don't log them as errors
      final errorStr = e.toString();
      if (errorStr.contains('permission-denied')) {
        // Permission denied is expected in some cases, silently return empty
        return [];
      }
      if (kDebugMode) {
        print('❌ Error getting recent rounds: $e');
      }
      return [];
    }
  }

  /// Get recent training sessions
  Future<List<MentalSessionsRecord>> _getRecentSessions(String userId,
      {int days = 7}) async {
    // Guard against empty userId - would cause permission denied
    if (userId.isEmpty) return [];
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('dateStarted',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('dateStarted', descending: true)
          .get();

      return sessions.docs
          .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      // Handle permission errors gracefully - don't log them as errors
      final errorStr = e.toString();
      if (errorStr.contains('permission-denied')) {
        // Permission denied is expected in some cases, silently return empty
        return [];
      }
      if (kDebugMode) {
        print('❌ Error getting recent sessions: $e');
      }
      return [];
    }
  }
}


