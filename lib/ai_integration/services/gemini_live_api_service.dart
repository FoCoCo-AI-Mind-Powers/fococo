/// Real-time Gemini Live API Service for FoCoCo
/// Based on: https://ai.google.dev/gemini-api/docs/live
/// Implements WebSocket-based real-time voice interactions with Gemini

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import '/backend/schema/structs/vark_preferences_struct.dart';
import '../config/gemini_live_config.dart';
import 'audio_session_service.dart';
import 'permission_service.dart';

/// Gemini Live API Service States
enum GeminiLiveState {
  disconnected,
  connecting,
  connected,
  listening,
  thinking,
  speaking,
  error,
}

/// Audio generation architecture types
enum AudioArchitecture {
  nativeAudio, // Most natural, supports thinking mode
  halfCascade, // Better performance and reliability
}

/// Gemini Live API Configuration
class GeminiLiveConfig {
  final String model;
  final List<String> responseModalities;
  final String systemInstruction;
  final AudioArchitecture audioArchitecture;
  final bool enableThinking;
  final Map<String, dynamic>? tools;
  final bool enableMapsGrounding;
  final Map<String, dynamic>? locationContext;

  const GeminiLiveConfig({
    this.model = 'gemini-2.5-flash-preview-native-audio-dialog',
    this.responseModalities = const ['AUDIO', 'TEXT'],
    this.systemInstruction =
        '''You are FoCoCo's AI golf mental performance coach. 
You help golfers improve their mental game through personalized coaching, 
mindfulness techniques, and performance analysis. Be encouraging, 
knowledgeable about golf psychology, and provide actionable advice. 
Keep responses concise and conversational for voice interactions.''',
    this.audioArchitecture = AudioArchitecture.nativeAudio,
    this.enableThinking = false,
    this.tools,
    this.enableMapsGrounding = false,
    this.locationContext,
  });

  /// Get the appropriate model based on configuration
  String get effectiveModel {
    if (enableThinking && audioArchitecture == AudioArchitecture.nativeAudio) {
      return 'gemini-2.5-flash-exp-native-audio-thinking-dialog';
    }

    switch (audioArchitecture) {
      case AudioArchitecture.nativeAudio:
        return 'gemini-2.5-flash-preview-native-audio-dialog';
      case AudioArchitecture.halfCascade:
        return 'gemini-2.5-flash-native-audio-preview-12-2025';
    }
  }

  Map<String, dynamic> toJson() => {
        'model': effectiveModel,
        'response_modalities': responseModalities,
        'system_instruction': systemInstruction,
        if (tools != null) 'tools': tools,
        if (enableMapsGrounding) 'grounding': {
          'googleMaps': <String, dynamic>{}
        },
      };
}

/// Real-time Gemini Live API Service
class GeminiLiveAPIService {
  static final GeminiLiveAPIService _instance =
      GeminiLiveAPIService._internal();
  factory GeminiLiveAPIService() => _instance;
  GeminiLiveAPIService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;

  // Audio components
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PermissionService _permissionService = PermissionService();

  // State management
  final StreamController<GeminiLiveState> _stateController =
      StreamController<GeminiLiveState>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<String> _responseController =
      StreamController<String>.broadcast();
  final StreamController<Uint8List> _audioDataController =
      StreamController<Uint8List>.broadcast();

  GeminiLiveState _currentState = GeminiLiveState.disconnected;
  GeminiLiveConfig _config = const GeminiLiveConfig();

  // Audio recording state
  bool _isRecording = false;
  Timer? _audioTimer;

  // Session management
  List<Map<String, dynamic>> _conversationHistory = [];
  
  // Maps Grounding location context
  Map<String, dynamic>? _currentLocationContext;

  // Getters
  Stream<GeminiLiveState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get responseStream => _responseController.stream;
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  GeminiLiveState get currentState => _currentState;
  bool get isConnected => _currentState != GeminiLiveState.disconnected;
  bool get isListening => _currentState == GeminiLiveState.listening;
  bool get isThinking => _currentState == GeminiLiveState.thinking;
  bool get isSpeaking => _currentState == GeminiLiveState.speaking;

