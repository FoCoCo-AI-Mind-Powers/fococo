/// Configuration for Gemini Live API
/// Based on: https://ai.google.dev/gemini-api/docs/live
///
/// NOTE: The raw-API-key WebSocket path (`wss://...?key=...`) has been
/// retired. Live bidi traffic must go through `FirebaseAI.googleAI().liveModel(...)`
/// which authenticates via Firebase App Check. These getters remain only so
/// call-sites compile; they return empty values and `isConfigured` is always
/// false for the raw path. Migrate any remaining consumer to `firebase_ai`.
class GeminiLiveAPIConfig {
  GeminiLiveAPIConfig._();

  /// Gemini Live API WebSocket endpoint (deprecated — use firebase_ai Live).
  static const String websocketEndpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';

  /// Always empty — client no longer holds a Gemini key.
  static String get apiKey => '';

  /// Always empty — use `FirebaseAI.googleAI().liveModel(...)` instead.
  static Future<String> getApiKey() async => '';

  /// Always false for the raw-key path.
  static bool get isConfigured => false;

  /// Native audio models (best quality, supports thinking)
  static const String nativeAudioModel =
      'gemini-2.5-flash-native-audio-preview-12-2025';
  static const String nativeAudioThinkingModel =
      'gemini-2.5-flash-exp-native-audio-thinking-dialog';

  /// @deprecated These models were shut down Dec 9, 2025.
  /// Use [nativeAudioModel] instead.
  @Deprecated('Shut down Dec 9 2025. Use nativeAudioModel.')
  static const String halfCascadeModel = 'gemini-live-2.5-flash-preview';
  @Deprecated('Shut down Dec 9 2025. Use nativeAudioModel.')
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
