// AI Integration Module - Complete Export File for FoCoCo
// Firebase AI Logic with Gemini Integration

// ============================================================================
// GEMINI AI INTEGRATION (Firebase AI Logic)
// ============================================================================

// Core Gemini Client
export 'gemini_ai_client.dart' hide GeminiException;

// Gemini Configuration
export 'config/gemini_config.dart';
export 'config/gemini_voice_config.dart';

// Gemini Models and Response Types
export 'models/gemini_models.dart';

// Gemini Services
export 'services/mental_coach_system.dart';
export 'services/conversation_manager.dart';
export 'services/gemini_cost_tracker.dart';
export 'services/gemini_voice_service.dart';
export 'services/unified_ai_service.dart';
export 'services/gemini_live_api_service.dart';
export 'services/audio_session_service.dart';
export 'services/permission_service.dart';

// ============================================================================
// LEGACY AI INTEGRATION (For Migration/Compatibility)
// ============================================================================

// Legacy AI Client (to be phased out)
export 'ai_client.dart' hide AIException;

// Legacy Configuration
export 'config/ai_config.dart';

// Legacy Models
export 'models/ai_models.dart';

// Legacy Services
export 'services/ai_coaching_service.dart';
export 'services/ai_cost_tracker.dart';
export 'services/ai_insight_service.dart';

// ============================================================================
// SHARED UTILITIES AND WIDGETS
// ============================================================================

// AI Utilities
export 'utils/ai_utils.dart';

// AI Widgets
export 'widgets/ai_insight_card_widget.dart';
export 'widgets/ai_insight_widget_enhanced.dart';
// voice_chat_modal.dart has been removed
export 'widgets/navbar_widget.dart';

// ============================================================================
// MAIN FACADE CLASS
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/golf_rounds_record.dart';
import 'package:fo_co_co/backend/schema/mental_sessions_record.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import 'package:fo_co_co/backend/schema/user_record.dart';
import 'gemini_ai_client.dart';
import 'models/gemini_models.dart';
import 'services/mental_coach_system.dart';
import 'services/conversation_manager.dart';
import 'services/gemini_cost_tracker.dart';
import 'config/gemini_config.dart';

/// Main AI Integration facade for FoCoCo using Gemini
class FoCoCoAI {
  FoCoCoAI._();

  static FoCoCoAI? _instance;
  static FoCoCoAI get instance => _instance ??= FoCoCoAI._();

  /// Gemini AI Client — authenticates via Firebase AI Logic + App Check.
  static GeminiAIClient get client => GeminiAIClient();

  /// Mental Coach System for specialized coaching
  static MentalCoachSystem get mentalCoach => MentalCoachSystem(
        geminiClient: client,
        costTracker: costTracker,
      );

  /// Conversation Manager for multi-turn conversations
  static ConversationManager get conversations => ConversationManager.instance;

  /// Cost Tracker for usage analytics and budgeting
  static GeminiCostTracker get costTracker => GeminiCostTracker.instance;

  /// Initialize AI services
  static Future<void> initialize() async {
    try {
      // Validate Gemini configuration
      if (!GeminiConfig.validateConfiguration()) {
        throw Exception('Gemini configuration validation failed');
      }

      // Initialize all services
      await costTracker.initialize();

      if (kDebugMode) {
        print('🤖 FoCoCo AI Integration initialized with Gemini');
        print('✅ Features enabled:');
        print('   - Golf Insights: ✓');
        print('   - Mental Coaching: ✓');
        print('   - Personalized Content: ✓');
        print('   - Multi-turn Conversations: ✓');
        print('   - Cost Tracking: ✓');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FoCoCo AI: $e');
      }
      rethrow;
    }
  }

