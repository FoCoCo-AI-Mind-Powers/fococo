import 'package:firebase_ai/firebase_ai.dart';
import 'package:fo_co_co/backend/schema/structs/recommendation_struct.dart';

/// Base class for all Gemini AI response models
abstract class BaseGeminiResponse {
  final DateTime timestamp;
  final String model;
  final int? tokensUsed;
  final String userId;

  const BaseGeminiResponse({
    required this.timestamp,
    required this.model,
    this.tokensUsed,
    required this.userId,
  });

  Map<String, dynamic> toMap();
}

/// Response wrapper for GeminiAIClient.generateGolfInsight()
class GeminiInsightResponse {
  final String insightTitle;
  final String category;
  final String priority;
  final List<String> keyPoints;
  final List<GeminiRecommendation> recommendations;
  final List<String> personalizedElements;
  final String summaryText;
  final GeminiSentimentAnalysis sentimentAnalysis;
  final List<String> contextualFactors;
  final List<String> followUpQuestions;
  final String sourceId;
  final String sourceType;
  final DateTime timestamp;
  final String model;
  final String userId;
  final int tokensUsed;

  GeminiInsightResponse({
    required this.insightTitle,
    required this.category,
    required this.priority,
    required this.keyPoints,
    required this.recommendations,
    required this.personalizedElements,
    required this.summaryText,
    required this.sentimentAnalysis,
    required this.contextualFactors,
    required this.followUpQuestions,
    required this.sourceId,
    required this.sourceType,
    required this.timestamp,
    required this.model,
    required this.userId,
    required this.tokensUsed,
  });

  /// Create from API response
  factory GeminiInsightResponse.fromResponse(
    GenerateContentResponse response,
    String userId,
    String model,
  ) {
    // Parse the response - placeholder implementation
    return GeminiInsightResponse(
      insightTitle: 'Generated Insight',
      category: 'mental_game',
      priority: 'medium',
      keyPoints: ['Generated insight point'],
      recommendations: [],
      personalizedElements: ['Personalized for user'],
      summaryText: 'Generated summary',
      sentimentAnalysis: GeminiSentimentAnalysis(
        overallSentiment: 'positive',
        confidenceLevel: 0.8,
        emotionalIndicators: ['confidence'],
        moodProgression: 'improving',
      ),
      contextualFactors: [],
      followUpQuestions: [],
      sourceId: 'api_generated',
      sourceType: 'golf_round',
      timestamp: DateTime.now(),
      model: model,
      userId: userId,
      tokensUsed: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'insightTitle': insightTitle,
      'category': category,
      'priority': priority,
      'keyPoints': keyPoints,
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'personalizedElements': personalizedElements,
      'summaryText': summaryText,
      'sentimentAnalysis': sentimentAnalysis.toMap(),
      'contextualFactors': contextualFactors,
      'followUpQuestions': followUpQuestions,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'userId': userId,
      'tokensUsed': tokensUsed,
    };
  }
}

/// Response wrapper for coaching recommendations
class GeminiRecommendationResponse {
  final String recommendationType;
  final List<GeminiModuleRecommendation> recommendations;
  final String primaryFocus;
  final GeminiWeeklyPlan weeklyPlan;
  final String motivationalMessage;
  final DateTime timestamp;
  final String model;
  final int? tokensUsed;
  final double? estimatedCost;

  GeminiRecommendationResponse({
    required this.recommendationType,
    required this.recommendations,
    required this.primaryFocus,
    required this.weeklyPlan,
    required this.motivationalMessage,
    required this.timestamp,
    required this.model,
    this.tokensUsed,
    this.estimatedCost,
  });

  factory GeminiRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return GeminiRecommendationResponse(
      recommendationType: json['recommendationType'] ?? 'general',
      recommendations: (json['recommendations'] as List? ?? [])
          .map((r) => GeminiModuleRecommendation.fromMap(r))
          .toList(),
      primaryFocus: json['primaryFocus'] ?? 'focus',
      weeklyPlan: json['weeklyPlan'] != null
          ? GeminiWeeklyPlan.fromMap(json['weeklyPlan'])
          : GeminiWeeklyPlan(
              sessionsPerWeek: 3,
              totalDuration: 45,
              focusAreas: ['Focus', 'Confidence', 'Control'],
              progressMilestones: [],
            ),
      motivationalMessage:
          json['motivationalMessage'] ?? 'Keep up the great work!',
      timestamp: DateTime.now(),
      model: 'gemini-2.5-flash',
      tokensUsed: json['tokensUsed'] ?? 0,
      estimatedCost: json['estimatedCost']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recommendationType': recommendationType,
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'primaryFocus': primaryFocus,
      'weeklyPlan': weeklyPlan.toMap(),
      'motivationalMessage': motivationalMessage,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
    };
  }
}

