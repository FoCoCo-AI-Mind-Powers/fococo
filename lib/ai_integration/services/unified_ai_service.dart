import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../config/gemini_config.dart';

import '/backend/schema/structs/vark_preferences_struct.dart';

/// Unified AI Service for FoCoCo
/// Manages all AI integrations including Firebase AI, OpenAI, and voice services
/// Provides fallback mechanisms and error handling
class UnifiedAIService {
  static final UnifiedAIService _instance = UnifiedAIService._internal();
  factory UnifiedAIService() => _instance;
  UnifiedAIService._internal();

  // AI Clients
  GenerativeModel? _firebaseModel;
  FlutterTts? _tts;

  // State management
  bool _isInitialized = false;
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  // Getters
  Stream<String> get statusStream => _statusController.stream;
  bool get isInitialized => _isInitialized;

  /// Initialize all AI services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _statusController.add('Initializing AI services...');

      // Initialize Firebase AI
      await _initializeFirebaseAI();

      // Initialize TTS
      await _initializeTTS();

      _isInitialized = true;
      _statusController.add('AI services ready');

      if (kDebugMode) {
        print('🤖 Unified AI Service initialized successfully');
      }
    } catch (e) {
      _statusController.add('AI initialization failed: $e');
      if (kDebugMode) {
        print('❌ Error initializing AI services: $e');
      }
      rethrow;
    }
  }

  /// Initialize Firebase AI with proper error handling
  Future<void> _initializeFirebaseAI() async {
    try {
      // Create Firebase AI model
      _firebaseModel = FirebaseAI.googleAI().generativeModel(
        model: GeminiConfig.defaultModel,
        generationConfig: GeminiConfig.conversationGenerationConfig,
        safetySettings: GeminiConfig.defaultSafetySettings,
      );

      // Test the model with a simple query
      await _testFirebaseAI();

      if (kDebugMode) {
        print('✅ Firebase AI initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firebase AI initialization failed: $e');
      }
      _firebaseModel = null;
    }
  }

  /// Test Firebase AI connection
  Future<void> _testFirebaseAI() async {
    if (_firebaseModel == null) return;

    try {
      final response = await _firebaseModel!.generateContent(
          [Content.text('Test connection - respond with "OK"')]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Firebase AI');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase AI test failed: $e');
      }
      rethrow;
    }
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.45); // Slower, more natural speech rate
      await _tts!.setPitch(0.95); // Slightly lower pitch for better clarity
      await _tts!.setVolume(0.8);

      if (kDebugMode) {
        print('✅ TTS initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ TTS initialization failed: $e');
      }
      _tts = null;
    }
  }

  /// Generate AI response with enhanced memory and NLP analysis
  Future<String> generateResponse({
    required String userMessage,
    String? conversationContext,
    VarkPreferencesStruct? varkPreferences,
    String interactionType = 'quickChat',
    Map<String, dynamic>? userInsights,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Build enhanced system prompt with user insights
      final systemPrompt = _buildEnhancedSystemPrompt(
        varkPreferences: varkPreferences,
        interactionType: interactionType,
        userInsights: userInsights,
      );

      // Build full prompt with context and personalization
      final fullPrompt = _buildFullPrompt(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        conversationContext: conversationContext,
      );

      // Try Firebase AI first
      if (_firebaseModel != null) {
        try {
          final response =
              await _firebaseModel!.generateContent([Content.text(fullPrompt)]);

          final responseText = response.text;
          if (responseText != null && responseText.isNotEmpty) {
            return _cleanResponse(responseText);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Firebase AI failed, trying fallback: $e');
          }
        }
      }

      // Fallback to hardcoded intelligent responses with user insights
      return _generateFallbackResponse(
          userMessage, varkPreferences, userInsights);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating AI response: $e');
      }
      return _generateErrorResponse();
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    if (_tts == null) {
      await _initializeTTS();
    }

    try {
      await _tts?.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('❌ TTS error: $e');
      }
    }
  }

  /// Stop TTS
  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping TTS: $e');
      }
    }
  }

  /// Build enhanced system prompt with user insights and memory
  String _buildEnhancedSystemPrompt({
    VarkPreferencesStruct? varkPreferences,
    String interactionType = 'quickChat',
    Map<String, dynamic>? userInsights,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('''
You are the FoCoCo AI Mental Performance Coach, a world-class expert in golf psychology and mental training.

Your expertise:
- Mental toughness and confidence building using proven sports psychology techniques
- Focus, Confidence, and Control (FoCoCo methodology) - the three pillars of mental golf
- Golf-specific performance psychology and course management
- Practical mindfulness, visualization, and breathing techniques
- NLP-based pattern recognition and personalized coaching
- Long-term mental performance tracking and optimization
- Pre-shot routines, pressure management, and recovery strategies

Core Principles (from FoCoCo concept):
- Scalable, personalized mental performance coaching
- VARK-based content delivery adaptation (Visual, Auditory, Read/Write, Kinesthetic)
- Data-driven insights and evidence-based recommendations
- Proven sports psychology techniques adapted for golf

Communication Guidelines:
- Be encouraging, supportive, and professional like a trusted coach
- Provide specific, actionable advice with clear steps
- Keep responses conversational, engaging, and appropriately detailed
- Reference specific golf scenarios and situations
- Use insights from previous conversations to build rapport and personalize advice
- Ask thoughtful follow-up questions to deepen understanding
- Remember user preferences, challenges, and progress patterns
- Adapt communication style based on user history and learning preferences
- Always end with an engaging question or next step
- Use golf terminology naturally and appropriately

Response Structure:
1. Acknowledge the user's situation with empathy
2. Provide specific, actionable advice
3. Include a practical technique or exercise when relevant
4. Ask a follow-up question to continue the conversation

Remember: You're not just answering questions - you're building a coaching relationship!
''');

    // Add user-specific insights if available
    if (userInsights != null && userInsights.isNotEmpty) {
      buffer.writeln('\n--- USER PROFILE ---');

      final userProfile =
          userInsights['userInsights'] as Map<String, dynamic>? ?? {};
      final golfPatterns =
          userInsights['golfPatterns'] as Map<String, dynamic>? ?? {};
      final mentalPatterns =
          userInsights['mentalPatterns'] as Map<String, dynamic>? ?? {};
      final keyTopics = userInsights['keyTopics'] as List<dynamic>? ?? [];
      final personalityTraits =
          userInsights['personalityTraits'] as Map<String, dynamic>? ?? {};
      final totalInteractions = userInsights['totalInteractions'] as int? ?? 0;
      final engagementScore = userInsights['engagementScore'] as double? ?? 0.0;

      if (userProfile['communicationStyle'] != null &&
          userProfile['communicationStyle'] != 'unknown') {
        buffer.writeln(
            'Communication Style: ${userProfile['communicationStyle']}');
      }

      if (keyTopics.isNotEmpty) {
        buffer.writeln('Primary Interests: ${keyTopics.take(5).join(', ')}');
      }

      final commonChallenges =
          golfPatterns['commonChallenges'] as List<dynamic>? ?? [];
      if (commonChallenges.isNotEmpty) {
        buffer.writeln('Known Challenges: ${commonChallenges.join(', ')}');
      }

      final strengthAreas =
          golfPatterns['strengthAreas'] as List<dynamic>? ?? [];
      if (strengthAreas.isNotEmpty) {
        buffer.writeln('Strength Areas: ${strengthAreas.join(', ')}');
      }

      final mentalFocus =
          mentalPatterns['mentalGameFocus'] as List<dynamic>? ?? [];
      if (mentalFocus.isNotEmpty) {
        buffer.writeln('Mental Game Focus: ${mentalFocus.join(', ')}');
      }

      if (totalInteractions > 0) {
        buffer.writeln(
            'Coaching History: $totalInteractions previous interactions');
      }

      if (engagementScore > 0.7) {
        buffer.writeln('Engagement Level: High - user is actively engaged');
      } else if (engagementScore > 0.4) {
        buffer.writeln(
            'Engagement Level: Moderate - encourage deeper exploration');
      } else if (engagementScore > 0.0) {
        buffer.writeln('Engagement Level: Low - focus on building rapport');
      }

      // Add personality-based coaching adjustments
      if (personalityTraits.isNotEmpty) {
        final openness = personalityTraits['openness'] as double? ?? 0.5;
        final conscientiousness =
            personalityTraits['conscientiousness'] as double? ?? 0.5;
        final neuroticism = personalityTraits['neuroticism'] as double? ?? 0.5;

        if (openness > 0.7) {
          buffer.writeln(
              'Coaching Note: User is open to new techniques - introduce advanced concepts');
        } else if (openness < 0.3) {
          buffer.writeln(
              'Coaching Note: User prefers familiar approaches - build on existing knowledge');
        }

        if (conscientiousness > 0.7) {
          buffer.writeln(
              'Coaching Note: User is disciplined - provide structured practice plans');
        }

        if (neuroticism > 0.6) {
          buffer.writeln(
              'Coaching Note: User may experience anxiety - focus on calming techniques');
        }
      }

      buffer.writeln('--- END PROFILE ---\n');
    }

    // Add interaction type context
    if (interactionType == 'thinkingMode') {
      buffer.writeln(
          'Mode: Deep analysis - provide detailed, step-by-step guidance.');
    } else {
      buffer.writeln(
          'Mode: Quick coaching - provide concise, actionable advice (2-4 sentences).');
    }

    // Add VARK preferences
    if (varkPreferences != null) {
      if (varkPreferences.visual) {
        buffer.writeln(
            'Learning Style: Visual - use imagery, visualization, and descriptive language.');
      }
      if (varkPreferences.aural) {
        buffer.writeln(
            'Learning Style: Auditory - use verbal cues, rhythmic patterns, and sound-based techniques.');
      }
      if (varkPreferences.readWrite) {
        buffer.writeln(
            'Learning Style: Read/Write - provide structured lists, steps, and written exercises.');
      }
      if (varkPreferences.kinesthetic) {
        buffer.writeln(
            'Learning Style: Kinesthetic - focus on physical sensations, movement, and hands-on practice.');
      }
    }

    return buffer.toString();
  }

  /// Build full prompt with context
  String _buildFullPrompt({
    required String systemPrompt,
    required String userMessage,
    String? conversationContext,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(systemPrompt);
    buffer.writeln();

    if (conversationContext != null && conversationContext.isNotEmpty) {
      buffer.writeln('Recent conversation context:');
      buffer.writeln(conversationContext);
      buffer.writeln();
    }

    buffer.writeln('Golfer: $userMessage');
    buffer.writeln();
    buffer.writeln('Coach:');

    return buffer.toString();
  }

  /// Clean AI response
  String _cleanResponse(String response) {
    // Remove any unwanted prefixes or formatting
    return response
        .replaceAll(RegExp(r'^(Coach:|AI:|Assistant:)\s*'), '')
        .trim();
  }

  /// Generate intelligent fallback response with user context
  String _generateFallbackResponse(
      String userMessage, VarkPreferencesStruct? varkPreferences,
      [Map<String, dynamic>? userInsights]) {
    final inputLower = userMessage.toLowerCase();

    // Golf psychology responses based on common themes
    if (inputLower.contains('nervous') ||
        inputLower.contains('pressure') ||
        inputLower.contains('anxiety')) {
      return _adaptToVARK(
        'Pressure is a privilege - it means you care about your performance. Take three deep breaths, visualize your successful shot, and trust your preparation. What specific situation is making you feel nervous?',
        varkPreferences,
      );
    }

    if (inputLower.contains('focus') ||
        inputLower.contains('concentration') ||
        inputLower.contains('distracted')) {
      return _adaptToVARK(
        'Focus is like a muscle that needs training. Try the 4-7-8 breathing technique: inhale for 4, hold for 7, exhale for 8. This centers your mind and improves concentration. What\'s been distracting you most?',
        varkPreferences,
      );
    }

    if (inputLower.contains('confidence') ||
        inputLower.contains('doubt') ||
        inputLower.contains('believe')) {
      return _adaptToVARK(
        'Confidence comes from preparation and positive self-talk. Remember your best shots and the feeling of success. Create a pre-shot routine that builds confidence. What aspect of your game feels strongest right now?',
        varkPreferences,
      );
    }

    if (inputLower.contains('bad shot') ||
        inputLower.contains('mistake') ||
        inputLower.contains('error')) {
      return _adaptToVARK(
        'Every golfer faces setbacks - it\'s how quickly you bounce back that matters. Reset with a deep breath, learn from the shot, then focus on the next one. What can this shot teach you?',
        varkPreferences,
      );
    }

    if (inputLower.contains('routine') ||
        inputLower.contains('preparation') ||
        inputLower.contains('pre-shot')) {
      return _adaptToVARK(
        'A consistent pre-shot routine is your anchor in pressure situations. Develop a 30-second routine and stick to it every time. Consistency breeds confidence. What does your current routine look like?',
        varkPreferences,
      );
    }

    // Personalized default response based on user history
    String defaultResponse =
        'I\'m here to help you develop your mental game and unlock your potential on the course.';

    if (userInsights != null) {
      final keyTopics = userInsights['keyTopics'] as List<dynamic>? ?? [];
      final totalInteractions = userInsights['totalInteractions'] as int? ?? 0;

      if (totalInteractions > 0) {
        defaultResponse =
            'Welcome back! I remember our previous conversations about your mental game.';

        if (keyTopics.isNotEmpty) {
          final topTopic = keyTopics.first as String;
          defaultResponse += ' Last time we discussed $topTopic.';
        }

        defaultResponse += ' What would you like to work on today?';
      } else {
        defaultResponse +=
            ' What specific aspect of your golf psychology would you like to work on today?';
      }
    } else {
      defaultResponse +=
          ' What specific aspect of your golf psychology would you like to work on today?';
    }

    return _adaptToVARK(defaultResponse, varkPreferences);
  }

  /// Adapt response to VARK learning preferences
  String _adaptToVARK(
      String baseResponse, VarkPreferencesStruct? varkPreferences) {
    if (varkPreferences == null) return baseResponse;

    if (varkPreferences.visual) {
      return baseResponse
          .replaceAll('Try', 'Visualize')
          .replaceAll('think', 'picture');
    }

    if (varkPreferences.aural) {
      return '$baseResponse Listen to your inner voice and trust what it tells you.';
    }

    if (varkPreferences.readWrite) {
      return '$baseResponse Consider writing down your thoughts or keeping a mental game journal.';
    }

    if (varkPreferences.kinesthetic) {
      return baseResponse
          .replaceAll('think', 'feel')
          .replaceAll('visualize', 'experience');
    }

    return baseResponse;
  }

  /// Generate error response
  String _generateErrorResponse() {
    return 'I\'m experiencing some technical difficulties right now. Please try again in a moment, or feel free to continue our conversation - I\'m here to help with your mental game!';
  }

  /// Dispose of resources
  void dispose() {
    _statusController.close();
    _tts?.stop();
  }
}