  /// Generate AI insight for a golf round
  static Future<GeminiInsightResponse> generateRoundInsight({
    required String userId,
    required GolfRoundsRecord golfRound,
    UserRecord? userProfile,
    List<GolfRoundsRecord>? historicalRounds,
    List<MentalSessionsRecord>? mentalSessions,
    String? sessionId,
  }) async {
    // Convert WeatherStruct to Map for JSON serialization
    final weatherMap = golfRound.weather?.toMap() ?? <String, dynamic>{};

    return await client.generateGolfInsight(
      userId: userId,
      roundData: {
        'score': golfRound.score,
        'parTotal': golfRound.parTotal,
        'weather': weatherMap,
        'date': golfRound.date?.toIso8601String() ?? '',
      },
      userNotes: golfRound.notes,
      contextualFactors: {
        'weather': weatherMap,
        'courseName': golfRound.courseName,
        'date': golfRound.date?.toIso8601String() ?? '',
        'userProfile': 'basic',
        'historicalRounds': historicalRounds?.length ?? 0,
        'mentalSessions': mentalSessions?.length ?? 0,
      },
    );
  }

  /// Generate mental coaching recommendations
  static Future<GeminiCoachingResponse> getCoachingRecommendations({
    required String userId,
    required UserRecord userProfile,
    List<MentalSessionsRecord>? recentSessions,
    List<GolfRoundsRecord>? recentRounds,
    String? sessionId,
  }) async {
    // Create user profile map
    final userProfileMap = {
      'userId': userId,
      'golfSkillLevel': 'intermediate',
      'mentalGameGoals': 'General improvement',
      'subscriptionTier': 'BASE',
      'varkPreferences': {
        'primaryStyle': 'visual',
        'secondaryStyle': 'kinesthetic',
        'preferences': []
      }
    };

    // Create VARK preferences map
    final varkPreferencesMap = {
      'visual': userProfile.varkPreferences.visual,
      'aural': userProfile.varkPreferences.aural,
      'readWrite': userProfile.varkPreferences.readWrite,
      'kinesthetic': userProfile.varkPreferences.kinesthetic,
    };

    return await client.generateMentalCoachingRecommendations(
      userId: userId,
      userProfile: userProfileMap,
      subscriptionTier: 'BASE',
      varkPreferences: varkPreferencesMap,
      recentRounds: recentRounds
          ?.map((r) => {
                'score': r.score,
                'date': r.date?.toIso8601String() ?? '',
                'notes': r.notes,
              })
          .toList(),
    );
  }

  /// Generate personalized content
  static Future<GeminiContentResponse> createPersonalizedContent({
    required String userId,
    required VarkPreferencesStruct varkPreferences,
    required String contentType,
    required String topic,
    required String userTier,
    Map<String, dynamic>? additionalContext,
    String? sessionId,
  }) async {
    final varkMap = {
      'visual': varkPreferences.visual,
      'aural': varkPreferences.aural,
      'readWrite': varkPreferences.readWrite,
      'kinesthetic': varkPreferences.kinesthetic,
    };

    return await client.generatePersonalizedContent(
      userId: userId,
      contentType: contentType,
      varkPreferences: varkMap,
      userTier: userTier,
      specificTopic: topic,
      difficultyLevel: additionalContext?['difficulty'] as String?,
      targetDuration: additionalContext?['duration'] as int?,
      learningObjectives: additionalContext?['objectives'] as List<String>?,
    );
  }

