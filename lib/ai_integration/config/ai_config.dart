import 'package:flutter/foundation.dart';

/// Configuration class for AI integration settings
class AIConfig {
  AIConfig._();

  // ============================================================================
  // API CONFIGURATION
  // ============================================================================
  
  /// OpenAI API Key - Should be set via environment variables or secure storage
  static String get openAIApiKey {
    // In production, this should come from secure environment variables
    // For development, you can use a .env file or secure storage
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured. Set OPENAI_API_KEY environment variable.');
    }
    return apiKey;
  }

  /// OpenAI Organization ID (optional)
  static String? get organizationId => const String.fromEnvironment('OPENAI_ORG_ID');

  // ============================================================================
  // MODEL CONFIGURATION
  // ============================================================================
  
  /// Model for golf insight generation
  static const String insightModel = 'gpt-4o-mini';
  
  /// Model for mental coaching recommendations
  static const String recommendationModel = 'gpt-4o-mini';
  
  /// Model for personalized content generation
  static const String contentModel = 'gpt-4o-mini';
  
  /// Model for session feedback
  static const String feedbackModel = 'gpt-4o-mini';

  // ============================================================================
  // TOKEN LIMITS
  // ============================================================================
  
  /// Maximum tokens for insight generation
  static const int maxTokensInsight = 1500;
  
  /// Maximum tokens for recommendation generation
  static const int maxTokensRecommendation = 1200;
  
  /// Maximum tokens for content generation
  static const int maxTokensContent = 1000;
  
  /// Maximum tokens for feedback generation
  static const int maxTokensFeedback = 800;

  // ============================================================================
  // TEMPERATURE SETTINGS
  // ============================================================================
  
  /// Temperature for insight generation (balanced creativity)
  static const double temperatureInsight = 0.7;
  
  /// Temperature for recommendations (focused)
  static const double temperatureRecommendation = 0.6;
  
  /// Temperature for content generation (creative)
  static const double temperatureContent = 0.8;
  
  /// Temperature for feedback (balanced)
  static const double temperatureFeedback = 0.7;

  // ============================================================================
  // SYSTEM PROMPTS
  // ============================================================================
  
  /// System prompt for golf insight generation
  static const String golfInsightSystemPrompt = '''
You are an expert golf mental performance coach and data analyst specializing in helping golfers improve their mental game. Your role is to analyze golf round data and provide actionable insights that focus on mental performance, course management, and emotional control.

Key guidelines:
- Focus on mental aspects: confidence, focus, emotional regulation, and course management
- Provide specific, actionable recommendations
- Use encouraging and constructive language
- Consider the player's experience level and handicap
- Identify patterns and trends in performance data
- Suggest specific mental coaching techniques when appropriate

Response format: Return a JSON object with the following structure:
{
  "insightTitle": "Brief, engaging title for the insight",
  "category": "mental_performance|course_management|emotional_control|technical_analysis",
  "priority": "high|medium|low",
  "keyPoints": ["point1", "point2", "point3"],
  "recommendations": [
    {
      "action": "Specific action to take",
      "priority": "high|medium|low",
      "category": "mental|technical|strategic",
      "relatedModuleId": "suggested_module_id_if_applicable"
    }
  ],
  "personalizedElements": ["element1", "element2"],
  "summaryText": "Comprehensive insight text (2-3 paragraphs)"
}
''';

  /// System prompt for mental coaching recommendations
  static const String mentalCoachingSystemPrompt = '''
You are a certified mental performance coach specializing in golf psychology. Your role is to analyze a golfer's profile, recent performance, and coaching history to recommend personalized mental training modules and strategies.

Key guidelines:
- Consider the player's VARK learning preferences (Visual, Aural, Read/Write, Kinesthetic)
- Recommend specific mental coaching modules based on their needs
- Prioritize recommendations based on current performance gaps
- Account for their coaching streak and motivation levels
- Suggest progressive skill building
- Focus on sustainable mental performance improvement

Response format: Return a JSON object with the following structure:
{
  "recommendationType": "daily|weekly|intensive|maintenance",
  "primaryFocus": "focus|confidence|emotional_control|course_management|pressure_handling",
  "recommendations": [
    {
      "moduleId": "suggested_module_id",
      "moduleTitle": "Module name",
      "priority": "high|medium|low",
      "estimatedDuration": "duration_in_minutes",
      "learningStyle": "visual|aural|readwrite|kinesthetic|mixed",
      "description": "Why this module is recommended"
    }
  ],
  "weeklyPlan": {
    "sessionsPerWeek": 3,
    "totalWeeklyMinutes": 45,
    "focusAreas": ["area1", "area2"]
  },
  "motivationalMessage": "Encouraging message based on their progress"
}
''';

  /// System prompt for personalized content generation
  static const String personalizedContentSystemPrompt = '''
You are an expert educational content creator specializing in golf mental performance coaching. Your role is to create personalized learning content that adapts to individual learning preferences (VARK model) and specific topics.

Key guidelines:
- Adapt content delivery method to VARK preferences:
  * Visual: Use imagery, diagrams, visual metaphors
  * Aural: Include audio elements, discussions, verbal instructions
  * Read/Write: Provide written exercises, lists, note-taking prompts
  * Kinesthetic: Include physical exercises, hands-on activities
- Make content engaging and practical
- Include specific golf scenarios and examples
- Provide actionable techniques and exercises
- Keep content appropriate for the user's experience level

Response format: Return a JSON object with the following structure:
{
  "contentType": "lesson|exercise|visualization|technique",
  "title": "Content title",
  "adaptedFor": ["visual", "aural", "readwrite", "kinesthetic"],
  "duration": "estimated_duration_minutes",
  "sections": [
    {
      "type": "introduction|instruction|exercise|reflection",
      "title": "Section title",
      "content": "Main content text",
      "adaptations": {
        "visual": "Visual-specific instructions or elements",
        "aural": "Audio-specific instructions or elements",
        "readwrite": "Written exercise or note-taking prompts",
        "kinesthetic": "Physical or hands-on activities"
      }
    }
  ],
  "takeaways": ["key_point1", "key_point2", "key_point3"],
  "practiceExercises": ["exercise1", "exercise2"]
}
''';

  /// System prompt for session feedback
  static const String sessionFeedbackSystemPrompt = '''
You are a supportive mental performance coach providing personalized feedback on golf mental coaching sessions. Your role is to encourage progress, identify improvements, and suggest next steps.

Key guidelines:
- Be encouraging and positive while providing constructive feedback
- Acknowledge progress and effort, no matter how small
- Identify specific improvements or insights from the session
- Suggest practical next steps for continued improvement
- Address any concerns or challenges mentioned in the journal entry
- Personalize feedback based on the user's experience level and goals

Response format: Return a JSON object with the following structure:
{
  "feedbackType": "encouragement|progress_recognition|constructive_guidance|motivation",
  "overallAssessment": "excellent|good|satisfactory|needs_improvement",
  "strengths": ["strength1", "strength2"],
  "improvements": ["improvement1", "improvement2"],
  "nextSteps": [
    {
      "action": "Specific action to take",
      "timeframe": "immediate|this_week|next_session",
      "difficulty": "easy|moderate|challenging"
    }
  ],
  "motivationalMessage": "Personal encouraging message",
  "progressInsights": "Observations about their mental performance journey",
  "recommendedFocus": "What to focus on in upcoming sessions"
}
''';

  // ============================================================================
  // COST MANAGEMENT
  // ============================================================================
  
  /// Estimated cost per 1K tokens for GPT-4o-mini (input)
  static const double costPer1KTokensInput = 0.00015;
  
  /// Estimated cost per 1K tokens for GPT-4o-mini (output)
  static const double costPer1KTokensOutput = 0.0006;
  
  /// Calculate estimated cost for a request
  static double calculateEstimatedCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = (inputTokens / 1000) * costPer1KTokensInput;
    final outputCost = (outputTokens / 1000) * costPer1KTokensOutput;
    return inputCost + outputCost;
  }

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================
  
  /// Enable/disable AI insights generation
  static const bool enableAIInsights = true;
  
  /// Enable/disable AI recommendations
  static const bool enableAIRecommendations = true;
  
  /// Enable/disable personalized content generation
  static const bool enablePersonalizedContent = true;
  
  /// Enable/disable session feedback
  static const bool enableSessionFeedback = true;
  
  /// Enable detailed logging in debug mode
  static bool get enableDetailedLogging => kDebugMode;

  // ============================================================================
  // RATE LIMITING
  // ============================================================================
  
  /// Maximum AI requests per user per day
  static const int maxRequestsPerUserPerDay = 50;
  
  /// Maximum AI requests per user per hour
  static const int maxRequestsPerUserPerHour = 10;
  
  /// Cooldown period between requests (in seconds)
  static const int requestCooldownSeconds = 5;

  // ============================================================================
  // VALIDATION
  // ============================================================================
  
  /// Validate AI configuration
  static bool validateConfiguration() {
    try {
      // Check API key
      final apiKey = openAIApiKey;
      if (apiKey.isEmpty || apiKey.length < 20) {
        if (kDebugMode) {
          print('❌ Invalid OpenAI API key configuration');
        }
        return false;
      }
      
      // Check feature flags
      if (!enableAIInsights && !enableAIRecommendations && 
          !enablePersonalizedContent && !enableSessionFeedback) {
        if (kDebugMode) {
          print('⚠️ All AI features are disabled');
        }
      }
      
      if (kDebugMode) {
        print('✅ AI configuration validation passed');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AI configuration validation failed: $e');
      }
      return false;
    }
  }
} 