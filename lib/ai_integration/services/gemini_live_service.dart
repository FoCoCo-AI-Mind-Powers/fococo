/// Gemini Live API Service for FoCoCo
/// Integrates with Google's new Live API for real-time voice interactions
/// Based on: https://ai.google.dev/gemini-api/docs/live

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Gemini Live API Service States
enum GeminiLiveServiceState {
  disconnected,
  connecting,
  connected,
  listening,
  thinking,
  speaking,
  error,
}

/// Gemini Live API Configuration
class GeminiLiveConfig {
  final String model;
  final List<String> responseModalities;
  final String systemInstruction;
  final Map<String, dynamic>? tools;

  const GeminiLiveConfig({
    this.model = 'gemini-2.5-flash-preview-native-audio-dialog',
    this.responseModalities = const ['AUDIO', 'TEXT'],
    this.systemInstruction =
        '''You are FoCoCo's AI golf mental performance coach. 
    You help golfers improve their mental game through personalized coaching, 
    mindfulness techniques, and performance analysis. Be encouraging, 
    knowledgeable about golf psychology, and provide actionable advice. 
    Keep responses concise and conversational for voice interactions.''',
    this.tools,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'response_modalities': responseModalities,
        'system_instruction': systemInstruction,
        if (tools != null) 'tools': tools,
      };
}

/// Main Gemini Live API Service
class GeminiLiveService {
  static final GeminiLiveService _instance = GeminiLiveService._internal();
  factory GeminiLiveService() => _instance;
  GeminiLiveService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;

  // Audio components
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State management
  final StreamController<GeminiLiveServiceState> _stateController =
      StreamController<GeminiLiveServiceState>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<Uint8List> _audioController =
      StreamController<Uint8List>.broadcast();

  GeminiLiveServiceState _currentState = GeminiLiveServiceState.disconnected;
  GeminiLiveConfig _config = const GeminiLiveConfig();

  // Audio recording
  bool _isRecording = false;

  // Getters
  Stream<GeminiLiveServiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<Uint8List> get audioStream => _audioController.stream;
  GeminiLiveServiceState get currentState => _currentState;
  bool get isConnected => _currentState != GeminiLiveServiceState.disconnected;
  bool get isListening => _currentState == GeminiLiveServiceState.listening;

  /// Initialize the service with configuration
  Future<void> initialize({
    GeminiLiveConfig? config,
  }) async {
    _config = config ?? const GeminiLiveConfig();

    // Request microphone permission
    await _requestPermissions();
  }

  /// Connect to Gemini Live API
  Future<void> connect() async {
    if (_currentState != GeminiLiveServiceState.disconnected) {
      debugPrint('GeminiLiveService: Already connected or connecting');
      return;
    }

    try {
      _updateState(GeminiLiveServiceState.connecting);

      // Construct WebSocket URL
      final uri = Uri.parse(
          'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent');

      // Create WebSocket connection with API key
      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['gemini-live'],
      );

      // Send initial configuration
      await _sendConfiguration();

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClosed,
      );

