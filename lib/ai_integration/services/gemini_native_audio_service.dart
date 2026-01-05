import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '/backend/schema/structs/vark_preferences_struct.dart';

/// State of the Gemini Native Audio Service
enum GeminiNativeAudioState {
  disconnected,
  connecting,
  connected,
  listening,
  speaking,
  thinking,
  error
}

/// Native audio response from Gemini
class GeminiNativeAudioResponse {
  final String text;
  final Uint8List? audioData;
  final String? thinkingProcess;
  final bool isThinking;
  final Map<String, dynamic>? metadata;

  GeminiNativeAudioResponse({
    required this.text,
    this.audioData,
    this.thinkingProcess,
    this.isThinking = false,
    this.metadata,
  });
}

/// Gemini Native Audio Service for Speech-to-Speech Interaction
/// Supports gemini-2.5-flash-native-audio-preview-09-2025 and
/// gemini-2.5-flash-exp-native-audio-thinking-dialog models
class GeminiNativeAudioService {
  static const String _baseUrl = 'wss://generativelanguage.googleapis.com/ws';
  static const String _apiPath =
      '/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';

  // Native Audio Models
  static const String _standardModel =
      'gemini-2.5-flash-native-audio-preview-09-2025';
  static const String _thinkingModel =
      'gemini-2.5-flash-exp-native-audio-thinking-dialog';

  late String _apiKey;
  WebSocketChannel? _webSocketChannel;

  // State management
  final StreamController<GeminiNativeAudioState> _stateController =
      StreamController<GeminiNativeAudioState>.broadcast();
  final StreamController<GeminiNativeAudioResponse> _responseController =
      StreamController<GeminiNativeAudioResponse>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  GeminiNativeAudioState _currentState = GeminiNativeAudioState.disconnected;
  String _sessionId = '';
  bool _isThinkingMode = false;
  VarkPreferencesStruct? _varkPreferences;

  // Streams
  Stream<GeminiNativeAudioState> get stateStream => _stateController.stream;
  Stream<GeminiNativeAudioResponse> get responseStream =>
      _responseController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;

  // Getters
  GeminiNativeAudioState get state => _currentState;
  bool get isConnected => _currentState != GeminiNativeAudioState.disconnected;
  bool get isListening => _currentState == GeminiNativeAudioState.listening;
  bool get isSpeaking => _currentState == GeminiNativeAudioState.speaking;
  bool get isThinking => _currentState == GeminiNativeAudioState.thinking;