/// Response wrapper for GeminiAIClient.generateMentalCoachingRecommendations()
class GeminiCoachingResponse {
  final String recommendationType;
  final String primaryFocus;
  final String userTier;
  final GeminiVarkAdaptation varkAdaptation;
  final List<GeminiModuleRecommendation> recommendations;
  final GeminiWeeklyPlan weeklyPlan;
  final String motivationalMessage;
  final List<String> contextualInsights;
  final List<GeminiAdaptiveStrategy> adaptiveStrategies;
  final DateTime timestamp;
  final String model;
  final String userId;
  final int tokensUsed;

  GeminiCoachingResponse({
    required this.recommendationType,
    required this.primaryFocus,
    required this.userTier,
    required this.varkAdaptation,
    required this.recommendations,
    required this.weeklyPlan,
    required this.motivationalMessage,
    required this.contextualInsights,
    required this.adaptiveStrategies,
    required this.timestamp,
    required this.model,
    required this.userId,
    required this.tokensUsed,
  });

  /// Create from API response
  factory GeminiCoachingResponse.fromResponse(
    GenerateContentResponse response,
    String userId,
    String model,
  ) {
    // Parse the response - placeholder implementation
    return GeminiCoachingResponse(
      recommendationType: 'weekly_plan',
      primaryFocus: 'focus',
      userTier: 'BASE',
      varkAdaptation: GeminiVarkAdaptation(
        primaryStyle: 'visual',
        secondaryStyle: 'kinesthetic',
        adaptationStrategies: ['Visual learning strategies'],
      ),
      recommendations: [],
      weeklyPlan: GeminiWeeklyPlan(
        sessionsPerWeek: 3,
        totalDuration: 90,
        focusAreas: ['Focus', 'Control'],
        progressMilestones: [],
      ),
      motivationalMessage: 'Keep up the great work!',
      contextualInsights: ['Generated insight'],
      adaptiveStrategies: [],
      timestamp: DateTime.now(),
      model: model,
      userId: userId,
      tokensUsed: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recommendationType': recommendationType,
      'primaryFocus': primaryFocus,
      'userTier': userTier,
      'varkAdaptation': varkAdaptation.toMap(),
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'weeklyPlan': weeklyPlan.toMap(),
      'motivationalMessage': motivationalMessage,
      'contextualInsights': contextualInsights,
      'adaptiveStrategies': adaptiveStrategies.map((s) => s.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'userId': userId,
      'tokensUsed': tokensUsed,
    };
  }
}

/// Response wrapper for personalized content generation
class GeminiContentResponse {
  final String contentType;
  final String title;
  final List<String> adaptedFor;
  final int duration;
  final String difficulty;
  final List<GeminiContentSection> sections;
  final List<String> takeaways;
  final DateTime timestamp;
  final String model;
  final String userId;
  final int tokensUsed;

  GeminiContentResponse({
    required this.contentType,
    required this.title,
    required this.adaptedFor,
    required this.duration,
    required this.difficulty,
    required this.sections,
    required this.takeaways,
    required this.timestamp,
    required this.model,
    required this.userId,
    required this.tokensUsed,
  });

  /// Create from API response
  factory GeminiContentResponse.fromResponse(
    GenerateContentResponse response,
    String userId,
    String model,
  ) {
    // Parse the response - placeholder implementation
    return GeminiContentResponse(
      contentType: 'module',
      title: 'Generated Content',
      adaptedFor: ['visual'],
      duration: 15,
      difficulty: 'intermediate',
      sections: [],
      takeaways: ['Generated takeaway'],
      timestamp: DateTime.now(),
      model: model,
      userId: userId,
      tokensUsed: 0,
    );
  }

