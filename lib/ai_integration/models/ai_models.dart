import 'dart:convert';
import 'package:fo_co_co/backend/schema/ai_insights_record.dart';
import 'package:fo_co_co/backend/schema/structs/recommendation_struct.dart';


/// Base class for all AI response models
abstract class BaseAIResponse {
  final DateTime timestamp;
  final String model;
  final int? tokensUsed;
  final double? estimatedCost;

  const BaseAIResponse({
    required this.timestamp,
    required this.model,
    this.tokensUsed,
    this.estimatedCost,
  });

  Map<String, dynamic> toMap();
}

/// Response model for AI-generated golf insights
class AIInsightResponse extends BaseAIResponse {
  final String insightTitle;
  final String category;
  final String priority;
  final List<String> keyPoints;
  final List<AIRecommendation> recommendations;
  final List<String> personalizedElements;
  final String summaryText;

  const AIInsightResponse({
    required this.insightTitle,
    required this.category,
    required this.priority,
    required this.keyPoints,
    required this.recommendations,
    required this.personalizedElements,
    required this.summaryText,
    required super.timestamp,
    required super.model,
    super.tokensUsed,
    super.estimatedCost,
  });

  factory AIInsightResponse.fromOpenAIResponse(Map<String, dynamic> response) {
    final content = response['choices'][0]['message']['content'] as String;
    final data = jsonDecode(content) as Map<String, dynamic>;
    final usage = response['usage'] as Map<String, dynamic>?;

    return AIInsightResponse(
      insightTitle: data['insightTitle'] as String,
      category: data['category'] as String,
      priority: data['priority'] as String,
      keyPoints: List<String>.from(data['keyPoints'] as List),
      recommendations: (data['recommendations'] as List)
          .map((r) => AIRecommendation.fromMap(r as Map<String, dynamic>))
          .toList(),
      personalizedElements:
          List<String>.from(data['personalizedElements'] as List),
      summaryText: data['summaryText'] as String,
      timestamp: DateTime.now(),
      model: response['model'] as String,
      tokensUsed: usage?['total_tokens'] as int?,
      estimatedCost: _calculateCost(usage),
    );
  }

  /// Convert to AiInsightsRecord for database storage
  AiInsightsRecord toAiInsightsRecord({
    required String userId,
    required String sourceId,
    required String sourceType,
  }) {
    // This would be used to create a new Firestore document
    // Implementation would depend on your specific Firestore setup
    throw UnimplementedError(
        'Implementation depends on Firestore document creation pattern');
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'insightTitle': insightTitle,
      'category': category,
      'priority': priority,
      'keyPoints': keyPoints,
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'personalizedElements': personalizedElements,
      'summaryText': summaryText,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
    };
  }

  static double? _calculateCost(Map<String, dynamic>? usage) {
    if (usage == null) return null;

    final promptTokens = usage['prompt_tokens'] as int? ?? 0;
    final completionTokens = usage['completion_tokens'] as int? ?? 0;

    // GPT-4o-mini pricing (as of 2024)
    const inputCostPer1K = 0.00015;
    const outputCostPer1K = 0.0006;

    final inputCost = (promptTokens / 1000) * inputCostPer1K;
    final outputCost = (completionTokens / 1000) * outputCostPer1K;

    return inputCost + outputCost;
  }
}

/// Response model for AI recommendations
class AIRecommendationResponse extends BaseAIResponse {
  final String recommendationType;
  final String primaryFocus;
  final List<AIModuleRecommendation> recommendations;
  final AIWeeklyPlan weeklyPlan;
  final String motivationalMessage;

  const AIRecommendationResponse({
    required this.recommendationType,
    required this.primaryFocus,
    required this.recommendations,
    required this.weeklyPlan,
    required this.motivationalMessage,
    required super.timestamp,
    required super.model,
    super.tokensUsed,
    super.estimatedCost,
  });

  factory AIRecommendationResponse.fromOpenAIResponse(
      Map<String, dynamic> response) {
    final content = response['choices'][0]['message']['content'] as String;
    final data = jsonDecode(content) as Map<String, dynamic>;
    final usage = response['usage'] as Map<String, dynamic>?;

    return AIRecommendationResponse(
      recommendationType: data['recommendationType'] as String,
      primaryFocus: data['primaryFocus'] as String,
      recommendations: (data['recommendations'] as List)
          .map((r) => AIModuleRecommendation.fromMap(r as Map<String, dynamic>))
          .toList(),
      weeklyPlan:
          AIWeeklyPlan.fromMap(data['weeklyPlan'] as Map<String, dynamic>),
      motivationalMessage: data['motivationalMessage'] as String,
      timestamp: DateTime.now(),
      model: response['model'] as String,
      tokensUsed: usage?['total_tokens'] as int?,
      estimatedCost: AIInsightResponse._calculateCost(usage),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'recommendationType': recommendationType,
      'primaryFocus': primaryFocus,
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'weeklyPlan': weeklyPlan.toMap(),
      'motivationalMessage': motivationalMessage,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
    };
  }
}

