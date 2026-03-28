/// Vertex AI Gemini Live Service for Speech-to-Speech
/// Uses Vertex AI WebSocket API with model: gemini-live-2.5-flash-preview-native-audio-09-2025
/// Based on: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/live-api/get-started-websocket

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
// Note: audioplayers removed - Cartesia handles TTS playback

import '../config/gemini_live_config.dart';
import 'permission_service.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';

/// Vertex AI Gemini Live Service States
enum VertexAIGeminiLiveState {
  disconnected,
  connecting,
  connected,
  listening,
  thinking,
  speaking,
  error,
}

/// Response from Vertex AI Gemini Live
/// Note: Only text responses are used - Cartesia handles TTS
class VertexAIGeminiLiveResponse {
  final String? text;
  final String? thinkingProcess;
  final bool isThinking;
  final Map<String, dynamic>? metadata;

  VertexAIGeminiLiveResponse({
    this.text,
    this.thinkingProcess,
    this.isThinking = false,
    this.metadata,
  });
}

/// Vertex AI Gemini Live Service
/// Connects to Vertex AI WebSocket API for real-time speech-to-speech interaction
class VertexAIGeminiLiveService {
  static final VertexAIGeminiLiveService _instance =
      VertexAIGeminiLiveService._internal();
  factory VertexAIGeminiLiveService() => _instance;
  VertexAIGeminiLiveService._internal();

  // Configuration
  static const String _modelId = 'gemini-live-2.5-flash-preview-native-audio-09-2025';
  String? _projectId;
  String _location = 'global';
  String? _accessToken;

  // WebSocket connection
  WebSocketChannel? _channel;

  // Audio components
  final AudioRecorder _audioRecorder = AudioRecorder();
  final PermissionService _permissionService = PermissionService();
  // Note: AudioPlayer removed - Cartesia handles TTS playback

  // State management
  final StreamController<VertexAIGeminiLiveState> _stateController =
      StreamController<VertexAIGeminiLiveState>.broadcast();
  final StreamController<VertexAIGeminiLiveResponse> _responseController =
      StreamController<VertexAIGeminiLiveResponse>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  VertexAIGeminiLiveState _currentState = VertexAIGeminiLiveState.disconnected;
  bool _isRecording = false;
  Timer? _audioTimer;
  VarkPreferencesStruct? _varkPreferences; // Used in system instruction generation

  // Streams
  Stream<VertexAIGeminiLiveState> get stateStream => _stateController.stream;
  Stream<VertexAIGeminiLiveResponse> get responseStream =>
      _responseController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;

  // Getters
  VertexAIGeminiLiveState get state => _currentState;
  bool get isConnected =>
      _currentState != VertexAIGeminiLiveState.disconnected;
  bool get isListening => _currentState == VertexAIGeminiLiveState.listening;
  bool get isSpeaking => _currentState == VertexAIGeminiLiveState.speaking;
  bool get isThinking => _currentState == VertexAIGeminiLiveState.thinking;

  /// Initialize the service
  Future<void> initialize({
    String? projectId,
    String location = 'global',
    String? accessToken,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    _projectId = projectId ?? const String.fromEnvironment('GOOGLE_CLOUD_PROJECT');
    _location = location;
    _accessToken = accessToken;
    _varkPreferences = varkPreferences;

    // Initialize permission service
    await _permissionService.initialize();

    if (kDebugMode) {
      print('🎤 Vertex AI Gemini Live Service initializing...');
      print('   Model: $_modelId');
      print('   Project: $_projectId');
      print('   Location: $_location');
    }
  }

  /// Get access token (for Vertex AI authentication)
  /// In production, use Application Default Credentials (ADC) or service account
  Future<String?> _getAccessToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }

    // Try to get from environment or use API key as fallback
    // For Vertex AI, you typically use ADC or service account credentials
    // This is a simplified version - in production, use proper authentication
    final apiKey = await GeminiLiveAPIConfig.getApiKey();
    if (apiKey.isNotEmpty) {
      return null; // Will use API key in URL instead
    }

