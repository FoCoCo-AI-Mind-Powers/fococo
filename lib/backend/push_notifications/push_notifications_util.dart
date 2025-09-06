import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fo_co_co/backend/schema/structs/notification_settings_struct.dart';

import '/auth/firebase_auth/auth_util.dart';
import 'push_notifications_handler.dart';

/// Utility class for managing push notifications based on user preferences
class PushNotificationsUtil {
  PushNotificationsUtil._();

  static final PushNotificationsHandler _handler =
      PushNotificationsHandler.instance;

  /// Initialize push notifications for the current user
  static Future<void> initializeForUser() async {
    try {
      await _handler.initialize();
      await _scheduleUserNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing push notifications for user: $e');
      }
    }
  }

  /// Schedule notifications based on user preferences
  static Future<void> _scheduleUserNotifications() async {
    try {
      if (currentUserUid.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final notificationSettings = NotificationSettingsStruct.maybeFromMap(
        userData['notificationSettings'],
      );

      if (notificationSettings == null) return;

      // Schedule daily reminders if enabled
      if (notificationSettings.dailyReminders) {
        await _scheduleDailyReminders();
      }

      // Set up other notification types based on preferences
      if (notificationSettings.weeklyProgress) {
        await _scheduleWeeklyProgress();
      }

      if (notificationSettings.achievementAlerts) {
        // Achievement notifications are triggered by backend events
        // No scheduling needed here
      }

      if (notificationSettings.insightNotifications) {
        // AI insight notifications are triggered when insights are generated
        // No scheduling needed here
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling user notifications: $e');
      }
    }
  }

  /// Schedule daily reminder notifications
  static Future<void> _scheduleDailyReminders() async {
    try {
      // Default reminder time is 7:00 PM
      const TimeOfDay defaultReminderTime = TimeOfDay(hour: 19, minute: 0);

      await _handler.scheduleDailyReminder(
        title: '🧠 Time for Your Mental Golf Training',
        body:
            'Keep your streak alive! Complete today\'s mental coaching session.',
        reminderTime: defaultReminderTime,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling daily reminders: $e');
      }
    }
  }

  /// Schedule weekly progress notifications
  static Future<void> _scheduleWeeklyProgress() async {
    try {
      // Schedule for Sunday evenings
      final now = DateTime.now();
      var nextSunday = now.add(Duration(days: 7 - now.weekday));
      nextSunday =
          DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 18, 0);

      await _handler.scheduleNotification(
        id: 'weekly_progress'.hashCode,
        title: '📊 Your Weekly Golf Progress',
        body: 'Check out your progress this week and set goals for next week!',
        payload: {'type': 'weekly_progress'},
        scheduledDate: nextSunday,
        repeat: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling weekly progress: $e');
      }
    }
  }

  /// Trigger AI insight notification
  static Future<void> triggerAIInsightNotification({
    required String insightId,
    required String insightTitle,
    String? customMessage,
  }) async {
    try {
      final title = '🤖 New AI Golf Insight Ready!';
      final body = customMessage ??
          'Your personalized golf insight "$insightTitle" is ready to view.';

      await _handler.scheduleAIInsightNotification(
        insightId: insightId,
        title: title,
        body: body,
        delay: const Duration(minutes: 5),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering AI insight notification: $e');
      }
    }
  }

  /// Trigger achievement notification
  static Future<void> triggerAchievementNotification({
    required String achievementName,
    required String achievementDescription,
  }) async {
    try {
      // This would typically be called from a Cloud Function
      // when an achievement is unlocked
      if (kDebugMode) {
        print('🏆 Achievement unlocked: $achievementName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering achievement notification: $e');
      }
    }
  }

  /// Trigger streak reminder notification
  static Future<void> triggerStreakReminder({
    required int currentStreak,
    bool isAtRisk = false,
  }) async {
    try {
      String title;
      String body;

      if (isAtRisk) {
        title = '🔥 Don\'t Break Your Streak!';
        body =
            'You\'re at $currentStreak days. Complete a session today to keep it going!';
      } else {
        title = '🔥 Amazing Streak!';
        body =
            'You\'re on a $currentStreak day streak! Keep up the great work!';
      }

      await _handler.scheduleStreakReminder(
        streakCount: currentStreak,
        title: title,
        body: body,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering streak reminder: $e');
      }
    }
  }

  /// Update user notification preferences
  static Future<void> updateNotificationPreferences(
    NotificationSettingsStruct newSettings,
  ) async {
    try {
      if (currentUserUid.isEmpty) return;

      // Update user document with new notification settings
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'notificationSettings': newSettings.toMap(),
        'updatedTime': FieldValue.serverTimestamp(),
      });

      // Cancel all existing notifications
      await _handler.cancelAllNotifications();

      // Reschedule based on new preferences
      await _scheduleUserNotifications();

      if (kDebugMode) {
        print('✅ Notification preferences updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating notification preferences: $e');
      }
    }
  }

  /// Check if user has enabled specific notification type
  static Future<bool> isNotificationTypeEnabled(String notificationType) async {
    try {
      if (currentUserUid.isEmpty) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final notificationSettings = NotificationSettingsStruct.maybeFromMap(
        userData['notificationSettings'],
      );

      if (notificationSettings == null) return false;

      switch (notificationType) {
        case 'daily_reminder':
          return notificationSettings.dailyReminders;
        case 'insight_notifications':
          return notificationSettings.insightNotifications;
        case 'achievement_alerts':
          return notificationSettings.achievementAlerts;
        case 'weekly_progress':
          return notificationSettings.weeklyProgress;
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking notification preference: $e');
      }
      return false;
    }
  }

  /// Handle notification for round analysis completion
  static Future<void> triggerRoundAnalysisNotification({
    required String roundId,
    required String courseName,
    required int score,
  }) async {
    try {
      final isEnabled =
          await isNotificationTypeEnabled('insight_notifications');
      if (!isEnabled) return;

      final title = '⛳ Round Analysis Complete';
      final body =
          'Your round at $courseName (Score: $score) has been analyzed. Check out your insights!';

      await _handler.scheduleNotification(
        id: roundId.hashCode,
        title: title,
        body: body,
        payload: {
          'type': 'round_analysis_complete',
          'roundId': roundId,
        },
        scheduledDate: DateTime.now().add(const Duration(minutes: 2)),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering round analysis notification: $e');
      }
    }
  }

  /// Handle notification for subscription expiry warning
  static Future<void> triggerSubscriptionReminderNotification({
    required String membershipTier,
    required DateTime expiryDate,
  }) async {
    try {
      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

      String title;
      String body;

      if (daysUntilExpiry <= 3) {
        title = '⚠️ Subscription Expiring Soon';
        body =
            'Your $membershipTier subscription expires in $daysUntilExpiry days. Renew now to keep your access!';
      } else if (daysUntilExpiry <= 7) {
        title = '💳 Subscription Reminder';
        body =
            'Your $membershipTier subscription expires in $daysUntilExpiry days.';
      } else {
        return; // Don't send notification if more than 7 days
      }

      await _handler.scheduleNotification(
        id: 'subscription_reminder'.hashCode,
        title: title,
        body: body,
        payload: {'type': 'subscription_reminder'},
        scheduledDate: DateTime.now().add(const Duration(hours: 1)),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering subscription reminder: $e');
      }
    }
  }

  /// Clear all notifications and reset
  static Future<void> clearAllNotifications() async {
    await _handler.cancelAllNotifications();
  }

  /// Handle user logout - clear notifications
  static Future<void> handleUserLogout() async {
    await clearAllNotifications();
  }

  /// Test notification (for debugging)
  static Future<void> sendTestNotification() async {
    if (kDebugMode) {
      await _handler.scheduleNotification(
        id: 'test'.hashCode,
        title: '🧪 Test Notification',
        body: 'This is a test notification from FoCoCo!',
        payload: {'type': 'test'},
        scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
      );
    }
  }
}

/// Extension to add notification helpers to TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  /// Convert TimeOfDay to DateTime for today
  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Convert TimeOfDay to next occurrence (today if not passed, tomorrow if passed)
  DateTime toNextOccurrence() {
    final dateTime = toDateTime();
    final now = DateTime.now();

    if (dateTime.isAfter(now)) {
      return dateTime;
    } else {
      return dateTime.add(const Duration(days: 1));
    }
  }
}