/// Response model for personalized content
class AIContentResponse extends BaseAIResponse {
  final String contentType;
  final String title;
  final List<String> adaptedFor;
  final int duration;
  final List<AIContentSection> sections;
  final List<String> takeaways;
  final List<String> practiceExercises;

  const AIContentResponse({
    required this.contentType,
    required this.title,
    required this.adaptedFor,
    required this.duration,
    required this.sections,
    required this.takeaways,
    required this.practiceExercises,
    required super.timestamp,
    required super.model,
    super.tokensUsed,
    super.estimatedCost,
  });

  factory AIContentResponse.fromOpenAIResponse(Map<String, dynamic> response) {
    final content = response['choices'][0]['message']['content'] as String;
    final data = jsonDecode(content) as Map<String, dynamic>;
    final usage = response['usage'] as Map<String, dynamic>?;

    return AIContentResponse(
      contentType: data['contentType'] as String,
      title: data['title'] as String,
      adaptedFor: List<String>.from(data['adaptedFor'] as List),
      duration: data['duration'] as int,
      sections: (data['sections'] as List)
          .map((s) => AIContentSection.fromMap(s as Map<String, dynamic>))
          .toList(),
      takeaways: List<String>.from(data['takeaways'] as List),
      practiceExercises: List<String>.from(data['practiceExercises'] as List),
      timestamp: DateTime.now(),
      model: response['model'] as String,
      tokensUsed: usage?['total_tokens'] as int?,
      estimatedCost: AIInsightResponse._calculateCost(usage),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'contentType': contentType,
      'title': title,
      'adaptedFor': adaptedFor,
      'duration': duration,
      'sections': sections.map((s) => s.toMap()).toList(),
      'takeaways': takeaways,
      'practiceExercises': practiceExercises,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
    };
  }
}

/// Response model for session feedback
class AIFeedbackResponse extends BaseAIResponse {
  final String feedbackType;
  final String overallAssessment;
  final List<String> strengths;
  final List<String> improvements;
  final List<AINextStep> nextSteps;
  final String motivationalMessage;
  final String progressInsights;
  final String recommendedFocus;

  const AIFeedbackResponse({
    required this.feedbackType,
    required this.overallAssessment,
    required this.strengths,
    required this.improvements,
    required this.nextSteps,
    required this.motivationalMessage,
    required this.progressInsights,
    required this.recommendedFocus,
    required super.timestamp,
    required super.model,
    super.tokensUsed,
    super.estimatedCost,
  });

  factory AIFeedbackResponse.fromOpenAIResponse(Map<String, dynamic> response) {
    final content = response['choices'][0]['message']['content'] as String;
    final data = jsonDecode(content) as Map<String, dynamic>;
    final usage = response['usage'] as Map<String, dynamic>?;

    return AIFeedbackResponse(
      feedbackType: data['feedbackType'] as String,
      overallAssessment: data['overallAssessment'] as String,
      strengths: List<String>.from(data['strengths'] as List),
      improvements: List<String>.from(data['improvements'] as List),
      nextSteps: (data['nextSteps'] as List)
          .map((s) => AINextStep.fromMap(s as Map<String, dynamic>))
          .toList(),
      motivationalMessage: data['motivationalMessage'] as String,
      progressInsights: data['progressInsights'] as String,
      recommendedFocus: data['recommendedFocus'] as String,
      timestamp: DateTime.now(),
      model: response['model'] as String,
      tokensUsed: usage?['total_tokens'] as int?,
      estimatedCost: AIInsightResponse._calculateCost(usage),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'feedbackType': feedbackType,
      'overallAssessment': overallAssessment,
      'strengths': strengths,
      'improvements': improvements,
      'nextSteps': nextSteps.map((s) => s.toMap()).toList(),
      'motivationalMessage': motivationalMessage,
      'progressInsights': progressInsights,
      'recommendedFocus': recommendedFocus,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
    };
  }
}

// ============================================================================
// SUPPORTING MODELS
// ============================================================================

/// AI recommendation model that aligns with RecommendationStruct
class AIRecommendation {
  final String action;
  final String priority;
  final String category;
  final String? relatedModuleId;

  const AIRecommendation({
    required this.action,
    required this.priority,
    required this.category,
    this.relatedModuleId,
  });

