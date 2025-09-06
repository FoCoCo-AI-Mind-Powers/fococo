import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '../config/cartesia_mcp_config.dart';
import 'cartesia_mcp_service.dart';
import 'gemini_voice_service.dart';

/// LiveKit integration service that combines Cartesia TTS with Gemini AI
/// Based on https://github.com/livekit-examples/cartesia-voice-agent
class LiveKitCartesiaService {
  LiveKitCartesiaService._();

  static LiveKitCartesiaService? _instance;
  static LiveKitCartesiaService get instance =>
      _instance ??= LiveKitCartesiaService._();

  final CartesiaMCPService _cartesiaService = CartesiaMCPService.instance;
  final GeminiVoiceService _geminiService = GeminiVoiceService();

  bool _isInitialized = false;
  bool _useCartesiaForTTS = true; // Toggle between Cartesia and Gemini TTS
  String _currentRoom = '';

  // Stream controllers for LiveKit integration
  final StreamController<Map<String, dynamic>> _roomEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<VoiceServiceState> _stateController =
      StreamController<VoiceServiceState>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get useCartesiaForTTS => _useCartesiaForTTS;
  String get currentRoom => _currentRoom;
  Stream<Map<String, dynamic>> get roomEventStream =>
      _roomEventController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<VoiceServiceState> get stateStream => _stateController.stream;

  /// Initialize the LiveKit Cartesia service
  Future<void> initialize({
    String? liveKitUrl,
    String? liveKitToken,
  }) async {
    if (_isInitialized) return;

    try {
      // Initialize both services
      await _cartesiaService.initialize();
      await _geminiService.initialize();

      // Set up LiveKit configuration (simulated for Flutter)
      await _configureLiveKit(liveKitUrl, liveKitToken);

      _isInitialized = true;
      _stateController.add(VoiceServiceState.ready);

      if (kDebugMode) {
        print('🎥 LiveKit Cartesia Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing LiveKit Cartesia: $e');
      }
      _stateController.add(VoiceServiceState.error);
      rethrow;
    }
  }

  /// Configure LiveKit settings (simulated for Flutter implementation)
  Future<void> _configureLiveKit(String? url, String? token) async {
    // In a real implementation, this would configure the LiveKit client
    // For now, we'll simulate the configuration

    final config = {
      'url': url ?? 'wss://fococo-livekit.livekit.cloud',
      'token': token ?? 'generated-jwt-token',
      'room': 'fococo-voice-room',
      'participant': 'golf-coach-ai',
      'audio': {
        'enabled': true,
        'codec': 'opus',
        'bitrate': 64000,
      },
      'video': {
        'enabled': false, // Audio-only for voice coaching
      },
    };

    if (kDebugMode) {
      print('🔧 LiveKit configured: ${jsonEncode(config)}');
    }
  }

  /// Start a voice coaching session with LiveKit
  Future<void> startVoiceSession({
    required String roomName,
    required VarkPreferencesStruct varkPreferences,
    String? participantName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _currentRoom = roomName;
      _stateController.add(VoiceServiceState.ready);

      // Simulate joining LiveKit room
      await _joinRoom(roomName, participantName ?? 'golfer');

      // Start listening for voice input
      await _startVoiceListening(varkPreferences);

      // Send welcome message
      await _sendWelcomeMessage(varkPreferences);

      _stateController.add(VoiceServiceState.ready);

      if (kDebugMode) {
        print('🎤 Voice session started in room: $roomName');
      }
    } catch (e) {
      _stateController.add(VoiceServiceState.error);
      if (kDebugMode) {
        print('❌ Error starting voice session: $e');
      }
      rethrow;
    }
  }