      _updateState(GeminiLiveServiceState.connected);
      debugPrint('GeminiLiveService: Connected successfully');
    } catch (e) {
      debugPrint('GeminiLiveService: Connection failed: $e');
      _updateState(GeminiLiveServiceState.error);
      rethrow;
    }
  }

  /// Disconnect from Gemini Live API
  Future<void> disconnect() async {
    try {
      await stopListening();
      await _channel?.sink.close(status.goingAway);
      _channel = null;
      _updateState(GeminiLiveServiceState.disconnected);
      debugPrint('GeminiLiveService: Disconnected');
    } catch (e) {
      debugPrint('GeminiLiveService: Disconnect error: $e');
    }
  }

  /// Start listening for audio input
  Future<void> startListening() async {
    if (!isConnected || _isRecording) return;

    try {
      _updateState(GeminiLiveServiceState.listening);

      // Start audio recording
      await _audioRecorder.start(
        path: 'temp_audio_recording.wav', // Temporary file path
        encoder: AudioEncoder.aacLc, // Use AAC instead of PCM for compatibility
        bitRate: 128000,
        samplingRate: 16000,
      );

      _isRecording = true;

      // Note: For real-time streaming, we would need to implement
      // a different approach using the record package's stream API
      // This is a simplified implementation for demonstration

      debugPrint('GeminiLiveService: Started listening');
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to start listening: $e');
      _updateState(GeminiLiveServiceState.error);
    }
  }

  /// Stop listening for audio input
  Future<void> stopListening() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      _isRecording = false;

      if (isConnected) {
        _updateState(GeminiLiveServiceState.connected);
      }

      debugPrint('GeminiLiveService: Stopped listening');
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to stop listening: $e');
    }
  }

  /// Send text message to Live API
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
                {
                  'text': text,
                }
              ]
            }
          ],
          'turn_complete': true,
        }
      };

      _channel!.sink.add(jsonEncode(message));
      debugPrint('GeminiLiveService: Sent text message: $text');
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to send text message: $e');
      rethrow;
    }
  }

  /// Send initial configuration to Live API
  Future<void> _sendConfiguration() async {
    final setupMessage = {
      'setup': {
        'model': _config.model,
        'generation_config': {
          'response_modalities': _config.responseModalities,
          'speech_config': {
            'voice_config': {
              'prebuilt_voice_config': {
                'voice_name': 'Puck' // Friendly voice for coaching
              }
            }
          }
        },
        'system_instruction': {
          'parts': [
            {'text': _config.systemInstruction}
          ]
        },
        if (_config.tools != null) 'tools': _config.tools,
      }
    };

    _channel!.sink.add(jsonEncode(setupMessage));
    debugPrint('GeminiLiveService: Sent configuration');
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      // Handle setup complete
      if (data['setupComplete'] != null) {
        debugPrint('GeminiLiveService: Setup completed');
        return;
      }

      // Handle server content (AI responses)
      if (data['serverContent'] != null) {
        _handleServerContent(data['serverContent']);
      }

      // Handle tool calls
      if (data['toolCall'] != null) {
        _handleToolCall(data['toolCall']);
      }
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to parse message: $e');
    }
  }

  /// Handle server content (AI responses)
  void _handleServerContent(Map<String, dynamic> serverContent) {
    // Handle model turn (AI thinking/responding)
    if (serverContent['modelTurn'] != null) {
      final modelTurn = serverContent['modelTurn'];

      // Handle text parts
      if (modelTurn['parts'] != null) {
        for (final part in modelTurn['parts']) {
          if (part['text'] != null) {
            _transcriptController.add(part['text']);
          }

          // Handle audio parts
          if (part['inlineData'] != null) {
            final audioData = base64Decode(part['inlineData']['data']);
            _playAudioResponse(audioData);
          }
        }
      }
    }

    // Handle turn complete
    if (serverContent['turnComplete'] == true) {
      if (_currentState == GeminiLiveServiceState.speaking) {
        _updateState(GeminiLiveServiceState.connected);
      }
    }

    // Update state based on server content
    if (serverContent['modelTurn'] != null) {
      _updateState(GeminiLiveServiceState.thinking);
    }
  }

  /// Handle tool calls from the AI
  void _handleToolCall(Map<String, dynamic> toolCall) {
    // Implement tool call handling for FoCoCo-specific functions
    // e.g., logging golf rounds, accessing performance data, etc.
    debugPrint('GeminiLiveService: Tool call received: $toolCall');
  }

  /// Play audio response from AI
  Future<void> _playAudioResponse(Uint8List audioData) async {
    try {
      _updateState(GeminiLiveServiceState.speaking);

      // Convert PCM data to playable format and play
      // Note: This is a simplified implementation
      // In production, you might need audio format conversion

      final source = BytesSource(audioData);
      await _audioPlayer.play(source);
      _audioController.add(audioData);
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to play audio: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    debugPrint('GeminiLiveService: WebSocket error: $error');
    _updateState(GeminiLiveServiceState.error);
  }

  /// Handle WebSocket connection closed
  void _handleWebSocketClosed() {
    debugPrint('GeminiLiveService: WebSocket connection closed');
    _updateState(GeminiLiveServiceState.disconnected);
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    final micPermission = await Permission.microphone.request();
    if (micPermission != PermissionStatus.granted) {
      throw Exception('Microphone permission is required for voice chat');
    }
  }

  /// Update service state and notify listeners
  void _updateState(GeminiLiveServiceState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('GeminiLiveService: State changed to $newState');
    }
  }

  /// Dispose of the service
  void dispose() {
    disconnect();
    _stateController.close();
    _transcriptController.close();
    _audioController.close();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}

/// Extension for easy access to Gemini Live Service
extension GeminiLiveServiceExtension on GeminiLiveService {
  /// Quick start voice conversation
  Future<void> startVoiceConversation() async {
    if (!isConnected) {
      await connect();
    }
    await startListening();
  }

  /// Quick stop voice conversation
  Future<void> stopVoiceConversation() async {
    await stopListening();
  }

  /// Toggle listening state
  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }
}
