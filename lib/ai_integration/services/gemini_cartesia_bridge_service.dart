import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:record/record.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '../config/gemini_live_config.dart';
import '../services/gemini_live_api_service.dart';
import 'cartesia_api_service.dart';
import 'permission_service.dart';
import 'ai_memory_service.dart';

/// Bridge service connecting Gemini Live API for transcription/AI with Cartesia for TTS
/// Provides seamless voice interaction using best-in-class services for each component
class GeminiCartesiaBridgeService {
  static final GeminiCartesiaBridgeService _instance =
      GeminiCartesiaBridgeService._internal();
  factory GeminiCartesiaBridgeService() => _instance;
  GeminiCartesiaBridgeService._internal();

  // Service dependencies
  final CartesiaAPIService _cartesiaService = CartesiaAPIService.instance;
  final PermissionService _permissionService = PermissionService();
  final AIMemoryService _memoryService = AIMemoryService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // WebSocket connection to Gemini Live API
  WebSocketChannel? _channel;

  // State management
  final StreamController<BridgeState> _stateController =
      StreamController<BridgeState>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<String> _responseController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  BridgeState _currentState = BridgeState.disconnected;
  GeminiLiveConfig _config = const GeminiLiveConfig();
  VarkPreferencesStruct? _varkPreferences;

  // Audio recording state
  bool _isRecording = false;
  Timer? _audioTimer;
  List<Map<String, dynamic>> _conversationHistory = [];

  // Getters
  Stream<BridgeState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get responseStream => _responseController.stream;
  Stream<String> get errorStream => _errorController.stream;
  BridgeState get currentState => _currentState;
  bool get isConnected => _currentState != BridgeState.disconnected;
  bool get isListening => _currentState == BridgeState.listening;

  /// Initialize the bridge service
  Future<void> initialize({
    GeminiLiveConfig? config,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    try {
      _config = config ?? const GeminiLiveConfig();
      _varkPreferences = varkPreferences;

      // Initialize dependencies
      await _cartesiaService.initialize();
      await _permissionService.initialize();
      await _memoryService.initialize();

      // Request microphone permission
      await _requestPermissions();

      if (kDebugMode) {
        print('✅ Gemini-Cartesia Bridge Service initialized');
      }
    } catch (e) {
      _updateState(BridgeState.error);
      _errorController.add('Failed to initialize bridge service: $e');
      rethrow;
    }
  }

  /// Connect to Gemini Live API
  Future<void> connect() async {
    if (_currentState == BridgeState.connected) return;

    try {
      _updateState(BridgeState.connecting);

      if (!GeminiLiveAPIConfig.isConfigured) {
        throw Exception('Gemini API key not configured');
      }

      // Build WebSocket URL with API key
      final uri = Uri.parse(
        '${GeminiLiveAPIConfig.websocketEndpoint}?key=${GeminiLiveAPIConfig.apiKey}',
      );

      _channel = WebSocketChannel.connect(uri);

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClosed,
      );

      // Send initial setup message
      await _sendSetupMessage();

      _updateState(BridgeState.connected);

      if (kDebugMode) {
        print('🔗 Connected to Gemini Live API');
      }
    } catch (e) {
      _updateState(BridgeState.error);
      _errorController.add('Failed to connect to Gemini Live API: $e');
      if (kDebugMode) {
        print('❌ Connection error: $e');
      }
    }
  }

  /// Disconnect from Gemini Live API
  Future<void> disconnect() async {
    if (_currentState == BridgeState.disconnected) return;

    try {
      if (_isRecording) {
        await stopListening();
      }

      await _channel?.sink.close(status.normalClosure);
      _channel = null;

      _updateState(BridgeState.disconnected);

      if (kDebugMode) {
        print('🔌 Disconnected from Gemini Live API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error during disconnect: $e');
      }
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!isConnected || _isRecording) return;

    try {
      _updateState(BridgeState.listening);

      // Check microphone permission
      final hasPermission =
          await _permissionService.checkMicrophonePermission();
      if (hasPermission != PermissionServiceState.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Start audio recording
      await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;

      // Start sending audio data periodically
      _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _sendAudioData();
      });

      if (kDebugMode) {
        print('🎤 Started listening for voice input');
      }
    } catch (e) {
      _updateState(BridgeState.error);
      _errorController.add('Failed to start listening: $e');
      if (kDebugMode) {
        print('❌ Error starting listening: $e');
      }
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isRecording) return;

