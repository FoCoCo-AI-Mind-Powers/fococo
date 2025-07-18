import '/backend/schema/index.dart';

/// Comprehensive user audio profile for intelligent adaptations
class UserAudioProfile {
  final String userId;
  final VarkPreferencesStruct varkPreferences;
  final VoiceCharacteristics preferredVoiceCharacteristics;
  final AudioEngagementPatterns audioEngagementPatterns;
  final AudioLearningEffectiveness learningEffectiveness;
  final String currentMood;
  final String subscriptionTier;
  final int coachingStreak;
  final DateTime lastUpdated;

  const UserAudioProfile({
    required this.userId,
    required this.varkPreferences,
    required this.preferredVoiceCharacteristics,
    required this.audioEngagementPatterns,
    required this.learningEffectiveness,
    required this.currentMood,
    required this.subscriptionTier,
    required this.coachingStreak,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'varkPreferences': varkPreferences.toMap(),
      'preferredVoiceCharacteristics': preferredVoiceCharacteristics.toMap(),
      'audioEngagementPatterns': audioEngagementPatterns.toMap(),
      'learningEffectiveness': learningEffectiveness.toMap(),
      'currentMood': currentMood,
      'subscriptionTier': subscriptionTier,
      'coachingStreak': coachingStreak,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Voice characteristics and preferences
class VoiceCharacteristics {
  final double preferredSpeechRate; // 0.1 to 2.0
  final double preferredPitch; // 0.5 to 2.0
  final double preferredVolume; // 0.0 to 1.0
  final String preferredVoiceGender; // 'male', 'female', 'neutral'
  final String preferredVoiceAge; // 'young', 'middle', 'mature'
  final String preferredVoiceStyle; // 'professional', 'friendly', 'energetic', 'calm'
  final String emotionalTone; // 'encouraging', 'motivational', 'analytical', 'supportive'
  final bool enableBackgroundAudio;
  final double backgroundAudioVolume;

  const VoiceCharacteristics({
    required this.preferredSpeechRate,
    required this.preferredPitch,
    required this.preferredVolume,
    required this.preferredVoiceGender,
    required this.preferredVoiceAge,
    required this.preferredVoiceStyle,
    required this.emotionalTone,
    required this.enableBackgroundAudio,
    required this.backgroundAudioVolume,
  });

  Map<String, dynamic> toMap() {
    return {
      'preferredSpeechRate': preferredSpeechRate,
      'preferredPitch': preferredPitch,
      'preferredVolume': preferredVolume,
      'preferredVoiceGender': preferredVoiceGender,
      'preferredVoiceAge': preferredVoiceAge,
      'preferredVoiceStyle': preferredVoiceStyle,
      'emotionalTone': emotionalTone,
      'enableBackgroundAudio': enableBackgroundAudio,
      'backgroundAudioVolume': backgroundAudioVolume,
    };
  }
}

/// Audio engagement pattern analysis
class AudioEngagementPatterns {
  final double averageListeningDuration; // in minutes
  final double completionRate; // 0.0 to 1.0
  final List<String> preferredTimeOfDay; // 'morning', 'afternoon', 'evening'
  final Map<String, double> contentTypeEngagement; // engagement by content type
  final double interactionFrequency; // interactions per week
  final List<String> skipPatterns; // what parts users skip
  final double averageResponseTime; // response time to interactive elements

  const AudioEngagementPatterns({
    required this.averageListeningDuration,
    required this.completionRate,
    required this.preferredTimeOfDay,
    required this.contentTypeEngagement,
    required this.interactionFrequency,
    required this.skipPatterns,
    required this.averageResponseTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'averageListeningDuration': averageListeningDuration,
      'completionRate': completionRate,
      'preferredTimeOfDay': preferredTimeOfDay,
      'contentTypeEngagement': contentTypeEngagement,
      'interactionFrequency': interactionFrequency,
      'skipPatterns': skipPatterns,
      'averageResponseTime': averageResponseTime,
    };
  }
}

/// Audio learning effectiveness metrics
class AudioLearningEffectiveness {
  final double comprehensionScore; // 0.0 to 1.0
  final double retentionRate; // 0.0 to 1.0
  final double applicationSuccess; // how well users apply audio coaching
  final Map<String, double> topicEffectiveness; // effectiveness by topic
  final double varkAlignmentScore; // how well audio matches VARK preferences
  final List<String> optimalLearningConditions;

  const AudioLearningEffectiveness({
    required this.comprehensionScore,
    required this.retentionRate,
    required this.applicationSuccess,
    required this.topicEffectiveness,
    required this.varkAlignmentScore,
    required this.optimalLearningConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'comprehensionScore': comprehensionScore,
      'retentionRate': retentionRate,
      'applicationSuccess': applicationSuccess,
      'topicEffectiveness': topicEffectiveness,
      'varkAlignmentScore': varkAlignmentScore,
      'optimalLearningConditions': optimalLearningConditions,
    };
  }
}

/// Conversation audio context for intelligent adaptations
class ConversationAudioContext {
  final String responseType;
  final String dominantEmotion;
  final EmotionalProgression emotionalProgression;
  final String urgencyLevel; // 'low', 'medium', 'high', 'critical'
  final double engagementLevel; // 0.0 to 1.0
  final String conversationFlow; // 'introduction', 'exploration', 'coaching', 'conclusion'
  final Map<String, dynamic> contextFactors;
  final int turnCount;
  final Duration sessionDuration;

  const ConversationAudioContext({
    required this.responseType,
    required this.dominantEmotion,
    required this.emotionalProgression,
    required this.urgencyLevel,
    required this.engagementLevel,
    required this.conversationFlow,
    required this.contextFactors,
    required this.turnCount,
    required this.sessionDuration,
  });
}

/// Emotional progression analysis
class EmotionalProgression {
  final String initialEmotion;
  final String currentEmotion;
  final String projectedEmotion;
  final List<EmotionalTransition> transitions;
  final double emotionalStability; // 0.0 to 1.0
  final List<String> emotionalTriggers;

  const EmotionalProgression({
    required this.initialEmotion,
    required this.currentEmotion,
    required this.projectedEmotion,
    required this.transitions,
    required this.emotionalStability,
    required this.emotionalTriggers,
  });
}

/// Individual emotional transition
class EmotionalTransition {
  final String fromEmotion;
  final String toEmotion;
  final DateTime timestamp;
  final String trigger;
  final double intensity;

  const EmotionalTransition({
    required this.fromEmotion,
    required this.toEmotion,
    required this.timestamp,
    required this.trigger,
    required this.intensity,
  });
}

/// NLP analysis results for audio optimization
class AudioNLPAnalysis {
  final TextComplexityAnalysis textComplexity;
  final KeyConceptsExtraction keyConcepts;
  final EmotionalToneAnalysis emotionalTone;
  final PacingAnalysis pacingRequirements;
  final List<ActionableContent> actionableContent;
  final List<EmphasisRecommendation> recommendedEmphasis;
  final Duration estimatedSpeakingTime;

  const AudioNLPAnalysis({
    required this.textComplexity,
    required this.keyConcepts,
    required this.emotionalTone,
    required this.pacingRequirements,
    required this.actionableContent,
    required this.recommendedEmphasis,
    required this.estimatedSpeakingTime,
  });
}

/// Text complexity analysis
class TextComplexityAnalysis {
  final double readabilityScore; // Flesch-Kincaid scale
  final int averageWordsPerSentence;
  final int averageSyllablesPerWord;
  final List<String> complexTerms;
  final double technicalDensity; // golf-specific terms ratio
  final String recommendedAudienceLevel; // 'beginner', 'intermediate', 'advanced'

  const TextComplexityAnalysis({
    required this.readabilityScore,
    required this.averageWordsPerSentence,
    required this.averageSyllablesPerWord,
    required this.complexTerms,
    required this.technicalDensity,
    required this.recommendedAudienceLevel,
  });
}

/// Key concepts extraction for emphasis
class KeyConceptsExtraction {
  final List<Concept> primaryConcepts;
  final List<Concept> secondaryConcepts;
  final List<String> golfTerminology;
  final List<String> mentalPerformanceTerms;
  final Map<String, double> conceptImportance;

  const KeyConceptsExtraction({
    required this.primaryConcepts,
    required this.secondaryConcepts,
    required this.golfTerminology,
    required this.mentalPerformanceTerms,
    required this.conceptImportance,
  });
}

/// Individual concept for emphasis
class Concept {
  final String term;
  final String category; // 'golf_technique', 'mental_strategy', 'emotional_control'
  final double importance; // 0.0 to 1.0
  final int frequency; // how often mentioned
  final String context; // surrounding context

  const Concept({
    required this.term,
    required this.category,
    required this.importance,
    required this.frequency,
    required this.context,
  });
}

/// Emotional tone analysis
class EmotionalToneAnalysis {
  final String primaryTone; // 'encouraging', 'analytical', 'supportive', 'challenging'
  final Map<String, double> emotionalSpectrum; // multiple emotions with weights
  final String recommendedDeliveryStyle;
  final List<String> emotionalCues; // words/phrases indicating emotion
  final double intensityLevel; // 0.0 to 1.0

  const EmotionalToneAnalysis({
    required this.primaryTone,
    required this.emotionalSpectrum,
    required this.recommendedDeliveryStyle,
    required this.emotionalCues,
    required this.intensityLevel,
  });
}

/// Pacing analysis for audio delivery
class PacingAnalysis {
  final double recommendedSpeechRate;
  final List<PausePoint> pausePoints;
  final List<String> emphasisWords;
  final String overallRhythm; // 'steady', 'varied', 'dynamic'
  final Map<String, double> segmentPacing; // different pacing for different segments

  const PacingAnalysis({
    required this.recommendedSpeechRate,
    required this.pausePoints,
    required this.emphasisWords,
    required this.overallRhythm,
    required this.segmentPacing,
  });
}

/// Pause point for natural speech
class PausePoint {
  final int position; // character position in text
  final Duration duration;
  final String reason; // 'breath', 'emphasis', 'transition', 'reflection'
  final String type; // 'short', 'medium', 'long'

  const PausePoint({
    required this.position,
    required this.duration,
    required this.reason,
    required this.type,
  });
}

/// Actionable content identification
class ActionableContent {
  final String content;
  final String actionType; // 'exercise', 'reflection', 'practice', 'technique'
  final int position; // position in text
  final String urgency; // 'immediate', 'short_term', 'long_term'
  final bool requiresInteraction; // needs user response
  final String varkAlignment; // which VARK style this aligns with

  const ActionableContent({
    required this.content,
    required this.actionType,
    required this.position,
    required this.urgency,
    required this.requiresInteraction,
    required this.varkAlignment,
  });
}

/// Emphasis recommendation for audio delivery
class EmphasisRecommendation {
  final String text;
  final int startPosition;
  final int endPosition;
  final String emphasisType; // 'stress', 'pitch_change', 'pace_slow', 'volume_increase'
  final double intensity; // 0.0 to 1.0
  final String reason; // why this needs emphasis

  const EmphasisRecommendation({
    required this.text,
    required this.startPosition,
    required this.endPosition,
    required this.emphasisType,
    required this.intensity,
    required this.reason,
  });
}

/// Audio adaptation strategy
class AudioAdaptationStrategy {
  final String primaryStrategy;
  final VoiceParameters voiceParameters;
  final PacingStrategy pacingStrategy;
  final BackgroundAudioStrategy backgroundAudioStrategy;
  final VARKAudioAdaptation varkAdaptation;
  final List<EmphasisRecommendation> emphasisPoints;
  final List<InteractiveAudioElement> interactiveElements;

  const AudioAdaptationStrategy({
    required this.primaryStrategy,
    required this.voiceParameters,
    required this.pacingStrategy,
    required this.backgroundAudioStrategy,
    required this.varkAdaptation,
    required this.emphasisPoints,
    required this.interactiveElements,
  });
}

/// Voice parameters for TTS configuration
class VoiceParameters {
  final double speechRate;
  final double pitch;
  final double volume;
  final String voiceId;
  final String emotionalTone;
  final String style; // 'conversational', 'professional', 'energetic', 'calm'

  const VoiceParameters({
    required this.speechRate,
    required this.pitch,
    required this.volume,
    required this.voiceId,
    required this.emotionalTone,
    required this.style,
  });
}

/// Pacing strategy for speech delivery
class PacingStrategy {
  final double baseSpeechRate;
  final Map<String, double> segmentRates; // different rates for different segments
  final List<PausePoint> scheduledPauses;
  final String rhythmPattern; // 'steady', 'accelerating', 'decelerating', 'varied'

  const PacingStrategy({
    required this.baseSpeechRate,
    required this.segmentRates,
    required this.scheduledPauses,
    required this.rhythmPattern,
  });
}

/// Background audio strategy
class BackgroundAudioStrategy {
  final bool enabled;
  final String audioType; // 'nature', 'golf_course', 'ambient', 'none'
  final double volume; // 0.0 to 1.0
  final String trigger; // when to play background audio
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  const BackgroundAudioStrategy({
    required this.enabled,
    required this.audioType,
    required this.volume,
    required this.trigger,
    required this.fadeInDuration,
    required this.fadeOutDuration,
  });
}

/// VARK-specific audio adaptations
class VARKAudioAdaptation {
  final bool isAuralDominant;
  final List<String> auralTechniques; // techniques for aural learners
  final List<String> kinestheticCues; // physical cues in audio
  final List<String> visualAudioHybrid; // audio that supports visual learning
  final List<String> readWriteSupport; // audio that complements reading

  const VARKAudioAdaptation({
    required this.isAuralDominant,
    required this.auralTechniques,
    required this.kinestheticCues,
    required this.visualAudioHybrid,
    required this.readWriteSupport,
  });
}

/// Interactive audio elements
class InteractiveAudioElement {
  final String type; // 'pause_for_reflection', 'guided_breathing', 'visualization_prompt'
  final String content;
  final int position; // position in audio
  final Duration duration;
  final bool requiresResponse;
  final String followUpAction;

  const InteractiveAudioElement({
    required this.type,
    required this.content,
    required this.position,
    required this.duration,
    required this.requiresResponse,
    required this.followUpAction,
  });
}

/// Text transformation result
class AudioTextTransformation {
  final String originalText;
  final String adaptedText;
  final List<String> transformations;

  const AudioTextTransformation({
    required this.originalText,
    required this.adaptedText,
    required this.transformations,
  });
}

/// Audio generation result
class AudioGenerationResult {
  final String mainAudioPath;
  final String? backgroundAudioPath;
  final String finalAudioPath;
  final Duration duration;
  final VoiceParameters voiceParameters;
  final DateTime generationTimestamp;

  const AudioGenerationResult({
    required this.mainAudioPath,
    this.backgroundAudioPath,
    required this.finalAudioPath,
    required this.duration,
    required this.voiceParameters,
    required this.generationTimestamp,
  });
}

/// Complete audio output result
class AudioOutputResult {
  final String originalText;
  final String adaptedText;
  final AudioAdaptationStrategy audioStrategy;
  final ConversationAudioContext contextAnalysis;
  final AudioNLPAnalysis nlpAnalysis;
  final AudioGenerationResult audioMetadata;
  final List<String> transformations;
  final DateTime timestamp;
  final String userId;

  const AudioOutputResult({
    required this.originalText,
    required this.adaptedText,
    required this.audioStrategy,
    required this.contextAnalysis,
    required this.nlpAnalysis,
    required this.audioMetadata,
    required this.transformations,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'adaptedText': adaptedText,
      'audioStrategy': {
        'primaryStrategy': audioStrategy.primaryStrategy,
        'voiceParameters': {
          'speechRate': audioStrategy.voiceParameters.speechRate,
          'pitch': audioStrategy.voiceParameters.pitch,
          'volume': audioStrategy.voiceParameters.volume,
          'emotionalTone': audioStrategy.voiceParameters.emotionalTone,
        },
      },
      'contextAnalysis': {
        'responseType': contextAnalysis.responseType,
        'dominantEmotion': contextAnalysis.dominantEmotion,
        'urgencyLevel': contextAnalysis.urgencyLevel,
        'engagementLevel': contextAnalysis.engagementLevel,
      },
      'transformations': transformations,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }
}

/// Voice input processing result
class VoiceInputResult {
  final String recognizedText;
  final double confidence;
  final VoiceInputNLPProcessing nlpProcessing;
  final ContextualResponseGeneration contextualResponse;
  final Duration processingDuration;
  final DateTime timestamp;

  const VoiceInputResult({
    required this.recognizedText,
    required this.confidence,
    required this.nlpProcessing,
    required this.contextualResponse,
    required this.processingDuration,
    required this.timestamp,
  });
}

/// Voice input NLP processing
class VoiceInputNLPProcessing {
  final String processedText;
  final String detectedIntent; // 'question', 'feedback', 'request', 'emotional_response'
  final Map<String, dynamic> extractedEntities;
  final String emotionalState;
  final double urgencyLevel;
  final List<String> keyTopics;

  const VoiceInputNLPProcessing({
    required this.processedText,
    required this.detectedIntent,
    required this.extractedEntities,
    required this.emotionalState,
    required this.urgencyLevel,
    required this.keyTopics,
  });
}

/// Contextual response generation
class ContextualResponseGeneration {
  final String responseText;
  final String responseType;
  final AudioAdaptationStrategy audioStrategy;
  final List<String> followUpSuggestions;
  final Map<String, dynamic> responseMetadata;

  const ContextualResponseGeneration({
    required this.responseText,
    required this.responseType,
    required this.audioStrategy,
    required this.followUpSuggestions,
    required this.responseMetadata,
  });
} 