  /// Start a coaching conversation (PRIME tier)
  static Future<CoachingConversationResult> startCoachingConversation({
    required String userId,
    required String userMessage,
    required String conversationType,
    UserRecord? userProfile,
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    return await mentalCoach.continueCoachingConversation(
      userId: userId,
      sessionId: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userMessage: userMessage,
      conversationType: conversationType,
      userProfile: userProfile,
      context: context,
    );
  }

  /// Analyze round performance with mental coaching
  static Future<MentalPerformanceAnalysis> analyzeRoundPerformance({
    required String userId,
    required GolfRoundsRecord golfRound,
    UserRecord? userProfile,
    List<GolfRoundsRecord>? historicalRounds,
    List<MentalSessionsRecord>? mentalSessions,
    String? sessionId,
  }) async {
    return await mentalCoach.analyzeRoundPerformance(
      userId: userId,
      golfRound: golfRound,
      userProfile: userProfile,
      historicalRounds: historicalRounds,
      mentalSessions: mentalSessions,
      sessionId: sessionId,
    );
  }

  /// Analyze mindset trends over time
  static Future<Map<String, dynamic>> analyzeMindsetTrends({
    required String userId,
    required UserRecord userProfile,
    int analysisWeeks = 8,
    String? sessionId,
  }) async {
    final result = await mentalCoach.analyzeMindsetTrends(
      userId: userId,
      userProfile: userProfile,
      analysisWeeks: analysisWeeks,
      sessionId: sessionId,
    );

    // Convert MindsetTrendAnalysis to Map<String, dynamic>
    return {
      'moodPatterns': result.moodPatterns,
      'themes': result.themes,
      'trendInsights': result.trendInsights,
      'progressMetrics': result.progressMetrics,
      'analysisDate': result.analysisDate.toIso8601String(),
      'userId': result.userId,
      'analysisPeriod': result.analysisPeriod,
    };
  }

  /// Optimize routine effectiveness
  static Future<Map<String, dynamic>> optimizeRoutine({
    required String userId,
    required UserRecord userProfile,
    required String routineType,
    List<GolfRoundsRecord>? recentRounds,
    String? sessionId,
  }) async {
    final result = await mentalCoach.optimizeRoutineEffectiveness(
      userId: userId,
      userProfile: userProfile,
      routineType: routineType,
      recentRounds: recentRounds,
      sessionId: sessionId,
    );

    // Convert RoutineOptimizationResult to Map<String, dynamic>
    return {
      'routineType': result.routineType,
      'adherenceAnalysis': result.adherenceAnalysis,
      'correlationAnalysis': result.correlationAnalysis,
      'recommendations': result.recommendations,
      'optimizationDate': result.optimizationDate.toIso8601String(),
      'userId': result.userId,
    };
  }

  /// Generate personalized recommendations with adaptive learning
  static Future<PersonalizedRecommendations> getPersonalizedRecommendations({
    required String userId,
    required UserRecord userProfile,
    List<GolfRoundsRecord>? recentRounds,
    List<MentalSessionsRecord>? completedSessions,
    String? focusArea,
  }) async {
    return await mentalCoach.generatePersonalizedRecommendations(
      userId: userId,
      userProfile: userProfile,
      recentRounds: recentRounds,
      recentSessions: completedSessions,
      sessionId: focusArea,
    );
  }

  /// Update adaptive learning based on user performance
  static Future<AdaptiveLearningUpdate> updateAdaptiveLearning({
    required String userId,
    required UserRecord userProfile,
    required MentalSessionsRecord completedSession,
    Map<String, dynamic>? sessionFeedback,
  }) async {
    return await mentalCoach.updateAdaptiveLearning(
      userId: userId,
      userProfile: userProfile,
      completedSession: completedSession,
      sessionFeedback: sessionFeedback,
    );
  }

  /// Get user's token usage and balance
  static Future<UserTokenBalance> getTokenBalance(String userId) async {
    return await costTracker.getUserTokenBalance(userId);
  }

  /// Check if user has sufficient tokens for operation
  static Future<bool> hasTokensForOperation({
    required String userId,
    required int tokensRequired,
  }) async {
    return await costTracker.hasTokensForOperation(
      userId: userId,
      tokensRequired: tokensRequired,
    );
  }

  /// Generate session feedback for completed sessions
  static Future<GeminiSessionFeedbackResponse> generateSessionFeedback({
    required String userId,
    required Map<String, dynamic> sessionData,
    required String sessionType,
    Map<String, dynamic>? userProgress,
    String? userInput,
  }) async {
    return await client.generateSessionFeedback(
      userId: userId,
      sessionData: sessionData,
      sessionType: sessionType,
      userProgress: userProgress,
      userInput: userInput,
    );
  }

  /// Create a new conversation session
  static Future<ConversationSession> createConversation({
    required String userId,
    required String conversationType,
    Map<String, dynamic>? initialContext,
  }) async {
    return await conversations.createConversation(
      userId: userId,
      conversationType: conversationType,
      initialContext: initialContext,
    );
  }

  /// Continue an existing conversation
  static Future<ConversationTurn> continueConversation({
    required String sessionId,
    required String userMessage,
    Map<String, dynamic>? context,
  }) async {
    return await conversations.continueConversation(
      sessionId: sessionId,
      userMessage: userMessage,
      context: context,
    );
  }

  /// Get conversation history
  static Future<List<ConversationTurn>> getConversationHistory({
    required String sessionId,
    int? limit,
  }) async {
    return await conversations.getConversationHistory(
      sessionId: sessionId,
      limit: limit,
    );
  }

  /// Archive old conversations
  static Future<void> archiveConversation({
    required String sessionId,
    String? reason,
  }) async {
    await conversations.archiveConversation(
      sessionId: sessionId,
      reason: reason,
    );
  }

  /// Dispose resources
  static void dispose() {
    // No need to dispose client as it's managed by Firebase AI Logic
    if (kDebugMode) {
      print('🧹 FoCoCo AI resources disposed');
    }
  }
}

// ============================================================================
// EXTENSION METHODS FOR CONVENIENCE
// ============================================================================

extension GolfRoundsAI on GolfRoundsRecord {
  /// Generate AI insight for this golf round
  Future<GeminiInsightResponse> generateInsight({
    required String userId,
    UserRecord? userProfile,
    List<GolfRoundsRecord>? historicalRounds,
    List<MentalSessionsRecord>? mentalSessions,
  }) async {
    return await FoCoCoAI.generateRoundInsight(
      userId: userId,
      golfRound: this,
      userProfile: userProfile,
      historicalRounds: historicalRounds,
      mentalSessions: mentalSessions,
    );
  }

