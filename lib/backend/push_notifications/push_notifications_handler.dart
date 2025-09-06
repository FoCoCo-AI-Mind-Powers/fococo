import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '/auth/firebase_auth/auth_util.dart';

// Notification types for the FoCoCo app
enum NotificationType {
  dailyReminder,
  aiInsightReady,
  streakReminder,
  achievementUnlocked,
  weeklyProgress,
  moduleRecommendation,
  roundAnalysisComplete,
  subscriptionReminder,
  contentUpdate,
}

class PushNotificationsHandler {
  PushNotificationsHandler._();

  static PushNotificationsHandler? _instance;
  static PushNotificationsHandler get instance =>
      _instance ??= PushNotificationsHandler._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      _initialized = true;
      if (kDebugMode) {
        print('✅ Push notifications initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing push notifications: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    final NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print(
          'Push notification permission granted: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _configureFCM() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message if app was opened from terminated state
    final RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Get and save FCM token (with retry logic for iOS APNS)
    _updateFCMToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📱 Received foreground message: ${message.notification?.title}');
    }

    // Show local notification when app is in foreground
    await _showLocalNotification(message);

    // Handle in-app notification logic
    await _handleInAppNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'fococo_channel',
        'FoCoCo Notifications',
        channelDescription: 'Golf mental coaching notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _handleInAppNotification(RemoteMessage message) async {
    // Parse notification type and handle accordingly
    final notificationType = _parseNotificationType(message.data['type']);

    if (notificationType != null) {
      switch (notificationType) {
        case NotificationType.aiInsightReady:
          await _handleAIInsightNotification(message);
          break;
        case NotificationType.achievementUnlocked:
          await _handleAchievementNotification(message);
          break;
        case NotificationType.streakReminder:
          await _handleStreakNotification(message);
          break;
        case NotificationType.weeklyProgress:
          await _handleWeeklyProgressNotification(message);
          break;
        case NotificationType.dailyReminder:
          await _handleDailyReminderNotification(message);
          break;
        case NotificationType.moduleRecommendation:
          await _handleModuleRecommendationNotification(message);
          break;
        case NotificationType.roundAnalysisComplete:
          await _handleRoundAnalysisNotification(message);
          break;
        case NotificationType.subscriptionReminder:
          await _handleSubscriptionReminderNotification(message);
          break;
        case NotificationType.contentUpdate:
          await _handleContentUpdateNotification(message);
          break;
      }
    }
  }

  NotificationType? _parseNotificationType(String? type) {
    if (type == null) return null;

    switch (type) {
      case 'daily_reminder':
        return NotificationType.dailyReminder;
      case 'ai_insight_ready':
        return NotificationType.aiInsightReady;
      case 'streak_reminder':
        return NotificationType.streakReminder;
      case 'achievement_unlocked':
        return NotificationType.achievementUnlocked;
      case 'weekly_progress':
        return NotificationType.weeklyProgress;
      case 'module_recommendation':
        return NotificationType.moduleRecommendation;
      case 'round_analysis_complete':
        return NotificationType.roundAnalysisComplete;
      case 'subscription_reminder':
        return NotificationType.subscriptionReminder;
      case 'content_update':
        return NotificationType.contentUpdate;
      default:
        return null;
    }
  }

  Future<void> _handleAIInsightNotification(RemoteMessage message) async {
    final insightId = message.data['insightId'];
    if (insightId != null && kDebugMode) {
      print('🤖 AI Insight ready: $insightId');
    }
  }

  Future<void> _handleAchievementNotification(RemoteMessage message) async {
    final achievement = message.data['achievement'];
    if (achievement != null && kDebugMode) {
      print('🏆 Achievement unlocked: $achievement');
    }
  }

  Future<void> _handleStreakNotification(RemoteMessage message) async {
    final streakCount = message.data['streakCount'];
    if (streakCount != null && kDebugMode) {
      print('🔥 Streak reminder: $streakCount days');
    }
  }

  Future<void> _handleWeeklyProgressNotification(RemoteMessage message) async {
    if (kDebugMode) {
      print('📊 Weekly progress notification received');
    }
  }

  Future<void> _handleDailyReminderNotification(RemoteMessage message) async {
    if (kDebugMode) {
      print('⏰ Daily reminder notification received');
    }
  }

  Future<void> _handleModuleRecommendationNotification(
      RemoteMessage message) async {
    final moduleId = message.data['moduleId'];
    if (moduleId != null && kDebugMode) {
      print('📚 Module recommendation: $moduleId');
    }
  }