  factory GeminiContentResponse.fromJson(Map<String, dynamic> json) {
    return GeminiContentResponse(
      contentType: json['contentType'] ?? 'module',
      title: json['title'] ?? 'Generated Content',
      adaptedFor: List<String>.from(json['adaptedFor'] ?? ['visual']),
      duration: json['duration'] ?? 15,
      difficulty: json['difficulty'] ?? 'intermediate',
      sections: (json['sections'] as List? ?? [])
          .map((s) => GeminiContentSection.fromMap(s))
          .toList(),
      takeaways: List<String>.from(json['takeaways'] ?? ['Generated takeaway']),
      timestamp: DateTime.now(),
      model: 'gemini-2.5-flash',
      userId: '',
      tokensUsed: json['tokensUsed'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentType': contentType,
      'title': title,
      'adaptedFor': adaptedFor,
      'duration': duration,
      'difficulty': difficulty,
      'sections': sections.map((s) => s.toMap()).toList(),
      'takeaways': takeaways,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'userId': userId,
      'tokensUsed': tokensUsed,
    };
  }
}

/// Response wrapper for session feedback
class GeminiFeedbackResponse {
  final String feedbackType;
  final String overallAssessment;
  final List<String> strengths;
  final List<String> improvements;
  final String motivationalMessage;
  final DateTime timestamp;
  final String model;
  final String userId;
  final int? tokensUsed;
  final double? estimatedCost;

  GeminiFeedbackResponse({
    required this.feedbackType,
    required this.overallAssessment,
    required this.strengths,
    required this.improvements,
    required this.motivationalMessage,
    required this.timestamp,
    required this.model,
    required this.userId,
    this.tokensUsed,
    this.estimatedCost,
  });

  factory GeminiFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return GeminiFeedbackResponse(
      feedbackType: json['feedbackType'] ?? 'progress',
      overallAssessment:
          json['overallAssessment'] ?? 'Good progress in your mental training.',
      strengths:
          List<String>.from(json['strengths'] ?? ['Consistent practice']),
      improvements: List<String>.from(
          json['improvements'] ?? ['Continue building focus']),
      motivationalMessage:
          json['motivationalMessage'] ?? 'Keep up the excellent work!',
      timestamp: DateTime.now(),
      model: 'gemini-2.5-flash',
      userId: '',
      tokensUsed: json['tokensUsed'] ?? 0,
      estimatedCost: json['estimatedCost']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feedbackType': feedbackType,
      'overallAssessment': overallAssessment,
      'strengths': strengths,
      'improvements': improvements,
      'motivationalMessage': motivationalMessage,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'userId': userId,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
    };
  }
}

/// Response wrapper for session feedback
class GeminiSessionFeedbackResponse {
  final String feedbackType;
  final String overallAssessment;
  final List<String> strengths;
  final List<String> improvements;
  final String motivationalMessage;
  final DateTime timestamp;
  final String model;
  final String userId;
  final int tokensUsed;

  GeminiSessionFeedbackResponse({
    required this.feedbackType,
    required this.overallAssessment,
    required this.strengths,
    required this.improvements,
    required this.motivationalMessage,
    required this.timestamp,
    required this.model,
    required this.userId,
    required this.tokensUsed,
  });

  /// Create from API response
  factory GeminiSessionFeedbackResponse.fromResponse(
    GenerateContentResponse response,
    String userId,
    String model,
  ) {
    // Parse the response - placeholder implementation
    return GeminiSessionFeedbackResponse(
      feedbackType: 'progress',
      overallAssessment: 'Good progress',
      strengths: ['Consistent practice'],
      improvements: ['Focus on technique'],
      motivationalMessage: 'Keep improving!',
      timestamp: DateTime.now(),
      model: model,
      userId: userId,
      tokensUsed: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feedbackType': feedbackType,
      'overallAssessment': overallAssessment,
      'strengths': strengths,
      'improvements': improvements,
      'motivationalMessage': motivationalMessage,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'userId': userId,
      'tokensUsed': tokensUsed,
    };
  }
}

/// Response model for multi-turn conversations
class GeminiConversationResponse extends BaseGeminiResponse {
  final String response;
  final String conversationType;
  final String sessionId;
  final Map<String, dynamic> context;

