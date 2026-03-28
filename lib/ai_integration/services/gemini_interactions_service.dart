import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '/ai_integration/config/gemini_live_config.dart';

/// Gemini Interactions API Service
/// Uses the new Interactions API (Beta) for stateful conversations
/// Documentation: https://ai.google.dev/gemini-api/docs/interactions
class GeminiInteractionsService {
  static final GeminiInteractionsService _instance =
      GeminiInteractionsService._internal();
  factory GeminiInteractionsService() => _instance;
  GeminiInteractionsService._internal();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/interactions';
  static const String _model = 'gemini-3-flash-preview';

  /// Get API key from Secret Manager / cache / dart-define
  Future<String> get _apiKey => GeminiLiveAPIConfig.getApiKey();

  /// Create a new interaction
  /// Returns the interaction ID and outputs
  Future<Map<String, dynamic>> createInteraction({
    required String input,
    String? previousInteractionId,
    String? systemInstruction,
    Map<String, dynamic>? tools,
    bool store = true,
    bool stream = false,
  }) async {
    try {
      final apiKey = await _apiKey;
      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not configured');
      }

      final url = Uri.parse('$_baseUrl?key=$apiKey');

      final body = <String, dynamic>{
        'model': _model,
        'input': input,
        'store': store,
        'stream': stream,
      };

      if (previousInteractionId != null) {
        body['previous_interaction_id'] = previousInteractionId;
      }

      if (systemInstruction != null) {
        body['system_instruction'] = systemInstruction;
      }

      if (tools != null) {
        body['tools'] = tools;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'API Error: ${errorBody['error']?['message'] ?? response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating interaction: $e');
      }
      rethrow;
    }
  }

  /// Get interaction by ID
  Future<Map<String, dynamic>> getInteraction(String interactionId) async {
    try {
      final apiKey = await _apiKey;
      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not configured');
      }

      final url = Uri.parse('$_baseUrl/$interactionId?key=$apiKey');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'API Error: ${errorBody['error']?['message'] ?? response.statusCode}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting interaction: $e');
      }
      rethrow;
    }
  }

  /// Generate VARK assessment using Interactions API
  Future<Map<String, dynamic>> generateVarkAssessment({
    required String userId,
    Map<String, dynamic>? userProfile,
    int questionCount = 12,
  }) async {
    try {
      final systemInstruction = '''
You are an expert in learning style assessment, specifically the VARK (Visual, Auditory, Read/Write, Kinesthetic) model for golf mental performance training.

Your task is to generate a comprehensive, engaging VARK assessment that helps golfers discover their optimal learning style for mental performance training.

Generate assessment questions in this EXACT JSON format (use these exact field names):
{
  "assessmentId": "unique_id",
  "title": "VARK Learning Style Assessment for Golf Mental Performance",
  "description": "Discover your optimal learning style",
  "questions": [
    {
      "id": "q1",
      "question": "Question text here",
      "answers": [
        {"id": "a", "text": "Option A", "varkType": "visual"},
        {"id": "b", "text": "Option B", "varkType": "aural"},
        {"id": "c", "text": "Option C", "varkType": "readWrite"},
        {"id": "d", "text": "Option D", "varkType": "kinesthetic"}
      ],
      "category": "general",
      "order": 1
    }
  ]
}

CRITICAL: Use "question" (not "questionText"), "answers" (not "options"), and "id" (not "questionId" or "optionId").

Focus on golf mental performance scenarios. Make questions engaging and personalized.
Return ONLY valid JSON, no markdown formatting or code blocks.
''';

      final prompt = _buildAssessmentPrompt(
        userId: userId,
        userProfile: userProfile,
        questionCount: questionCount,
      );

      final interaction = await createInteraction(
        input: prompt,
        systemInstruction: systemInstruction,
        store: true,
      );

      // Extract outputs from interaction
      final outputs = interaction['outputs'] as List?;
      if (outputs == null || outputs.isEmpty) {
        throw Exception('No outputs in interaction response');
      }

      // Get the last output (most recent response)
      final lastOutput = outputs.last as Map<String, dynamic>;
      final text = lastOutput['text'] as String?;

      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response
      final jsonResponse = _parseJsonResponse(text, userId: userId);

      return {
        ...jsonResponse,
        'interactionId': interaction['id'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating VARK assessment: $e');
      }
      throw Exception('Failed to generate VARK assessment: $e');
    }
  }

  /// Generate AI recommendations using Interactions API
  Future<List<Map<String, dynamic>>> generateRecommendations({
    required String userId,
    required Map<String, dynamic> userContext,
    String? adaptiveMode,
    int count = 5,
  }) async {
    try {
      final systemInstruction = '''
You are an expert golf mental performance coach specializing in the FoCoCo (Focus-Confidence-Control) methodology.

Generate personalized coaching module recommendations based on:
- User's VARK learning style
- Current adaptive mode (Pre-Round, Post-Round, Off-Day, AI-Reactive)
- User progress and history
- Mental performance goals

Return recommendations in this JSON format:
{
  "recommendations": [
    {
      "moduleId": "unique_module_id",
      "moduleTitle": "Module Title",
      "priority": "high|medium|low",
      "estimatedDuration": 15,
      "learningStyle": "visual|auditory|readWrite|kinesthetic",
      "description": "Detailed description",
      "expectedOutcome": "What user will achieve",
      "difficulty": "beginner|intermediate|advanced",
      "pillar": "focus|confidence|control",
      "aiReasoning": "Why this module is recommended for this user"
    }
  ]
}

Return ONLY valid JSON, no markdown formatting or code blocks.
''';

      final prompt = _buildRecommendationsPrompt(
        userId: userId,
        userContext: userContext,
        adaptiveMode: adaptiveMode,
        count: count,
      );

      final interaction = await createInteraction(
        input: prompt,
        systemInstruction: systemInstruction,
        store: true,
      );

      // Extract outputs
      final outputs = interaction['outputs'] as List?;
      if (outputs == null || outputs.isEmpty) {
        throw Exception('No outputs in interaction response');
      }

      final lastOutput = outputs.last as Map<String, dynamic>;
      final text = lastOutput['text'] as String?;

      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response
      final jsonData = jsonDecode(text) as Map<String, dynamic>;
      final recommendations = jsonData['recommendations'] as List?;

      if (recommendations == null) {
        return [];
      }

      return recommendations
          .cast<Map<String, dynamic>>()
          .take(count)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating recommendations: $e');
      }
      return [];
    }
  }

  /// Build assessment prompt
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
      buffer.writeln(jsonEncode(userProfile));
      buffer.writeln();
    }

    buffer.writeln(
        'Generate $questionCount questions that help identify their learning style.');
    buffer.writeln('Focus on golf mental performance scenarios.');
    buffer.writeln('Make it engaging and personalized.');

    return buffer.toString();
  }

  /// Build recommendations prompt
  String _buildRecommendationsPrompt({
    required String userId,
    required Map<String, dynamic> userContext,
    String? adaptiveMode,
    required int count,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Generate $count personalized coaching module recommendations.');
    buffer.writeln();

    buffer.writeln('User Context:');
    buffer.writeln(jsonEncode(userContext));
    buffer.writeln();

    if (adaptiveMode != null) {
      buffer.writeln('Current Adaptive Mode: $adaptiveMode');
      buffer.writeln();
    }

    buffer.writeln(
        'Provide recommendations that align with the user\'s learning style, current mode, and progress.');

    return buffer.toString();
  }

  /// Parse JSON response, handling markdown code blocks and various formats
  Map<String, dynamic> _parseJsonResponse(String responseText, {String? userId}) {
    try {
      // Remove markdown code blocks if present
      String cleanedText = responseText.trim();
      
      // Remove ```json or ``` at start
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      
      // Remove ``` at end
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      
      cleanedText = cleanedText.trim();
      
      // Try to extract JSON from text if it's embedded
      // Look for first { and last }
      final firstBrace = cleanedText.indexOf('{');
      final lastBrace = cleanedText.lastIndexOf('}');
      
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);
      }

      final jsonData = jsonDecode(cleanedText) as Map<String, dynamic>;
      
      if (kDebugMode) {
        print('✅ Successfully parsed JSON response');
        print('   Keys: ${jsonData.keys}');
        if (jsonData['questions'] != null) {
          print('   Questions count: ${(jsonData['questions'] as List?)?.length ?? 0}');
        }
      }
      
      return jsonData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing JSON response: $e');
        print('Response text (first 500 chars): ${responseText.length > 500 ? responseText.substring(0, 500) : responseText}');
      }
      rethrow;
    }
  }
}
