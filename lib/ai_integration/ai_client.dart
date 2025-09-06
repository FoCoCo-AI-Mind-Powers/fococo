import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/golf_rounds_record.dart';
import 'package:fo_co_co/backend/schema/mental_sessions_record.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import 'package:fo_co_co/backend/schema/user_record.dart';
import 'package:http/http.dart' as http;

import '/flutter_flow/flutter_flow_util.dart';
import 'models/ai_models.dart';
import 'config/ai_config.dart';

/// Main OpenAI client for handling API communications
class AIClient {
  AIClient._();

  static AIClient? _instance;
  static AIClient get instance => _instance ??= AIClient._();

  final String _baseUrl = 'https://api.openai.com/v1';
  final http.Client _httpClient = http.Client();

  /// Generate AI insights for golf performance
  Future<AIInsightResponse> generateGolfInsight({
    required String userId,
    required GolfRoundsRecord golfRound,
    UserRecord? userProfile,
    List<GolfRoundsRecord>? historicalRounds,
    List<MentalSessionsRecord>? mentalSessions,
  }) async {
    try {
      final prompt = _buildGolfInsightPrompt(
        golfRound: golfRound,
        userProfile: userProfile,
        historicalRounds: historicalRounds ?? [],
        mentalSessions: mentalSessions ?? [],
      );

      final response = await _makeOpenAIRequest(
        endpoint: '/chat/completions',
        requestData: {
          'model': AIConfig.insightModel,
          'messages': [
            {
              'role': 'system',
              'content': AIConfig.golfInsightSystemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': AIConfig.maxTokensInsight,
          'temperature': AIConfig.temperatureInsight,
          'response_format': {'type': 'json_object'},
        },
      );

      return AIInsightResponse.fromOpenAIResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating golf insight: $e');
      }
      rethrow;
    }
  }

  /// Generate personalized mental coaching recommendations
  Future<AIRecommendationResponse> generateMentalCoachingRecommendations({
    required String userId,
    required UserRecord userProfile,
    List<MentalSessionsRecord>? recentSessions,
    List<GolfRoundsRecord>? recentRounds,
  }) async {
    try {
      final prompt = _buildMentalCoachingPrompt(
        userProfile: userProfile,
        recentSessions: recentSessions ?? [],
        recentRounds: recentRounds ?? [],
      );

      final response = await _makeOpenAIRequest(
        endpoint: '/chat/completions',
        requestData: {
          'model': AIConfig.recommendationModel,
          'messages': [
            {
              'role': 'system',
              'content': AIConfig.mentalCoachingSystemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': AIConfig.maxTokensRecommendation,
          'temperature': AIConfig.temperatureRecommendation,
          'response_format': {'type': 'json_object'},
        },
      );

      return AIRecommendationResponse.fromOpenAIResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating mental coaching recommendations: $e');
      }
      rethrow;
    }
  }

  /// Generate personalized content based on VARK preferences
  Future<AIContentResponse> generatePersonalizedContent({
    required String userId,
    required VarkPreferencesStruct varkPreferences,
    required String contentType,
    required String topic,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final prompt = _buildPersonalizedContentPrompt(
        varkPreferences: varkPreferences,
        contentType: contentType,
        topic: topic,
        additionalContext: additionalContext ?? {},
      );

      final response = await _makeOpenAIRequest(
        endpoint: '/chat/completions',
        requestData: {
          'model': AIConfig.contentModel,
          'messages': [
            {
              'role': 'system',
              'content': AIConfig.personalizedContentSystemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': AIConfig.maxTokensContent,
          'temperature': AIConfig.temperatureContent,
          'response_format': {'type': 'json_object'},
        },
      );

      return AIContentResponse.fromOpenAIResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating personalized content: $e');
      }
      rethrow;
    }
  }

  /// Generate session feedback for mental coaching
  Future<AIFeedbackResponse> generateSessionFeedback({
    required String userId,
    required MentalSessionsRecord session,
    UserRecord? userProfile,
  }) async {
    try {
      final prompt = _buildSessionFeedbackPrompt(
        session: session,
        userProfile: userProfile,
      );

      final response = await _makeOpenAIRequest(
        endpoint: '/chat/completions',
        requestData: {
          'model': AIConfig.feedbackModel,
          'messages': [
            {
              'role': 'system',
              'content': AIConfig.sessionFeedbackSystemPrompt,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': AIConfig.maxTokensFeedback,
          'temperature': AIConfig.temperatureFeedback,
          'response_format': {'type': 'json_object'},
        },
      );

      return AIFeedbackResponse.fromOpenAIResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating session feedback: $e');
      }
      rethrow;
    }
  }

  /// Make authenticated request to OpenAI API
  Future<Map<String, dynamic>> _makeOpenAIRequest({
    required String endpoint,
    required Map<String, dynamic> requestData,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AIConfig.openAIApiKey}',
      if (AIConfig.organizationId != null)
        'OpenAI-Organization': AIConfig.organizationId!,
    };

    if (kDebugMode) {
      print('🤖 Making OpenAI request to: $endpoint');
      print('📊 Request data: ${jsonEncode(requestData)}');
    }

    final response = await _httpClient.post(
      url,
      headers: headers,
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (kDebugMode) {
        print('✅ OpenAI response successful');
        print('💰 Usage: ${responseData['usage']}');
      }

      return responseData;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMessage =
          errorData['error']?['message'] ?? 'Unknown OpenAI API error';

      if (kDebugMode) {
        print('❌ OpenAI API error: ${response.statusCode}');
        print('📝 Error details: $errorMessage');
      }

      throw AIException(
        message: errorMessage,
        statusCode: response.statusCode,
        errorType: errorData['error']?['type'] ?? 'api_error',
      );
    }
  }

  /// Build golf insight generation prompt
  String _buildGolfInsightPrompt({
    required GolfRoundsRecord golfRound,
    UserRecord? userProfile,
    required List<GolfRoundsRecord> historicalRounds,
    required List<MentalSessionsRecord> mentalSessions,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Generate a comprehensive golf performance insight based on the following data:');
    buffer.writeln();

    // Current round data
    buffer.writeln('CURRENT ROUND:');
    buffer.writeln('Course: ${golfRound.courseName}');
    buffer.writeln('Date: ${golfRound.date}');
    buffer.writeln('Score: ${golfRound.score} (Par: ${golfRound.parTotal})');
    buffer.writeln('Mental Focus: ${golfRound.mentalFocus}/10');
    buffer.writeln('Course Management: ${golfRound.courseManagement}/10');
    buffer.writeln('Emotional Control: ${golfRound.emotionalControl}/10');
    buffer.writeln('Pre-round Mood: ${golfRound.preRoundMood}');
    buffer.writeln('Post-round Mood: ${golfRound.postRoundMood}');
    buffer.writeln();

    // User profile context
    if (userProfile != null) {
      buffer.writeln('PLAYER PROFILE:');
      buffer.writeln('Handicap: ${userProfile.handicap}');
      buffer.writeln('Experience: ${userProfile.golfExperience}');
      buffer.writeln(
          'Mental Performance Score: ${userProfile.mentalPerformanceScore}');
      buffer.writeln('Coaching Streak: ${userProfile.coachingStreak} days');
      buffer.writeln();
    }

    // Historical context
    if (historicalRounds.isNotEmpty) {
      buffer.writeln('RECENT PERFORMANCE TRENDS:');
      for (final round in historicalRounds.take(5)) {
        buffer.writeln(
            '${round.date}: Score ${round.score}, Mental Focus ${round.mentalFocus}/10');
      }
      buffer.writeln();
    }

    // Mental coaching context
    if (mentalSessions.isNotEmpty) {
      buffer.writeln('RECENT MENTAL COACHING:');
      for (final session in mentalSessions.take(3)) {
        buffer.writeln(
            '${session.dateCompleted}: ${session.moduleTitle} - Value: ${session.perceivedValue}/10');
      }
      buffer.writeln();
    }

    buffer.writeln(
        'Please provide actionable insights focusing on mental performance and areas for improvement.');

    return buffer.toString();
  }

  /// Build mental coaching recommendation prompt
  String _buildMentalCoachingPrompt({
    required UserRecord userProfile,
    required List<MentalSessionsRecord> recentSessions,
    required List<GolfRoundsRecord> recentRounds,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Generate personalized mental coaching recommendations for this golfer:');
    buffer.writeln();

    buffer.writeln('PLAYER PROFILE:');
    buffer.writeln('Handicap: ${userProfile.handicap}');
    buffer.writeln('Experience: ${userProfile.golfExperience}');
    buffer.writeln(
        'Mental Performance Score: ${userProfile.mentalPerformanceScore}');
    buffer.writeln('Coaching Streak: ${userProfile.coachingStreak} days');
    buffer.writeln(
        'VARK Preferences: Visual=${userProfile.varkPreferences.visual}, Aural=${userProfile.varkPreferences.aural}, Read/Write=${userProfile.varkPreferences.readWrite}, Kinesthetic=${userProfile.varkPreferences.kinesthetic}');
    buffer.writeln();

    if (recentSessions.isNotEmpty) {
      buffer.writeln('RECENT COACHING SESSIONS:');
      for (final session in recentSessions) {
        buffer.writeln(
            '${session.moduleTitle}: Completion ${session.progressPercentage}%, Value ${session.perceivedValue}/10');
      }
      buffer.writeln();
    }

    if (recentRounds.isNotEmpty) {
      buffer.writeln('RECENT PERFORMANCE:');
      for (final round in recentRounds) {
        buffer.writeln(
            'Score: ${round.score}, Mental Focus: ${round.mentalFocus}/10, Emotional Control: ${round.emotionalControl}/10');
      }
      buffer.writeln();
    }

    buffer.writeln(
        'Recommend specific mental coaching modules and strategies based on their needs and learning preferences.');

    return buffer.toString();
  }

  /// Build personalized content prompt
  String _buildPersonalizedContentPrompt({
    required VarkPreferencesStruct varkPreferences,
    required String contentType,
    required String topic,
    required Map<String, dynamic> additionalContext,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Generate personalized $contentType content about $topic based on these learning preferences:');
    buffer.writeln();

    buffer.writeln('LEARNING PREFERENCES (VARK):');
    buffer.writeln(
        'Visual: ${varkPreferences.visual ? "Preferred" : "Not preferred"}');
    buffer.writeln(
        'Aural: ${varkPreferences.aural ? "Preferred" : "Not preferred"}');
    buffer.writeln(
        'Read/Write: ${varkPreferences.readWrite ? "Preferred" : "Not preferred"}');
    buffer.writeln(
        'Kinesthetic: ${varkPreferences.kinesthetic ? "Preferred" : "Not preferred"}');
    buffer.writeln();

    if (additionalContext.isNotEmpty) {
      buffer.writeln('ADDITIONAL CONTEXT:');
      additionalContext.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
      buffer.writeln();
    }

    buffer.writeln(
        'Create content that aligns with their learning style preferences for maximum effectiveness.');

    return buffer.toString();
  }

  /// Build session feedback prompt
  String _buildSessionFeedbackPrompt({
    required MentalSessionsRecord session,
    UserRecord? userProfile,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Provide personalized feedback for this mental coaching session:');
    buffer.writeln();

    buffer.writeln('SESSION DETAILS:');
    buffer.writeln('Module: ${session.moduleTitle}');
    buffer.writeln('Duration: ${session.duration} minutes');
    buffer.writeln('Completion: ${session.progressPercentage}%');
    buffer.writeln('Mood Before: ${session.userMoodBefore}');
    buffer.writeln('Mood After: ${session.userMoodAfter}');
    buffer.writeln('Perceived Value: ${session.perceivedValue}/10');
    buffer.writeln('Journal Entry: ${session.journalEntry}');
    buffer.writeln();

    if (userProfile != null) {
      buffer.writeln('PLAYER CONTEXT:');
      buffer.writeln('Experience: ${userProfile.golfExperience}');
      buffer.writeln('Current Streak: ${userProfile.coachingStreak} days');
      buffer.writeln();
    }

    buffer.writeln(
        'Provide encouraging, constructive feedback and suggestions for continued improvement.');

    return buffer.toString();
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exception for AI-related errors
class AIException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  const AIException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  @override
  String toString() =>
      'AIException: $message (Status: $statusCode, Type: $errorType)';
}
