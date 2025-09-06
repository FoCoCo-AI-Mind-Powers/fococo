import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import '../models/ai_models.dart';

/// Voice configuration for Cartesia TTS
class VoiceConfig {
  final String id;
  final String name;
  final String description;
  final String language;
  final String gender;
  final String style;

  const VoiceConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.gender,
    this.style = 'natural',
  });

  /// Predefined voice configurations optimized for golf coaching
  static const List<VoiceConfig> predefinedVoices = [
    VoiceConfig(
      id: 'coach_male_confident',
      name: 'Coach Marcus',
      description: 'Confident male coach voice',
      language: 'en-US',
      gender: 'male',
    ),
    VoiceConfig(
      id: 'coach_female_encouraging',
      name: 'Coach Sarah',
      description: 'Encouraging female coach voice',
      language: 'en-US',
      gender: 'female',
    ),
    VoiceConfig(
      id: 'mentor_calm',
      name: 'Mentor Alex',
      description: 'Calm and reassuring mentor voice',
      language: 'en-US',
      gender: 'neutral',
    ),
  ];

  static VoiceConfig getDefaultVoice() => predefinedVoices.first;

  static VoiceConfig? getVoiceById(String id) {
    try {
      return predefinedVoices.firstWhere((voice) => voice.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Cartesia TTS Service for high-quality voice synthesis
/// Integrates with FoCoCo's VARK learning preferences
class CartesiaTTSService {
  CartesiaTTSService._();

  static CartesiaTTSService? _instance;
  static CartesiaTTSService get instance =>
      _instance ??= CartesiaTTSService._();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  VoiceConfig _currentVoice = VoiceConfig.getDefaultVoice();

  // Stream controllers for state management
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  Duration _currentPosition = Duration.zero;
  Duration? _duration;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  VoiceConfig get currentVoice => _currentVoice;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Duration get currentPosition => _currentPosition;
  Duration? get duration => _duration;

  /// Initialize the Cartesia TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _configureTTS();
      await _audioPlayer.setLoopMode(LoopMode.off);

      _isInitialized = true;

      if (kDebugMode) {
        print('🎤 Cartesia TTS Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Cartesia TTS: $e');
      }
      _errorController.add('Failed to initialize TTS: $e');
      rethrow;
    }
  }

  /// Configure TTS with optimal settings for golf coaching
  Future<void> _configureTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.7); // Slightly slower for clarity
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.9);

    // Set up completion and error handlers
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingController.add(false);
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('TTS Error: $msg');
      if (kDebugMode) {
        print('❌ TTS Error: $msg');
      }
    });
  }

  /// Generate AI insight with speech optimized for VARK preferences
  Future<AIInsightWithAudioResponse> generateInsightWithSpeech({
    required String insightText,
    required VarkPreferencesStruct varkPreferences,
    VoiceConfig? voiceConfig,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Adapt the text based on VARK preferences
      final adaptedText = _adaptTextForVARK(insightText, varkPreferences);

      // Configure voice based on preferences
      if (voiceConfig != null) {
        await _setVoiceConfig(voiceConfig);
      }

      // Generate audio data (simulated for now - in production would use actual Cartesia API)
      final audioData = await _generateAudioData(adaptedText);

      // Create the response with audio metadata
      final audioMetadata = {
        'audioPath': null, // Would be set after saving to file
        'audioSize': audioData.length,
        'voiceId': _currentVoice.id,
        'generatedAt': DateTime.now().toIso8601String(),
        'varkAdapted': true,
        'originalText': insightText,
        'adaptedText': adaptedText,
      };

      // Create a mock AIInsightResponse for the text part
      final textInsight = AIInsightResponse(
        insightTitle: 'Golf Performance Insight',
        category: 'Performance',
        priority: 'Medium',
        keyPoints: [insightText],
        recommendations: [],
        personalizedElements: ['VARK-adapted content'],
        summaryText: adaptedText,
        timestamp: DateTime.now(),
        model: 'cartesia-tts',
      );

      return AIInsightWithAudioResponse(
        textInsight: textInsight,
        audioData: audioMetadata,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating insight with speech: $e');
      }
      _errorController.add('Failed to generate speech: $e');
      rethrow;
    }
  }

  /// Speak text with VARK-adapted delivery
  Future<void> speakText({
    required String text,
    required VarkPreferencesStruct varkPreferences,
    VoiceConfig? voiceConfig,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      // Adapt text for VARK preferences
      final adaptedText = _adaptTextForVARK(text, varkPreferences);

      // Configure voice if provided
      if (voiceConfig != null) {
        await _setVoiceConfig(voiceConfig);
      }

      _isSpeaking = true;
      _speakingController.add(true);

      await _tts.speak(adaptedText);
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('Failed to speak text: $e');
      if (kDebugMode) {
        print('❌ Error speaking text: $e');
      }
      rethrow;
    }
  }

  /// Stop current speech
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
      _speakingController.add(false);
      _playerStateController.add(PlayerState(false, ProcessingState.idle));
    }
  }

  /// Generate speech audio data
  Future<Uint8List> generateSpeech({
    required String text,
    String? contentType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Adapt text if needed based on content type
      String processedText = text;
      if (contentType == 'insight') {
        processedText = 'Here\'s your golf insight: $text';
      } else if (contentType == 'recommendation') {
        processedText = 'Recommendation: $text';
      }

      // Generate audio data (placeholder for actual Cartesia API)
      final audioData = await _generateAudioData(processedText);

      // Set duration based on text length (rough estimate)
      _duration = Duration(seconds: (text.length / 10).ceil());

      return audioData;
    } catch (e) {
      _errorController.add('Failed to generate speech: $e');
      rethrow;
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    await _tts.pause();
    _playerStateController.add(PlayerState(false, ProcessingState.ready));
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    // Note: FlutterTts doesn't have resume, so we'd need to restart
    _playerStateController.add(PlayerState(true, ProcessingState.ready));
  }

  /// Set voice configuration
  Future<void> _setVoiceConfig(VoiceConfig voiceConfig) async {
    _currentVoice = voiceConfig;

    // Adjust TTS settings based on voice characteristics
    switch (voiceConfig.gender) {
      case 'male':
        await _tts.setPitch(0.9);
        break;
      case 'female':
        await _tts.setPitch(1.1);
        break;
      default:
        await _tts.setPitch(1.0);
    }

    // Adjust speech rate based on voice type
    if (voiceConfig.id.contains('calm') || voiceConfig.id.contains('mentor')) {
      await _tts.setSpeechRate(0.6); // Slower for calm voices
    } else if (voiceConfig.id.contains('confident')) {
      await _tts.setSpeechRate(0.8); // Slightly faster for confident voices
    }
  }

  /// Adapt text content based on VARK learning preferences
  String _adaptTextForVARK(String text, VarkPreferencesStruct varkPreferences) {
    String adaptedText = text;

    if (varkPreferences.visual) {
      // Add visual language
      adaptedText = _addVisualLanguage(adaptedText);
    }

    if (varkPreferences.aural) {
      // Add auditory cues and rhythm
      adaptedText = _addAuditoryLanguage(adaptedText);
    }

    if (varkPreferences.readWrite) {
      // Structure for note-taking
      adaptedText = _addReadWriteStructure(adaptedText);
    }

    if (varkPreferences.kinesthetic) {
      // Add physical and action-oriented language
      adaptedText = _addKinestheticLanguage(adaptedText);
    }

    return adaptedText;
  }

  String _addVisualLanguage(String text) {
    // Add visual metaphors and imagery
    return text
        .replaceAll('focus', 'visualize your focus')
        .replaceAll('improve', 'picture yourself improving')
        .replaceAll('remember', 'see yourself remembering');
  }

  String _addAuditoryLanguage(String text) {
    // Add sound-based language and rhythm
    return text
        .replaceAll('focus', 'listen to your inner focus')
        .replaceAll('breathe', 'hear your breathing rhythm')
        .replaceAll('calm', 'find your quiet sound of calm');
  }

  String _addReadWriteStructure(String text) {
    // Add structure for note-taking
    if (!text.contains('1.') && !text.contains('•')) {
      return 'Key point to remember: $text';
    }
    return text;
  }

  String _addKinestheticLanguage(String text) {
    // Add physical and movement language
    return text
        .replaceAll('focus', 'feel your focus')
        .replaceAll('practice', 'experience this practice')
        .replaceAll('improve', 'sense your improvement');
  }

  /// Generate audio data (placeholder for actual Cartesia API integration)
  Future<Uint8List> _generateAudioData(String text) async {
    // In production, this would call the actual Cartesia API
    // For now, return empty data as placeholder
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate API call
    return Uint8List.fromList([]);
  }

  /// Play audio data
  Future<void> playAudioData(
    Uint8List audioData, {
    VoidCallback? onComplete,
  }) async {
    try {
      _playerStateController.add(PlayerState(true, ProcessingState.ready));
      _currentPosition = Duration.zero;

      // In production, would play the actual audio data
      // For now, simulate playback
      await Future.delayed(const Duration(seconds: 2));

      _playerStateController.add(PlayerState(false, ProcessingState.completed));
      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      _errorController.add('Failed to play audio: $e');
      _playerStateController.add(PlayerState(false, ProcessingState.idle));
      if (kDebugMode) {
        print('❌ Error playing audio: $e');
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    _speakingController.close();
    _errorController.close();
    _playerStateController.close();
    _positionController.close();
    _audioPlayer.dispose();
  }
}