  factory AIRecommendation.fromMap(Map<String, dynamic> map) {
    return AIRecommendation(
      action: map['action'] as String,
      priority: map['priority'] as String,
      category: map['category'] as String,
      relatedModuleId: map['relatedModuleId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'priority': priority,
      'category': category,
      'relatedModuleId': relatedModuleId,
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

/// AI module recommendation model
class AIModuleRecommendation {
  final String moduleId;
  final String moduleTitle;
  final String priority;
  final int estimatedDuration;
  final String learningStyle;
  final String description;

  const AIModuleRecommendation({
    required this.moduleId,
    required this.moduleTitle,
    required this.priority,
    required this.estimatedDuration,
    required this.learningStyle,
    required this.description,
  });

  factory AIModuleRecommendation.fromMap(Map<String, dynamic> map) {
    return AIModuleRecommendation(
      moduleId: map['moduleId'] as String,
      moduleTitle: map['moduleTitle'] as String,
      priority: map['priority'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      learningStyle: map['learningStyle'] as String,
      description: map['description'] as String,
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
    };
  }
}

/// AI weekly plan model
class AIWeeklyPlan {
  final int sessionsPerWeek;
  final int totalWeeklyMinutes;
  final List<String> focusAreas;

  const AIWeeklyPlan({
    required this.sessionsPerWeek,
    required this.totalWeeklyMinutes,
    required this.focusAreas,
  });

  factory AIWeeklyPlan.fromMap(Map<String, dynamic> map) {
    return AIWeeklyPlan(
      sessionsPerWeek: map['sessionsPerWeek'] as int,
      totalWeeklyMinutes: map['totalWeeklyMinutes'] as int,
      focusAreas: List<String>.from(map['focusAreas'] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionsPerWeek': sessionsPerWeek,
      'totalWeeklyMinutes': totalWeeklyMinutes,
      'focusAreas': focusAreas,
    };
  }
}

/// AI content section model
class AIContentSection {
  final String type;
  final String title;
  final String content;
  final Map<String, String> adaptations;

  const AIContentSection({
    required this.type,
    required this.title,
    required this.content,
    required this.adaptations,
  });

  factory AIContentSection.fromMap(Map<String, dynamic> map) {
    return AIContentSection(
      type: map['type'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      adaptations: Map<String, String>.from(map['adaptations'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'content': content,
      'adaptations': adaptations,
    };
  }
}

/// AI next step model for feedback
class AINextStep {
  final String action;
  final String timeframe;
  final String difficulty;

  const AINextStep({
    required this.action,
    required this.timeframe,
    required this.difficulty,
  });

  factory AINextStep.fromMap(Map<String, dynamic> map) {
    return AINextStep(
      action: map['action'] as String,
      timeframe: map['timeframe'] as String,
      difficulty: map['difficulty'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'timeframe': timeframe,
      'difficulty': difficulty,
    };
  }
}

// ============================================================================
// AUDIO-ENABLED RESPONSE MODELS
// ============================================================================

/// Enhanced AI insight response with optional audio data
class AIInsightWithAudioResponse {
  final AIInsightResponse textInsight;
  final Map<String, dynamic>? audioData;

  const AIInsightWithAudioResponse({
    required this.textInsight,
    this.audioData,
  });

  bool get hasAudio => audioData != null;

  String? get audioPath => audioData?['audioPath'] as String?;
  int? get audioSize => audioData?['audioSize'] as int?;
  String? get voiceId => audioData?['voiceId'] as String?;
  DateTime? get audioGeneratedAt {
    final dateStr = audioData?['generatedAt'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  /// Get summary text for audio playback
  String get summary => textInsight.summaryText;

  Map<String, dynamic> toMap() {
    return {
      'textInsight': textInsight.toMap(),
      'audioData': audioData,
      'hasAudio': hasAudio,
    };
  }
}

/// Enhanced AI recommendation response with optional audio data
class AIRecommendationWithAudioResponse {
  final AIRecommendationResponse textRecommendations;
  final Map<String, dynamic>? audioData;

  const AIRecommendationWithAudioResponse({
    required this.textRecommendations,
    this.audioData,
  });

  bool get hasAudio => audioData != null;

  String? get audioPath => audioData?['audioPath'] as String?;
  int? get audioSize => audioData?['audioSize'] as int?;
  String? get voiceId => audioData?['voiceId'] as String?;
  DateTime? get audioGeneratedAt {
    final dateStr = audioData?['generatedAt'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  /// Get primary recommendation for quick access
  String get primaryRecommendation => textRecommendations.primaryFocus;

  /// Get focus areas as a list
  List<String> get focusAreas => textRecommendations.weeklyPlan.focusAreas;

  /// Get action items from recommendations
  List<String> get actionItems =>
      textRecommendations.recommendations.map((r) => r.description).toList();

  Map<String, dynamic> toMap() {
    return {
      'textRecommendations': textRecommendations.toMap(),
      'audioData': audioData,
      'hasAudio': hasAudio,
    };
  }
}

/// Enhanced AI content response with optional audio data
class AIContentWithAudioResponse {
  final AIContentResponse textContent;
  final Map<String, dynamic>? audioData;

  const AIContentWithAudioResponse({
    required this.textContent,
    this.audioData,
  });

  bool get hasAudio => audioData != null;

  String? get audioPath => audioData?['audioPath'] as String?;
  int? get audioSize => audioData?['audioSize'] as int?;
  String? get voiceId => audioData?['voiceId'] as String?;
  DateTime? get audioGeneratedAt {
    final dateStr = audioData?['generatedAt'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  /// Get content text for audio playback
  String get content {
    // Combine all sections into a single text for audio
    final buffer = StringBuffer();
    buffer.writeln(textContent.title);
    buffer.writeln();

    for (final section in textContent.sections) {
      buffer.writeln(section.title);
      buffer.writeln(section.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'textContent': textContent.toMap(),
      'audioData': audioData,
      'hasAudio': hasAudio,
    };
  }
}
