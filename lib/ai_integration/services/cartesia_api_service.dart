import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '../config/cartesia_mcp_config.dart';

/// Enhanced Cartesia API Service implementing the official API
/// Based on: https://docs.cartesia.ai/get-started/make-an-api-request
/// Uses sonic-2-2025-05-08 model with Pro voice clone
class CartesiaAPIService {
  CartesiaAPIService._();

  static CartesiaAPIService? _instance;
  static CartesiaAPIService get instance =>
      _instance ??= CartesiaAPIService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final http.Client _httpClient = http.Client();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentVoiceId =
      'da3224fe-d8d1-4774-8902-e6a7115f5132'; // Voice 1 (Male) - Default

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
  String get currentVoiceId => _currentVoiceId;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Duration get currentPosition => _currentPosition;
  Duration? get duration => _duration;

  /// Initialize the Cartesia API service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Test API connection
      await _testAPIConnection();

      // Configure audio player
      await _configureAudioPlayer();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Cartesia API Service initialized with sonic-2-2025-05-08');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Cartesia API: $e');
      }
      _errorController.add('Failed to initialize Cartesia API: $e');
      rethrow;
    }
  }

  /// Test API connection with a simple request
  Future<void> _testAPIConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${CartesiaMCPConfig.baseUrl}/voices'),
        headers: CartesiaMCPConfig.apiHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('API connection failed: ${response.statusCode}');
      }

      if (kDebugMode) {
        print('🔗 Cartesia API connection successful');
      }
    } catch (e) {
      throw Exception('Failed to connect to Cartesia API: $e');
    }
  }

  /// Configure audio player with optimal settings
  Future<void> _configureAudioPlayer() async {
    await _audioPlayer.setLoopMode(LoopMode.off);

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _playerStateController.add(state);

      if (state.processingState == ProcessingState.completed) {
        _isSpeaking = false;
        _speakingController.add(false);
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _duration = duration;
    });
  }

  /// Generate speech using Cartesia TTS API
  /// Implements the official API as documented
  Future<List<int>> generateSpeech({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final effectiveVoiceId = voiceId ?? _currentVoiceId;

      // Adapt text for VARK preferences
      final adaptedText = _adaptTextForVARK(text, varkPreferences);

      // Get voice settings based on content type
      final voiceSettings = _getVoiceSettings(contentType, varkPreferences);

      // Convert speed setting to numeric value
      final speedValue = _resolveSpeedValue(
        voiceSettings: voiceSettings,
        voiceProfileKey: voiceProfileKey,
        explicitSpeedMultiplier: speedMultiplier,
      );

      // Prepare request payload matching your curl command format
      final payload = {
        'model_id': CartesiaMCPConfig.defaultVoiceModel,
        'transcript': adaptedText,
        'voice': {
          'mode': 'id',
          'id': effectiveVoiceId,
        },
        'output_format': {
          'container': 'wav',
          'encoding': 'pcm_f32le',
          'sample_rate': 44100,
        },
        'language': CartesiaMCPConfig.defaultLanguage,
        'speed': speedValue, // Dynamic speed based on content type and VARK
      };

      if (kDebugMode) {
        print('🎤 Generating speech with payload: ${json.encode(payload)}');
      }

      // Make API request to TTS bytes endpoint
      final response = await _httpClient.post(
        Uri.parse('${CartesiaMCPConfig.baseUrl}/tts/bytes'),
        headers: CartesiaMCPConfig.apiHeaders,
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'TTS generation failed: ${response.statusCode} - ${response.body}',
        );
      }

      final audioData = response.bodyBytes;

      if (kDebugMode) {
        print('✅ Generated ${audioData.length} bytes of audio');
      }

      return audioData;
    } catch (e) {
      _errorController.add('Failed to generate speech: $e');
      if (kDebugMode) {
        print('❌ Error generating speech: $e');
      }
      rethrow;
    }
  }

  /// Speak text using Cartesia TTS with VARK adaptations
  Future<void> speakText({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
    VoidCallback? onComplete,
  }) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      _speakingController.add(true);

      // Generate audio data
      final audioData = await generateSpeech(
        text: text,
        voiceId: voiceId,
        voiceProfileKey: voiceProfileKey,
        contentType: contentType,
        varkPreferences: varkPreferences,
        speedMultiplier: speedMultiplier,
      );

      // Play the generated audio
      await playAudioData(audioData, onComplete: onComplete);
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('Failed to speak text: $e');
      rethrow;
    }
  }

  /// Play audio data directly
  Future<void> playAudioData(
    List<int> audioData, {
    VoidCallback? onComplete,
  }) async {
    try {
      // Create a temporary audio source from bytes
      final audioSource = _BytesAudioSource(audioData);

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();

      // Set up completion callback
      if (onComplete != null) {
        _audioPlayer.playerStateStream
            .where(
                (state) => state.processingState == ProcessingState.completed)
            .take(1)
            .listen((_) => onComplete());
      }

      if (kDebugMode) {
        print('🔊 Playing generated audio');
      }
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      throw Exception('Failed to play audio: $e');
    }
  }

  Future<void> speakTextAndWait({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
    VoidCallback? onComplete,
  }) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      _speakingController.add(true);

      final audioData = await generateSpeech(
        text: text,
        voiceId: voiceId,
        voiceProfileKey: voiceProfileKey,
        contentType: contentType,
        varkPreferences: varkPreferences,
        speedMultiplier: speedMultiplier,
      );

      await playAudioDataAndWait(audioData, onComplete: onComplete);
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('Failed to speak text: $e');
      rethrow;
    }
  }

  Future<void> playAudioDataAndWait(
    List<int> audioData, {
    VoidCallback? onComplete,
  }) async {
    try {
      final audioSource = _BytesAudioSource(audioData);
      await _audioPlayer.setAudioSource(audioSource);

      final completion = Completer<void>();
      late final StreamSubscription<PlayerState> stateSub;
      stateSub = _audioPlayer.playerStateStream.listen(
        (state) {
          if (state.processingState == ProcessingState.completed &&
              !completion.isCompleted) {
            completion.complete();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completion.isCompleted) {
            completion.completeError(error, stackTrace);
          }
        },
      );

      await _audioPlayer.play();
      if (!completion.isCompleted) {
        await completion.future;
      }
      await stateSub.cancel();
      onComplete?.call();
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Stop current speech
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _speakingController.add(false);
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    if (_isSpeaking) {
      await _audioPlayer.pause();
    }
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    if (!_isSpeaking &&
        _audioPlayer.playerState.processingState == ProcessingState.ready) {
      await _audioPlayer.play();
      _isSpeaking = true;
      _speakingController.add(true);
    }
  }

  /// Set voice ID for subsequent requests
  void setVoiceId(String voiceId) {
    _currentVoiceId = voiceId;
    if (kDebugMode) {
      print('🎭 Voice ID set to: $voiceId');
    }
  }

  double _resolveSpeedValue({
    required Map<String, dynamic> voiceSettings,
    String? voiceProfileKey,
    double? explicitSpeedMultiplier,
  }) {
    if (explicitSpeedMultiplier != null && explicitSpeedMultiplier > 0) {
      return explicitSpeedMultiplier;
    }

    final profile = voiceProfileKey == null
        ? null
        : CartesiaMCPConfig.getVoiceProfile(voiceProfileKey);
    final profileSpeed = profile?['speed_multiplier'];
    if (profileSpeed is num && profileSpeed > 0) {
      return profileSpeed.toDouble();
    }

    switch (voiceSettings['speed']) {
      case 'slow':
        return 0.8;
      case 'fast':
        return 1.2;
      case 'normal':
      default:
        return 1.0;
    }
  }

  /// Adapt text based on VARK learning preferences
  String _adaptTextForVARK(
      String text, VarkPreferencesStruct? varkPreferences) {
    if (varkPreferences == null) return text;

    String adaptedText = text;

    // Visual learners - add visualization cues
    if (varkPreferences.visual) {
      adaptedText = adaptedText.replaceAllMapped(
        RegExp(r'\b(focus|concentrate|aim)\b', caseSensitive: false),
        (match) => 'visualize ${match.group(0)}',
      );
    }

    // Auditory learners - add listening cues
    if (varkPreferences.aural) {
      adaptedText = adaptedText.replaceAllMapped(
        RegExp(r'\b(breathe|rhythm|tempo)\b', caseSensitive: false),
        (match) => 'listen to your ${match.group(0)}',
      );
    }

    // Read/Write learners - add note-taking cues
    if (varkPreferences.readWrite) {
      if (text.length > 100) {
        adaptedText = 'Remember to note this down: $adaptedText';
      }
    }

    // Kinesthetic learners - add physical cues
    if (varkPreferences.kinesthetic) {
      adaptedText = adaptedText.replaceAllMapped(
        RegExp(r'\b(practice|drill|exercise)\b', caseSensitive: false),
        (match) => 'feel the ${match.group(0)}',
      );
    }

    return adaptedText;
  }

  /// Get voice settings based on content type and VARK preferences
  Map<String, dynamic> _getVoiceSettings(
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
  ) {
    Map<String, dynamic> settings = {};

    // Base settings for content type using string values like your curl command
    switch (contentType) {
      case 'coaching':
        settings['speed'] = 'normal';
        break;
      case 'meditation':
        settings['speed'] = 'slow';
        break;
      case 'motivation':
        settings['speed'] = 'fast';
        break;
      case 'instruction':
        settings['speed'] = 'normal';
        break;
      default:
        settings['speed'] = 'normal';
    }

    // VARK adaptations
    if (varkPreferences != null) {
      if (varkPreferences.visual) {
        settings['speed'] = 'normal'; // Normal speed for visualization
      }
      if (varkPreferences.aural) {
        settings['speed'] = 'slow'; // Slightly slower for listening
      }
      if (varkPreferences.readWrite) {
        settings['speed'] = 'slow'; // Slower for note-taking
      }
      if (varkPreferences.kinesthetic) {
        settings['speed'] = 'fast'; // Faster for action
      }
    }

    return settings;
  }

  /// Dispose resources
  void dispose() {
    _speakingController.close();
    _errorController.close();
    _playerStateController.close();
    _positionController.close();
    _audioPlayer.dispose();
    _httpClient.close();
  }
}

/// Custom audio source for playing bytes data
class _BytesAudioSource extends StreamAudioSource {
  final List<int> _audioData;

  _BytesAudioSource(this._audioData);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _audioData.length;

    return StreamAudioResponse(
      sourceLength: _audioData.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(Uint8List.fromList(_audioData.sublist(start, end))),
      contentType: 'audio/wav',
    );
  }
}