  const GeminiConversationResponse({
    required this.response,
    required this.conversationType,
    required this.sessionId,
    required this.context,
    required super.timestamp,
    required super.model,
    required super.userId,
    super.tokensUsed,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'response': response,
      'conversationType': conversationType,
      'sessionId': sessionId,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'userId': userId,
      'tokensUsed': tokensUsed,
    };
  }
}

// ============================================================================
// SUPPORTING MODELS
// ============================================================================

/// Enhanced AI recommendation model with impact estimation
class GeminiRecommendation {
  final String action;
  final String priority;
  final String category;
  final String? relatedModuleId;
  final String estimatedImpact;
  final String timeframe;

  const GeminiRecommendation({
    required this.action,
    required this.priority,
    required this.category,
    this.relatedModuleId,
    required this.estimatedImpact,
    required this.timeframe,
  });

  factory GeminiRecommendation.fromMap(Map<String, dynamic> map) {
    return GeminiRecommendation(
      action: map['action'] as String,
      priority: map['priority'] as String,
      category: map['category'] as String,
      relatedModuleId: map['relatedModuleId'] as String?,
      estimatedImpact: map['estimatedImpact'] as String,
      timeframe: map['timeframe'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'priority': priority,
      'category': category,
      'relatedModuleId': relatedModuleId,
      'estimatedImpact': estimatedImpact,
      'timeframe': timeframe,
    };
  }

  /// Convert to RecommendationStruct for use in existing schema
  RecommendationStruct toRecommendationStruct() {
    return RecommendationStruct(
      action: action,
      priority: priority,
      category: category,
      relatedModuleId: relatedModuleId ?? '',
    );
  }
}

/// Enhanced sentiment analysis model
class GeminiSentimentAnalysis {
  final String overallSentiment;
  final double confidenceLevel;
  final List<String> emotionalIndicators;
  final String moodProgression;

  const GeminiSentimentAnalysis({
    required this.overallSentiment,
    required this.confidenceLevel,
    required this.emotionalIndicators,
    required this.moodProgression,
  });

  factory GeminiSentimentAnalysis.fromMap(Map<String, dynamic> map) {
    return GeminiSentimentAnalysis(
      overallSentiment: map['overallSentiment'] as String,
      confidenceLevel: (map['confidenceLevel'] as num).toDouble(),
      emotionalIndicators:
          List<String>.from(map['emotionalIndicators'] as List),
      moodProgression: map['moodProgression'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overallSentiment': overallSentiment,
      'confidenceLevel': confidenceLevel,
      'emotionalIndicators': emotionalIndicators,
      'moodProgression': moodProgression,
    };
  }
}

/// VARK adaptation model for personalized learning
class GeminiVarkAdaptation {
  final String primaryStyle;
  final String? secondaryStyle;
  final List<String> adaptationStrategies;

  const GeminiVarkAdaptation({
    required this.primaryStyle,
    this.secondaryStyle,
    required this.adaptationStrategies,
  });

  factory GeminiVarkAdaptation.fromMap(Map<String, dynamic> map) {
    return GeminiVarkAdaptation(
      primaryStyle: map['primaryStyle'] as String,
      secondaryStyle: map['secondaryStyle'] as String?,
      adaptationStrategies:
          List<String>.from(map['adaptationStrategies'] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryStyle': primaryStyle,
      'secondaryStyle': secondaryStyle,
      'adaptationStrategies': adaptationStrategies,
    };
  }
}

/// Enhanced module recommendation with outcomes and prerequisites
class GeminiModuleRecommendation {
  final String moduleId;
  final String moduleTitle;
  final String priority;
  final int estimatedDuration;
  final String learningStyle;
  final String description;
  final String expectedOutcome;
  final List<String> prerequisites;
  final String difficulty;

  const GeminiModuleRecommendation({
    required this.moduleId,
    required this.moduleTitle,
    required this.priority,
    required this.estimatedDuration,
    required this.learningStyle,
    required this.description,
    required this.expectedOutcome,
    required this.prerequisites,
    required this.difficulty,
  });