    return null;
  }

  /// Connect to Vertex AI Gemini Live WebSocket
  Future<bool> connect() async {
    if (_currentState == VertexAIGeminiLiveState.connected) {
      return true;
    }

    try {
      _updateState(VertexAIGeminiLiveState.connecting);

      if (_projectId == null || _projectId!.isEmpty) {
        throw Exception(
            'Google Cloud Project ID not configured. Set GOOGLE_CLOUD_PROJECT environment variable.');
      }

      // Construct Vertex AI WebSocket URL
      final host = '$_location-aiplatform.googleapis.com';
      final path =
          '/ws/google.cloud.aiplatform.v1.LlmBidiService/BidiGenerateContent';
      final modelResource =
          'projects/$_projectId/locations/$_location/publishers/google/models/$_modelId';

      // Use API key if available, otherwise use access token
      final apiKey = await GeminiLiveAPIConfig.getApiKey();
      Uri uri;

      if (apiKey.isNotEmpty) {
        uri = Uri.parse('wss://$host$path?key=$apiKey');
      } else {
        // Use access token in Authorization header (for Vertex AI)
        final token = await _getAccessToken();
        if (token == null) {
          throw Exception(
              'No authentication method available. Set GEMINI_API_KEY or configure Vertex AI credentials.');
        }
        uri = Uri.parse('wss://$host$path');
        // Note: WebSocketChannel.connect doesn't support headers directly
        // For Vertex AI with access token, you may need to use a different approach
        // or pass the token in the WebSocket URL or initial message
      }

      if (kDebugMode) {
        print('🔗 Connecting to Vertex AI Gemini Live: $uri');
      }

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(uri, protocols: null);

      // Send setup message with system instruction
      // Note: We request TEXT modality only, as Cartesia will handle TTS
      final setupMessage = {
        'setup': {
          'model': modelResource,
          'generation_config': {
            'response_modalities': ['TEXT'], // TEXT only - Cartesia handles TTS
          },
          'system_instruction': {
            'parts': [
              {
                'text': _buildSystemInstruction(),
              }
            ]
          }
        }
      };

      _channel!.sink.add(jsonEncode(setupMessage));

      // Listen for responses
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      // Wait for connection confirmation
      await Future.delayed(const Duration(milliseconds: 1500));

      _updateState(VertexAIGeminiLiveState.connected);

      if (kDebugMode) {
        print('✅ Vertex AI Gemini Live connected successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to Vertex AI Gemini Live: $e');
      }
      _updateState(VertexAIGeminiLiveState.error);
      return false;
    }
  }

  /// Disconnect from the service
  Future<void> disconnect() async {
    try {
      await stopListening();

      _channel?.sink.close();
      _channel = null;

      _updateState(VertexAIGeminiLiveState.disconnected);

      if (kDebugMode) {
        print('🔌 Vertex AI Gemini Live disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting: $e');
      }
    }
  }

  /// Start listening for audio input
  Future<void> startListening() async {
    if (!isConnected) {
      final connected = await connect();
      if (!connected) {
        throw Exception('Failed to connect to Vertex AI Gemini Live');
      }
    }

    // Check microphone permission
    final permissionState =
        await _permissionService.checkMicrophonePermission();
    if (permissionState != PermissionServiceState.granted) {
      final granted = await _permissionService.requestMicrophoneWithRetry();
      if (!granted) {
        throw Exception('Microphone permission not granted');
      }
    }

    try {
      _updateState(VertexAIGeminiLiveState.listening);

      // Start audio recording
      await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;

      // Start streaming audio data
      _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _sendAudioChunk();
      });

      if (kDebugMode) {
        print('👂 Started listening for audio input');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting listening: $e');
      }
      _updateState(VertexAIGeminiLiveState.error);
      rethrow;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isRecording) return;

    try {
      _audioTimer?.cancel();
      _audioTimer = null;

      await _audioRecorder.stop();
      _isRecording = false;

      // Send end of turn message
      final endMessage = {
        'realtime_input': {
          'media_chunks': [],
          'turn_complete': true,
        }
      };
      _channel?.sink.add(jsonEncode(endMessage));

      if (isConnected) {
        _updateState(VertexAIGeminiLiveState.connected);
      }

      if (kDebugMode) {
        print('🛑 Stopped listening');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping listening: $e');
      }
    }
  }

  /// Send audio chunk to Vertex AI
  void _sendAudioChunk() async {
    if (!_isRecording || _channel == null) return;

    try {
      // Get audio stream data (simplified - in production, capture actual audio chunks)
      // The record package should provide audio stream data
      // For now, this is a placeholder that shows the structure

      // In a real implementation, you would:
      // 1. Capture audio chunks from the recorder stream
      // 2. Convert to base64
      // 3. Send as realtime_input with media_chunks

      // TODO: Implement actual audio capture from AudioRecorder stream
      // For now, this method is a placeholder
      // When implementing, uncomment and use:
      /*
      final audioData = await _captureAudioChunk(); // Implement this method
      final audioMessage = {
        'realtime_input': {
          'media_chunks': [
            {
              'mime_type': 'audio/pcm;rate=16000',
              'data': base64Encode(audioData),
            }
          ]
        }
      };
      _channel!.sink.add(jsonEncode(audioMessage));
      */
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending audio chunk: $e');
      }
    }
  }

  /// Send text message (for text-to-speech)
  Future<void> sendTextMessage(String text) async {
    if (!isConnected) {
      throw Exception('Not connected to Vertex AI Gemini Live');
    }

    try {
      final textMessage = {
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

      _channel!.sink.add(jsonEncode(textMessage));
      _updateState(VertexAIGeminiLiveState.thinking);

      if (kDebugMode) {
        print('📤 Sent text message: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending text: $e');
      }
      throw e;
    }
  }

  /// Build system instruction based on VARK preferences
  String _buildSystemInstruction() {
    final baseInstruction =
        '''You are FoCoCo's AI golf mental performance coach. You specialize in sports psychology, focus, confidence, and mental game improvement.

Key characteristics:
- Professional, encouraging, and supportive
- Expert in golf mental training techniques
- Provide actionable, practical advice
- Use coaching language and terminology
- Be concise but thorough in explanations

Areas of expertise:
- Pre-shot routines and visualization
- Pressure management and nerves
- Confidence building techniques
- Focus and concentration training
- Recovery from bad shots
- Mental game consistency''';

    if (_varkPreferences != null) {
      if (_varkPreferences!.visual) {
        return '$baseInstruction\n\nLearning Style: Visual learner - Use descriptive imagery, visualization techniques, and paint mental pictures when explaining concepts.';
      } else if (_varkPreferences!.aural) {
        return '$baseInstruction\n\nLearning Style: Auditory learner - Use conversational tone, rhythmic patterns, and verbal cues. Focus on sound-based techniques and spoken instructions.';
      } else if (_varkPreferences!.readWrite) {
        return '$baseInstruction\n\nLearning Style: Read/Write learner - Provide structured information, lists, and clear step-by-step instructions. Encourage note-taking.';
      } else if (_varkPreferences!.kinesthetic) {
        return '$baseInstruction\n\nLearning Style: Kinesthetic learner - Focus on physical sensations, practice drills, and hands-on techniques. Use action-oriented language.';
      }
    }

    return '$baseInstruction\n\nAdapt your communication style to be engaging and effective for all learning preferences.';
  }

  /// Update VARK preferences
  void updateVarkPreferences(VarkPreferencesStruct? preferences) {
    _varkPreferences = preferences;

    if (kDebugMode) {
      print('🎯 VARK preferences updated');
    }

    // If connected, reconnect with new preferences
    if (isConnected) {
      disconnect().then((_) => connect());
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());

      if (kDebugMode) {
        print('📨 Received message: ${data.toString().substring(0, 200)}...');
      }

      // Handle server content (AI response)
      if (data['serverContent'] != null) {
        _handleServerContent(data['serverContent']);
      }

      // Handle setup confirmation
      if (data['setupComplete'] != null) {
        if (kDebugMode) {
          print('✅ Setup complete');
        }
      }

      // Handle errors
      if (data['error'] != null) {
        if (kDebugMode) {
          print('❌ Server error: ${data['error']}');
        }
        _updateState(VertexAIGeminiLiveState.error);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing message: $e');
      }
    }
  }

  /// Handle server content (AI responses)
  void _handleServerContent(Map<String, dynamic> content) {
    try {
      if (content['modelTurn'] != null) {
        final modelTurn = content['modelTurn'];
        final parts = modelTurn['parts'] as List?;

        if (parts != null && parts.isNotEmpty) {
          String? responseText;
          String? thinkingProcess;
          bool isThinkingResponse = false;

          for (final part in parts) {
            // Handle text responses
            if (part['text'] != null) {
              responseText = part['text'] as String;
              if (!_transcriptController.isClosed) {
                _transcriptController.add(responseText);
              }
            }

            // Note: We don't handle audio responses here as Cartesia handles TTS
            // Audio responses from Gemini are ignored when using TEXT modality
          }

          // Create and emit response
          final response = VertexAIGeminiLiveResponse(
            text: responseText,
            thinkingProcess: thinkingProcess,
            isThinking: isThinkingResponse,
            metadata: {
              'timestamp': DateTime.now().toIso8601String(),
              'model': _modelId,
            },
          );

          if (!_responseController.isClosed) {
            _responseController.add(response);
          }
          _updateState(VertexAIGeminiLiveState.connected);
        }
      }

      // Check if turn is complete
      if (content['turnComplete'] == true) {
        _updateState(VertexAIGeminiLiveState.connected);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling server content: $e');
      }
    }
  }

  // Note: Audio playback is handled by Cartesia TTS service, not here
  // This service only handles Gemini Live for STT and AI responses

  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
    _updateState(VertexAIGeminiLiveState.error);
  }

  /// Handle WebSocket close
  void _handleWebSocketClose() {
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }
    _updateState(VertexAIGeminiLiveState.disconnected);
  }

  /// Update service state
  void _updateState(VertexAIGeminiLiveState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      // Check if controller is closed before adding events
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }

      if (kDebugMode) {
        print('🔄 State changed to: $newState');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _stateController.close();
    _responseController.close();
    _transcriptController.close();
  }
}