  Future<void> _handleRoundAnalysisNotification(RemoteMessage message) async {
    final roundId = message.data['roundId'];
    if (roundId != null && kDebugMode) {
      print('⛳ Round analysis complete: $roundId');
    }
  }

  Future<void> _handleSubscriptionReminderNotification(
      RemoteMessage message) async {
    if (kDebugMode) {
      print('💳 Subscription reminder notification received');
    }
  }

  Future<void> _handleContentUpdateNotification(RemoteMessage message) async {
    if (kDebugMode) {
      print('🆕 Content update notification received');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${message.notification?.title}');
    }

    final notificationType = _parseNotificationType(message.data['type']);

    if (notificationType != null) {
      _navigateToPage(notificationType, message.data);
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print('📱 Local notification tapped: ${notificationResponse.payload}');
    }
  }

  void _navigateToPage(NotificationType type, Map<String, dynamic> data) {
    // Navigation logic would be implemented here
    switch (type) {
      case NotificationType.aiInsightReady:
        // Navigate to AI insights page
        break;
      case NotificationType.achievementUnlocked:
        // Navigate to achievements page
        break;
      case NotificationType.streakReminder:
      case NotificationType.dailyReminder:
      case NotificationType.moduleRecommendation:
        // Navigate to coaching modules
        break;
      case NotificationType.weeklyProgress:
        // Navigate to progress page
        break;
      case NotificationType.roundAnalysisComplete:
        // Navigate to round details
        break;
      case NotificationType.subscriptionReminder:
        // Navigate to subscription page
        break;
      case NotificationType.contentUpdate:
        // Navigate to home or content page
        break;
    }
  }

  Future<void> _updateFCMToken() async {
    try {
      // For iOS, we need to wait for APNS token to be available
      if (Platform.isIOS) {
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            if (kDebugMode) {
              print(
                  '📱 APNS token not available yet, skipping FCM token retrieval');
            }
            // Schedule a retry after a delay
            Timer(const Duration(seconds: 5), () => _updateFCMToken());
            return;
          }
          if (kDebugMode) {
            print('📱 APNS token available: ${apnsToken.substring(0, 20)}...');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error getting APNS token: $e');
          }
          return;
        }
      }

      final String? token = await _firebaseMessaging.getToken();
      if (token != null && currentUserUid.isNotEmpty) {
        await _saveFCMTokenToFirestore(token);
        if (kDebugMode) {
          print('📱 FCM Token updated: ${token.substring(0, 20)}...');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating FCM token: $e');
      }
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    if (kDebugMode) {
      print('📱 FCM Token refreshed');
    }
    await _saveFCMTokenToFirestore(token);
  }

  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      if (currentUserUid.isEmpty) return;

      final userDocRef =
          FirebaseFirestore.instance.collection('user').doc(currentUserUid);

      await userDocRef.update({
        'notificationTokens': FieldValue.arrayUnion([token]),
        'lastActive': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token to Firestore: $e');
      }
    }
  }

  // Public methods for scheduling notifications
  Future<void> scheduleAIInsightNotification({
    required String insightId,
    required String title,
    required String body,
    Duration delay = const Duration(minutes: 30),
  }) async {
    await scheduleNotification(
      id: insightId.hashCode,
      title: title,
      body: body,
      payload: {'type': 'ai_insight_ready', 'insightId': insightId},
      scheduledDate: DateTime.now().add(delay),
    );
  }

  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required TimeOfDay reminderTime,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: 'daily_reminder'.hashCode,
      title: title,
      body: body,
      payload: {'type': 'daily_reminder'},
      scheduledDate: scheduledDate,
      repeat: true,
    );
  }

  Future<void> scheduleStreakReminder({
    required int streakCount,
    required String title,
    required String body,
  }) async {
    await scheduleNotification(
      id: 'streak_reminder'.hashCode,
      title: title,
      body: body,
      payload: {
        'type': 'streak_reminder',
        'streakCount': streakCount.toString()
      },
      scheduledDate: DateTime.now().add(const Duration(hours: 20)),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, String> payload,
    required DateTime scheduledDate,
    bool repeat = false,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fococo_scheduled_channel',
      'FoCoCo Scheduled Notifications',
      channelDescription: 'Scheduled golf mental coaching notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    if (repeat) {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload.toString(),
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload.toString(),
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (kDebugMode) {
      print('📱 Background message received: ${message.notification?.title}');
    }

    // Handle background message processing here if needed
    // For now, just log the message
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in background message handler: $e');
    }
  }
}
