import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Configuration class for Firebase AI Logic with Gemini integration
class GeminiConfig {
  GeminiConfig._();

  // ============================================================================
  // FIREBASE AI LOGIC CONFIGURATION
  // ============================================================================
  
  /// Default Gemini model for general tasks (Gemini 2.5 Flash)
  static const String defaultModel = 'gemini-3-flash-preview';
  
  /// Gemini model for complex analysis and insights
  static const String insightModel = 'gemini-3-flash-preview';
  
  /// Gemini model for coaching recommendations
  static const String coachingModel = 'gemini-3-flash-preview';
  
  /// Gemini model for content generation
  static const String contentModel = 'gemini-3-flash-preview';
  
  /// Gemini model for session feedback
  static const String feedbackModel = 'gemini-3-flash-preview';
  
  /// Voice AI models
  static const String voiceFlashLiteModel = 'gemini-2.5-flash-lite';
  static const String voiceLiveModel = 'models/gemini-live-2.5-flash-preview';
  static const String voiceNativeAudioModel = 'models/gemini-2.5-flash-preview-native-audio-dialog';
  static const String voiceThinkingModel = 'models/gemini-2.5-flash-exp-native-audio-thinking-dialog';
  static const String voiceTTSFlashModel = 'models/gemini-2.5-flash-preview-tts';
  static const String voiceTTSProModel = 'models/gemini-2.5-pro-preview-tts';

  // ============================================================================
  // MODEL CREATION
  // ============================================================================

  /// Create a Gemini model instance using Firebase AI Logic
  static GenerativeModel createModel({
    required String modelName,
    GenerationConfig? generationConfig,
    List<SafetySetting>? safetySettings,
    String? systemInstruction,
  }) {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      systemInstruction: systemInstruction != null 
        ? Content.text(systemInstruction) 
        : null,
    );
    
