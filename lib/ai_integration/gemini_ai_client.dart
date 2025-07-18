import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'models/gemini_models.dart';
import 'config/gemini_config.dart';
import 'services/gemini_cost_tracker.dart';

/// Main client for Google Generative AI Gemini integration
class GeminiAIClient {
  final String _apiKey;
  final GeminiCostTracker _costTracker;
  
  GeminiAIClient({
    required String apiKey,
    GeminiCostTracker? costTracker,
  }) : _apiKey = apiKey,
       _costTracker = costTracker ?? GeminiCostTracker.instance;

  // Add getter to use the _apiKey field
  String get apiKey => _apiKey;

  // ============================================================================
  // GOLF INSIGHT GENERATION
  // ============================================================================

  /// Generate golf performance insights from round data
  Future<GeminiInsightResponse> generateGolfInsight({
    required Map<String, dynamic> roundData,
    required String userId,
    String? userNotes,
    List<String>? previousInsights,
    Map<String, dynamic>? contextualFactors,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Create model for insights
      final model = FirebaseAI.googleAI().generativeModel(
        model: GeminiConfig.insightModel,
        generationConfig: GeminiConfig.insightGenerationConfig,
        safetySettings: GeminiConfig.defaultSafetySettings,
        systemInstruction: Content.text(GeminiConfig.golfInsightSystemPrompt),
      );

      // Prepare the prompt
      final prompt = _buildInsightPrompt(
        roundData: roundData,
        userNotes: userNotes,
        previousInsights: previousInsights,
        contextualFactors: contextualFactors,
      );

      // Generate response
      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response directly
      final jsonResponse = json.decode(responseText);
      
      // Create insight response manually
      final insightResponse = GeminiInsightResponse(
        insightTitle: jsonResponse['insightTitle'] as String,
        category: jsonResponse['category'] as String,
        priority: jsonResponse['priority'] as String,
        keyPoints: List<String>.from(jsonResponse['keyPoints'] as List),
        recommendations: (jsonResponse['recommendations'] as List)
            .map((r) => GeminiRecommendation.fromMap(r as Map<String, dynamic>))
            .toList(),
        personalizedElements: List<String>.from(jsonResponse['personalizedElements'] as List),
        summaryText: jsonResponse['summaryText'] as String,
        sentimentAnalysis: GeminiSentimentAnalysis.fromMap(
          jsonResponse['sentimentAnalysis'] as Map<String, dynamic>
        ),
        contextualFactors: List<String>.from(jsonResponse['contextualFactors'] as List? ?? []),
        followUpQuestions: List<String>.from(jsonResponse['followUpQuestions'] as List? ?? []),
        sourceId: 'golf_round_analysis',
        sourceType: 'golf_round',
        timestamp: DateTime.now(),
        model: GeminiConfig.insightModel,
        userId: userId,
        tokensUsed: _estimateTokens(responseText),
      );

      // Track usage
      await _trackInsightUsage(
        userId: userId,
        inputTokens: _estimateTokens(prompt),
        outputTokens: _estimateTokens(responseText),
        model: GeminiConfig.insightModel,
        duration: DateTime.now().difference(startTime),
      );

      return insightResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating golf insight: $e');
      }
      throw Exception('Failed to generate golf insight: $e');
    }
  }

  // ============================================================================
  // MENTAL COACHING RECOMMENDATIONS
  // ============================================================================

  /// Generate mental coaching recommendations
  Future<GeminiCoachingResponse> generateMentalCoachingRecommendations({
    required String userId,
    required Map<String, dynamic> userProfile,
    required String subscriptionTier,
    required Map<String, dynamic> varkPreferences,
    List<Map<String, dynamic>>? recentRounds,
    List<String>? completedModules,
    Map<String, dynamic>? performancePatterns,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Create model for coaching
      final model = FirebaseAI.googleAI().generativeModel(
        model: GeminiConfig.coachingModel,
        generationConfig: GeminiConfig.coachingGenerationConfig,
        safetySettings: GeminiConfig.defaultSafetySettings,
        systemInstruction: Content.text(GeminiConfig.mentalCoachingSystemPrompt),
      );

      // Prepare the prompt
      final prompt = _buildCoachingPrompt(
        userProfile: userProfile,
        subscriptionTier: subscriptionTier,
        varkPreferences: varkPreferences,
        recentRounds: recentRounds,
        completedModules: completedModules,
        performancePatterns: performancePatterns,
      );

      // Generate response
      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response directly
      final jsonResponse = json.decode(responseText);
      
      // Create coaching response manually
      final coachingResponse = GeminiCoachingResponse(
        recommendationType: jsonResponse['recommendationType'] as String,
        primaryFocus: jsonResponse['primaryFocus'] as String,
        userTier: jsonResponse['userTier'] as String,
        varkAdaptation: GeminiVarkAdaptation.fromMap(
          jsonResponse['varkAdaptation'] as Map<String, dynamic>
        ),
        recommendations: (jsonResponse['recommendations'] as List)
            .map((r) => GeminiModuleRecommendation.fromMap(r as Map<String, dynamic>))
            .toList(),
        weeklyPlan: GeminiWeeklyPlan.fromMap(
          jsonResponse['weeklyPlan'] as Map<String, dynamic>
        ),
        motivationalMessage: jsonResponse['motivationalMessage'] as String,
        contextualInsights: List<String>.from(jsonResponse['contextualInsights'] as List),
        adaptiveStrategies: (jsonResponse['adaptiveStrategies'] as List)
            .map((s) => GeminiAdaptiveStrategy.fromMap(s as Map<String, dynamic>))
            .toList(),
        timestamp: DateTime.now(),
        model: GeminiConfig.coachingModel,
        userId: userId,
        tokensUsed: _estimateTokens(responseText),
      );

      // Track usage
      await _trackRecommendationUsage(
        userId: userId,
        inputTokens: _estimateTokens(prompt),
        outputTokens: _estimateTokens(responseText),
        model: GeminiConfig.coachingModel,
        duration: DateTime.now().difference(startTime),
      );

      return coachingResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating mental coaching recommendations: $e');
      }
      throw Exception('Failed to generate coaching recommendations: $e');
    }
  }

  // ============================================================================
  // PERSONALIZED CONTENT GENERATION
  // ============================================================================

  /// Generate personalized content based on user preferences
  Future<GeminiContentResponse> generatePersonalizedContent({
    required String userId,
    required String contentType,
    required Map<String, dynamic> varkPreferences,
    required String userTier,
    String? specificTopic,
    String? difficultyLevel,
    int? targetDuration,
    List<String>? learningObjectives,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Create model for content generation
      final model = FirebaseAI.googleAI().generativeModel(
        model: GeminiConfig.contentModel,
        generationConfig: GeminiConfig.contentGenerationConfig,
        safetySettings: GeminiConfig.defaultSafetySettings,
        systemInstruction: Content.text(GeminiConfig.personalizedContentSystemPrompt),
      );

      // Prepare the prompt
      final prompt = _buildContentPrompt(
        contentType: contentType,
        varkPreferences: varkPreferences,
        userTier: userTier,
        specificTopic: specificTopic,
        difficultyLevel: difficultyLevel,
        targetDuration: targetDuration,
        learningObjectives: learningObjectives,
      );

      // Generate response
      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response directly
      final jsonResponse = json.decode(responseText);
      
      // Create content response manually
      final contentResponse = GeminiContentResponse(
        contentType: jsonResponse['contentType'] as String,
        title: jsonResponse['title'] as String,
        adaptedFor: List<String>.from(jsonResponse['adaptedFor'] as List),
        duration: jsonResponse['duration'] as int,
        difficulty: jsonResponse['difficulty'] as String,
        sections: (jsonResponse['sections'] as List)
            .map((s) => GeminiContentSection.fromMap(s as Map<String, dynamic>))
            .toList(),
        takeaways: List<String>.from(jsonResponse['takeaways'] as List),
        timestamp: DateTime.now(),
        model: GeminiConfig.contentModel,
        userId: userId,
        tokensUsed: _estimateTokens(responseText),
      );

      // Track usage
      await _trackContentUsage(
        userId: userId,
        inputTokens: _estimateTokens(prompt),
        outputTokens: _estimateTokens(responseText),
        model: GeminiConfig.contentModel,
        duration: DateTime.now().difference(startTime),
      );

      return contentResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating personalized content: $e');
      }
      throw Exception('Failed to generate personalized content: $e');
    }
  }

  // ============================================================================
  // SESSION FEEDBACK GENERATION
  // ============================================================================

  /// Generate session feedback and analysis
  Future<GeminiSessionFeedbackResponse> generateSessionFeedback({
    required String userId,
    required Map<String, dynamic> sessionData,
    required String sessionType,
    Map<String, dynamic>? userProgress,
    String? userInput,
    List<String>? previousFeedback,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Create model for feedback
      final model = FirebaseAI.googleAI().generativeModel(
        model: GeminiConfig.feedbackModel,
        generationConfig: GeminiConfig.feedbackGenerationConfig,
        safetySettings: GeminiConfig.defaultSafetySettings,
        systemInstruction: Content.text(GeminiConfig.sessionFeedbackSystemPrompt),
      );

      // Prepare the prompt
      final prompt = _buildFeedbackPrompt(
        sessionData: sessionData,
        sessionType: sessionType,
        userProgress: userProgress,
        userInput: userInput,
        previousFeedback: previousFeedback,
      );

      // Generate response
      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response directly
      final jsonResponse = json.decode(responseText);
      
      // Create feedback response manually
      final feedbackResponse = GeminiSessionFeedbackResponse(
        feedbackType: jsonResponse['feedbackType'] as String,
        overallAssessment: jsonResponse['overallAssessment'] as String,
        strengths: List<String>.from(jsonResponse['strengths'] as List),
        improvements: List<String>.from(jsonResponse['improvements'] as List),
        motivationalMessage: jsonResponse['motivationalMessage'] as String,
        timestamp: DateTime.now(),
        model: GeminiConfig.feedbackModel,
        userId: userId,
        tokensUsed: _estimateTokens(responseText),
      );

      // Track usage (assuming feedback is similar to other operations)
      await _trackContentUsage(
        userId: userId,
        inputTokens: _estimateTokens(prompt),
        outputTokens: _estimateTokens(responseText),
        model: GeminiConfig.feedbackModel,
        duration: DateTime.now().difference(startTime),
      );

      return feedbackResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating session feedback: $e');
      }
      throw Exception('Failed to generate session feedback: $e');
    }
  }

  // ============================================================================
  // MULTI-TURN CONVERSATION
  // ============================================================================

  /// Generate response in a multi-turn conversation
  Future<GeminiConversationResponse> generateConversationResponse({
    required String userId,
    required String conversationId,
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    String? context,
    Map<String, dynamic>? userProfile,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Create model for conversation
      final model = FirebaseAI.googleAI().generativeModel(
        model: GeminiConfig.defaultModel,
        generationConfig: GeminiConfig.conversationGenerationConfig,
        safetySettings: GeminiConfig.defaultSafetySettings,
      );

      // Build conversation context
      final conversationContent = _buildConversationContent(
        userMessage: userMessage,
        conversationHistory: conversationHistory,
        context: context,
        userProfile: userProfile,
      );

      // Generate response
      final response = await model.generateContent(conversationContent);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      final conversationResponse = GeminiConversationResponse(
        response: responseText,
        conversationType: 'coaching_conversation',
        sessionId: conversationId,
        context: context != null ? {'context': context} : {},
        timestamp: DateTime.now(),
        model: GeminiConfig.defaultModel,
        userId: userId,
        tokensUsed: _estimateTokens(responseText),
      );

      // Track usage
      await _trackConversationUsage(
        userId: userId,
        inputTokens: _estimateTokens(userMessage),
        outputTokens: _estimateTokens(responseText),
        sessionId: conversationId,
        duration: DateTime.now().difference(startTime),
      );

      return conversationResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating conversation response: $e');
      }
      throw Exception('Failed to generate conversation response: $e');
    }
  }

  // ============================================================================
  // AUDIO GENERATION (Future Implementation)
  // ============================================================================

  /// Generate audio content from text (placeholder for future implementation)
  Future<Uint8List> generateAudioContent({
    required String text,
    String? voice,
    double? speed,
  }) async {
    // This is a placeholder for future audio generation functionality
    // The google_generative_ai package may add audio generation in the future
    throw UnimplementedError('Audio generation not yet implemented');
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Build prompt for golf insight generation
  String _buildInsightPrompt({
    required Map<String, dynamic> roundData,
    String? userNotes,
    List<String>? previousInsights,
    Map<String, dynamic>? contextualFactors,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Analyze this golf round data and provide mental performance insights:');
    buffer.writeln();
    buffer.writeln('Round Data:');
    buffer.writeln(json.encode(roundData));
    
    if (userNotes != null && userNotes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('User Notes:');
      buffer.writeln(userNotes);
    }
    
    if (previousInsights != null && previousInsights.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Previous Insights:');
      for (final insight in previousInsights) {
        buffer.writeln('- $insight');
      }
    }
    
    if (contextualFactors != null && contextualFactors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Contextual Factors:');
      buffer.writeln(json.encode(contextualFactors));
    }
    
    buffer.writeln();
    buffer.writeln('Please provide a structured JSON response following the insight schema.');
    buffer.writeln('Include sentiment analysis of any text inputs and personalized recommendations.');
    
    return buffer.toString();
  }

  /// Build prompt for mental coaching recommendations
  String _buildCoachingPrompt({
    required Map<String, dynamic> userProfile,
    required String subscriptionTier,
    required Map<String, dynamic> varkPreferences,
    List<Map<String, dynamic>>? recentRounds,
    List<String>? completedModules,
    Map<String, dynamic>? performancePatterns,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate personalized mental coaching recommendations:');
    buffer.writeln();
    buffer.writeln('User Profile:');
    buffer.writeln(json.encode(userProfile));
    buffer.writeln();
    buffer.writeln('Subscription Tier: $subscriptionTier');
    buffer.writeln();
    buffer.writeln('VARK Preferences:');
    buffer.writeln(json.encode(varkPreferences));
    
    if (recentRounds != null && recentRounds.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Recent Rounds:');
      buffer.writeln(json.encode(recentRounds));
    }
    
    if (completedModules != null && completedModules.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Completed Modules:');
      for (final module in completedModules) {
        buffer.writeln('- $module');
      }
    }
    
    if (performancePatterns != null && performancePatterns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Performance Patterns:');
      buffer.writeln(json.encode(performancePatterns));
    }
    
    buffer.writeln();
    buffer.writeln('Please provide a structured JSON response with coaching recommendations.');
    buffer.writeln('Adapt all recommendations to the user\'s VARK preferences and subscription tier.');
    
    return buffer.toString();
  }

  /// Build prompt for personalized content generation
  String _buildContentPrompt({
    required String contentType,
    required Map<String, dynamic> varkPreferences,
    required String userTier,
    String? specificTopic,
    String? difficultyLevel,
    int? targetDuration,
    List<String>? learningObjectives,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate personalized learning content:');
    buffer.writeln();
    buffer.writeln('Content Type: $contentType');
    buffer.writeln('User Tier: $userTier');
    buffer.writeln();
    buffer.writeln('VARK Preferences:');
    buffer.writeln(json.encode(varkPreferences));
    
    if (specificTopic != null) {
      buffer.writeln();
      buffer.writeln('Specific Topic: $specificTopic');
    }
    
    if (difficultyLevel != null) {
      buffer.writeln('Difficulty Level: $difficultyLevel');
    }
    
    if (targetDuration != null) {
      buffer.writeln('Target Duration: $targetDuration minutes');
    }
    
    if (learningObjectives != null && learningObjectives.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Learning Objectives:');
      for (final objective in learningObjectives) {
        buffer.writeln('- $objective');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Please provide a structured JSON response with personalized content.');
    buffer.writeln('Include specific VARK adaptations and interactive elements.');
    
    return buffer.toString();
  }

  /// Build prompt for session feedback
  String _buildFeedbackPrompt({
    required Map<String, dynamic> sessionData,
    required String sessionType,
    Map<String, dynamic>? userProgress,
    String? userInput,
    List<String>? previousFeedback,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Provide feedback on this mental coaching session:');
    buffer.writeln();
    buffer.writeln('Session Type: $sessionType');
    buffer.writeln();
    buffer.writeln('Session Data:');
    buffer.writeln(json.encode(sessionData));
    
    if (userProgress != null) {
      buffer.writeln();
      buffer.writeln('User Progress:');
      buffer.writeln(json.encode(userProgress));
    }
    
    if (userInput != null && userInput.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('User Input:');
      buffer.writeln(userInput);
    }
    
    if (previousFeedback != null && previousFeedback.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Previous Feedback:');
      for (final feedback in previousFeedback) {
        buffer.writeln('- $feedback');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Please provide a structured JSON response with comprehensive feedback.');
    buffer.writeln('Include sentiment analysis and specific next steps.');
    
    return buffer.toString();
  }

  /// Build conversation content from history
  List<Content> _buildConversationContent({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    String? context,
    Map<String, dynamic>? userProfile,
  }) {
    final contentList = <Content>[];
    
    // Add context if provided
    if (context != null && context.isNotEmpty) {
      contentList.add(Content.text('Context: $context'));
    }
    
    // Add user profile if provided
    if (userProfile != null) {
      contentList.add(Content.text('User Profile: ${json.encode(userProfile)}'));
    }
    
    // Add conversation history
    for (final message in conversationHistory) {
      final role = message['role'] as String? ?? 'user';
      final content = message['content'] as String? ?? '';
      
      if (role == 'user') {
        contentList.add(Content.text('User: $content'));
      } else {
        contentList.add(Content.text('Assistant: $content'));
      }
    }
    
    // Add current user message
    contentList.add(Content.text('User: $userMessage'));
    contentList.add(Content.text('Assistant:'));
    
    return contentList;
  }

  /// Track insight generation usage
  Future<void> _trackInsightUsage({
    required String userId,
    required int inputTokens,
    required int outputTokens,
    required String model,
    required Duration duration,
  }) async {
    try {
      final totalTokens = inputTokens + outputTokens;
      final estimatedCost = GeminiConfig.estimateCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
      
      await _costTracker.trackInsightGeneration(
        userId: userId,
        tokensUsed: totalTokens,
        estimatedCost: estimatedCost,
        insightType: 'golf_performance',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error tracking insight usage: $e');
      }
    }
  }

  /// Track recommendation generation usage
  Future<void> _trackRecommendationUsage({
    required String userId,
    required int inputTokens,
    required int outputTokens,
    required String model,
    required Duration duration,
  }) async {
    try {
      final totalTokens = inputTokens + outputTokens;
      final estimatedCost = GeminiConfig.estimateCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
      
      await _costTracker.trackRecommendationGeneration(
        userId: userId,
        tokensUsed: totalTokens,
        estimatedCost: estimatedCost,
        recommendationType: 'mental_coaching',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error tracking recommendation usage: $e');
      }
    }
  }

  /// Track content generation usage
  Future<void> _trackContentUsage({
    required String userId,
    required int inputTokens,
    required int outputTokens,
    required String model,
    required Duration duration,
  }) async {
    try {
      final totalTokens = inputTokens + outputTokens;
      final estimatedCost = GeminiConfig.estimateCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
      
      await _costTracker.trackContentGeneration(
        userId: userId,
        tokensUsed: totalTokens,
        estimatedCost: estimatedCost,
        contentType: 'personalized_content',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error tracking content usage: $e');
      }
    }
  }

  /// Track conversation usage
  Future<void> _trackConversationUsage({
    required String userId,
    required int inputTokens,
    required int outputTokens,
    required String sessionId,
    required Duration duration,
  }) async {
    try {
      final totalTokens = inputTokens + outputTokens;
      final estimatedCost = GeminiConfig.estimateCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
      
      await _costTracker.trackConversationUsage(
        userId: userId,
        tokensUsed: totalTokens,
        estimatedCost: estimatedCost,
        sessionId: sessionId,
        conversationType: 'coaching_conversation',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error tracking conversation usage: $e');
      }
    }
  }

  /// Estimate token count for text
  int _estimateTokens(String text) {
    return GeminiConfig.estimateTokenCount(text);
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}

/// Custom exception for Gemini AI-related errors
class GeminiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  const GeminiException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  @override
  String toString() => 'GeminiException: $message (Status: $statusCode, Type: $errorType)';
} 