  /// Initialize the service with configuration
  Future<void> initialize({
    GeminiLiveConfig? config,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    _config = config ?? const GeminiLiveConfig();

    // Adapt system instruction for VARK preferences
    if (varkPreferences != null) {
      _config = GeminiLiveConfig(
        model: _config.model,
        responseModalities: _config.responseModalities,
        systemInstruction: _adaptSystemInstructionForVARK(
            _config.systemInstruction, varkPreferences),
        audioArchitecture: _config.audioArchitecture,
        enableThinking: _config.enableThinking,
        tools: _config.tools,
      );
    }

    // Initialize and request permissions
    await _permissionService.initialize();
    await _requestPermissions();

    if (kDebugMode) {
      print(
          '🎤 Gemini Live API Service initialized with model: ${_config.effectiveModel}');
    }
  }

  /// Connect to Gemini Live API via WebSocket
  Future<void> connect() async {
    if (_currentState != GeminiLiveState.disconnected) {
      if (kDebugMode) {
        print('⚠️ Already connected or connecting');
      }
      return;
    }

    try {
      _updateState(GeminiLiveState.connecting);

      // Raw-key WebSocket path is disabled — see GeminiLiveAPIConfig.
      // Live features should go through FirebaseAI.googleAI().liveModel(...).
      final apiKey = await GeminiLiveAPIConfig.getApiKey();
      if (apiKey.isEmpty) {
        throw Exception(
            'Gemini Live (raw-key) is disabled. Migrate this path to firebase_ai Live bidi.');
      }

      // Connect to Gemini Live API WebSocket
      final uri = Uri.parse(
          '${GeminiLiveAPIConfig.websocketEndpoint}?key=$apiKey');

      _channel = WebSocketChannel.connect(uri);

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      // Send initial setup message
      await _sendSetupMessage();

      _updateState(GeminiLiveState.connected);
      await AudioSessionService.activateVoiceChat();

      if (kDebugMode) {
        print('✅ Connected to Gemini Live API');
      }
    } catch (e) {
      _updateState(GeminiLiveState.error);
      if (kDebugMode) {
        print('❌ Failed to connect to Gemini Live API: $e');
      }
      rethrow;
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!isConnected || _isRecording) return;

    try {
      _updateState(GeminiLiveState.listening);

      // Start audio recording (simplified for now)
      await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;

      // Start streaming audio data
      _startAudioStreaming();

      if (kDebugMode) {
        print('🎤 Started listening');
      }
    } catch (e) {
      _updateState(GeminiLiveState.error);
      if (kDebugMode) {
        print('❌ Failed to start listening: $e');
      }
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _audioTimer?.cancel();

      if (isConnected) {
        _updateState(GeminiLiveState.connected);
      }

      if (kDebugMode) {
        print('🛑 Stopped listening');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping listening: $e');
      }
    }
  }

  /// Send text message
  Future<void> sendTextMessage(String text) async {
    if (!isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      final message = {
        'client_content': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': text}
              ]
            }
          ],
          'turn_complete': true,
        }
      };

      _channel!.sink.add(jsonEncode(message));
      _updateState(GeminiLiveState.thinking);

      if (kDebugMode) {
        print('📤 Sent text message: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send text message: $e');
      }
      rethrow;
    }
  }

  /// Enable or disable thinking mode
  void setThinkingMode(bool enabled) {
    _config = GeminiLiveConfig(
      model: _config.model,
      responseModalities: _config.responseModalities,
      systemInstruction: _config.systemInstruction,
      audioArchitecture: _config.audioArchitecture,
      enableThinking: enabled,
      tools: _config.tools,
    );

    if (kDebugMode) {
      print('🧠 Thinking mode ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Disconnect from the service
  Future<void> disconnect() async {
    try {
      await stopListening();
      await _audioPlayer.stop();
      await AudioSessionService.deactivateVoiceChat();

      _channel?.sink.close(status.goingAway);
      _channel = null;

      _updateState(GeminiLiveState.disconnected);
      _conversationHistory.clear();

      if (kDebugMode) {
        print('🔌 Disconnected from Gemini Live API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during disconnect: $e');
      }
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Request necessary permissions with enhanced handling
  Future<void> _requestPermissions() async {
    try {
      // Check current permission status
      final currentState = await _permissionService.checkMicrophonePermission();

      if (currentState == PermissionServiceState.granted) {
        if (kDebugMode) {
          print('✅ Microphone permission already granted');
        }
        return;
      }

      // Request permission with retry mechanism
      final granted = await _permissionService.requestMicrophoneWithRetry(
        maxRetries: 2,
        retryDelay: const Duration(milliseconds: 500),
      );

      if (!granted) {
        final state = _permissionService.microphoneState;
        final message = _permissionService.getPermissionStatusMessage(state);

        if (kDebugMode) {
          print('⚠️ Microphone permission not granted: $message');
        }

        // Don't throw exception, just log the issue
        // The service can still work in text-only mode
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
      // Don't throw exception to allow text-only functionality
    }
  }

  /// Send initial setup message to configure the session
  Future<void> _sendSetupMessage() async {
    final setupConfig = _config.toJson();
    
    // Add location context to setup if Maps Grounding is enabled
    if (_config.enableMapsGrounding && _currentLocationContext != null) {
      setupConfig['location'] = _currentLocationContext;
    }
    
    final setupMessage = {
      'setup': setupConfig,
    };

    _channel!.sink.add(jsonEncode(setupMessage));

    if (kDebugMode) {
      print('📤 Sent setup message: ${_config.effectiveModel}');
      if (_config.enableMapsGrounding && _currentLocationContext != null) {
        print('📍 Maps Grounding enabled with location context');
      }
    }
  }
  
  /// Update location context for Maps Grounding
  /// Call this during an active session to update location
  void updateLocationContext({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
  }) {
    _currentLocationContext = {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // If connected and Maps Grounding is enabled, send location update
    if (isConnected && _config.enableMapsGrounding && _channel != null) {
      try {
        final locationUpdate = {
          'realtime_input': {
            'location': _currentLocationContext,
          },
        };
        _channel!.sink.add(jsonEncode(locationUpdate));
        
        if (kDebugMode) {
          print('📍 Sent location update: $latitude, $longitude');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error sending location update: $e');
        }
      }
    }
  }
  
  /// Initialize with location context for Maps Grounding
  Future<void> initializeWithLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    GeminiLiveConfig? config,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    _currentLocationContext = {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Enable Maps Grounding if not explicitly disabled
    final finalConfig = config ?? const GeminiLiveConfig();
    final configWithMaps = GeminiLiveConfig(
      model: finalConfig.model,
      responseModalities: finalConfig.responseModalities,
      systemInstruction: finalConfig.systemInstruction,
      audioArchitecture: finalConfig.audioArchitecture,
      enableThinking: finalConfig.enableThinking,
      tools: finalConfig.tools,
      enableMapsGrounding: true,
      locationContext: _currentLocationContext,
    );
    
    await initialize(
      config: configWithMaps,
      varkPreferences: varkPreferences,
    );
  }

  /// Start streaming audio data to the API
  void _startAudioStreaming() {
    _audioTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording || _channel == null) {
        timer.cancel();
        return;
      }

      try {
        // Get audio stream (this is a simplified approach)
        // In a real implementation, you'd need to capture audio chunks
        // and convert them to the proper format (16-bit PCM, 16kHz, mono)

        // For now, we'll use the text-based approach until proper audio streaming is implemented
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error streaming audio: $e');
        }
      }
    });
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      if (data['server_content'] != null) {
        final serverContent = data['server_content'];

        // Handle model turn (AI response)
        if (serverContent['model_turn'] != null) {
          final modelTurn = serverContent['model_turn'];
          final parts = modelTurn['parts'] as List?;

          if (parts != null) {
            for (final part in parts) {
              // Handle text response
              if (part['text'] != null) {
                final responseText = part['text'] as String;
                _responseController.add(responseText);
                _transcriptController.add('AI: $responseText');
              }

              // Handle audio response
              if (part['inline_data'] != null) {
                final inlineData = part['inline_data'];
                if (inlineData['mime_type'] == 'audio/pcm') {
                  final audioData = base64Decode(inlineData['data']);
                  _audioDataController.add(audioData);
                  _playAudioResponse(audioData);
                }
              }
              
              // Handle Maps Grounding responses (function calls, places, navigation)
              if (part['function_call'] != null && _config.enableMapsGrounding) {
                final functionCall = part['function_call'];
                if (kDebugMode) {
                  print('🗺️ Maps Grounding function call: ${functionCall['name']}');
                }
                // Function calls from Maps Grounding can be processed here
                // For example: get_place_details, search_nearby, get_directions, etc.
              }
              
              // Handle grounding metadata (places, routes, etc.)
              if (part['grounding_metadata'] != null && _config.enableMapsGrounding) {
                final groundingMeta = part['grounding_metadata'];
                if (kDebugMode) {
                  print('🗺️ Maps Grounding metadata received');
                  if (groundingMeta['search_entry_point'] != null) {
                    print('   Search entry point: ${groundingMeta['search_entry_point']}');
                  }
                  if (groundingMeta['grounding_chunks'] != null) {
                    print('   Grounding chunks: ${groundingMeta['grounding_chunks'].length}');
                  }
                }
              }
            }
          }

          // Check if turn is complete
          if (serverContent['turn_complete'] == true) {
            _updateState(GeminiLiveState.connected);
          }
        }

        // Handle thinking process (if enabled)
        if (serverContent['thinking'] != null) {
          _updateState(GeminiLiveState.thinking);
        }
      }

      if (kDebugMode) {
        print('📥 Received WebSocket message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling WebSocket message: $e');
      }
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    _updateState(GeminiLiveState.error);
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
  }

  /// Handle WebSocket close
  void _handleWebSocketClose() {
    _updateState(GeminiLiveState.disconnected);
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }
  }

  /// Play audio response
  Future<void> _playAudioResponse(Uint8List audioData) async {
    try {
      _updateState(GeminiLiveState.speaking);

      // Convert PCM data to playable format and play
      // This is a simplified approach - in production you'd need proper audio conversion

      await Future.delayed(
          const Duration(seconds: 2)); // Simulate audio playback

      if (_currentState == GeminiLiveState.speaking) {
        _updateState(GeminiLiveState.connected);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing audio response: $e');
      }
    }
  }

  /// Update service state and notify listeners
  void _updateState(GeminiLiveState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);

      if (kDebugMode) {
        print('🔄 State changed to: $newState');
      }
    }
  }

  /// Adapt system instruction for VARK learning preferences
  String _adaptSystemInstructionForVARK(
      String baseInstruction, VarkPreferencesStruct varkPrefs) {
    final buffer = StringBuffer(baseInstruction);

    buffer.writeln(
        '\n\nAdapt your responses for this user\'s learning preferences:');

    if (varkPrefs.visual) {
      buffer.writeln(
          '- Visual learner: Use descriptive imagery, visualization techniques, and spatial metaphors');
    }
    if (varkPrefs.aural) {
      buffer.writeln(
          '- Auditory learner: Use verbal cues, rhythmic patterns, and sound-based techniques');
    }
    if (varkPrefs.readWrite) {
      buffer.writeln(
          '- Read/Write learner: Provide structured information, lists, and written exercises');
    }
    if (varkPrefs.kinesthetic) {
      buffer.writeln(
          '- Kinesthetic learner: Focus on physical sensations, movement, and hands-on practice');
    }

    return buffer.toString();
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _stateController.close();
    _transcriptController.close();
    _responseController.close();
    _audioDataController.close();
  }
}
