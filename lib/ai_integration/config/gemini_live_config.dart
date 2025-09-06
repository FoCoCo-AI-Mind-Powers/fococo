/// Configuration for Gemini Live API
/// Based on: https://ai.google.dev/gemini-api/docs/live

import 'package:flutter/foundation.dart';

class GeminiLiveAPIConfig {
  GeminiLiveAPIConfig._();

  /// Gemini Live API WebSocket endpoint
  static const String websocketEndpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';

  /// Get API key from environment or secure storage
  static String get apiKey {
    // In production, use secure storage or environment variables
    const key = String.fromEnvironment('GEMINI_API_KEY');

    if (key.isEmpty) {
      if (kDebugMode) {
        print('⚠️ GEMINI_API_KEY not set. Please configure your API key.');
        print(
            '💡 Add --dart-define=GEMINI_API_KEY=your_key_here to flutter run command');
      }
      // Return empty string to prevent crashes during development
      return '';
    }

    return key;
  }

  /// Check if API key is configured
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Native audio models (best quality, supports thinking)
  static const String nativeAudioModel =
      'gemini-2.5-flash-preview-native-audio-dialog';
  static const String nativeAudioThinkingModel =
      'gemini-2.5-flash-exp-native-audio-thinking-dialog';

  /// Half-cascade models (better performance)
  static const String halfCascadeModel = 'gemini-live-2.5-flash-preview';
  static const String halfCascadeFlashModel = 'gemini-2.0-flash-live-001';

  /// Default system instruction for FoCoCo
  static const String defaultSystemInstruction = '''
You are FoCoCo's AI golf mental performance coach. You specialize in:

- Golf psychology and mental training
- Focus, Confidence, and Control (FoCoCo methodology)
- Personalized coaching based on learning preferences
- Practical mindfulness and visualization techniques
- Performance analysis and improvement strategies

Guidelines:
- Be encouraging, supportive, and professional
- Provide specific, actionable advice for golf mental game
- Keep voice responses concise and conversational (2-4 sentences)
- Ask follow-up questions to understand the golfer's situation
- Reference golf-specific scenarios and challenges
- Adapt your communication style to the user's learning preferences

Remember: You're helping golfers unlock their mental potential on the course.
''';

  /// Default response modalities
  static const List<String> defaultResponseModalities = ['AUDIO', 'TEXT'];

  /// Audio format specifications
  static const int inputSampleRate = 16000; // 16kHz input
  static const int outputSampleRate = 24000; // 24kHz output
  static const int channels = 1; // Mono
  static const int bitDepth = 16; // 16-bit PCM
}