    return model;
  }

  // ============================================================================
  // GENERATION CONFIGURATIONS
  // ============================================================================

  /// Default generation configuration for insights
  static GenerationConfig get insightGenerationConfig => GenerationConfig(
    temperature: 0.7,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 2048,
    responseMimeType: 'application/json',
  );

  /// Generation configuration for coaching recommendations
  static GenerationConfig get coachingGenerationConfig => GenerationConfig(
    temperature: 0.8,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 3072,
    responseMimeType: 'application/json',
  );

  /// Generation configuration for content creation
  static GenerationConfig get contentGenerationConfig => GenerationConfig(
    temperature: 0.9,
    topK: 50,
    topP: 0.95,
    maxOutputTokens: 4096,
    responseMimeType: 'application/json',
  );

  /// Generation configuration for feedback
  static GenerationConfig get feedbackGenerationConfig => GenerationConfig(
    temperature: 0.6,
    topK: 30,
    topP: 0.9,
    maxOutputTokens: 2048,
    responseMimeType: 'application/json',
  );

  /// Generation configuration for conversations
  static GenerationConfig get conversationGenerationConfig => GenerationConfig(
    temperature: 0.8,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 1024,
    responseMimeType: 'text/plain',
  );

  // ============================================================================
  // SAFETY SETTINGS
  // ============================================================================

  /// Default safety settings for content generation
  static List<SafetySetting> get defaultSafetySettings => [
    // TODO: Fix SafetySetting constructor once we understand the firebase_ai API
    // SafetySetting(
    //   category: HarmCategory.harassment,
    //   threshold: HarmBlockThreshold.medium,
    // ),
    // SafetySetting(
    //   category: HarmCategory.hateSpeech,
    //   threshold: HarmBlockThreshold.medium,
    // ),
    // SafetySetting(
    //   category: HarmCategory.sexuallyExplicit,
    //   threshold: HarmBlockThreshold.medium,
    // ),
    // SafetySetting(
    //   category: HarmCategory.dangerousContent,
    //   threshold: HarmBlockThreshold.medium,
    // ),
  ];

  // ============================================================================
  // SYSTEM PROMPTS
  // ============================================================================

  /// System prompt for golf insight generation
  static String get golfInsightSystemPrompt => '''
You are an expert golf mental performance coach specialized in the FoCoCo (Focus-Confidence-Control) methodology. 

FoCoCo Core Principles:
- FOCUS: Present-moment awareness, routine consistency, target clarity
- CONFIDENCE: Self-belief, positive visualization, past success recall
- CONTROL: Emotional regulation, breathing techniques, pre-shot routines

Analyze golf performance data and provide insights in the following JSON format:
{
  "insightTitle": "Clear, actionable title",
  "category": "mental_game|technique|course_management|scoring",
  "priority": "high|medium|low",
  "keyPoints": ["Key insight 1", "Key insight 2", "Key insight 3"],
  "recommendations": [
    {
      "action": "Specific action to take",
      "priority": "high|medium|low",
      "category": "focus|confidence|control",
      "estimatedImpact": "Description of expected improvement",
      "timeframe": "immediate|1_week|1_month|ongoing"
    }
  ],
  "personalizedElements": ["Tailored advice based on user data"],
  "summaryText": "Comprehensive summary of the analysis",
  "sentimentAnalysis": {
    "overallSentiment": "positive|neutral|negative|mixed",
    "confidenceLevel": 0.85,
    "emotionalIndicators": ["confidence", "frustration", "determination"],
    "moodProgression": "Description of emotional journey"
  },
  "contextualFactors": ["Weather impact", "Course difficulty", "etc"],
  "followUpQuestions": ["Questions to ask user for more insights"]
}

Focus on mental game improvements that align with FoCoCo principles.
''';

  /// System prompt for mental coaching recommendations
  static String get mentalCoachingSystemPrompt => '''
You are a certified golf mental performance coach specializing in the FoCoCo methodology.

FoCoCo Framework:
- FOCUS: Concentration, attention control, present-moment awareness
- CONFIDENCE: Self-efficacy, positive mindset, success visualization
- CONTROL: Emotional regulation, stress management, routine execution

Provide coaching recommendations in this JSON format:
{
  "recommendationType": "daily_practice|weekly_plan|specific_issue|general_improvement",
  "primaryFocus": "focus|confidence|control|combined",
  "userTier": "BASE|PLUS|PRIME",
  "varkAdaptation": {
    "primaryStyle": "visual|auditory|reading|kinesthetic",
    "secondaryStyle": "visual|auditory|reading|kinesthetic",
    "adaptationStrategies": ["Strategy 1", "Strategy 2"]
  },
  "recommendations": [
    {
      "moduleId": "unique_module_id",
      "moduleTitle": "Module Title",
      "priority": "high|medium|low",
      "estimatedDuration": 15,
      "learningStyle": "visual|auditory|reading|kinesthetic",
      "description": "Detailed description",
      "expectedOutcome": "What user will achieve",
      "prerequisites": ["Required prior knowledge"],
      "difficulty": "beginner|intermediate|advanced"
    }
  ],
  "weeklyPlan": {
    "totalDuration": 120,
    "sessionsPerWeek": 3,
    "focusAreas": ["Primary area 1", "Primary area 2"],
    "progressMilestones": ["Milestone 1", "Milestone 2"]
  },
  "motivationalMessage": "Encouraging, personalized message",
  "contextualInsights": ["Insight 1", "Insight 2"],
  "adaptiveStrategies": [
    {
      "strategy": "Specific strategy",
      "varkAlignment": "visual|auditory|reading|kinesthetic",
      "rationale": "Why this strategy works for the user"
    }
  ]
}

Adapt all content to the user's VARK learning preferences and subscription tier.
''';

  /// System prompt for personalized content generation
  static String get personalizedContentSystemPrompt => '''
You are an expert instructional designer specializing in golf mental performance using the FoCoCo methodology.

Create personalized learning content adapted to VARK learning styles:
- VISUAL: Charts, diagrams, imagery, color-coding
- AUDITORY: Spoken instructions, music, rhythm, discussions
- READING/WRITING: Text, lists, note-taking, written exercises
- KINESTHETIC: Hands-on practice, movement, physical exercises

Generate content in this JSON format:
{
  "contentType": "module|exercise|assessment|guide",
  "title": "Engaging, clear title",
  "adaptedFor": ["visual", "kinesthetic"],
  "duration": 20,
  "difficulty": "beginner|intermediate|advanced",
  "sections": [
    {
      "sectionTitle": "Section Title",
      "content": "Main content text",
      "varkElements": {
        "visual": "Visual elements description",
        "auditory": "Audio elements description",
        "reading": "Text/reading elements",
        "kinesthetic": "Physical/interactive elements"
      },
      "interactiveElements": [
        {
          "type": "visualization|breathing|movement|reflection",
          "content": "Element description",
          "expectedResponse": "What user should do/feel"
        }
      ]
    }
  ],
  "takeaways": ["Key learning 1", "Key learning 2"],
  "practiceExercises": [
    {
      "exercise": "Exercise description",
      "varkStyle": "primary_style_focus",
      "duration": 5,
      "difficulty": "beginner|intermediate|advanced"
    }
  ],
  "assessmentCriteria": ["Success indicator 1", "Success indicator 2"],
  "followUpContent": ["Related content suggestions"]
}

Ensure all content aligns with FoCoCo principles and user's learning preferences.
''';

  /// System prompt for session feedback
  static String get sessionFeedbackSystemPrompt => '''
You are a supportive golf mental performance coach providing session feedback using FoCoCo methodology.

Analyze session data and provide constructive feedback in this JSON format:
{
  "feedbackType": "progress|completion|encouragement|correction",
  "overallAssessment": "Comprehensive session evaluation",
  "strengths": ["Strength 1", "Strength 2"],
  "improvements": ["Area for improvement 1", "Area for improvement 2"],
  "sentimentAnalysis": {
    "overallSentiment": "positive|neutral|negative|mixed",
    "confidenceLevel": 0.85,
    "emotionalIndicators": ["engagement", "frustration", "breakthrough"],
    "moodProgression": "How user's mood evolved during session"
  },
  "nextSteps": [
    {
      "action": "Specific next action",
      "timeframe": "immediate|this_week|next_session|ongoing",
      "difficulty": "easy|medium|challenging",
      "priority": "high|medium|low",
      "expectedOutcome": "What this will achieve"
    }
  ],
  "motivationalMessage": "Encouraging, personalized message",
  "progressInsights": "How this session fits into overall progress",
  "recommendedFocus": "focus|confidence|control|maintenance",
  "adaptiveRecommendations": [
    {
      "recommendation": "Specific recommendation",
      "varkAlignment": "visual|auditory|reading|kinesthetic",
      "rationale": "Why this works for the user"
    }
  ],
  "sessionPatterns": ["Pattern 1", "Pattern 2"]
}

Be encouraging, specific, and focused on FoCoCo principle development.
''';

  // ============================================================================
  // VALIDATION AND UTILITIES
  // ============================================================================

  /// Validate configuration settings
  static bool validateConfiguration() {
    try {
      // Check if Firebase is initialized (this should be done in main.dart)
      // Validate model names
      final models = [defaultModel, insightModel, coachingModel, contentModel, feedbackModel];
      for (final model in models) {
        if (model.isEmpty) return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gemini configuration validation failed: $e');
      }
      return false;
    }
  }

  /// Estimate token count for text (rough approximation)
  static int estimateTokenCount(String text) {
    // Rough approximation: 1 token ≈ 4 characters for English text
    return (text.length / 4).ceil();
  }

  /// Estimate cost for API call
  static double estimateCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    // Firebase AI Logic pricing (update with actual rates)
    const double inputTokenCost = 0.000001; // $0.000001 per input token
    const double outputTokenCost = 0.000002; // $0.000002 per output token
    
    return (inputTokens * inputTokenCost) + (outputTokens * outputTokenCost);
  }

  /// Get model capabilities
  static Map<String, dynamic> getModelCapabilities(String modelName) {
    switch (modelName) {
      case 'gemini-2.5-flash':
        return {
          'textGeneration': true,
          'audioGeneration': false, // Not yet supported in Firebase AI Logic
          'imageGeneration': false,
          'maxInputTokens': 1000000,
          'maxOutputTokens': 8192,
          'multimodal': true,
        };
      default:
        return {
          'textGeneration': true,
          'audioGeneration': false,
          'imageGeneration': false,
          'maxInputTokens': 32000,
          'maxOutputTokens': 4096,
          'multimodal': false,
        };
    }
  }

  /// Create JSON schema for structured output
  static Map<String, dynamic> createJsonSchema(String schemaType) {
    switch (schemaType) {
      case 'insight':
        return {
          'type': 'object',
          'properties': {
            'insightTitle': {'type': 'string'},
            'category': {'type': 'string', 'enum': ['mental_game', 'technique', 'course_management', 'scoring']},
            'priority': {'type': 'string', 'enum': ['high', 'medium', 'low']},
            'keyPoints': {'type': 'array', 'items': {'type': 'string'}},
            'recommendations': {'type': 'array'},
            'personalizedElements': {'type': 'array', 'items': {'type': 'string'}},
            'summaryText': {'type': 'string'},
            'sentimentAnalysis': {'type': 'object'},
            'contextualFactors': {'type': 'array', 'items': {'type': 'string'}},
            'followUpQuestions': {'type': 'array', 'items': {'type': 'string'}}
          },
          'required': ['insightTitle', 'category', 'priority', 'keyPoints', 'summaryText']
        };
      case 'coaching':
        return {
          'type': 'object',
          'properties': {
            'recommendationType': {'type': 'string'},
            'primaryFocus': {'type': 'string'},
            'userTier': {'type': 'string'},
            'recommendations': {'type': 'array'},
            'motivationalMessage': {'type': 'string'}
          },
          'required': ['recommendationType', 'primaryFocus', 'userTier', 'recommendations']
        };
      case 'content':
        return {
          'type': 'object',
          'properties': {
            'contentType': {'type': 'string'},
            'title': {'type': 'string'},
            'adaptedFor': {'type': 'array', 'items': {'type': 'string'}},
            'duration': {'type': 'number'},
            'difficulty': {'type': 'string'},
            'sections': {'type': 'array'},
            'takeaways': {'type': 'array', 'items': {'type': 'string'}}
          },
          'required': ['contentType', 'title', 'adaptedFor', 'duration', 'sections']
        };
      case 'feedback':
        return {
          'type': 'object',
          'properties': {
            'feedbackType': {'type': 'string'},
            'overallAssessment': {'type': 'string'},
            'strengths': {'type': 'array', 'items': {'type': 'string'}},
            'improvements': {'type': 'array', 'items': {'type': 'string'}},
            'motivationalMessage': {'type': 'string'}
          },
          'required': ['feedbackType', 'overallAssessment', 'strengths', 'improvements']
        };
      default:
        return {'type': 'object'};
    }
  }
} 