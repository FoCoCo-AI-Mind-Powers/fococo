import 'package:flutter/foundation.dart';


import '/backend/schema/index.dart';
import '../ai_client.dart';
import '../models/ai_models.dart';
import '../config/ai_config.dart';
import 'ai_cost_tracker.dart';

/// Service for AI-powered mental coaching and recommendations
class AICoachingService {
  AICoachingService._();
  
  static AICoachingService? _instance;
  static AICoachingService get instance => _instance ??= AICoachingService._();

  final AIClient _aiClient = AIClient.instance;
  final AICostTracker _costTracker = AICostTracker.instance;

  /// Generate personalized mental coaching recommendations
  Future<AIRecommendationResponse> generateCoachingRecommendations({
    required String userId,
    bool includeWeeklyPlan = true,
  }) async {
    try {
      if (!AIConfig.enableAIRecommendations) {
        throw Exception('AI recommendations are disabled');
      }

      if (!await _canGenerateRecommendation(userId)) {
        throw Exception('User has exceeded daily AI recommendation limit');
      }

      // Get user data
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final recentSessions = await _getRecentMentalSessions(userId, limit: 10);
      final recentRounds = await _getRecentGolfRounds(userId, limit: 5);

      // Generate recommendations
      final recommendations = await _aiClient.generateMentalCoachingRecommendations(
        userId: userId,
        userProfile: userProfile,
        recentSessions: recentSessions,
        recentRounds: recentRounds,
      );

      // Track usage and costs
      await _updateUserRecommendationStats(userId, recommendations);
      await _costTracker.trackRecommendationGeneration(
        userId: userId,
        tokensUsed: recommendations.tokensUsed ?? 0,
        estimatedCost: recommendations.estimatedCost ?? 0.0,
      );

      if (kDebugMode) {
        print('✅ Generated coaching recommendations for user $userId');
        print('🎯 Primary focus: ${recommendations.primaryFocus}');
        print('💰 Estimated cost: \$${recommendations.estimatedCost?.toStringAsFixed(4)}');
      }

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating coaching recommendations: $e');
      }
      rethrow;
    }
  }

  /// Generate personalized content based on VARK preferences
  Future<AIContentResponse> generatePersonalizedContent({
    required String userId,
    required String contentType, // 'lesson', 'exercise', 'visualization', 'technique'
    required String topic,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      if (!AIConfig.enablePersonalizedContent) {
        throw Exception('Personalized content generation is disabled');
      }

      if (!await _canGenerateContent(userId)) {
        throw Exception('User has exceeded daily AI content limit');
      }

      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final content = await _aiClient.generatePersonalizedContent(
        userId: userId,
        varkPreferences: userProfile.varkPreferences,
        contentType: contentType,
        topic: topic,
        additionalContext: additionalContext,
      );

      await _updateUserContentStats(userId, content);
      await _costTracker.trackContentGeneration(
        userId: userId,
        tokensUsed: content.tokensUsed ?? 0,
        estimatedCost: content.estimatedCost ?? 0.0,
      );

      if (kDebugMode) {
        print('✅ Generated personalized $contentType content about "$topic" for user $userId');
        print('🎨 Adapted for: ${content.adaptedFor.join(", ")}');
      }

      return content;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating personalized content: $e');
      }
      rethrow;
    }
  }

  /// Generate session feedback
  Future<AIFeedbackResponse> generateSessionFeedback({
    required String userId,
    required MentalSessionsRecord session,
  }) async {
    try {
      if (!AIConfig.enableSessionFeedback) {
        throw Exception('Session feedback is disabled');
      }

      if (!await _canGenerateFeedback(userId)) {
        throw Exception('User has exceeded daily AI feedback limit');
      }

      final userProfile = await _getUserProfile(userId);

      final feedback = await _aiClient.generateSessionFeedback(
        userId: userId,
        session: session,
        userProfile: userProfile,
      );

      // Update session with AI feedback flag
      await session.reference.update({
        'aiFeedbackReceived': true,
        'aiProcessingStatus': 'completed',
        'updatedTime': FieldValue.serverTimestamp(),
      });

      await _updateUserFeedbackStats(userId, feedback);
      await _costTracker.trackFeedbackGeneration(
        userId: userId,
        tokensUsed: feedback.tokensUsed ?? 0,
        estimatedCost: feedback.estimatedCost ?? 0.0,
      );

      if (kDebugMode) {
        print('✅ Generated session feedback for session ${session.reference.id}');
        print('📊 Assessment: ${feedback.overallAssessment}');
      }

      return feedback;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating session feedback: $e');
      }
      rethrow;
    }
  }

  /// Get adaptive learning path based on user progress
  Future<List<AIModuleRecommendation>> getAdaptiveLearningPath({
    required String userId,
    int pathLength = 5,
  }) async {
    try {
      final recommendations = await generateCoachingRecommendations(userId: userId);
      
      // Sort recommendations by priority and learning style match
      final userProfile = await _getUserProfile(userId);
      final sortedRecommendations = _sortRecommendationsByRelevance(
        recommendations.recommendations,
        userProfile?.varkPreferences,
      );

      return sortedRecommendations.take(pathLength).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating adaptive learning path: $e');
      }
      return [];
    }
  }

  /// Generate content for specific VARK learning styles
  Future<Map<String, AIContentResponse>> generateMultiModalContent({
    required String userId,
    required String topic,
    List<String> targetStyles = const ['visual', 'aural', 'readwrite', 'kinesthetic'],
  }) async {
    final results = <String, AIContentResponse>{};

    for (final style in targetStyles) {
      try {
        final content = await generatePersonalizedContent(
          userId: userId,
          contentType: 'lesson',
          topic: topic,
          additionalContext: {
            'primaryLearningStyle': style,
            'multiModal': true,
          },
        );
        results[style] = content;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error generating $style content for topic "$topic": $e');
        }
      }
    }

    return results;
  }

  /// Check if user can generate recommendations
  Future<bool> _canGenerateRecommendation(String userId) async {
    return await _checkDailyLimit(userId, 'recommendations');
  }

  /// Check if user can generate content
  Future<bool> _canGenerateContent(String userId) async {
    return await _checkDailyLimit(userId, 'content');
  }

  /// Check if user can generate feedback
  Future<bool> _canGenerateFeedback(String userId) async {
    return await _checkDailyLimit(userId, 'feedback');
  }

  /// Generic daily limit checker
  Future<bool> _checkDailyLimit(String userId, String type) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // This is a simplified check - in a real app, you might want separate 
      // tracking for each AI service type
      final todayRequests = await AiInsightsRecord.collection
          .where('userId', isEqualTo: userId)
          .where('createdTime', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final count = todayRequests.docs.length;
      final canGenerate = count < AIConfig.maxRequestsPerUserPerDay;

      if (!canGenerate && kDebugMode) {
        print('⚠️ User $userId has reached daily $type limit ($count/${AIConfig.maxRequestsPerUserPerDay})');
      }

      return canGenerate;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking $type limit: $e');
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

  /// Get recent mental sessions
  Future<List<MentalSessionsRecord>> _getRecentMentalSessions(String userId, {int limit = 10}) async {
    try {
      final snapshot = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: userId)
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

  /// Get recent golf rounds
  Future<List<GolfRoundsRecord>> _getRecentGolfRounds(String userId, {int limit = 5}) async {
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
        print('❌ Error fetching golf rounds: $e');
      }
      return [];
    }
  }

  /// Sort recommendations by relevance to user's VARK preferences
  List<AIModuleRecommendation> _sortRecommendationsByRelevance(
    List<AIModuleRecommendation> recommendations,
    VarkPreferencesStruct? varkPreferences,
  ) {
    if (varkPreferences == null) return recommendations;

    return recommendations..sort((a, b) {
      final aScore = _calculateRelevanceScore(a, varkPreferences);
      final bScore = _calculateRelevanceScore(b, varkPreferences);
      
      // Higher score comes first
      return bScore.compareTo(aScore);
    });
  }

  /// Calculate relevance score based on VARK preferences and priority
  int _calculateRelevanceScore(
    AIModuleRecommendation recommendation,
    VarkPreferencesStruct varkPreferences,
  ) {
    int score = 0;

    // Priority scoring
    switch (recommendation.priority.toLowerCase()) {
      case 'high':
        score += 30;
        break;
      case 'medium':
        score += 20;
        break;
      case 'low':
        score += 10;
        break;
    }

    // VARK alignment scoring
    final learningStyle = recommendation.learningStyle.toLowerCase();
    if (learningStyle.contains('visual') && varkPreferences.visual) score += 15;
    if (learningStyle.contains('aural') && varkPreferences.aural) score += 15;
    if (learningStyle.contains('read') && varkPreferences.readWrite) score += 15;
    if (learningStyle.contains('kinesthetic') && varkPreferences.kinesthetic) score += 15;
    if (learningStyle.contains('mixed')) score += 5; // Mixed content is always somewhat relevant

    return score;
  }

  /// Update user recommendation statistics
  Future<void> _updateUserRecommendationStats(String userId, AIRecommendationResponse response) async {
    try {
      await UserRecord.collection.doc(userId).update({
        'tokensRemaining': FieldValue.increment(-(response.tokensUsed ?? 0)),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user recommendation stats: $e');
      }
    }
  }

  /// Update user content generation statistics
  Future<void> _updateUserContentStats(String userId, AIContentResponse response) async {
    try {
      await UserRecord.collection.doc(userId).update({
        'tokensRemaining': FieldValue.increment(-(response.tokensUsed ?? 0)),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user content stats: $e');
      }
    }
  }

  /// Update user feedback generation statistics
  Future<void> _updateUserFeedbackStats(String userId, AIFeedbackResponse response) async {
    try {
      await UserRecord.collection.doc(userId).update({
        'tokensRemaining': FieldValue.increment(-(response.tokensUsed ?? 0)),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user feedback stats: $e');
      }
    }
  }
} 