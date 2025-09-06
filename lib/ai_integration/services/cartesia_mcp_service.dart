import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '../config/cartesia_mcp_config.dart';
import '../models/ai_models.dart';

/// Enhanced Cartesia service with MCP (Model Context Protocol) integration
/// Provides high-quality TTS with VARK learning adaptations for golf coaching
class CartesiaMCPService {
  CartesiaMCPService._();

  static CartesiaMCPService? _instance;
  static CartesiaMCPService get instance =>
      _instance ??= CartesiaMCPService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentVoiceProfile = 'coach_confident';

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
  String get currentVoiceProfile => _currentVoiceProfile;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Duration get currentPosition => _currentPosition;
  Duration? get duration => _duration;

  /// Initialize the Cartesia MCP service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Validate API key
      if (!CartesiaMCPConfig.isValidApiKey(CartesiaMCPConfig.apiKey)) {
        throw Exception('Invalid Cartesia API key format');
      }

      // Initialize audio player
      await _configureAudioPlayer();

      // Test API connection
      await _testApiConnection();

      _isInitialized = true;

      if (kDebugMode) {
        print('🎤 Cartesia MCP Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Cartesia MCP: $e');
      }
      _errorController.add('Failed to initialize Cartesia MCP: $e');
      rethrow;
    }
  }

  /// Configure audio player with optimal settings
  Future<void> _configureAudioPlayer() async {
    await _audioPlayer.setLoopMode(LoopMode.off);

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _playerStateController.add(state);

      switch (state.processingState) {
        case ProcessingState.completed:
          _isSpeaking = false;
          _speakingController.add(false);
          break;
        case ProcessingState.ready:
          if (state.playing) {
            _isSpeaking = true;
            _speakingController.add(true);
          }
          break;
        default:
          break;
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

  /// Test API connection to Cartesia
  Future<void> _testApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${CartesiaMCPConfig.baseUrl}/voices'),
        headers: CartesiaMCPConfig.apiHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('API connection failed: ${response.statusCode}');
      }

      if (kDebugMode) {
        print('✅ Cartesia API connection successful');
      }
    } catch (e) {
      throw Exception('Failed to connect to Cartesia API: $e');
    }
  }

  /// Generate AI insight with speech using Cartesia MCP
  Future<AIInsightWithAudioResponse> generateInsightWithSpeech({
    required String insightText,
    required VarkPreferencesStruct varkPreferences,
    String? voiceProfile,
    String? contentType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Select appropriate voice profile
      final profileId =
          voiceProfile ?? _selectVoiceProfileForVARK(varkPreferences);
      final profile = CartesiaMCPConfig.getVoiceProfile(profileId);

      if (profile == null) {
        throw Exception('Voice profile not found: $profileId');
      }

      // Get VARK-specific settings
      final varkType = _getDominantVarkType(varkPreferences);
      final varkSettings = CartesiaMCPConfig.getVarkSettings(varkType);

      // Adapt text for golf coaching context
      final adaptedText = _adaptTextForGolfCoaching(insightText, contentType);

      // Generate TTS payload
      final payload = CartesiaMCPConfig.generateTTSPayload(
        text: adaptedText,
        voiceId: profile['voice_id'],
        model: profile['model'],
        speed: profile['speed'],
        varkSettings: varkSettings,
      );

      // Make API request to Cartesia
      final audioData = await _generateSpeechAPI(payload);

      // Create audio metadata
      final audioMetadata = {
        'audioPath': null, // Will be set after saving to file
        'audioSize': audioData.length,
        'voiceId': profile['voice_id'],
        'voiceProfile': profileId,
        'generatedAt': DateTime.now().toIso8601String(),
        'varkAdapted': true,
        'varkType': varkType,
        'originalText': insightText,
        'adaptedText': adaptedText,
        'model': profile['model'],
      };

      // Create mock AIInsightResponse for the text part
      final textInsight = AIInsightResponse(
        insightTitle: 'Golf Performance Insight',
        category: contentType ?? 'Performance',
        priority: 'Medium',
        keyPoints: [insightText],
        recommendations: [],
        personalizedElements: ['VARK-adapted content', 'Cartesia TTS'],
        summaryText: adaptedText,
        timestamp: DateTime.now(),
        model: 'cartesia-mcp-${profile['model']}',
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

  /// Generate speech using Cartesia API
  Future<Uint8List> _generateSpeechAPI(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('${CartesiaMCPConfig.baseUrl}/tts/bytes'),
        headers: CartesiaMCPConfig.apiHeaders,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
            'TTS API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate speech: $e');
    }
  }

  /// Speak text with VARK-adapted delivery using Cartesia
  Future<void> speakText({
    required String text,
    required VarkPreferencesStruct varkPreferences,
    String? voiceProfile,
    String? contentType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      // Generate audio with Cartesia
      final insightWithAudio = await generateInsightWithSpeech(
        insightText: text,
        varkPreferences: varkPreferences,
        voiceProfile: voiceProfile,
        contentType: contentType,
      );

      // Play the generated audio
      if (insightWithAudio.hasAudio) {
        // In a real implementation, you would save the audio data to a file
        // and play it. For now, we'll simulate this.
        await _simulateAudioPlayback(text);
      }
    } catch (e) {
      _errorController.add('Failed to speak text: $e');
      if (kDebugMode) {
        print('❌ Error speaking text: $e');
      }
      rethrow;
    }
  }

  /// Simulate audio playback (replace with actual file playback in production)
  Future<void> _simulateAudioPlayback(String text) async {
    _isSpeaking = true;
    _speakingController.add(true);
    _playerStateController.add(PlayerState(false, ProcessingState.ready));

    // Simulate playback duration based on text length
    final duration = Duration(seconds: (text.length / 15).ceil());
    _duration = duration;

    // Simulate position updates
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentPosition < duration) {
        _currentPosition = Duration(
          milliseconds: _currentPosition.inMilliseconds + 100,
        );
        _positionController.add(_currentPosition);
      } else {
        timer.cancel();
        _isSpeaking = false;
        _speakingController.add(false);
        _playerStateController
            .add(PlayerState(false, ProcessingState.completed));
        _currentPosition = Duration.zero;
      }
    });
  }

  /// Select appropriate voice profile based on VARK preferences
  String _selectVoiceProfileForVARK(VarkPreferencesStruct varkPreferences) {
    if (varkPreferences.aural) {
      return 'coach_encouraging'; // Warm, supportive voice for auditory learners
    } else if (varkPreferences.kinesthetic) {
      return 'coach_confident'; // Energetic, action-oriented voice
    } else {
      return 'mentor_calm'; // Calm, measured voice for visual/read-write learners
    }
  }

  /// Get dominant VARK type
  String _getDominantVarkType(VarkPreferencesStruct varkPreferences) {
    if (varkPreferences.visual) return 'visual';
    if (varkPreferences.aural) return 'aural';
    if (varkPreferences.readWrite) return 'readWrite';
    if (varkPreferences.kinesthetic) return 'kinesthetic';
    return 'aural'; // Default to auditory
  }

  /// Adapt text for golf coaching context
  String _adaptTextForGolfCoaching(String text, String? contentType) {
    String adaptedText = text;

    // Add golf-specific context based on content type
    switch (contentType?.toLowerCase()) {
      case 'insight':
        adaptedText =
            'Here\'s an important insight about your golf game: $text';
        break;
      case 'recommendation':
        adaptedText = 'I recommend focusing on this: $text';
        break;
      case 'encouragement':
        adaptedText = 'Remember: $text Keep up the great work!';
        break;
      case 'technique':
        adaptedText = 'Let\'s work on your technique: $text';
        break;
      default:
        adaptedText = text;
    }

    return adaptedText;
  }

  /// Stop current speech
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _speakingController.add(false);
      _playerStateController.add(PlayerState(false, ProcessingState.idle));
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    if (_isSpeaking) {
      await _audioPlayer.pause();
      _playerStateController.add(PlayerState(false, ProcessingState.ready));
    }
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    if (!_isSpeaking && _audioPlayer.processingState == ProcessingState.ready) {
      await _audioPlayer.play();
      _playerStateController.add(PlayerState(true, ProcessingState.ready));
    }
  }

  /// Set voice profile
  void setVoiceProfile(String profileId) {
    if (CartesiaMCPConfig.getVoiceProfile(profileId) != null) {
      _currentVoiceProfile = profileId;
    }
  }

  /// Get available voice profiles
  List<String> getAvailableVoiceProfiles() {
    return CartesiaMCPConfig.voiceProfiles.keys.toList();
  }

  /// Generate coaching audio for specific scenarios
  Future<void> speakCoachingPrompt({
    required String scenario,
    required VarkPreferencesStruct varkPreferences,
  }) async {
    final prompt = CartesiaMCPConfig.getCoachingPrompt(scenario);
    if (prompt != null) {
      await speakText(
        text: prompt,
        varkPreferences: varkPreferences,
        contentType: 'coaching',
      );
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
