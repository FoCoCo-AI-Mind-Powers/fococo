import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Configuration class for Gemini Voice AI integration
class GeminiVoiceConfig {
  GeminiVoiceConfig._();

  // ============================================================================
  // VOICE AI MODELS
  // ============================================================================

  /// Most cost-efficient model supporting high throughput (for real-time voice)
  static const String flashLiteModel = 'gemini-2.5-flash-lite';

  /// Live API model for bidirectional voice interactions
  static const String liveModel = 'gemini-2.5-flash-native-audio-preview-12-2025';

  /// Native audio dialog model
  static const String nativeAudioDialogModel =
      'gemini-2.5-flash-native-audio-preview-12-2025';

  /// Native audio with thinking model
  static const String nativeAudioThinkingModel =
      'gemini-2.5-flash-exp-native-audio-thinking-dialog';

  /// Prebuilt Gemini live voice name. Cartesia voice IDs are not accepted here.
  static const String geminiLiveVoiceName = 'Puck';

  /// Text-to-speech models
  static const String flashTTSModel = 'models/gemini-2.5-flash-preview-tts';
  static const String proTTSModel = 'models/gemini-2.5-pro-preview-tts';

  // ============================================================================
  // VOICE GENERATION CONFIGURATIONS
  // ============================================================================