  /// Initialize the service
  Future<void> initialize({
    required String apiKey,
    bool thinkingMode = false,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    _apiKey = apiKey;
    _isThinkingMode = thinkingMode;
    _varkPreferences = varkPreferences;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    if (kDebugMode) {
      print('🎤 Gemini Native Audio Service initializing...');
      print('   Model: ${_isThinkingMode ? _thinkingModel : _standardModel}');
      print('   Thinking Mode: $_isThinkingMode');
      print('   Session ID: $_sessionId');
    }
  }

  /// Connect to Gemini Native Audio WebSocket
  Future<bool> connect() async {
    if (_currentState == GeminiNativeAudioState.connected) {
      return true;
    }

    try {
      _updateState(GeminiNativeAudioState.connecting);

      final model = _isThinkingMode ? _thinkingModel : _standardModel;
      final uri = Uri.parse('$_baseUrl$_apiPath?key=$_apiKey');

      if (kDebugMode) {
        print('🔗 Connecting to Gemini Native Audio: $uri');
      }

      _webSocketChannel = WebSocketChannel.connect(uri);

      // Setup connection message
      final connectionMessage = {
        'setup': {
          'model': 'models/$model',
          'generation_config': _getGenerationConfig(),
          'system_instruction': _buildSystemInstruction(),
        }
      };

      _webSocketChannel!.sink.add(jsonEncode(connectionMessage));

      // Listen for responses
      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      // Wait for connection confirmation
      await Future.delayed(const Duration(milliseconds: 1500));

      _updateState(GeminiNativeAudioState.connected);

      if (kDebugMode) {
        print('✅ Gemini Native Audio connected successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to Gemini Native Audio: $e');
      }
      _updateState(GeminiNativeAudioState.error);
      return false;
    }
  }

  /// Disconnect from the service
  Future<void> disconnect() async {
    try {
      _webSocketChannel?.sink.close();
      _webSocketChannel = null;
      _updateState(GeminiNativeAudioState.disconnected);

      if (kDebugMode) {
        print('🔌 Gemini Native Audio disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting: $e');
      }
    }
  }

  /// Send audio data for processing
  Future<void> sendAudio(Uint8List audioData) async {
    if (!isConnected) {
      throw Exception('Not connected to Gemini Native Audio');
    }

    try {
      final audioMessage = {
        'client_content': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'audio/wav',
                    'data': base64Encode(audioData),
                  }
                }
              ]
            }
          ],
          'turn_complete': true,
        }
      };

      _webSocketChannel!.sink.add(jsonEncode(audioMessage));

      if (kDebugMode) {
        print('🎤 Sent audio data (${audioData.length} bytes)');
      }

      if (_isThinkingMode) {
        _updateState(GeminiNativeAudioState.thinking);
      } else {
        _updateState(GeminiNativeAudioState.speaking);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending audio: $e');
      }
      throw e;
    }
  }

  /// Send text message for TTS conversion
  Future<void> sendTextMessage(String text) async {
    if (!isConnected) {
      throw Exception('Not connected to Gemini Native Audio');
    }

    try {
      final textMessage = {
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

      _webSocketChannel!.sink.add(jsonEncode(textMessage));

      if (kDebugMode) {
        print('📝 Sent text message: $text');
      }

      if (_isThinkingMode) {
        _updateState(GeminiNativeAudioState.thinking);
      } else {
        _updateState(GeminiNativeAudioState.speaking);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending text: $e');
      }
      throw e;
    }
  }

  /// Start listening for audio input
  Future<void> startListening() async {
    if (!isConnected) {
      await connect();
    }

    _updateState(GeminiNativeAudioState.listening);

    if (kDebugMode) {
      print('👂 Started listening for audio input');
    }
  }

  /// Stop listening
  void stopListening() {
    if (_currentState == GeminiNativeAudioState.listening) {
      _updateState(GeminiNativeAudioState.connected);

      if (kDebugMode) {
        print('🛑 Stopped listening');
      }
    }
  }

  /// Toggle thinking mode
  Future<void> setThinkingMode(bool enabled) async {
    if (_isThinkingMode != enabled) {
      _isThinkingMode = enabled;

      if (isConnected) {
        // Reconnect with new model
        await disconnect();
        await connect();
      }

      if (kDebugMode) {
        print('🧠 Thinking mode ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Update VARK preferences
  void updateVarkPreferences(VarkPreferencesStruct? preferences) {
    _varkPreferences = preferences;

    if (kDebugMode) {
      print('🎯 VARK preferences updated');
    }
  }

  /// Get generation configuration
  Map<String, dynamic> _getGenerationConfig() {
    return {
      'response_modalities': ['AUDIO'],
      'speech_config': {
        'voice_config': {
          'prebuilt_voice_config': {
            'voice_name': 'Aoede', // Professional coaching voice
          }
        }
      },
      if (_isThinkingMode) ...{
        'response_schema': {
          'type': 'object',
          'properties': {
            'thinking': {
              'type': 'string',
              'description': 'Your internal thinking process'
            },
            'response': {
              'type': 'string',
              'description': 'Your final response to the user'
            }
          }
        }
      }
    };
  }

  /// Build system instruction based on VARK preferences
  String _buildSystemInstruction() {
    final baseInstruction =
        '''You are a professional AI mental performance coach for golf. You specialize in sports psychology, focus, confidence, and mental game improvement.

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
        _updateState(GeminiNativeAudioState.error);
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
          String responseText = '';
          Uint8List? audioData;
          String? thinkingProcess;
          bool isThinkingResponse = false;

          for (final part in parts) {
            // Handle text responses
            if (part['text'] != null) {
              final text = part['text'] as String;

              // Check if it's a thinking mode response
              if (_isThinkingMode && text.contains('"thinking"')) {
                try {
                  final jsonResponse = jsonDecode(text);
                  thinkingProcess = jsonResponse['thinking'];
                  responseText = jsonResponse['response'] ?? text;
                  isThinkingResponse = true;
                } catch (e) {
                  responseText = text;
                }
              } else {
                responseText = text;
              }

              // Update transcript
              if (!_transcriptController.isClosed) {
                _transcriptController.add(responseText);
              }
            }

            // Handle audio responses
            if (part['inlineData'] != null) {
              final inlineData = part['inlineData'];
              if (inlineData['mimeType'] == 'audio/pcm' ||
                  inlineData['mimeType'] == 'audio/wav') {
                final audioBase64 = inlineData['data'] as String;
                audioData = base64Decode(audioBase64);
              }
            }
          }

          // Create and emit response
          final response = GeminiNativeAudioResponse(
            text: responseText,
            audioData: audioData,
            thinkingProcess: thinkingProcess,
            isThinking: isThinkingResponse,
            metadata: {
              'sessionId': _sessionId,
              'timestamp': DateTime.now().toIso8601String(),
              'model': _isThinkingMode ? _thinkingModel : _standardModel,
            },
          );

          if (!_responseController.isClosed) {
            _responseController.add(response);
          }
          _updateState(GeminiNativeAudioState.connected);

          if (kDebugMode) {
            print(
                '🎯 Generated response: ${responseText.length} chars, ${audioData?.length ?? 0} audio bytes');
            if (thinkingProcess != null) {
              print(
                  '🧠 Thinking process: ${thinkingProcess.substring(0, 100)}...');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling server content: $e');
      }
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
    _updateState(GeminiNativeAudioState.error);
  }

  /// Handle WebSocket close
  void _handleWebSocketClose() {
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }
    _updateState(GeminiNativeAudioState.disconnected);
  }

  /// Update service state
  void _updateState(GeminiNativeAudioState newState) {
    if (_currentState != newState) {
      _currentState = newState;
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
