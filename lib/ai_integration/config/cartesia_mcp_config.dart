import 'package:flutter/foundation.dart';

/// Cartesia MCP (Model Context Protocol) Configuration
/// Integrates with Cartesia's voice platform for advanced TTS capabilities
class CartesiaMCPConfig {
  static const String apiKey = 'sk_car_hksASYyHegCKwWLWfAL8SW';
  static const String baseUrl = 'https://api.cartesia.ai';
  static const String mcpServerUrl = 'wss://mcp.cartesia.ai';

  // Voice model configurations
  static const String defaultVoiceModel = 'sonic-2';
  static const String defaultLanguage = 'en';
  static const String apiVersion = '2024-06-10';

  // MCP Server settings
  static const Map<String, dynamic> mcpServerConfig = {
    'command': 'cartesia-mcp',
    'env': {
      'CARTESIA_API_KEY': apiKey,
      'OUTPUT_DIRECTORY': '/tmp/cartesia_audio', // For generated audio files
    },
  };

  // Voice configurations optimized for golf coaching with specified voice
  static const Map<String, Map<String, dynamic>> voiceProfiles = {
    'coach_confident': {
      'voice_id':
          '7442d6b8-ff51-4477-bd30-0c0d16df84eb', // Your specified voice ID
      'model': 'sonic-2',
      'speed': 'normal',
      'emotion': 'confident',
      'style': 'coaching',
    },
    'coach_encouraging': {
      'voice_id':
          '7442d6b8-ff51-4477-bd30-0c0d16df84eb', // Using same voice with different settings
      'model': 'sonic-2',
      'speed': 'slow',
      'emotion': 'encouraging',
      'style': 'supportive',
    },
    'mentor_calm': {
      'voice_id':
          '7442d6b8-ff51-4477-bd30-0c0d16df84eb', // Using same voice with calm settings
      'model': 'sonic-2',
      'speed': 'slow',
      'emotion': 'calm',
      'style': 'meditative',
    },
    'coach_conversational': {
      'voice_id': '7442d6b8-ff51-4477-bd30-0c0d16df84eb',
      'model': 'sonic-2',
      'speed': 'normal',
      'emotion': 'conversational',
      'style': 'dialogue',
    },
  };

  // VARK-specific voice adaptations
  static const Map<String, Map<String, dynamic>> varkVoiceSettings = {
    'visual': {
      'speed': 1.0,
      'pause_duration': 0.8, // Longer pauses for visualization
      'emphasis_words': ['see', 'picture', 'visualize', 'imagine'],
    },
    'aural': {
      'speed': 0.9,
      'pause_duration': 0.5,
      'emphasis_words': ['listen', 'hear', 'sound', 'rhythm'],
      'use_background_sounds': true,
    },
    'readWrite': {
      'speed': 0.8,
      'pause_duration': 1.0, // More time for note-taking
      'emphasis_words': ['note', 'write', 'list', 'remember'],
    },
    'kinesthetic': {
      'speed': 1.1,
      'pause_duration': 0.3, // Faster, action-oriented
      'emphasis_words': ['feel', 'practice', 'try', 'experience'],
    },
  };

  /// Get API headers for Cartesia requests
  static Map<String, String> get apiHeaders => {
        'Cartesia-Version': apiVersion,
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      };

  /// Get voice profile by ID
  static Map<String, dynamic>? getVoiceProfile(String profileId) {
    return voiceProfiles[profileId];
  }

  /// Get VARK-adapted voice settings
  static Map<String, dynamic>? getVarkSettings(String varkType) {
    return varkVoiceSettings[varkType];
  }

  /// Generate TTS request payload
  static Map<String, dynamic> generateTTSPayload({
    required String text,
    required String voiceId,
    String model = 'sonic-2',
    String speed = 'normal',
    String format = 'wav',
    Map<String, dynamic>? varkSettings,
  }) {
    // Apply VARK adaptations to text if provided
    String adaptedText = text;
    if (varkSettings != null) {
      adaptedText = _adaptTextForVARK(text, varkSettings);
    }

    return {
      'model_id': model,
      'transcript': adaptedText,
      'voice': {
        'mode': 'id',
        'id': voiceId,
      },
      'output_format': {
        'container': format,
        'encoding': 'pcm_f32le',
        'sample_rate': 44100,
      },
      'language': defaultLanguage,
      'speed': speed,
    };
  }

  /// Adapt text based on VARK learning preferences
  static String _adaptTextForVARK(
      String text, Map<String, dynamic> varkSettings) {
    String adaptedText = text;

    // Add emphasis to VARK-specific words
    final emphasisWords = varkSettings['emphasis_words'] as List<String>?;
    if (emphasisWords != null) {
      for (final word in emphasisWords) {
        adaptedText = adaptedText.replaceAllMapped(
          RegExp('\\b$word\\b', caseSensitive: false),
          (match) => '<emphasis>${match.group(0)}</emphasis>',
        );
      }
    }

    // Add pauses based on VARK type
    final pauseDuration = varkSettings['pause_duration'] as double?;
    if (pauseDuration != null && pauseDuration > 0.5) {
      adaptedText =
          adaptedText.replaceAll('.', '.<break time="${pauseDuration}s"/>');
    }

    return adaptedText;
  }

  /// Validate API key format
  static bool isValidApiKey(String key) {
    return key.startsWith('sk_car_') && key.length > 20;
  }

  /// Get environment configuration for MCP server
  static Map<String, String> get mcpEnvironment => {
        'CARTESIA_API_KEY': apiKey,
        'OUTPUT_DIRECTORY': '/tmp/cartesia_audio',
        'LOG_LEVEL': kDebugMode ? 'DEBUG' : 'INFO',
      };

  /// Golf-specific coaching prompts for different scenarios
  static const Map<String, String> coachingPrompts = {
    'pre_round': '''
    You're about to start your round. Take a deep breath and visualize success.
    Remember your pre-shot routine and trust your preparation.
    ''',
    'post_shot_good': '''
    Excellent shot! Feel that confidence and carry it to the next hole.
    Your mental focus is paying off.
    ''',
    'post_shot_poor': '''
    That's golf - every shot is a new opportunity. 
    Reset your mindset and focus on the process, not the outcome.
    ''',
    'pressure_situation': '''
    This is where mental training matters most. 
    Slow down your breathing, trust your routine, and commit to your shot.
    ''',
  };

  /// Get coaching prompt by scenario
  static String? getCoachingPrompt(String scenario) {
    return coachingPrompts[scenario];
  }
}