  /// Configuration for real-time voice chat (flash-lite)
  static GenerationConfig get voiceChatConfig => GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
        responseMimeType: 'text/plain',
      );

  /// Configuration for live voice interactions
  static GenerationConfig get liveVoiceConfig => GenerationConfig(
        temperature: 0.7,
        topK: 30,
        topP: 0.9,
        maxOutputTokens: 512,
        responseMimeType: 'text/plain',
      );

  /// Configuration for native audio with thinking
  static GenerationConfig get thinkingVoiceConfig => GenerationConfig(
        temperature: 0.6,
        topK: 25,
        topP: 0.85,
        maxOutputTokens: 2048,
        responseMimeType: 'text/plain',
      );

  /// Configuration for TTS generation
  static GenerationConfig get ttsConfig => GenerationConfig(
        temperature: 0.3,
        topK: 10,
        topP: 0.7,
        maxOutputTokens: 512,
        responseMimeType: 'audio/wav',
      );

  // ============================================================================
  // VOICE SYSTEM PROMPTS
  // ============================================================================

  /// System prompt for golf mental coaching voice assistant
  static const String voiceCoachingSystemPrompt = '''
You are FoCoCo's AI Voice Mental Coach, specializing in golf psychology and mental performance.

COMMUNICATION STYLE:
- Speak conversationally and naturally, as if you're a professional golf mental coach
- Keep responses concise but impactful (30-60 seconds of speech)
- Use encouraging and supportive tone
- Reference golf-specific mental challenges and techniques
- Adapt to the user's VARK learning preference when known

EXPERTISE AREAS:
- Pre-shot routines and mental preparation
- Managing pressure and nerves on the course
- Focus and concentration techniques
- Confidence building and positive self-talk
- Course management and strategic thinking
- Recovery from bad shots or poor rounds
- Mental game fundamentals

RESPONSE GUIDELINES:
- Provide actionable advice the user can implement immediately
- Ask follow-up questions to understand their specific challenges
- Suggest specific FoCoCo modules or exercises when relevant
- Be empathetic and understanding of golf's mental challenges
- Keep technical jargon minimal and explain concepts clearly

Remember: You're having a real-time conversation, so be natural and responsive to their specific needs and emotions.
''';

  /// System prompt for voice chat with thinking enabled
  static const String voiceThinkingSystemPrompt = '''
You are FoCoCo's Advanced AI Voice Mental Coach with enhanced thinking capabilities.

Before responding, think through:
1. What specific mental game challenge is the user facing?
2. What's the most helpful advice for their current situation?
3. How can I make this actionable and golf-specific?
4. What follow-up questions would help me understand better?

$voiceCoachingSystemPrompt

THINKING PROCESS:
- Analyze the user's emotional state and confidence level
- Consider their skill level and experience
- Think about practical techniques they can use on the course
- Plan a response that builds their mental strength

Provide thoughtful, strategic advice while maintaining a conversational voice tone.
''';

  // ============================================================================
  // AUDIO SETTINGS
  // ============================================================================

  /// Audio recording settings
  static const Map<String, dynamic> audioRecordingSettings = {
    'sampleRate': 16000,
    'bitRate': 128000,
    'channels': 1,
    'format': 'wav',
    'quality': 'high',
  };

  /// TTS voice settings
  static const Map<String, dynamic> ttsVoiceSettings = {
    'voice': 'en-US-Standard-J', // Professional, warm voice
    'speakingRate': 1.0,
    'pitch': 0.0,
    'volumeGainDb': 0.0,
  };

  // ============================================================================
  // MODEL CREATION HELPERS
  // ============================================================================

  /// Create voice chat model (flash-lite for real-time)
  static GenerativeModel createVoiceChatModel({
    String? systemInstruction,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: flashLiteModel,
      generationConfig: voiceChatConfig,
      safetySettings: _voiceSafetySettings,
      systemInstruction: systemInstruction != null
          ? Content.text(systemInstruction)
          : Content.text(voiceCoachingSystemPrompt),
    );
  }

  /// Create thinking voice model
  static GenerativeModel createThinkingVoiceModel({
    String? systemInstruction,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: nativeAudioThinkingModel,
      generationConfig: thinkingVoiceConfig,
      safetySettings: _voiceSafetySettings,
      systemInstruction: systemInstruction != null
          ? Content.text(systemInstruction)
          : Content.text(voiceThinkingSystemPrompt),
    );
  }

  /// Create TTS model
  static GenerativeModel createTTSModel() {
    return FirebaseAI.googleAI().generativeModel(
      model: flashTTSModel,
      generationConfig: ttsConfig,
      safetySettings: _voiceSafetySettings,
    );
  }

  // ============================================================================
  // SAFETY SETTINGS
  // ============================================================================

  static List<SafetySetting> get _voiceSafetySettings => [
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
        //   threshold: HarmBlockThreshold.high,
        // ),
        // SafetySetting(
        //   category: HarmCategory.dangerousContent,
        //   threshold: HarmBlockThreshold.medium,
        // ),
      ];

  // ============================================================================
  // COST ESTIMATION
  // ============================================================================

  /// Estimate cost for voice interactions
  static double estimateVoiceCost({
    required int inputTokens,
    required int outputTokens,
    required String model,
  }) {
    // Pricing per 1M tokens (approximate)
    final Map<String, Map<String, double>> pricing = {
      flashLiteModel: {'input': 0.075, 'output': 0.30}, // Most cost-efficient
      nativeAudioDialogModel: {'input': 0.30, 'output': 1.20}, // Live / native audio
      nativeAudioThinkingModel: {'input': 0.30, 'output': 1.20},
      flashTTSModel: {'input': 0.30, 'output': 1.20},
      proTTSModel: {'input': 7.00, 'output': 21.00}, // Premium TTS
    };

    final modelPricing = pricing[model] ?? pricing[flashLiteModel]!;

    final inputCost = (inputTokens / 1000000) * modelPricing['input']!;
    final outputCost = (outputTokens / 1000000) * modelPricing['output']!;

    return inputCost + outputCost;
  }

  /// Estimate token count for text
  static int estimateTokenCount(String text) {
    // Rough estimation: 1 token ≈ 4 characters for Gemini models
    return (text.length / 4).ceil();
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Validate voice configuration
  static bool validateVoiceConfig() {
    try {
      // Check if required models are accessible
      createVoiceChatModel();
      if (kDebugMode) {
        print('✅ Voice configuration validated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Voice configuration validation failed: $e');
      }
      return false;
    }
  }
}

/// Voice interaction types
enum VoiceInteractionType {
  quickChat,
  thinkingMode,
  liveConversation,
  ttsOnly,
}

/// Voice response quality levels
enum VoiceResponseQuality {
  fast, // flash-lite for speed
  balanced, // flash for balance
  premium, // pro for best quality
}

/// Audio format types
enum AudioFormat {
  wav,
  mp3,
  aac,
  ogg,
}
