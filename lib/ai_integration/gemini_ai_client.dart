import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models/gemini_models.dart';
import 'config/gemini_config.dart';
import 'services/gemini_cost_tracker.dart';
import 'services/gemini_interactions_service.dart';

/// Main client for Google Generative AI Gemini integration
class GeminiAIClient {
  final String _apiKey;
  final GeminiCostTracker _costTracker;

  GeminiAIClient({
    required String apiKey,
    GeminiCostTracker? costTracker,
  })  : _apiKey = apiKey,
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

      // Parse JSON response with truncation handling
      final jsonResponse = _parseJsonResponse(responseText, userId: userId);

      // Create insight response manually with null safety
      final insightResponse = GeminiInsightResponse(
        insightTitle: jsonResponse['insightTitle'] as String? ??
            'Golf Performance Insight',
        category: jsonResponse['category'] as String? ?? 'performance',
        priority: jsonResponse['priority'] as String? ?? 'medium',
        keyPoints: List<String>.from(jsonResponse['keyPoints'] as List? ??
            ['Continue working on your game']),
        recommendations: (jsonResponse['recommendations'] as List?)
                ?.map((r) =>
                    GeminiRecommendation.fromMap(r as Map<String, dynamic>))
                .toList() ??
            [],
        personalizedElements: List<String>.from(
            jsonResponse['personalizedElements'] as List? ??
                ['Focus on fundamentals']),
        summaryText: jsonResponse['summaryText'] as String? ??
            'Keep practicing and stay consistent',
        sentimentAnalysis: jsonResponse['sentimentAnalysis'] != null
            ? GeminiSentimentAnalysis.fromMap(
                jsonResponse['sentimentAnalysis'] as Map<String, dynamic>)
            : GeminiSentimentAnalysis(
                overallSentiment: 'positive',
                confidenceLevel: 0.7,
                emotionalIndicators: ['determined'],
                moodProgression: 'stable',
              ),
        contextualFactors:
            List<String>.from(jsonResponse['contextualFactors'] as List? ?? []),
        followUpQuestions:
            List<String>.from(jsonResponse['followUpQuestions'] as List? ?? []),
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
        systemInstruction:
            Content.text(GeminiConfig.mentalCoachingSystemPrompt),
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

      // Parse JSON response with truncation handling
      final jsonResponse = _parseJsonResponse(responseText, userId: userId);

      // Create coaching response manually with null safety
      final coachingResponse = GeminiCoachingResponse(
        recommendationType: jsonResponse['recommendationType'] as String? ??
            'coaching_recommendations',
        primaryFocus: jsonResponse['primaryFocus'] as String? ??
            'Mental Game Development',
        userTier: jsonResponse['userTier'] as String? ?? 'FREE',
        varkAdaptation: jsonResponse['varkAdaptation'] != null
            ? GeminiVarkAdaptation.fromMap(
                jsonResponse['varkAdaptation'] as Map<String, dynamic>)
            : GeminiVarkAdaptation(
                primaryStyle: 'visual',
                adaptationStrategies: ['Focus', 'Practice', 'Improve'],
              ),
        recommendations: (jsonResponse['recommendations'] as List?)
                ?.map((r) => GeminiModuleRecommendation.fromMap(
                    r as Map<String, dynamic>))
                .toList() ??
            [],
        weeklyPlan: jsonResponse['weeklyPlan'] != null
            ? GeminiWeeklyPlan.fromMap(
                jsonResponse['weeklyPlan'] as Map<String, dynamic>)
            : GeminiWeeklyPlan(
                sessionsPerWeek: 3,
                totalDuration: 45,
                focusAreas: ['Focus', 'Confidence', 'Control'],
                progressMilestones: ['Complete first session'],
              ),
        motivationalMessage: jsonResponse['motivationalMessage'] as String? ??
            'Let\'s strengthen your mental game!',
        contextualInsights: List<String>.from(
            jsonResponse['contextualInsights'] as List? ??
                ['Build consistency in your mental training']),
        adaptiveStrategies: (jsonResponse['adaptiveStrategies'] as List?)
                ?.map((s) =>
                    GeminiAdaptiveStrategy.fromMap(s as Map<String, dynamic>))
                .toList() ??
            [],
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
        systemInstruction:
            Content.text(GeminiConfig.personalizedContentSystemPrompt),
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

      // Parse JSON response with truncation handling
      final jsonResponse = _parseJsonResponse(responseText, userId: userId);

      // Create content response manually with null safety
      final contentResponse = GeminiContentResponse(
        contentType: jsonResponse['contentType'] as String? ?? 'module',
        title: jsonResponse['title'] as String? ?? 'Generated Content',
        adaptedFor: List<String>.from(
            jsonResponse['adaptedFor'] as List? ?? ['visual']),
        duration: jsonResponse['duration'] as int? ?? 15,
        difficulty: jsonResponse['difficulty'] as String? ?? 'intermediate',
        sections: (jsonResponse['sections'] as List?)
                ?.map((s) =>
                    GeminiContentSection.fromMap(s as Map<String, dynamic>))
                .toList() ??
            [],
        takeaways: List<String>.from(
            jsonResponse['takeaways'] as List? ?? ['Generated takeaway']),
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
        systemInstruction:
            Content.text(GeminiConfig.sessionFeedbackSystemPrompt),
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

      // Parse JSON response with truncation handling
      final jsonResponse = _parseJsonResponse(responseText, userId: userId);

      // Create feedback response manually with null safety
      final feedbackResponse = GeminiSessionFeedbackResponse(
        feedbackType:
            jsonResponse['feedbackType'] as String? ?? 'session_feedback',
        overallAssessment: jsonResponse['overallAssessment'] as String? ??
            'Good progress in your mental training',
        strengths: List<String>.from(
            jsonResponse['strengths'] as List? ?? ['Consistent effort']),
        improvements: List<String>.from(
            jsonResponse['improvements'] as List? ?? ['Continue practicing']),
        motivationalMessage: jsonResponse['motivationalMessage'] as String? ??
            'Keep up the great work!',
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

  /// Generate response in a multi-turn conversation.
  /// Tries REST with client API key first; on 403 (blocked key) falls back to Firebase AI.
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
      String responseText = '';

      if (_apiKey.isNotEmpty) {
        try {
          responseText = await _generateConversationResponseViaRest(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            context: context,
            userProfile: userProfile,
          );
        } catch (restError) {
          final msg = restError.toString();
          if (msg.contains('403') ||
              msg.contains('PERMISSION_DENIED') ||
              msg.contains('API_KEY_SERVICE_BLOCKED')) {
            if (kDebugMode) {
              print('⚠️ Gemini REST blocked (403), falling back to Firebase AI.');
            }
            try {
              responseText = await _generateConversationResponseViaFirebaseAI(
                userMessage: userMessage,
                conversationHistory: conversationHistory,
                context: context,
                userProfile: userProfile,
              );
            } catch (firebaseError) {
              if (kDebugMode) {
                print('⚠️ Firebase AI also failed: $firebaseError');
              }
              throw Exception(
                'Gemini API is not available. Enable "Generative Language API" '
                'in Google Cloud Console and ensure your API key is not restricted '
                'for this app, or use Firebase AI with a valid key.',
              );
            }
          } else {
            rethrow;
          }
        }
      }

      if (responseText.isEmpty) {
        try {
          responseText = await _generateConversationResponseViaFirebaseAI(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            context: context,
            userProfile: userProfile,
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Firebase AI fallback failed: $e');
          }
        }
      }

      if (responseText.isEmpty) {
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
      final msg = e.toString();
      if (msg.contains('Gemini API is not available') ||
          msg.contains('PERMISSION_DENIED') ||
          msg.contains('API_KEY_SERVICE_BLOCKED')) {
        rethrow;
      }
      throw Exception('Failed to generate conversation response: $e');
    }
  }

  /// Generate conversation response via Firebase AI (server-side key). Used when REST key is blocked or no key.
  Future<String> _generateConversationResponseViaFirebaseAI({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    String? context,
    Map<String, dynamic>? userProfile,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: GeminiConfig.defaultModel,
      generationConfig: GeminiConfig.conversationGenerationConfig,
      safetySettings: GeminiConfig.defaultSafetySettings,
    );
    final conversationContent = _buildConversationContent(
      userMessage: userMessage,
      conversationHistory: conversationHistory,
      context: context,
      userProfile: userProfile,
    );
    final response = await model.generateContent(conversationContent);
    return response.text ?? '';
  }

  /// Call Gemini REST API for conversation (used when API key is provided to avoid Firebase AI leaked key).
  Future<String> _generateConversationResponseViaRest({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    String? context,
    Map<String, dynamic>? userProfile,
  }) async {
    final contents = <Map<String, dynamic>>[];

    if (context != null && context.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [{'text': 'Context: $context'}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Understood.'}],
      });
    }
    if (userProfile != null && userProfile.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [{'text': 'User Profile: ${json.encode(userProfile)}'}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Understood.'}],
      });
    }
    for (final message in conversationHistory) {
      final role = message['role'] as String? ?? 'user';
      final content = message['content'] as String? ?? '';
      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [{'text': content}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
    );
    final body = json.encode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.8,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${response.statusCode} ${response.body}',
      );
    }

    final map = json.decode(response.body) as Map<String, dynamic>;
    final candidates = map['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in Gemini response');
    }
    final parts = (candidates.first as Map<String, dynamic>)['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('No parts in Gemini response');
    }
    final text = (parts.first as Map<String, dynamic>)['text'] as String?;
    return text ?? '';
  }

  // ============================================================================
  // VARK ASSESSMENT GENERATION
  // ============================================================================

  /// Generate a comprehensive VARK assessment with questions and images
  /// Uses Gemini Interactions API with gemini-3-flash-preview
  Future<Map<String, dynamic>> generateVarkAssessment({
    required String userId,
    Map<String, dynamic>? userProfile,
    int questionCount = 12,
  }) async {
    final startTime = DateTime.now();

    try {
      // Use Interactions API service
      final interactionsService = GeminiInteractionsService();
      
      final jsonResponse = await interactionsService.generateVarkAssessment(
        userId: userId,
        userProfile: userProfile,
        questionCount: questionCount,
      );

      // Track usage (approximate)
      await _trackContentUsage(
        userId: userId,
        inputTokens: _estimateTokens(jsonEncode(userProfile ?? {})),
        outputTokens: _estimateTokens(jsonEncode(jsonResponse)),
        model: GeminiConfig.contentModel,
        duration: DateTime.now().difference(startTime),
      );

      return jsonResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating VARK assessment: $e');
      }
      throw Exception('Failed to generate VARK assessment: $e');
    }
  }

  /// Get system prompt for assessment generation
  String _getAssessmentSystemPrompt() {
    return '''
You are an expert in learning style assessment, specifically the VARK (Visual, Auditory, Read/Write, Kinesthetic) model for golf mental performance training.

Your task is to generate a comprehensive, engaging VARK assessment that helps golfers discover their optimal learning style for mental performance training.

Generate assessment questions in this JSON format:
{
  "title": "Discover Your Learning Style",
  "description": "Personalized assessment to understand how you learn best",
  "questions": [
    {
      "id": "q1",
      "question": "Engaging question text",
      "imageDescription": "Description of image that would help illustrate this question (for golf mental performance context)",
      "category": "focus|confidence|control|general",
      "order": 1,
      "answers": [
        {
          "id": "a1",
          "text": "Answer option text",
          "varkType": "visual|aural|readWrite|kinesthetic",
          "score": 1
        }
      ]
    }
  ],
  "imageDescriptions": [
    "Description for image 1",
    "Description for image 2",
    "Description for image 3"
  ]
}

Requirements:
- Generate exactly 12 questions
- Each question must have exactly 4 answers, one for each VARK type
- Questions should be golf-specific and relate to mental performance scenarios
- Include scenarios about: pre-shot routines, pressure situations, learning new techniques, reviewing performance, practice methods
- Make questions engaging and relatable to golfers
- Image descriptions should be detailed enough to generate relevant visuals
- Ensure balanced coverage of all VARK types across questions
- Questions should feel natural and not overly academic

Return ONLY valid JSON, no markdown formatting or code blocks.
''';
  }

  /// Build prompt for assessment generation
  String _buildAssessmentPrompt({
    required String userId,
    Map<String, dynamic>? userProfile,
    required int questionCount,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Generate a VARK learning style assessment for a golfer.');
    buffer.writeln();

    if (userProfile != null) {
      buffer.writeln('User Profile:');
      buffer.writeln(json.encode(userProfile));
      buffer.writeln();
    }

    buffer.writeln(
        'Generate $questionCount questions that help identify their learning style.');
    buffer.writeln('Focus on golf mental performance scenarios.');
    buffer.writeln('Make it engaging and personalized.');

    return buffer.toString();
  }

  // ============================================================================
  // IMAGE GENERATION
  // ============================================================================

  /// Generate image using Gemini 2.5 Flash Image Preview
  /// Note: This uses the REST API as Firebase AI SDK doesn't support image generation yet
  Future<String?> generateImage({
    required String prompt,
    String? userId,
  }) async {
    try {
      // For now, return null as Gemini 2.5 Flash Image Preview API integration
      // requires REST API calls which need proper API key management
      // This is a placeholder for future implementation
      if (kDebugMode) {
        print('🎨 Image generation requested with prompt: $prompt');
        print('⚠️ Image generation not yet implemented - requires Gemini Image API integration');
      }
      
      // TODO: Implement Gemini 2.5 Flash Image Preview API call
      // Example structure:
      // final response = await http.post(
      //   Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'x-goog-api-key': _apiKey,
      //   },
      //   body: jsonEncode({
      //     'prompt': prompt,
      //     'number_of_images': 1,
      //   }),
      // );
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating image: $e');
      }
      return null;
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

    buffer.writeln(
        'Analyze this golf round data and provide mental performance insights:');
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
    buffer.writeln(
        'Please provide a structured JSON response following the insight schema.');
    buffer.writeln(
        'Include sentiment analysis of any text inputs and personalized recommendations.');

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
    buffer.writeln(
        'Please provide a structured JSON response with coaching recommendations.');
    buffer.writeln(
        'Adapt all recommendations to the user\'s VARK preferences and subscription tier.');

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
    buffer.writeln(
        'Please provide a structured JSON response with personalized content.');
    buffer
        .writeln('Include specific VARK adaptations and interactive elements.');

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
    buffer.writeln(
        'Please provide a structured JSON response with comprehensive feedback.');
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
      contentList
          .add(Content.text('User Profile: ${json.encode(userProfile)}'));
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

  /// Parse JSON response with handling for truncated responses
  Map<String, dynamic> _parseJsonResponse(String responseText, {String? userId}) {
    bool attemptedRepair = false;

    try {
      // Clean up the response text
      String cleanedText = responseText.trim();

      // Remove markdown code blocks if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      // Always attempt repair for malformed JSON patterns
      if (_hasMalformedPatterns(cleanedText) || _isJsonTruncated(cleanedText)) {
        if (kDebugMode) {
          print('⚠️ JSON response appears malformed, attempting repair...');
        }
        cleanedText = _repairTruncatedJson(cleanedText);
        attemptedRepair = true;
      }

      // Parse JSON - handle both List and Map responses
      final decoded = json.decode(cleanedText);
      
      // If response is a List, take the first element or wrap it
      if (decoded is List) {
        if (decoded.isEmpty) {
          if (kDebugMode) {
            print('⚠️ JSON response is an empty list');
          }
          throw FormatException('Empty response from AI');
        }
        
        // If list contains a single map, return it
        if (decoded.length == 1 && decoded[0] is Map<String, dynamic>) {
          if (kDebugMode) {
            print('ℹ️ JSON response is a list with single map, extracting first element');
          }
          return decoded[0] as Map<String, dynamic>;
        }
        
        // If list contains multiple items, wrap in a response object
        if (kDebugMode) {
          print('ℹ️ JSON response is a list with ${decoded.length} items, wrapping in response object');
        }
        return {
          'items': decoded,
          'count': decoded.length,
        };
      }
      
      // If response is already a Map, return it
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      
      // Fallback for unexpected types
      if (kDebugMode) {
        print('⚠️ JSON response is unexpected type: ${decoded.runtimeType}');
      }
      throw FormatException('Unexpected response format: ${decoded.runtimeType}');
    } catch (e) {
      // Try a second repair pass if we haven't already
      if (!attemptedRepair) {
        final fallback = _repairTruncatedJson(responseText.trim());
        try {
          if (kDebugMode) {
            print('⚠️ Retrying JSON parse after additional repair...');
          }
          final decoded = json.decode(fallback);
          
          // Handle List response in retry
          if (decoded is List) {
            if (decoded.isNotEmpty && decoded[0] is Map<String, dynamic>) {
              return decoded[0] as Map<String, dynamic>;
            }
            return {
              'items': decoded,
              'count': decoded.length,
            };
          }
          
          return decoded as Map<String, dynamic>;
        } catch (_) {
          // Continue to logging below
        }
      }

      if (kDebugMode) {
        print('❌ Error parsing JSON response: $e');
        print('Response text length: ${responseText.length}');
        final previewLength =
            responseText.length > 500 ? 500 : responseText.length;
        print(
            'Response text (first $previewLength chars): ${responseText.substring(0, previewLength)}');
        if (responseText.length > 200) {
          final startPos =
              responseText.length > 300 ? responseText.length - 300 : 0;
          print(
              'Response text (last 300 chars): ${responseText.substring(startPos)}');
        }
      }

      // Log error to user record if userId is available (fire and forget)
      if (userId != null && userId.isNotEmpty) {
        _logAIErrorToUser(userId, e.toString(), responseText).catchError((err) {
          if (kDebugMode) {
            print('⚠️ Failed to log AI error: $err');
          }
        });
      }

      rethrow;
    }
  }

  /// Check for malformed JSON patterns that need repair
  bool _hasMalformedPatterns(String jsonText) {
    // Check for patterns like "key":] or "key":]] or "key":}
    final malformedPattern =
        RegExp(r'"[\w\s]+"\s*:\s*(\]+|}+)', caseSensitive: false);
    return malformedPattern.hasMatch(jsonText);
  }

  /// Check if JSON response appears truncated
  bool _isJsonTruncated(String jsonText) {
    // Check for common signs of truncation:
    // 1. Unclosed string quotes
    // 2. Unclosed brackets/braces

    int openBraces = jsonText.split('{').length - 1;
    int closeBraces = jsonText.split('}').length - 1;

    // Count quotes (should be even for complete strings)
    int quotes = jsonText.split('"').length - 1;

    // Check for incomplete string (odd number of quotes at end)
    if (quotes % 2 != 0) {
      return true;
    }

    // Check for unclosed braces
    if (openBraces > closeBraces) {
      return true;
    }

    return false;
  }

  /// Attempt to repair truncated JSON by closing incomplete structures
  String _repairTruncatedJson(String jsonText) {
    String repaired = jsonText.trim();

    // First, fix the specific pattern: ""}]} or ""}] that appears in truncated JSON
    // This happens when JSON is cut off mid-generation
    repaired = repaired.replaceAll(RegExp(r'""\s*(\]+\}+)'), r'\1');
    repaired = repaired.replaceAll(RegExp(r'""\s*(\]+)'), r'\1');
    repaired = repaired.replaceAll(RegExp(r'""\s*(})'), r'\1');

    // Fix malformed patterns where key has no value before closing brackets/braces
    // Pattern: "key":] or "key": ] or "key":]] or "key":]]} should become "key": null]
    // Apply multiple times to handle nested cases
    for (int i = 0; i < 5; i++) {
      final before = repaired;

      // Fix pattern: "key":] (single closing bracket)
      repaired = repaired.replaceAllMapped(
        RegExp(r'("[\w\s]+"\s*:\s*)(\])', caseSensitive: false),
        (match) => '${match.group(1)}null${match.group(2)}',
      );

      // Fix pattern: "key":} (single closing brace)
      repaired = repaired.replaceAllMapped(
        RegExp(r'("[\w\s]+"\s*:\s*)(})', caseSensitive: false),
        (match) => '${match.group(1)}null${match.group(2)}',
      );

      // Fix pattern: "key":]] (multiple closing brackets)
      repaired = repaired.replaceAllMapped(
        RegExp(r'("[\w\s]+"\s*:\s*)(\]+)', caseSensitive: false),
        (match) => '${match.group(1)}null${match.group(2)}',
      );

      // Fix pattern: "key":}} (multiple closing braces)
      repaired = repaired.replaceAllMapped(
        RegExp(r'("[\w\s]+"\s*:\s*)(}+)', caseSensitive: false),
        (match) => '${match.group(1)}null${match.group(2)}',
      );

      // Fix pattern: "key":]]} (mixed closing brackets/braces)
      repaired = repaired.replaceAllMapped(
        RegExp(r'("[\w\s]+"\s*:\s*)(\]+}+)', caseSensitive: false),
        (match) => '${match.group(1)}null${match.group(2)}',
      );

      // Fix specific pattern: "rationale":]}} -> "rationale": ""}}
      // This handles cases where rationale field is missing its string value
      repaired = repaired.replaceAllMapped(
        RegExp(r'("rationale"\s*:\s*)(\]+\}+)', caseSensitive: false),
        (match) => '${match.group(1)}""${match.group(2)}',
      );

      // Fix pattern: "rationale":] -> "rationale": ""
      repaired = repaired.replaceAllMapped(
        RegExp(r'("rationale"\s*:\s*)(\])', caseSensitive: false),
        (match) => '${match.group(1)}""${match.group(2)}',
      );

      // If no changes made, break early
      if (before == repaired) break;
    }

      // Fix pattern: "key":, (missing value before comma)
      repaired = repaired.replaceAllMapped(
        RegExp(r'("[\w\s]+"\s*:\s*)(,)', caseSensitive: false),
        (match) => '${match.group(1)}null${match.group(2)}',
      );

      // Fix specific pattern for missing score after varkType: "varkType": "aural"]] -> "varkType": "aural", "score": 1]]
      repaired = repaired.replaceAllMapped(
        RegExp(r'("varkType"\s*:\s*"[^"]+")(\s*\]+\s*\]+)', caseSensitive: false),
        (match) => '${match.group(1)}, "score": 1${match.group(2)}',
      );
      
      // Fix pattern: "varkType": "value"]]} -> "varkType": "value", "score": 1]]}
      repaired = repaired.replaceAllMapped(
        RegExp(r'("varkType"\s*:\s*"[^"]+")(\s*\]+\s*\]+})', caseSensitive: false),
        (match) => '${match.group(1)}, "score": 1${match.group(2)}',
      );

    // Remove trailing commas before closing braces/brackets
    repaired = repaired.replaceAll(RegExp(r',\s*([}\]])'), r'\1');

    // Close dangling string if the response was cut mid-string
    if (_hasUnclosedQuote(repaired)) {
      repaired = '$repaired"';
    }

    // Replace missing values right before a closing brace/bracket with null
    repaired = repaired.replaceAllMapped(
      RegExp(r'(".*?"\s*:\s*)(?=[}\]])'),
      (match) => '${match.group(1)}null',
    );

    // Fix empty values after colon at end: "key": -> "key": null
    repaired = repaired.replaceAllMapped(
      RegExp(r'("[\w\s]+"\s*:\s*)$', caseSensitive: false),
      (match) => '${match.group(1)}null',
    );

    // Track nesting depth by walking through the string
    bool inString = false;
    bool escaped = false;
    int lastValidPosition = 0;

    for (int i = 0; i < repaired.length; i++) {
      final char = repaired[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        if (!inString) {
          // String closed, this is a valid position
          lastValidPosition = i + 1;
        }
        continue;
      }

      if (inString) continue;

      // Track valid positions (after complete values)
      if (char == ',' || char == ':' || char == '}' || char == ']') {
        lastValidPosition = i + 1;
      }

      if (char == '{' || char == '[' || char == '}' || char == ']') {
        lastValidPosition = i + 1;
      }
    }

    // If we're in the middle of an incomplete field/value, truncate to last valid position
    if (inString || lastValidPosition < repaired.length) {
      // Find the last complete field/value
      // Look backwards from the end to find a valid closing point
      int truncatePos = repaired.length;

      // If we're in a string, try to find where it started
      if (inString) {
        // Find the last quote that started this string
        for (int i = repaired.length - 1; i >= 0; i--) {
          if (repaired[i] == '"' && (i == 0 || repaired[i - 1] != '\\')) {
            truncatePos = i;
            break;
          }
        }
      } else {
        // Find the last complete value (ends with quote, number, true/false/null, or closing bracket/brace)
        // Look for patterns like: ", "value", number, true, false, null, ], }
        for (int i = repaired.length - 1; i >= 0; i--) {
          final char = repaired[i];
          if (char == '"' ||
              char == '}' ||
              char == ']' ||
              char == ',' ||
              char == 'e' ||
              char == 'l' ||
              char == '0' ||
              char == '1' ||
              char == '2' ||
              char == '3' ||
              char == '4' ||
              char == '5' ||
              char == '6' ||
              char == '7' ||
              char == '8' ||
              char == '9') {
            // Check if this looks like end of a value
            if (i < repaired.length - 1) {
              final nextChars = repaired.substring(i).trim();
              if (nextChars.isEmpty ||
                  nextChars.startsWith(',') ||
                  nextChars.startsWith('}') ||
                  nextChars.startsWith(']')) {
                truncatePos = i + 1;
                break;
              }
            }
          }
        }
      }

      // Truncate to remove incomplete field/value
      repaired = repaired.substring(0, truncatePos).trim();

      // Remove trailing comma if present
      if (repaired.endsWith(',')) {
        repaired = repaired.substring(0, repaired.length - 1).trim();
      }
    }

    // Track remaining open delimiters so we can close them in the right order
    final openDelimiters = <String>[];
    inString = false;
    escaped = false;

    for (int i = 0; i < repaired.length; i++) {
      final char = repaired[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char == '{' || char == '[') {
        openDelimiters.add(char);
      } else if (char == '}' || char == ']') {
        if (openDelimiters.isNotEmpty &&
            ((char == '}' && openDelimiters.last == '{') ||
                (char == ']' && openDelimiters.last == '['))) {
          openDelimiters.removeLast();
        }
      }
    }

    for (final delimiter in openDelimiters.reversed) {
      repaired = repaired + (delimiter == '{' ? '}' : ']');
    }

    return repaired;
  }

  bool _hasUnclosedQuote(String text) {
    bool escaped = false;
    int quotes = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        quotes++;
      }
    }

    return quotes % 2 != 0;
  }

  /// Log AI error to user record
  Future<void> _logAIErrorToUser(
    String userId,
    String errorMessage,
    String? responseText,
  ) async {
    try {
      final errorLog = errorMessage.length > 500
          ? errorMessage.substring(0, 500)
          : errorMessage;
      
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .update({
        'lastAIError': errorLog,
        'lastAIErrorTimestamp': FieldValue.serverTimestamp(),
        'aiErrorCount': FieldValue.increment(1),
      });
      
      if (kDebugMode) {
        print('✅ AI error logged to user record: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to log AI error to user record: $e');
      }
    }
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
  String toString() =>
      'GeminiException: $message (Status: $statusCode, Type: $errorType)';
}
