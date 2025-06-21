import 'package:flutter/foundation.dart';


import '/backend/schema/index.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../ai_client.dart';
import '../models/ai_models.dart';
import '../config/ai_config.dart';
import 'ai_cost_tracker.dart';

/// Service for managing AI-generated golf insights
class AIInsightService {
  AIInsightService._();
  
  static AIInsightService? _instance;
  static AIInsightService get instance => _instance ??= AIInsightService._();

  final AIClient _aiClient = AIClient.instance;
  final AICostTracker _costTracker = AICostTracker.instance;

  /// Generate AI insight for a golf round
  Future<AiInsightsRecord?> generateRoundInsight({
    required String userId,
    required GolfRoundsRecord golfRound,
    bool forceGenerate = false,
  }) async {
    try {
      // Check if insight already exists for this round
      if (!forceGenerate && golfRound.aiInsightsGenerated) {
        if (kDebugMode) {
          print('💡 Insight already exists for round ${golfRound.reference.id}');
        }
        return null;
      }

      // Validate user can generate insights
      if (!await _canGenerateInsight(userId)) {
        throw Exception('User has exceeded daily AI insight limit');
      }

      // Update round status to processing
      await golfRound.reference.update({
        'aiProcessingStatus': 'processing',
        'updatedTime': FieldValue.serverTimestamp(),
      });

      // Get user profile and historical data
      final userProfile = await _getUserProfile(userId);
      final historicalRounds = await _getHistoricalRounds(userId, limit: 10);
      final mentalSessions = await _getRecentMentalSessions(userId, limit: 5);

      // Generate AI insight
      final aiResponse = await _aiClient.generateGolfInsight(
        userId: userId,
        golfRound: golfRound,
        userProfile: userProfile,
        historicalRounds: historicalRounds,
        mentalSessions: mentalSessions,
      );

      // Create insight record
      final insightRecord = await _createInsightRecord(
        userId: userId,
        sourceId: golfRound.reference.id,
        sourceType: 'golf_round',
        aiResponse: aiResponse,
      );

      // Update round with completion status
      await golfRound.reference.update({
        'aiInsightsGenerated': true,
        'aiProcessingStatus': 'completed',
        'updatedTime': FieldValue.serverTimestamp(),
      });

      // Update user AI usage stats
      await _updateUserAIStats(userId, aiResponse);

      // Track costs
      await _costTracker.trackInsightGeneration(
        userId: userId,
        tokensUsed: aiResponse.tokensUsed ?? 0,
        estimatedCost: aiResponse.estimatedCost ?? 0.0,
      );

      // Send notification if user has enabled insights notifications
      await PushNotificationsUtil.triggerAIInsightNotification(
        insightId: insightRecord.reference.id,
        insightTitle: aiResponse.insightTitle,
      );

      if (kDebugMode) {
        print('✅ Generated AI insight for round ${golfRound.reference.id}');
        print('💰 Estimated cost: \$${aiResponse.estimatedCost?.toStringAsFixed(4)}');
      }

      return insightRecord;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating round insight: $e');
      }

      // Update round with error status
      await golfRound.reference.update({
        'aiProcessingStatus': 'error',
        'updatedTime': FieldValue.serverTimestamp(),
      });

      rethrow;
    }
  }

  /// Generate comprehensive performance insight from multiple rounds
  Future<AiInsightsRecord?> generatePerformanceInsight({
    required String userId,
    int roundsToAnalyze = 5,
  }) async {
    try {
      if (!await _canGenerateInsight(userId)) {
        throw Exception('User has exceeded daily AI insight limit');
      }

      final userProfile = await _getUserProfile(userId);
      final recentRounds = await _getHistoricalRounds(userId, limit: roundsToAnalyze);
      final mentalSessions = await _getRecentMentalSessions(userId, limit: 10);

      if (recentRounds.isEmpty) {
        throw Exception('No golf rounds found for performance analysis');
      }

      // Use the most recent round as the primary source
      final primaryRound = recentRounds.first;

      final aiResponse = await _aiClient.generateGolfInsight(
        userId: userId,
        golfRound: primaryRound,
        userProfile: userProfile,
        historicalRounds: recentRounds.skip(1).toList(),
        mentalSessions: mentalSessions,
      );

      final insightRecord = await _createInsightRecord(
        userId: userId,
        sourceId: 'performance_analysis',
        sourceType: 'performance_trend',
        aiResponse: aiResponse,
      );

      await _updateUserAIStats(userId, aiResponse);
      await _costTracker.trackInsightGeneration(
        userId: userId,
        tokensUsed: aiResponse.tokensUsed ?? 0,
        estimatedCost: aiResponse.estimatedCost ?? 0.0,
      );

      await PushNotificationsUtil.triggerAIInsightNotification(
        insightId: insightRecord.reference.id,
        insightTitle: aiResponse.insightTitle,
        customMessage: 'Your performance analysis is ready! Get insights from your last $roundsToAnalyze rounds.',
      );

      if (kDebugMode) {
        print('✅ Generated performance insight analyzing $roundsToAnalyze rounds');
      }

      return insightRecord;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating performance insight: $e');
      }
      rethrow;
    }
  }

  /// Get user's recent insights
  Future<List<AiInsightsRecord>> getUserInsights({
    required String userId,
    int limit = 20,
    String? category,
  }) async {
    try {
      Query query = AiInsightsRecord.collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdTime', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AiInsightsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user insights: $e');
      }
      return [];
    }
  }

  /// Mark insight as read
  Future<void> markInsightAsRead(String insightId) async {
    try {
      await AiInsightsRecord.collection.doc(insightId).update({
        'isRead': true,
        'updatedTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking insight as read: $e');
      }
    }
  }

  /// Rate an insight
  Future<void> rateInsight({
    required String insightId,
    required int rating,
    String? feedback,
  }) async {
    try {
      final updateData = {
        'userRating': rating,
        'updatedTime': FieldValue.serverTimestamp(),
      };

      if (feedback != null && feedback.isNotEmpty) {
        updateData['userFeedback'] = feedback;
      }

      await AiInsightsRecord.collection.doc(insightId).update(updateData);

      if (kDebugMode) {
        print('✅ Rated insight $insightId: $rating/5');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rating insight: $e');
      }
    }
  }

  /// Check if user can generate more insights
  Future<bool> _canGenerateInsight(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayInsights = await AiInsightsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('createdTime', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final count = todayInsights.docs.length;
      final canGenerate = count < AIConfig.maxRequestsPerUserPerDay;

      if (!canGenerate && kDebugMode) {
        print('⚠️ User $userId has reached daily insight limit ($count/${AIConfig.maxRequestsPerUserPerDay})');
      }

      return canGenerate;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking insight limit: $e');
      }
      return false;
    }
  }

  /// Get user profile
  Future<UserRecord?> _getUserProfile(String userId) async {
    try {
      final userDoc = await UserRecord.collection.doc(userId).get();
      return userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Get historical golf rounds
  Future<List<GolfRoundsRecord>> _getHistoricalRounds(String userId, {int limit = 10}) async {
    try {
      final snapshot = await GolfRoundsRecord.collection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GolfRoundsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching historical rounds: $e');
      }
      return [];
    }
  }

  /// Get recent mental sessions
  Future<List<MentalSessionsRecord>> _getRecentMentalSessions(String userId, {int limit = 5}) async {
    try {
      final snapshot = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('completionStatus', isEqualTo: 'completed')
          .orderBy('dateCompleted', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching mental sessions: $e');
      }
      return [];
    }
  }

  /// Create insight record in Firestore
  Future<AiInsightsRecord> _createInsightRecord({
    required String userId,
    required String sourceId,
    required String sourceType,
    required AIInsightResponse aiResponse,
  }) async {
    final docRef = AiInsightsRecord.collection.doc();
    
    final data = {
      'userId': userId,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'insightType': 'golf_performance',
      'category': aiResponse.category,
      'priority': aiResponse.priority,
      'insightTitle': aiResponse.insightTitle,
      'insightContent': aiResponse.summaryText,
      'keyPoints': aiResponse.keyPoints,
      'recommendations': aiResponse.recommendations
          .map((r) => r.toRecommendationStruct().toMap())
          .toList(),
      'personalizedElements': aiResponse.personalizedElements,
      'isRead': false,
      'userRating': 0,
      'userFeedback': '',
      'actionsTaken': [],
      'generatedTime': aiResponse.timestamp,
      'aiModel': aiResponse.model,
      'promptUsed': '', // Could store the prompt if needed
      'rawAiResponse': jsonEncode(aiResponse.toMap()),
      'processingTime': 0, // Could measure this
      'tokensUsed': aiResponse.tokensUsed ?? 0,
      'costPerInsight': aiResponse.estimatedCost ?? 0.0,
      'generationVersion': '1.0',
      'status': 'active',
      'expiryDate': DateTime.now().add(const Duration(days: 90)),
      'viewCount': 0,
      'shareCount': 0,
      'relatedInsights': [],
      'followUpGenerated': false,
      'createdTime': FieldValue.serverTimestamp(),
      'updatedTime': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);
    
    // Return the created record
    final snapshot = await docRef.get();
    return AiInsightsRecord.fromSnapshot(snapshot);
  }

  /// Update user AI statistics
  Future<void> _updateUserAIStats(String userId, AIInsightResponse aiResponse) async {
    try {
      await UserRecord.collection.doc(userId).update({
        'totalAIInsightsGenerated': FieldValue.increment(1),
        'tokensRemaining': FieldValue.increment(-(aiResponse.tokensUsed ?? 0)),
        'updatedTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user AI stats: $e');
      }
    }
  }
} 