  factory GeminiModuleRecommendation.fromMap(Map<String, dynamic> map) {
    return GeminiModuleRecommendation(
      moduleId: map['moduleId'] as String,
      moduleTitle: map['moduleTitle'] as String,
      priority: map['priority'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      learningStyle: map['learningStyle'] as String,
      description: map['description'] as String,
      expectedOutcome: map['expectedOutcome'] as String,
      prerequisites: List<String>.from(map['prerequisites'] as List),
      difficulty: map['difficulty'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'priority': priority,
      'estimatedDuration': estimatedDuration,
      'learningStyle': learningStyle,
      'description': description,
      'expectedOutcome': expectedOutcome,
      'prerequisites': prerequisites,
      'difficulty': difficulty,
    };
  }
}

/// Enhanced weekly plan with progress milestones
class GeminiWeeklyPlan {
  final int sessionsPerWeek;
  final int totalDuration;
  final List<String> focusAreas;
  final List<String> progressMilestones;

  // Backwards compatibility
  int get totalWeeklyMinutes => totalDuration;

  const GeminiWeeklyPlan({
    required this.sessionsPerWeek,
    required this.totalDuration,
    required this.focusAreas,
    required this.progressMilestones,
  });

  factory GeminiWeeklyPlan.fromMap(Map<String, dynamic> map) {
    return GeminiWeeklyPlan(
      sessionsPerWeek: map['sessionsPerWeek'] as int? ?? 3,
      totalDuration: map['totalDuration'] as int? ??
          map['totalWeeklyMinutes'] as int? ??
          45,
      focusAreas: List<String>.from(
          map['focusAreas'] as List? ?? ['Focus', 'Confidence', 'Control']),
      progressMilestones:
          List<String>.from(map['progressMilestones'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionsPerWeek': sessionsPerWeek,
      'totalDuration': totalDuration,
      'totalWeeklyMinutes': totalDuration, // Backwards compatibility
      'focusAreas': focusAreas,
      'progressMilestones': progressMilestones,
    };
  }
}

/// Progress milestone model
class GeminiProgressMilestone {
  final String milestone;
  final String timeframe;
  final String measurableOutcome;

  const GeminiProgressMilestone({
    required this.milestone,
    required this.timeframe,
    required this.measurableOutcome,
  });

  factory GeminiProgressMilestone.fromMap(Map<String, dynamic> map) {
    return GeminiProgressMilestone(
      milestone: map['milestone'] as String,
      timeframe: map['timeframe'] as String,
      measurableOutcome: map['measurableOutcome'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'milestone': milestone,
      'timeframe': timeframe,
      'measurableOutcome': measurableOutcome,
    };
  }
}

/// Adaptive strategy model for VARK-aligned recommendations
class GeminiAdaptiveStrategy {
  final String strategy;
  final List<String> applicableScenarios;
  final String varkAlignment;

  const GeminiAdaptiveStrategy({
    required this.strategy,
    required this.applicableScenarios,
    required this.varkAlignment,
  });

  factory GeminiAdaptiveStrategy.fromMap(Map<String, dynamic> map) {
    return GeminiAdaptiveStrategy(
      strategy: map['strategy'] as String,
      applicableScenarios:
          List<String>.from(map['applicableScenarios'] as List),
      varkAlignment: map['varkAlignment'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strategy': strategy,
      'applicableScenarios': applicableScenarios,
      'varkAlignment': varkAlignment,
    };
  }
}

/// Enhanced content section with interactive elements
class GeminiContentSection {
  final String type;
  final String title;
  final String content;
  final Map<String, String> varkAdaptations;
  final List<GeminiInteractiveElement> interactiveElements;

  const GeminiContentSection({
    required this.type,
    required this.title,
    required this.content,
    required this.varkAdaptations,
    required this.interactiveElements,
  });

  factory GeminiContentSection.fromMap(Map<String, dynamic> map) {
    return GeminiContentSection(
      type: map['type'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      varkAdaptations: Map<String, String>.from(map['varkAdaptations'] as Map),
      interactiveElements: (map['interactiveElements'] as List? ?? [])
          .map((e) =>
              GeminiInteractiveElement.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'content': content,
      'varkAdaptations': varkAdaptations,
      'interactiveElements': interactiveElements.map((e) => e.toMap()).toList(),
    };
  }
}

/// Interactive element model for engaging content
class GeminiInteractiveElement {
  final String type;
  final String content;
  final String? expectedResponse;

  const GeminiInteractiveElement({
    required this.type,
    required this.content,
    this.expectedResponse,
  });

  factory GeminiInteractiveElement.fromMap(Map<String, dynamic> map) {
    return GeminiInteractiveElement(
      type: map['type'] as String,
      content: map['content'] as String,
      expectedResponse: map['expectedResponse'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'expectedResponse': expectedResponse,
    };
  }
}

/// Enhanced practice exercise with VARK alignment
class GeminiPracticeExercise {
  final String exercise;
  final String varkStyle;
  final int duration;
  final String difficulty;

  const GeminiPracticeExercise({
    required this.exercise,
    required this.varkStyle,
    required this.duration,
    required this.difficulty,
  });

  factory GeminiPracticeExercise.fromMap(Map<String, dynamic> map) {
    return GeminiPracticeExercise(
      exercise: map['exercise'] as String,
      varkStyle: map['varkStyle'] as String,
      duration: map['duration'] as int,
      difficulty: map['difficulty'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise,
      'varkStyle': varkStyle,
      'duration': duration,
      'difficulty': difficulty,
    };
  }
}

/// Enhanced next step model with expected outcomes
class GeminiNextStep {
  final String action;
  final String timeframe;
  final String difficulty;
  final String priority;
  final String expectedOutcome;

  const GeminiNextStep({
    required this.action,
    required this.timeframe,
    required this.difficulty,
    required this.priority,
    required this.expectedOutcome,
  });

  factory GeminiNextStep.fromMap(Map<String, dynamic> map) {
    return GeminiNextStep(
      action: map['action'] as String,
      timeframe: map['timeframe'] as String,
      difficulty: map['difficulty'] as String,
      priority: map['priority'] as String,
      expectedOutcome: map['expectedOutcome'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'timeframe': timeframe,
      'difficulty': difficulty,
      'priority': priority,
      'expectedOutcome': expectedOutcome,
    };
  }
}

/// Adaptive recommendation model with VARK alignment
class GeminiAdaptiveRecommendation {
  final String recommendation;
  final String varkAlignment;
  final String rationale;

  const GeminiAdaptiveRecommendation({
    required this.recommendation,
    required this.varkAlignment,
    required this.rationale,
  });

  factory GeminiAdaptiveRecommendation.fromMap(Map<String, dynamic> map) {
    return GeminiAdaptiveRecommendation(
      recommendation: map['recommendation'] as String,
      varkAlignment: map['varkAlignment'] as String,
      rationale: map['rationale'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recommendation': recommendation,
      'varkAlignment': varkAlignment,
      'rationale': rationale,
    };
  }
}

/// Conversation turn model for context management
class ConversationTurn {
  final String userMessage;
  final String aiResponse;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ConversationTurn({
    required this.userMessage,
    required this.aiResponse,
    required this.timestamp,
    required this.metadata,
  });

  factory ConversationTurn.fromMap(Map<String, dynamic> map) {
    return ConversationTurn(
      userMessage: map['userMessage'] as String,
      aiResponse: map['aiResponse'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userMessage': userMessage,
      'aiResponse': aiResponse,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Conversation session model for multi-turn conversations
class ConversationSession {
  final String sessionId;
  final String userId;
  final String sessionType;
  final DateTime startTime;
  final DateTime lastActivity;
  final List<ConversationTurn> conversationHistory;
  final Map<String, dynamic> sessionContext;

  const ConversationSession({
    required this.sessionId,
    required this.userId,
    required this.sessionType,
    required this.startTime,
    required this.lastActivity,
    required this.conversationHistory,
    required this.sessionContext,
  });

  factory ConversationSession.fromMap(Map<String, dynamic> map) {
    return ConversationSession(
      sessionId: map['sessionId'] as String,
      userId: map['userId'] as String,
      sessionType: map['sessionType'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      lastActivity: DateTime.parse(map['lastActivity'] as String),
      conversationHistory: (map['conversationHistory'] as List)
          .map((t) => ConversationTurn.fromMap(t as Map<String, dynamic>))
          .toList(),
      sessionContext: Map<String, dynamic>.from(map['sessionContext'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'sessionType': sessionType,
      'startTime': startTime.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'conversationHistory': conversationHistory.map((t) => t.toMap()).toList(),
      'sessionContext': sessionContext,
    };
  }
}
