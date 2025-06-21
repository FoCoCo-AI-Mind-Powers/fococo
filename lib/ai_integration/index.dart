// AI Integration Module for FoCoCo Golf Mental Coaching App
// 
// This module provides comprehensive OpenAI integration for:
// - Golf performance insights
// - Mental coaching recommendations
// - Personalized content generation
// - Session feedback and analysis
// - Cost tracking and analytics

// ============================================================================
// CORE CLIENT
// ============================================================================
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/ai_integration/ai_client.dart';
import 'package:fo_co_co/ai_integration/config/ai_config.dart';
import 'package:fo_co_co/ai_integration/models/ai_models.dart';
import 'package:fo_co_co/ai_integration/services/ai_coaching_service.dart';
import 'package:fo_co_co/ai_integration/services/ai_cost_tracker.dart';
import 'package:fo_co_co/ai_integration/services/ai_insight_service.dart';
import 'package:fo_co_co/backend/schema/ai_insights_record.dart';
import 'package:fo_co_co/backend/schema/golf_rounds_record.dart';
import 'package:fo_co_co/backend/schema/mental_sessions_record.dart';
import 'package:fo_co_co/backend/schema/user_record.dart';

export 'ai_client.dart';

// ============================================================================
// CONFIGURATION
// ============================================================================
export 'config/ai_config.dart';

// ============================================================================
// DATA MODELS
// ============================================================================
export 'models/ai_models.dart';

// ============================================================================
// SERVICES
// ============================================================================
export 'services/ai_insight_service.dart';
export 'services/ai_coaching_service.dart';
export 'services/ai_cost_tracker.dart';

// ============================================================================
// UTILITIES (excluding AIException to avoid ambiguity)
// ============================================================================
export 'utils/ai_utils.dart' hide AIException;

// ============================================================================
// PUBLIC API
// ============================================================================

/// Main AI Integration facade for easy access to all AI services
class FoCoCoAI {
  FoCoCoAI._();
  
  static FoCoCoAI? _instance;
  static FoCoCoAI get instance => _instance ??= FoCoCoAI._();

  /// AI Insight Service for golf performance analysis
  static AIInsightService get insights => AIInsightService.instance;
  
  /// AI Coaching Service for mental coaching and recommendations
  static AICoachingService get coaching => AICoachingService.instance;
  
  /// AI Cost Tracker for usage analytics and budgeting
  static AICostTracker get costTracker => AICostTracker.instance;
  
  /// Direct AI Client for custom requests
  static AIClient get client => AIClient.instance;

  /// Initialize AI services
  static Future<void> initialize() async {
    // Validate configuration
    if (!AIConfig.validateConfiguration()) {
      throw Exception('AI configuration validation failed');
    }
    
    if (kDebugMode) {
      print('🤖 FoCoCo AI Integration initialized');
      print('✅ Features enabled:');
      print('   - Insights: ${AIConfig.enableAIInsights}');
      print('   - Recommendations: ${AIConfig.enableAIRecommendations}');
      print('   - Personalized Content: ${AIConfig.enablePersonalizedContent}');
      print('   - Session Feedback: ${AIConfig.enableSessionFeedback}');
    }
  }

  /// Generate AI insight for a golf round
  static Future<AiInsightsRecord?> generateRoundInsight({
    required String userId,
    required GolfRoundsRecord golfRound,
    bool forceGenerate = false,
  }) async {
    return await insights.generateRoundInsight(
      userId: userId,
      golfRound: golfRound,
      forceGenerate: forceGenerate,
    );
  }

  /// Generate mental coaching recommendations
  static Future<AIRecommendationResponse> getCoachingRecommendations({
    required String userId,
  }) async {
    return await coaching.generateCoachingRecommendations(userId: userId);
  }

  /// Generate personalized content
  static Future<AIContentResponse> createPersonalizedContent({
    required String userId,
    required String contentType,
    required String topic,
    Map<String, dynamic>? context,
  }) async {
    return await coaching.generatePersonalizedContent(
      userId: userId,
      contentType: contentType,
      topic: topic,
      additionalContext: context,
    );
  }

  /// Get user's AI usage statistics
  static Future<DailyUsageStats> getDailyUsage(String userId) async {
    return await costTracker.getDailyUsageStats(userId);
  }

  /// Check for cost alerts
  static Future<CostAlert?> checkCostAlerts(String userId) async {
    return await costTracker.checkCostAlerts(userId);
  }

  /// Dispose of AI services
  static void dispose() {
    client.dispose();
  }
}

// ============================================================================
// CONVENIENCE EXTENSIONS
// ============================================================================

/// Extension on GolfRoundsRecord for AI functionality
extension GolfRoundsAI on GolfRoundsRecord {
  /// Generate AI insight for this round
  Future<AiInsightsRecord?> generateAIInsight({
    bool forceGenerate = false,
  }) async {
    return await FoCoCoAI.generateRoundInsight(
      userId: userId,
      golfRound: this,
      forceGenerate: forceGenerate,
    );
  }
}

/// Extension on UserRecord for AI functionality
extension UserAI on UserRecord {
  /// Get coaching recommendations for this user
  Future<AIRecommendationResponse> getCoachingRecommendations() async {
    return await FoCoCoAI.getCoachingRecommendations(
      userId: reference.id,
    );
  }

  /// Get personalized content for this user
  Future<AIContentResponse> getPersonalizedContent({
    required String contentType,
    required String topic,
    Map<String, dynamic>? context,
  }) async {
    return await FoCoCoAI.createPersonalizedContent(
      userId: reference.id,
      contentType: contentType,
      topic: topic,
      context: context,
    );
  }

  /// Get AI usage statistics for this user
  Future<DailyUsageStats> getAIUsageStats() async {
    return await FoCoCoAI.getDailyUsage(reference.id);
  }
}

/// Extension on MentalSessionsRecord for AI functionality
extension MentalSessionAI on MentalSessionsRecord {
  /// Generate AI feedback for this session
  Future<AIFeedbackResponse> generateAIFeedback() async {
    return await FoCoCoAI.coaching.generateSessionFeedback(
      userId: userId,
      session: this,
    );
  }
} 