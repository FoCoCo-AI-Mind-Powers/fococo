import 'package:shared_preferences/shared_preferences.dart';
import '/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';

class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  final RemoteConfigService _remoteConfigService = RemoteConfigService();

  static const String _sessionCountKey = 'user_session_count';
  static const String _lastSessionDateKey = 'last_session_date';
  static const String _hasRatedAppKey = 'has_rated_app';
  static const String _readScoreKey = 'user_read_score';
  static const String _totalReadingTimeKey = 'total_reading_time_minutes';
  static const String _modulesReadKey = 'modules_read_count';

  /// Initialize session tracking
  Future<void> initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastSession = prefs.getString(_lastSessionDateKey);

      // Increment session count if it's a new day
      if (lastSession != today) {
        final currentCount = prefs.getInt(_sessionCountKey) ?? 0;
        await prefs.setInt(_sessionCountKey, currentCount + 1);
        await prefs.setString(_lastSessionDateKey, today);

        debugPrint('📊 Session count updated: ${currentCount + 1}');

        // Check if we should prompt for rating
        await _checkRatingPrompt();
      }
    } catch (e) {
      debugPrint('❌ Error initializing session: $e');
    }
  }

  /// Get current session count
  Future<int> getSessionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_sessionCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting session count: $e');
      return 0;
    }
  }

  /// Check if user should be prompted to rate the app
  Future<bool> shouldPromptRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRated = prefs.getBool(_hasRatedAppKey) ?? false;
      final sessionCount = await getSessionCount();
      final minSessions = _remoteConfigService.minSessionsForRating;

      return !hasRated &&
          sessionCount >= minSessions &&
          _remoteConfigService.isRateAppEnabled;
    } catch (e) {
      debugPrint('❌ Error checking rating prompt: $e');
      return false;
    }
  }

  /// Mark app as rated
  Future<void> markAppAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRatedAppKey, true);
      debugPrint('✅ App marked as rated');
    } catch (e) {
      debugPrint('❌ Error marking app as rated: $e');
    }
  }

  /// Update reading time (in minutes)
  Future<void> updateReadingTime(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = prefs.getInt(_totalReadingTimeKey) ?? 0;
      await prefs.setInt(_totalReadingTimeKey, currentTime + minutes);

      // Update read score after reading time changes
      await _updateReadScore();
      debugPrint('📚 Reading time updated: ${currentTime + minutes} minutes');
    } catch (e) {
      debugPrint('❌ Error updating reading time: $e');
    }
  }

  /// Increment modules read count
  Future<void> incrementModulesRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_modulesReadKey) ?? 0;
      await prefs.setInt(_modulesReadKey, currentCount + 1);

      // Update read score after module completion
      await _updateReadScore();
      debugPrint('📖 Modules read count updated: ${currentCount + 1}');
    } catch (e) {
      debugPrint('❌ Error incrementing modules read: $e');
    }
  }

  /// Get total reading time in minutes
  Future<int> getTotalReadingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_totalReadingTimeKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting reading time: $e');
      return 0;
    }
  }

  /// Get modules read count
  Future<int> getModulesReadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_modulesReadKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting modules read count: $e');
      return 0;
    }
  }

  /// Get user's read score (0-100)
  Future<int> getReadScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_readScoreKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting read score: $e');
      return 0;
    }
  }

  /// Calculate and update read score based on reading activity
  Future<void> _updateReadScore() async {
    try {
      final readingTime = await getTotalReadingTime();
      final modulesRead = await getModulesReadCount();

      // Calculate score based on reading activity
      // Reading time: 1 point per 5 minutes (max 60 points)
      final timeScore = (readingTime / 5).clamp(0, 60).toInt();

      // Modules read: 5 points per module (max 40 points)
      final moduleScore = (modulesRead * 5).clamp(0, 40).toInt();

      final totalScore = (timeScore + moduleScore).clamp(0, 100);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readScoreKey, totalScore);

      debugPrint(
          '📊 Read score updated: $totalScore (time: $timeScore, modules: $moduleScore)');
    } catch (e) {
      debugPrint('❌ Error updating read score: $e');
    }
  }

  /// Get read score details for display
  Future<Map<String, dynamic>> getReadScoreDetails() async {
    final score = await getReadScore();
    final readingTime = await getTotalReadingTime();
    final modulesRead = await getModulesReadCount();

    String level;
    String description;

    if (score >= 80) {
      level = 'Expert Reader';
      description = 'Outstanding reading commitment!';
    } else if (score >= 60) {
      level = 'Advanced Reader';
      description = 'Excellent progress!';
    } else if (score >= 40) {
      level = 'Active Reader';
      description = 'Keep up the good work!';
    } else if (score >= 20) {
      level = 'Learning Reader';
      description = 'Great start!';
    } else {
      level = 'New Reader';
      description = 'Begin your reading journey!';
    }

    return {
      'score': score,
      'level': level,
      'description': description,
      'readingTime': readingTime,
      'modulesRead': modulesRead,
      'readingHours': (readingTime / 60).toStringAsFixed(1),
    };
  }

  /// Check and handle rating prompt
  Future<void> _checkRatingPrompt() async {
    final shouldPrompt = await shouldPromptRating();
    if (shouldPrompt) {
      debugPrint('⭐ User eligible for rating prompt');
      // Note: The actual prompt should be handled by the UI layer
    }
  }

  /// Reset all user session data (for testing or user request)
  Future<void> resetSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionCountKey);
      await prefs.remove(_lastSessionDateKey);
      await prefs.remove(_hasRatedAppKey);
      await prefs.remove(_readScoreKey);
      await prefs.remove(_totalReadingTimeKey);
      await prefs.remove(_modulesReadKey);
      debugPrint('🔄 Session data reset');
    } catch (e) {
      debugPrint('❌ Error resetting session data: $e');
    }
  }
}