  /// Analyze mental performance for this round
  Future<MentalPerformanceAnalysis> analyzeMentalPerformance({
    required String userId,
    UserRecord? userProfile,
    List<GolfRoundsRecord>? historicalRounds,
    List<MentalSessionsRecord>? mentalSessions,
  }) async {
    return await FoCoCoAI.analyzeRoundPerformance(
      userId: userId,
      golfRound: this,
      userProfile: userProfile,
      historicalRounds: historicalRounds,
      mentalSessions: mentalSessions,
    );
  }
}

extension UserRecordAI on UserRecord {
  /// Get personalized coaching recommendations
  Future<GeminiCoachingResponse> getCoachingRecommendations({
    required String userId,
    List<MentalSessionsRecord>? recentSessions,
    List<GolfRoundsRecord>? recentRounds,
  }) async {
    return await FoCoCoAI.getCoachingRecommendations(
      userId: userId,
      userProfile: this,
      recentSessions: recentSessions,
      recentRounds: recentRounds,
    );
  }

  /// Generate personalized content for this user
  Future<GeminiContentResponse> createPersonalizedContent({
    required String userId,
    required String contentType,
    required String topic,
    Map<String, dynamic>? additionalContext,
  }) async {
    return await FoCoCoAI.createPersonalizedContent(
      userId: userId,
      varkPreferences: varkPreferences,
      contentType: contentType,
      topic: topic,
      userTier: currentMembershipTier,
      additionalContext: additionalContext,
    );
  }

  /// Get personalized recommendations
  Future<PersonalizedRecommendations> getPersonalizedRecommendations({
    required String userId,
    List<GolfRoundsRecord>? recentRounds,
    List<MentalSessionsRecord>? completedSessions,
    String? focusArea,
  }) async {
    return await FoCoCoAI.getPersonalizedRecommendations(
      userId: userId,
      userProfile: this,
      recentRounds: recentRounds,
      completedSessions: completedSessions,
      focusArea: focusArea,
    );
  }
}

// ============================================================================
// MIGRATION HELPER
// ============================================================================

/// Helper class to migrate from OpenAI to Gemini
class AIMigrationHelper {
  AIMigrationHelper._();

  /// Check if migration is needed
  static bool get needsMigration {
    // Check if old AI config exists and new Gemini config is ready
    return true; // Placeholder - implement actual migration logic
  }

  /// Migrate user data from OpenAI to Gemini format
  static Future<void> migrateUserData({
    required String userId,
    required Map<String, dynamic> legacyData,
  }) async {
    try {
      // Implement migration logic here
      if (kDebugMode) {
        print('🔄 Migrating user data from OpenAI to Gemini for user: $userId');
      }

      // Convert legacy insights to Gemini format
      // Convert legacy coaching data to Gemini format
      // Update user preferences for new system

      if (kDebugMode) {
        print('✅ Migration completed for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Migration failed for user $userId: $e');
      }
      rethrow;
    }
  }

  /// Validate migration completion
  static Future<bool> validateMigration(String userId) async {
    try {
      // Implement validation logic
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Migration validation failed for user $userId: $e');
      }
      return false;
    }
  }
}
