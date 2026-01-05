import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/backend/schema/mental_sessions_record.dart';
import '/ai_integration/models/mind_coach_models.dart';

/// Service for calculating training streaks and weekly progress
class TrainingStreakService {
  TrainingStreakService._();
  static final TrainingStreakService instance = TrainingStreakService._();

  /// Get current training streak (consecutive days with completed sessions)
  Future<int> getCurrentStreak(String userId) async {
    try {
      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('dateCompleted', descending: true)
          .limit(30) // Check last 30 sessions
          .get();

      if (sessions.docs.isEmpty) return 0;

      // Group sessions by date (ignoring time)
      final completedDates = <String>{};
      for (var doc in sessions.docs) {
        final session = MentalSessionsRecord.fromSnapshot(doc);
        if (session.dateCompleted != null) {
          final dateStr = _getDateString(session.dateCompleted!);
          completedDates.add(dateStr);
        }
      }

      // Calculate consecutive days
      int streak = 0;
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dateStr = _getDateString(checkDate);
        if (completedDates.contains(dateStr)) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculating streak: $e');
      }
      return 0;
    }
  }

  /// Get weekly progress (sessions completed out of 7 target)
  Future<WeeklyProgress> getWeeklyProgress(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);

      // Get completed sessions from this week
      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .where('dateCompleted',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      final completed = sessions.docs.length;
      final percentage = (completed / 7 * 100).clamp(0.0, 100.0);
      final streak = await getCurrentStreak(userId);

      return WeeklyProgress(
        completed: completed,
        target: 7,
        percentage: percentage,
        currentStreak: streak,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculating weekly progress: $e');
      }
      return WeeklyProgress(
        completed: 0,
        target: 7,
        percentage: 0.0,
        currentStreak: 0,
      );
    }
  }

  /// Get next incomplete session that needs to be completed
  Future<MentalSessionsRecord?> getNextIncompleteSession(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);

      // Get incomplete sessions from this week
      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .where('dateStarted',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .orderBy('dateStarted', descending: false)
          .limit(1)
          .get();

      if (sessions.docs.isEmpty) return null;

      return MentalSessionsRecord.fromSnapshot(sessions.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting incomplete session: $e');
      }
      return null;
    }
  }

  /// Get sessions completed this week (for progress calculation)
  Future<List<MentalSessionsRecord>> getThisWeekSessions(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);

      final sessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .where('dateCompleted',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .orderBy('dateCompleted', descending: true)
          .get();

      return sessions.docs
          .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting this week sessions: $e');
      }
      return [];
    }
  }

  /// Helper: Get start of week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Helper: Get date string (YYYY-MM-DD)
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}