  /// Join LiveKit room (simulated)
  Future<void> _joinRoom(String roomName, String participantName) async {
    // Simulate room joining
    await Future.delayed(const Duration(milliseconds: 500));

    final roomEvent = {
      'type': 'room_joined',
      'room': roomName,
      'participant': participantName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _roomEventController.add(roomEvent);
  }

  /// Start voice listening with both Gemini and Cartesia
  Future<void> _startVoiceListening(
      VarkPreferencesStruct varkPreferences) async {
    try {
      // Use Gemini for speech recognition and AI processing
      await _geminiService.startListening();

      // Listen to Gemini's voice messages and process with Cartesia TTS
      _geminiService.stateStream.listen((state) {
        _stateController.add(state);
      });

      // Process transcriptions
      _geminiService.transcriptStream.listen((transcript) {
        _transcriptionController.add(transcript);
        _processVoiceInput(transcript, varkPreferences);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting voice listening: $e');
      }
      rethrow;
    }
  }

  /// Process voice input and generate response
  Future<void> _processVoiceInput(
    String transcript,
    VarkPreferencesStruct varkPreferences,
  ) async {
    try {
      _stateController.add(VoiceServiceState.thinking);

      // Generate AI response using Gemini
      final aiResponse = await _generateGolfCoachingResponse(transcript);

      // Generate speech using Cartesia or Gemini based on preference
      if (_useCartesiaForTTS) {
        await _cartesiaService.speakText(
          text: aiResponse,
          varkPreferences: varkPreferences,
          contentType: 'coaching',
        );
      } else {
        // Use Gemini TTS as fallback
        // Use Gemini TTS as fallback - temporarily disabled until interface is clarified
        // await _geminiService.processVoiceMessage(
        //   message: aiResponse,
        //   type: VoiceInteractionType.quickChat,
        // );
        print('Gemini TTS fallback: $aiResponse');
      }

      // Broadcast the interaction
      _broadcastVoiceInteraction(transcript, aiResponse);
    } catch (e) {
      _stateController.add(VoiceServiceState.error);
      if (kDebugMode) {
        print('❌ Error processing voice input: $e');
      }
    }
  }

  /// Generate golf coaching response (enhanced with context)
  Future<String> _generateGolfCoachingResponse(String userInput) async {
    // This would integrate with your existing AI services
    // For now, providing contextual golf coaching responses

    final inputLower = userInput.toLowerCase();

    if (inputLower.contains('nervous') || inputLower.contains('pressure')) {
      return CartesiaMCPConfig.getCoachingPrompt('pressure_situation') ??
          'Take a deep breath and trust your preparation. You\'ve got this!';
    } else if (inputLower.contains('good shot') ||
        inputLower.contains('great')) {
      return CartesiaMCPConfig.getCoachingPrompt('post_shot_good') ??
          'Excellent! That\'s the confidence I want to see. Keep that feeling going.';
    } else if (inputLower.contains('bad shot') ||
        inputLower.contains('mistake')) {
      return CartesiaMCPConfig.getCoachingPrompt('post_shot_poor') ??
          'Every shot is a learning opportunity. Reset and focus on the next one.';
    } else if (inputLower.contains('start') || inputLower.contains('begin')) {
      return CartesiaMCPConfig.getCoachingPrompt('pre_round') ??
          'Let\'s get your mind ready for a great round. Visualize success and trust your swing.';
    } else {
      return 'I hear you. Let\'s work on that together. What specific aspect would you like to focus on?';
    }
  }

  /// Send welcome message when session starts
  Future<void> _sendWelcomeMessage(
      VarkPreferencesStruct varkPreferences) async {
    const welcomeText = '''
    Welcome to your FoCoCo mental performance coaching session! 
    I'm here to help you develop the mental skills that will transform your golf game.
    What would you like to work on today?
    ''';

    if (_useCartesiaForTTS) {
      await _cartesiaService.speakText(
        text: welcomeText,
        varkPreferences: varkPreferences,
        contentType: 'welcome',
      );
    }
  }

  /// Broadcast voice interaction to room participants
  void _broadcastVoiceInteraction(String userInput, String aiResponse) {
    final interaction = {
      'type': 'voice_interaction',
      'user_input': userInput,
      'ai_response': aiResponse,
      'timestamp': DateTime.now().toIso8601String(),
      'room': _currentRoom,
      'tts_provider': _useCartesiaForTTS ? 'cartesia' : 'gemini',
    };

    _roomEventController.add(interaction);
  }

  /// Toggle between Cartesia and Gemini TTS
  void toggleTTSProvider() {
    _useCartesiaForTTS = !_useCartesiaForTTS;

    if (kDebugMode) {
      print(
          '🔄 TTS Provider switched to: ${_useCartesiaForTTS ? "Cartesia" : "Gemini"}');
    }
  }

  /// Stop voice listening
  Future<void> stopListening() async {
    await _geminiService.stopListening();
    await _cartesiaService.stopSpeaking();
    _stateController.add(VoiceServiceState.ready);
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    if (_currentRoom.isNotEmpty) {
      await stopListening();

      final roomEvent = {
        'type': 'room_left',
        'room': _currentRoom,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _roomEventController.add(roomEvent);
      _currentRoom = '';
      _stateController.add(VoiceServiceState.ready);
    }
  }

  /// Get room statistics
  Map<String, dynamic> getRoomStats() {
    return {
      'current_room': _currentRoom,
      'is_initialized': _isInitialized,
      'tts_provider': _useCartesiaForTTS ? 'cartesia' : 'gemini',
      'cartesia_initialized': _cartesiaService.isInitialized,
      'gemini_initialized': true, // Assuming Gemini is always available
    };
  }

  /// Process coaching scenario with appropriate voice response
  Future<void> processCoachingScenario({
    required String scenario,
    required VarkPreferencesStruct varkPreferences,
    Map<String, dynamic>? context,
  }) async {
    try {
      _stateController.add(VoiceServiceState.thinking);

      // Get scenario-specific coaching prompt
      String? prompt = CartesiaMCPConfig.getCoachingPrompt(scenario);

      // Enhance with context if provided
      if (context != null && prompt != null) {
        prompt = _enhancePromptWithContext(prompt, context);
      }

      if (prompt != null) {
        if (_useCartesiaForTTS) {
          await _cartesiaService.speakText(
            text: prompt,
            varkPreferences: varkPreferences,
            contentType: 'coaching',
          );
        }

        // Broadcast the coaching interaction
        _broadcastVoiceInteraction(scenario, prompt);
      }
    } catch (e) {
      _stateController.add(VoiceServiceState.error);
      if (kDebugMode) {
        print('❌ Error processing coaching scenario: $e');
      }
    }
  }

  /// Enhance coaching prompt with contextual information
  String _enhancePromptWithContext(
      String prompt, Map<String, dynamic> context) {
    String enhancedPrompt = prompt;

    // Add hole-specific context
    if (context.containsKey('hole_number')) {
      enhancedPrompt = 'On hole ${context['hole_number']}: $enhancedPrompt';
    }

    // Add score context
    if (context.containsKey('current_score')) {
      final score = context['current_score'];
      enhancedPrompt +=
          ' Remember, you\'re at $score right now - stay focused on the process.';
    }

    // Add weather context
    if (context.containsKey('weather')) {
      enhancedPrompt +=
          ' With these ${context['weather']} conditions, trust your adjustments.';
    }

    return enhancedPrompt;
  }

  /// Dispose of resources
  void dispose() {
    _roomEventController.close();
    _transcriptionController.close();
    _stateController.close();
    _cartesiaService.dispose();
  }
}
