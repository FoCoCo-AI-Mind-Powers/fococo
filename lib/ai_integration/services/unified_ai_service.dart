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
      await _tts!.setSpeechRate(0.6);
      await _tts!.setPitch(1.0);
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

  /// Generate AI response with fallback mechanisms
  Future<String> generateResponse({
    required String userMessage,
    String? conversationContext,
    VarkPreferencesStruct? varkPreferences,
    String interactionType = 'quickChat',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Build system prompt
      final systemPrompt = _buildSystemPrompt(
        varkPreferences: varkPreferences,
        interactionType: interactionType,
      );

      // Build full prompt with context
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

      // Fallback to hardcoded intelligent responses
      return _generateFallbackResponse(userMessage, varkPreferences);
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

  /// Build system prompt based on FoCoCo methodology
  String _buildSystemPrompt({
    VarkPreferencesStruct? varkPreferences,
    String interactionType = 'quickChat',
  }) {
    final buffer = StringBuffer();

    buffer.writeln('''
You are the FoCoCo AI Mental Performance Coach, specializing in golf psychology and mental training.

Your expertise:
- Mental toughness and confidence building
- Focus, Confidence, and Control (FoCoCo methodology)
- Golf-specific performance psychology
- Practical mindfulness and visualization techniques

Guidelines:
- Be encouraging, supportive, and professional
- Provide specific, actionable advice
- Keep responses conversational and engaging
- Reference golf scenarios when relevant
- Ask follow-up questions to understand better
''');

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

  /// Generate intelligent fallback response
  String _generateFallbackResponse(
      String userMessage, VarkPreferencesStruct? varkPreferences) {
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

    // Default response
    return _adaptToVARK(
      'I\'m here to help you develop your mental game and unlock your potential on the course. What specific aspect of your golf psychology would you like to work on today?',
      varkPreferences,
    );
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
