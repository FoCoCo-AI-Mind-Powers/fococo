import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/ai_insights_record.dart';
import 'package:fo_co_co/backend/schema/golf_rounds_record.dart';
import 'package:fo_co_co/backend/schema/mental_sessions_record.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import 'package:fo_co_co/backend/schema/user_record.dart';

import '../models/gemini_models.dart';
import '../config/gemini_config.dart';
import 'package:firebase_ai/firebase_ai.dart';

/// Service for AI-powered mental coaching and recommendations
class AICoachingService {
  AICoachingService._();

  static AICoachingService? _instance;
  static AICoachingService get instance => _instance ??= AICoachingService._();

  // Cost tracking functionality would be implemented here if needed
  // final GeminiCostTracker _costTracker = GeminiCostTracker.instance;

  /// Generate personalized mental coaching recommendations
  Future<GeminiRecommendationResponse> generateCoachingRecommendations({
    required String userId,
    bool includeWeeklyPlan = true,
  }) async {
    try {
      // Gemini is always available through Firebase AI Logic
      if (!GeminiConfig.validateConfiguration()) {
        throw Exception('Gemini configuration is invalid');
      }

      if (!await _canGenerateRecommendation(userId)) {
        throw Exception('User has exceeded daily AI recommendation limit');
      }

      // Get user data
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        // Return default recommendations if user profile doesn't exist
        return GeminiRecommendationResponse(
          recommendationType: 'default',
          recommendations: _getDefaultRecommendations(),
          primaryFocus: 'Getting Started',
          weeklyPlan: _getDefaultWeeklyPlan(),
          motivationalMessage:
              'Welcome to FoCoCo! Let\'s start building your mental game.',
          timestamp: DateTime.now(),
          model: 'default',
          tokensUsed: 0,
          estimatedCost: 0.0,
        );
      }

      final recentSessions = await _getRecentMentalSessions(userId, limit: 10);
      final recentRounds = await _getRecentGolfRounds(userId, limit: 5);

      // Generate recommendations using Gemini
      final recommendations = await _generateGeminiCoachingRecommendations(
        userId: userId,
        userProfile: userProfile,
        recentSessions: recentSessions,
        recentRounds: recentRounds,
      );

      // Track usage and costs
      await _updateUserRecommendationStats(userId, recommendations);
      // Note: trackRecommendationGeneration may not exist in GeminiCostTracker
      // await _costTracker.trackRecommendationGeneration(
      //   userId: userId,
      //   tokensUsed: recommendations.tokensUsed ?? 0,
      //   estimatedCost: recommendations.estimatedCost ?? 0.0,
      // );

      if (kDebugMode) {
        print('✅ Generated coaching recommendations for user $userId');
        print('🎯 Primary focus: ${recommendations.primaryFocus}');
        print(
            '💰 Estimated cost: \$${recommendations.estimatedCost?.toStringAsFixed(4)}');
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
  Future<GeminiContentResponse> generatePersonalizedContent({
    required String userId,
    required String
        contentType, // 'lesson', 'exercise', 'visualization', 'technique'
    required String topic,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      // Gemini content generation is always available
      if (!GeminiConfig.validateConfiguration()) {
        throw Exception('Gemini configuration is invalid');
      }

      if (!await _canGenerateContent(userId)) {
        throw Exception('User has exceeded daily AI content limit');
      }

      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final content = await _generateGeminiPersonalizedContent(
        userId: userId,
        varkPreferences: userProfile.varkPreferences,
        contentType: contentType,
        topic: topic,
        additionalContext: additionalContext,
      );

      await _updateUserContentStats(userId, content);
      // Note: trackContentGeneration may not exist in GeminiCostTracker
      // await _costTracker.trackContentGeneration(
      //   userId: userId,
      //   tokensUsed: content.tokensUsed ?? 0,
      //   estimatedCost: content.estimatedCost ?? 0.0,
      // );

      if (kDebugMode) {
        print(
            '✅ Generated personalized $contentType content about "$topic" for user $userId');
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
  Future<GeminiFeedbackResponse> generateSessionFeedback({
    required String userId,
    required MentalSessionsRecord session,
  }) async {
    try {
      // Gemini feedback generation is always available
      if (!GeminiConfig.validateConfiguration()) {
        throw Exception('Gemini configuration is invalid');
      }

      if (!await _canGenerateFeedback(userId)) {
        throw Exception('User has exceeded daily AI feedback limit');
      }

      final userProfile = await _getUserProfile(userId);

      final feedback = await _generateGeminiSessionFeedback(
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
      // Note: trackFeedbackGeneration may not exist in GeminiCostTracker
      // await _costTracker.trackFeedbackGeneration(
      //   userId: userId,
      //   tokensUsed: feedback.tokensUsed ?? 0,
      //   estimatedCost: feedback.estimatedCost ?? 0.0,
      // );

      if (kDebugMode) {
        print(
            '✅ Generated session feedback for session ${session.reference.id}');
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
  Future<List<GeminiModuleRecommendation>> getAdaptiveLearningPath({
    required String userId,
    int pathLength = 5,
  }) async {
    try {
      final recommendations =
          await generateCoachingRecommendations(userId: userId);

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
  Future<Map<String, GeminiContentResponse>> generateMultiModalContent({
    required String userId,
    required String topic,
    List<String> targetStyles = const [
      'visual',
      'aural',
      'readwrite',
      'kinesthetic'
    ],
  }) async {
    final results = <String, GeminiContentResponse>{};

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
      const maxDailyRequests = 50; // Default daily limit for Gemini
      final canGenerate = count < maxDailyRequests;

      if (!canGenerate && kDebugMode) {
        print(
            '⚠️ User $userId has reached daily $type limit ($count/$maxDailyRequests)');
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
  Future<List<MentalSessionsRecord>> _getRecentMentalSessions(String userId,
      {int limit = 10}) async {
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
  Future<List<GolfRoundsRecord>> _getRecentGolfRounds(String userId,
      {int limit = 5}) async {
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
  List<GeminiModuleRecommendation> _sortRecommendationsByRelevance(
    List<GeminiModuleRecommendation> recommendations,
    VarkPreferencesStruct? varkPreferences,
  ) {
    if (varkPreferences == null) return recommendations;

    return recommendations
      ..sort((a, b) {
        final aScore = _calculateRelevanceScore(a, varkPreferences);
        final bScore = _calculateRelevanceScore(b, varkPreferences);

        // Higher score comes first
        return bScore.compareTo(aScore);
      });
  }

  /// Calculate relevance score based on VARK preferences and priority
  int _calculateRelevanceScore(
    GeminiModuleRecommendation recommendation,
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
    if (learningStyle.contains('read') && varkPreferences.readWrite)
      score += 15;
    if (learningStyle.contains('kinesthetic') && varkPreferences.kinesthetic)
      score += 15;
    if (learningStyle.contains('mixed'))
      score += 5; // Mixed content is always somewhat relevant

    return score;
  }

  /// Update user recommendation statistics
  Future<void> _updateUserRecommendationStats(
      String userId, GeminiRecommendationResponse response) async {
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
  Future<void> _updateUserContentStats(
      String userId, GeminiContentResponse response) async {
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
  Future<void> _updateUserFeedbackStats(
      String userId, GeminiFeedbackResponse response) async {
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

  /// Get default recommendations for new users
  List<GeminiModuleRecommendation> _getDefaultRecommendations() {
    return [
      GeminiModuleRecommendation(
        moduleId: 'intro_mental_game',
        moduleTitle: 'Introduction to Mental Game',
        description: 'Learn the fundamentals of mental performance in golf',
        priority: 'high',
        estimatedDuration: 15,
        learningStyle: 'mixed',
        expectedOutcome: 'Understanding of mental game basics',
        prerequisites: [],
        difficulty: 'beginner',
      ),
      GeminiModuleRecommendation(
        moduleId: 'basic_breathing',
        moduleTitle: 'Basic Breathing Techniques',
        description: 'Master fundamental breathing exercises for golf',
        priority: 'high',
        estimatedDuration: 10,
        learningStyle: 'kinesthetic',
        expectedOutcome: 'Improved breathing control',
        prerequisites: [],
        difficulty: 'beginner',
      ),
      GeminiModuleRecommendation(
        moduleId: 'pre_shot_routine',
        moduleTitle: 'Pre-Shot Routine Development',
        description: 'Build a consistent mental pre-shot routine',
        priority: 'medium',
        estimatedDuration: 20,
        learningStyle: 'visual',
        expectedOutcome: 'Consistent pre-shot routine',
        prerequisites: ['intro_mental_game'],
        difficulty: 'intermediate',
      ),
    ];
  }

  /// Get default weekly plan for new users
  GeminiWeeklyPlan _getDefaultWeeklyPlan() {
    return GeminiWeeklyPlan(
      totalDuration: 45,
      sessionsPerWeek: 3,
      focusAreas: [
        'Complete VARK learning style assessment',
        'Practice basic breathing exercises (5 minutes daily)',
        'Develop your pre-shot routine',
        'Try one mental training module',
        'Set your first mental game goals',
      ],
      progressMilestones: [
        'Complete first mental training session',
        'Establish daily practice routine',
        'Identify primary learning style',
      ],
    );
  }

  /// Generate coaching recommendations using Gemini AI
  Future<GeminiRecommendationResponse> _generateGeminiCoachingRecommendations({
    required String userId,
    required UserRecord userProfile,
    required List<MentalSessionsRecord> recentSessions,
    required List<GolfRoundsRecord> recentRounds,
  }) async {
    try {
      final model = GeminiConfig.createModel(
        modelName: GeminiConfig.coachingModel,
        generationConfig: GeminiConfig.coachingGenerationConfig,
        systemInstruction: GeminiConfig.mentalCoachingSystemPrompt,
      );

      final prompt = _buildCoachingPrompt(
        userProfile: userProfile,
        recentSessions: recentSessions,
        recentRounds: recentRounds,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON response
      final jsonResponse = _parseJsonResponse(responseText);

      return GeminiRecommendationResponse.fromJson(jsonResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating Gemini coaching recommendations: $e');
      }
      rethrow;
    }
  }

  /// Generate personalized content using Gemini AI
  Future<GeminiContentResponse> _generateGeminiPersonalizedContent({
    required String userId,
    required VarkPreferencesStruct? varkPreferences,
    required String contentType,
    required String topic,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final model = GeminiConfig.createModel(
        modelName: GeminiConfig.contentModel,
        generationConfig: GeminiConfig.contentGenerationConfig,
        systemInstruction: GeminiConfig.personalizedContentSystemPrompt,
      );

      final prompt = _buildContentPrompt(
        varkPreferences: varkPreferences,
        contentType: contentType,
        topic: topic,
        additionalContext: additionalContext,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON response
      final jsonResponse = _parseJsonResponse(responseText);

      return GeminiContentResponse.fromJson(jsonResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating Gemini personalized content: $e');
      }
      rethrow;
    }
  }

  /// Generate session feedback using Gemini AI
  Future<GeminiFeedbackResponse> _generateGeminiSessionFeedback({
    required String userId,
    required MentalSessionsRecord session,
    UserRecord? userProfile,
  }) async {
    try {
      final model = GeminiConfig.createModel(
        modelName: GeminiConfig.feedbackModel,
        generationConfig: GeminiConfig.feedbackGenerationConfig,
        systemInstruction: GeminiConfig.sessionFeedbackSystemPrompt,
      );

      final prompt = _buildFeedbackPrompt(
        session: session,
        userProfile: userProfile,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON response
      final jsonResponse = _parseJsonResponse(responseText);

      return GeminiFeedbackResponse.fromJson(jsonResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating Gemini session feedback: $e');
      }
      rethrow;
    }
  }

  /// Build coaching prompt for Gemini
  String _buildCoachingPrompt({
    required UserRecord userProfile,
    required List<MentalSessionsRecord> recentSessions,
    required List<GolfRoundsRecord> recentRounds,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Generate personalized mental coaching recommendations for this golfer:');
    buffer.writeln();

    // User profile information
    buffer.writeln('USER PROFILE:');
    buffer.writeln('- Experience Level: ${userProfile.golfExperience}');
    buffer.writeln('- Handicap: ${userProfile.handicap}');
    buffer.writeln('- Membership Tier: ${userProfile.currentMembershipTier}');

    // VARK preferences
    if (userProfile.varkPreferences != null) {
      final vark = userProfile.varkPreferences!;
      buffer.writeln('- Learning Preferences:');
      if (vark.visual) buffer.writeln('  * Visual learner');
      if (vark.aural) buffer.writeln('  * Auditory learner');
      if (vark.readWrite) buffer.writeln('  * Reading/Writing learner');
      if (vark.kinesthetic) buffer.writeln('  * Kinesthetic learner');
      // Note: dominantStyle field may not exist in current schema
      // if (vark.dominantStyle?.isNotEmpty == true) {
      //   buffer.writeln('  * Dominant style: ${vark.dominantStyle}');
      // }
    }

    buffer.writeln();

    // Recent golf performance
    if (recentRounds.isNotEmpty) {
      buffer.writeln('RECENT GOLF PERFORMANCE:');
      for (final round in recentRounds.take(3)) {
        buffer.writeln(
            '- ${round.courseName}: Score ${round.score} (${round.scoreToPar > 0 ? '+' : ''}${round.scoreToPar})');
        // Note: aiNotes field may not exist in current schema
        // if (round.aiNotes?.isNotEmpty == true) {
        //   buffer.writeln('  Notes: ${round.aiNotes}');
        // }
      }
      buffer.writeln();
    }

    // Recent mental training sessions
    if (recentSessions.isNotEmpty) {
      buffer.writeln('RECENT MENTAL TRAINING:');
      for (final session in recentSessions.take(3)) {
        buffer.writeln(
            '- ${session.moduleTitle}: ${session.progressPercentage.toStringAsFixed(0)}% complete');
        if (session.journalEntry.isNotEmpty) {
          buffer.writeln('  Notes: ${session.journalEntry}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln(
        'Provide comprehensive coaching recommendations focusing on the FoCoCo methodology.');

    return buffer.toString();
  }

  /// Build content generation prompt for Gemini
  String _buildContentPrompt({
    required VarkPreferencesStruct? varkPreferences,
    required String contentType,
    required String topic,
    Map<String, dynamic>? additionalContext,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Create personalized $contentType content about: $topic');
    buffer.writeln();

    if (varkPreferences != null) {
      buffer.writeln('LEARNING STYLE PREFERENCES:');
      if (varkPreferences.visual)
        buffer.writeln('- Visual: Use diagrams, charts, imagery');
      if (varkPreferences.aural)
        buffer.writeln('- Auditory: Include spoken instructions, rhythm');
      if (varkPreferences.readWrite)
        buffer.writeln('- Reading/Writing: Provide text, lists, exercises');
      if (varkPreferences.kinesthetic)
        buffer.writeln('- Kinesthetic: Include physical practice, movement');

      // Note: dominantStyle field may not exist in current schema
      // if (varkPreferences.dominantStyle?.isNotEmpty == true) {
      //   buffer.writeln('- Primary focus: ${varkPreferences.dominantStyle}');
      // }
      buffer.writeln();
    }

    if (additionalContext != null) {
      buffer.writeln('ADDITIONAL CONTEXT:');
      additionalContext.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    buffer.writeln(
        'Create engaging, practical content that follows FoCoCo principles.');

    return buffer.toString();
  }

  /// Build feedback prompt for Gemini
  String _buildFeedbackPrompt({
    required MentalSessionsRecord session,
    UserRecord? userProfile,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Provide constructive feedback for this mental training session:');
    buffer.writeln();

    buffer.writeln('SESSION DETAILS:');
    buffer.writeln('- Module: ${session.moduleTitle}');
    buffer.writeln('- Duration: ${session.duration} minutes');
    buffer.writeln(
        '- Completion: ${session.progressPercentage.toStringAsFixed(0)}%');
    buffer.writeln('- Status: ${session.completionStatus}');

    if (session.journalEntry.isNotEmpty) {
      buffer.writeln('- User Notes: ${session.journalEntry}');
    }

    if (session.userMoodBefore.isNotEmpty && session.userMoodAfter.isNotEmpty) {
      buffer.writeln('- Mood Before: ${session.userMoodBefore}');
      buffer.writeln('- Mood After: ${session.userMoodAfter}');
    }

    buffer.writeln();

    if (userProfile != null) {
      buffer.writeln('USER CONTEXT:');
      buffer.writeln('- Experience: ${userProfile.golfExperience}');
      // Note: dominantStyle field may not exist in current schema
      // if (userProfile.varkPreferences?.dominantStyle?.isNotEmpty == true) {
      //   buffer.writeln('- Learning Style: ${userProfile.varkPreferences!.dominantStyle}');
      // }
      buffer.writeln();
    }

    buffer.writeln(
        'Provide encouraging, specific feedback using FoCoCo principles.');

    return buffer.toString();
  }

  /// Parse JSON response from Gemini
  Map<String, dynamic> _parseJsonResponse(String responseText) {
    try {
      // Clean up the response text
      String cleanedText = responseText.trim();

      // Remove markdown code blocks if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      // Parse JSON
      return jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing JSON response: $e');
        print('Response text: $responseText');
      }

      // Return a fallback response
      return {
        'error': 'Failed to parse AI response',
        'rawResponse': responseText,
      };
    }
  }
}