    try {
      _audioTimer?.cancel();
      _audioTimer = null;

      await _audioRecorder.stop();
      _isRecording = false;

      // Send end of audio message
      await _sendEndAudioMessage();

      _updateState(BridgeState.connected);

      if (kDebugMode) {
        print('🛑 Stopped listening for voice input');
      }
    } catch (e) {
      _errorController.add('Failed to stop listening: $e');
      if (kDebugMode) {
        print('❌ Error stopping listening: $e');
      }
    }
  }

  /// Send text message directly to Gemini
  Future<void> sendTextMessage(String message) async {
    if (!isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      final textMessage = {
        'client_content': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': message}
              ]
            }
          ],
          'turn_complete': true,
        }
      };

      _channel!.sink.add(json.encode(textMessage));

      // Add to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('📤 Sent text message: $message');
      }
    } catch (e) {
      _errorController.add('Failed to send text message: $e');
      rethrow;
    }
  }

  /// Set thinking mode for deeper analysis
  void setThinkingMode(bool enabled) {
    if (enabled) {
      _config = GeminiLiveConfig(
        model: 'gemini-2.5-flash-exp-native-audio-thinking-dialog',
        systemInstruction: _config.systemInstruction,
        enableThinking: true,
        audioArchitecture: AudioArchitecture.nativeAudio,
      );
    } else {
      _config = GeminiLiveConfig(
        model: 'gemini-2.5-flash-preview-native-audio-dialog',
        systemInstruction: _config.systemInstruction,
        enableThinking: false,
        audioArchitecture: AudioArchitecture.nativeAudio,
      );
    }

    if (kDebugMode) {
      print('🧠 Thinking mode ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Update VARK preferences for TTS adaptation
  void updateVarkPreferences(VarkPreferencesStruct varkPreferences) {
    _varkPreferences = varkPreferences;
    if (kDebugMode) {
      print('🎯 Updated VARK preferences');
    }
  }

  /// Send initial setup message to Gemini Live API
  Future<void> _sendSetupMessage() async {
    final setupMessage = {
      'setup': {
        'model': _config.effectiveModel,
        'generation_config': {
          'response_modalities': _config.responseModalities,
          'speech_config': {
            'voice_config': {
              'prebuilt_voice_config': {
                'voice_name': 'Aoede', // Gemini's voice for transcription only
              }
            }
          }
        },
        'system_instruction': {
          'parts': [
            {'text': _config.systemInstruction}
          ]
        }
      }
    };

    _channel!.sink.add(json.encode(setupMessage));

    if (kDebugMode) {
      print('⚙️ Sent setup message to Gemini Live API');
    }
  }

  /// Handle WebSocket messages from Gemini Live API
  void _handleWebSocketMessage(dynamic message) async {
    try {
      final data = json.decode(message as String);

      if (data['setupComplete'] != null) {
        if (kDebugMode) {
          print('✅ Gemini Live API setup complete');
        }
        return;
      }

      if (data['serverContent'] != null) {
        await _handleServerContent(data['serverContent']);
      }
    } catch (e) {
      _errorController.add('Error processing WebSocket message: $e');
      if (kDebugMode) {
        print('❌ WebSocket message error: $e');
      }
    }
  }

  /// Handle server content from Gemini Live API
  Future<void> _handleServerContent(Map<String, dynamic> serverContent) async {
    try {
      if (serverContent['modelTurn'] != null) {
        final modelTurn = serverContent['modelTurn'];

        if (modelTurn['parts'] != null) {
          for (final part in modelTurn['parts']) {
            if (part['text'] != null) {
              final responseText = part['text'] as String;

              // Emit the transcript
              _transcriptController.add(responseText);
              _responseController.add(responseText);

              // Add to conversation history
              _conversationHistory.add({
                'role': 'assistant',
                'content': responseText,
                'timestamp': DateTime.now().toIso8601String(),
              });

              // Store in AI memory for learning
              await _memoryService.addConversationTurn(
                userMessage: _conversationHistory.isNotEmpty
                    ? _conversationHistory.last['content'] ?? ''
                    : '',
                aiResponse: responseText,
                messageType: 'voice',
              );

              // Generate speech using Cartesia with VARK adaptations
              await _generateAndPlaySpeech(responseText);

              if (kDebugMode) {
                print('📝 Received response: $responseText');
              }
            }
          }
        }
      }

      if (serverContent['turnComplete'] != null &&
          serverContent['turnComplete']) {
        _updateState(BridgeState.connected);
      }
    } catch (e) {
      _errorController.add('Error handling server content: $e');
      if (kDebugMode) {
        print('❌ Server content error: $e');
      }
    }
  }

  /// Generate and play speech using Cartesia TTS
  Future<void> _generateAndPlaySpeech(String text) async {
    try {
      _updateState(BridgeState.speaking);

      await _cartesiaService.speakText(
        text: text,
        contentType: 'coaching',
        varkPreferences: _varkPreferences,
        onComplete: () {
          _updateState(BridgeState.connected);
        },
      );
    } catch (e) {
      _errorController.add('Failed to generate speech: $e');
      _updateState(BridgeState.connected);
      if (kDebugMode) {
        print('❌ TTS error: $e');
      }
    }
  }

  /// Send audio data to Gemini Live API
  Future<void> _sendAudioData() async {
    try {
      // This is a placeholder - in a real implementation, you would
      // capture audio chunks and send them to Gemini Live API
      // For now, we'll use the existing audio recording mechanism

      if (_isRecording && _channel != null) {
        // Audio data would be sent here in real-time
        // The actual implementation would depend on the audio recording setup
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error sending audio data: $e');
      }
    }
  }

  /// Send end of audio message
  Future<void> _sendEndAudioMessage() async {
    try {
      final endMessage = {
        'client_content': {
          'turn_complete': true,
        }
      };

      _channel!.sink.add(json.encode(endMessage));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error sending end audio message: $e');
      }
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(dynamic error) {
    _updateState(BridgeState.error);
    _errorController.add('WebSocket error: $error');
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
  }

  /// Handle WebSocket connection closed
  void _handleWebSocketClosed() {
    _updateState(BridgeState.disconnected);
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    try {
      final micPermission =
          await _permissionService.requestMicrophoneWithRetry();
      if (!micPermission) {
        throw Exception('Microphone permission is required for voice features');
      }
    } catch (e) {
      throw Exception('Failed to obtain required permissions: $e');
    }
  }

  /// Update service state
  void _updateState(BridgeState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      if (kDebugMode) {
        print('🔄 Bridge service state: $newState');
      }
    }
  }

  /// Get conversation context for AI memory
  String getConversationContext({int maxTurns = 5}) {
    if (_conversationHistory.isEmpty) return '';

    final recentTurns = _conversationHistory
        .take(maxTurns * 2) // User + AI pairs
        .map((turn) => '${turn['role']}: ${turn['content']}')
        .join('\n');

    return recentTurns;
  }

  /// Clear conversation history
  void clearConversation() {
    _conversationHistory.clear();
    if (kDebugMode) {
      print('🗑️ Conversation history cleared');
    }
  }

  /// Dispose resources
  void dispose() {
    _audioTimer?.cancel();
    _stateController.close();
    _transcriptController.close();
    _responseController.close();
    _errorController.close();
    _channel?.sink.close();
    _audioRecorder.dispose();
  }
}

/// Bridge service states
enum BridgeState {
  disconnected,
  connecting,
  connected,
  listening,
  thinking,
  speaking,
  error,
}
