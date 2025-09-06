import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '/auth/firebase_auth/auth_util.dart';

import 'cartesia_tts_service.dart';

/// Production FoCoCo Voice Service
/// Handles voice input, AI processing, and TTS output with Cartesia integration
class FoCoCoVoiceService {
  static final FoCoCoVoiceService _instance = FoCoCoVoiceService._internal();
  factory FoCoCoVoiceService() => _instance;
  FoCoCoVoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();

  final CartesiaTTSService _ttsService = CartesiaTTSService.instance;

  // Stream controllers for real-time updates
  final _stateController = StreamController<VoiceServiceState>.broadcast();
  final _transcriptionController = StreamController<String>.broadcast();
  final _responseController = StreamController<VoiceResponse>.broadcast();
  final _thinkingModeController = StreamController<bool>.broadcast();

  // State management
  VoiceServiceState _currentState = VoiceServiceState.uninitialized;
  bool _isThinkingMode = false;
  String _currentTranscription = '';
  String? _activeRoundId;
  Position? _currentLocation;
  List<ChatMessage> _conversationHistory = [];

  // Streams
  Stream<VoiceServiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<VoiceResponse> get responseStream => _responseController.stream;
  Stream<bool> get thinkingModeStream => _thinkingModeController.stream;

  // Getters
  VoiceServiceState get currentState => _currentState;
  bool get isThinkingMode => _isThinkingMode;
  String get currentTranscription => _currentTranscription;
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Initialize the voice service
  Future<void> initialize() async {
    try {
      _updateState(VoiceServiceState.connecting);

      // Initialize AI client

      // Initialize speech recognition
      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!available) {
        throw Exception('Speech recognition not available');
      }

      // Get current location for context
      await _updateLocation();

      _updateState(VoiceServiceState.ready);
      debugPrint('✅ FoCoCo Voice Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FoCoCo Voice Service: $e');
      _updateState(VoiceServiceState.error);
      rethrow;
    }
  }

  /// Toggle thinking mode
  void toggleThinkingMode() {
    _isThinkingMode = !_isThinkingMode;
    _thinkingModeController.add(_isThinkingMode);

    // Add system message about mode change
    final modeMessage = ChatMessage(
      id: 'mode_${DateTime.now().millisecondsSinceEpoch}',
      content: _isThinkingMode
          ? 'Switched to Deep Thinking mode - I\'ll take more time to analyze and provide comprehensive insights.'
          : 'Switched to Quick Chat mode - I\'ll provide faster, more direct responses.',
      isUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.system,
    );

    _conversationHistory.add(modeMessage);
    _responseController.add(VoiceResponse(
      message: modeMessage,
      audioPath: null,
      processingTime: Duration.zero,
    ));

    debugPrint('🧠 Thinking mode: ${_isThinkingMode ? 'ON' : 'OFF'}');
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (_currentState == VoiceServiceState.listening) return;

    try {
      _updateState(VoiceServiceState.listening);
      await _updateLocation();

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      HapticFeedback.lightImpact();
      debugPrint('🎤 Started listening...');
    } catch (e) {
      debugPrint('❌ Error starting voice recognition: $e');
      _updateState(VoiceServiceState.error);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_currentState != VoiceServiceState.listening) return;

    try {
      await _speechToText.stop();

      if (_currentTranscription.isNotEmpty) {
        await _processVoiceInput(_currentTranscription);
      } else {
        _updateState(VoiceServiceState.ready);
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('❌ Error stopping voice recognition: $e');
      _updateState(VoiceServiceState.error);
    }
  }

  /// Send text message
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      // Add user message to history
      final userMessage = ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        content: message.trim(),
        isUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      _conversationHistory.add(userMessage);
      _responseController.add(VoiceResponse(
        message: userMessage,
        audioPath: null,
        processingTime: Duration.zero,
      ));

      // Process the message
      await _processUserInput(message.trim(), isVoice: false);
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
      _updateState(VoiceServiceState.error);
    }
  }

  /// Process voice input
  Future<void> _processVoiceInput(String transcription) async {
    try {
      // Add user message to history
      final userMessage = ChatMessage(
        id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
        content: transcription,
        isUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.voice,
      );

      _conversationHistory.add(userMessage);
      _responseController.add(VoiceResponse(
        message: userMessage,
        audioPath: null,
        processingTime: Duration.zero,
      ));

      // Process the input
      await _processUserInput(transcription, isVoice: true);
    } catch (e) {
      debugPrint('❌ Error processing voice input: $e');
      _updateState(VoiceServiceState.error);
    }
  }

  /// Process user input (voice or text)
  Future<void> _processUserInput(String input, {required bool isVoice}) async {
    final startTime = DateTime.now();

    try {
      _updateState(VoiceServiceState.thinking);

      // Generate AI response with context
      final aiResponse = await _generateAIResponse(input);

      // Create response message
      final responseMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: isVoice ? MessageType.voice : MessageType.text,
      );

      _conversationHistory.add(responseMessage);

      // Generate TTS audio for the response
      String? audioPath;
      if (isVoice || _shouldGenerateAudio(aiResponse)) {
        _updateState(VoiceServiceState.speaking);

        try {
          final audioData = await _ttsService.generateSpeech(
            text: aiResponse,
            contentType: _getContentType(aiResponse),
          );

          // Save audio for playback
          final tempDir = await getTemporaryDirectory();
          final audioFile = File(
              '${tempDir.path}/response_${DateTime.now().millisecondsSinceEpoch}.wav');
          await audioFile.writeAsBytes(audioData);
          audioPath = audioFile.path;

          // Play the audio
          await _ttsService.playAudioData(audioData, onComplete: () {
            _updateState(VoiceServiceState.ready);
          });
        } catch (e) {
          debugPrint('⚠️ TTS generation failed, continuing without audio: $e');
          _updateState(VoiceServiceState.ready);
        }
      } else {
        _updateState(VoiceServiceState.ready);
      }

      final processingTime = DateTime.now().difference(startTime);

      // Emit the response
      _responseController.add(VoiceResponse(
        message: responseMessage,
        audioPath: audioPath,
        processingTime: processingTime,
      ));

      // Save to database if significant interaction
      if (_shouldSaveInteraction(input, aiResponse)) {
        await _saveInteractionToDatabase(input, aiResponse, isVoice);
      }
    } catch (e) {
      debugPrint('❌ Error processing user input: $e');
      _updateState(VoiceServiceState.error);

      // Send error message
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'I apologize, but I encountered an error processing your request. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.error,
      );

      _conversationHistory.add(errorMessage);
      _responseController.add(VoiceResponse(
        message: errorMessage,
        audioPath: null,
        processingTime: DateTime.now().difference(startTime),
      ));
    }
  }

  /// Generate AI response with context
  Future<String> _generateAIResponse(String input) async {
    // TODO: Use context and conversation history when integrating actual AI service
    // final contextPrompt = _buildContextPrompt();
    // final conversationContext = _buildConversationContext();

    // TODO: Integrate actual AI service with proper system prompt
    // For now using fallback responses

    try {
      // Use a fallback response for now - replace with actual AI integration
      final response = await _generateFallbackResponse(input);
      return response;
    } catch (e) {
      debugPrint('❌ AI generation failed: $e');
      return _generateFallbackResponse(input);
    }
  }

  /// Generate fallback response (replace with actual AI integration)
  Future<String> _generateFallbackResponse(String input) async {
    // Simulate processing time for thinking mode
    if (_isThinkingMode) {
      await Future.delayed(const Duration(seconds: 2));
    }

    final inputLower = input.toLowerCase();

    if (inputLower.contains('putt') || inputLower.contains('putting')) {
      return _isThinkingMode
          ? '''Let me analyze your putting concerns comprehensively.

Putting is fundamentally about confidence and routine. Here's a structured approach:

1. **Pre-putt Routine**: Establish a consistent 3-step process - read the green, visualize the ball path, and take your stance with confidence.

2. **Mental Approach**: Focus on the process, not the outcome. Trust your read and commit fully to your line and speed.

3. **Pressure Management**: Use box breathing (4-4-4-4 count) before crucial putts to maintain calm focus.

Practice this routine during training so it becomes automatic under pressure. Remember, even tour professionals miss putts - it's about maintaining confidence for the next one.'''
          : '''For putting confidence, focus on your routine: read, visualize, commit. Trust your instincts and stay positive regardless of the outcome. Every putt is a fresh start!''';
    }

    if (inputLower.contains('pressure') || inputLower.contains('nervous')) {
      return _isThinkingMode
          ? '''Pressure and nerves are natural responses that we can transform into focused energy.

**Understanding Pressure**:
Pressure often comes from focusing on outcomes rather than process. Your nervous system is actually preparing you to perform - we just need to channel it effectively.

**Immediate Techniques**:
1. **Physiological Reset**: Use the 4-7-8 breathing technique (inhale 4, hold 7, exhale 8)
2. **Mental Reframe**: Change "I have to make this" to "I get to play this shot"
3. **Physical Grounding**: Feel your feet, relax your shoulders, trust your preparation

**Long-term Development**:
Practice pressure situations in training. Create consequences for missed shots during practice to build resilience. Remember, pressure is a privilege - it means you're in contention!'''
          : '''When feeling pressure, remember: breathe deeply, focus on your process, and trust your preparation. Pressure means you care - channel that energy into focused execution!''';
    }

    if (inputLower.contains('focus') || inputLower.contains('concentration')) {
      return _isThinkingMode
          ? '''Focus in golf requires both broad awareness and narrow attention control.

**The Focus Funnel Approach**:
1. **Broad Focus** (30 seconds before): Survey conditions, wind, lie, target
2. **Medium Focus** (15 seconds): Select club, commit to strategy
3. **Narrow Focus** (5 seconds): Single swing thought, target focus
4. **Ultra-narrow** (during swing): Trust and let go

**Maintaining Concentration**:
- Use a pre-shot routine as your focus trigger
- Develop a "reset" cue for when focus drifts (deep breath, shoulder roll)
- Practice mindfulness exercises off-course to strengthen attention control

Remember: You can't focus for 4+ hours straight. Plan strategic "focus breaks" between shots to maintain peak attention when it matters.'''
          : '''For better focus, use a consistent pre-shot routine as your trigger. Take a deep breath, commit to your target, and trust your swing. One shot at a time!''';
    }

    // Default responses
    return _isThinkingMode
        ? '''Thank you for sharing that with me. Let me think about this comprehensively.

Every aspect of golf performance is interconnected - physical technique, mental approach, and emotional state all influence each other. 

Based on what you've shared, I'd recommend starting with building awareness of your current patterns. Notice when you perform well and what mental state accompanies those moments.

The key is developing consistent mental routines that you can rely on regardless of external circumstances. This creates a foundation of confidence that supports all other aspects of your game.

What specific situation would you like to work on first? I'm here to help you develop the mental tools for consistent performance.'''
        : '''I understand what you're going through. Golf is as much mental as it is physical. Let's work together to build your mental game. What specific area would you like to focus on today?''';
  }

  /// Build context prompt based on current situation
  String _buildContextPrompt() {
    final location = _currentLocation != null
        ? 'User is currently at GPS coordinates: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}'
        : 'User location not available';

    final roundContext = _activeRoundId != null
        ? 'User is currently playing a round (ID: $_activeRoundId)'
        : 'User is not currently playing a round';

    return '''
Context Information:
- $location
- $roundContext
- Current time: ${DateTime.now().toString()}
- Conversation mode: ${_isThinkingMode ? 'Deep Thinking' : 'Quick Chat'}
''';
  }

  /// Build conversation context from history
  String _buildConversationContext() {
    if (_conversationHistory.isEmpty) return 'No previous conversation';

    final recentMessages = _conversationHistory
        .where((msg) => msg.messageType != MessageType.system)
        .take(6)
        .map((msg) => '${msg.isUser ? 'User' : 'AI'}: ${msg.content}')
        .join('\n');

    return recentMessages;
  }

  /// Determine content type for TTS
  String _getContentType(String content) {
    final contentLower = content.toLowerCase();

    if (contentLower.contains('breathe') ||
        contentLower.contains('relax') ||
        contentLower.contains('calm')) {
      return 'meditation';
    }
    if (contentLower.contains('great') ||
        contentLower.contains('excellent') ||
        contentLower.contains('well done')) {
      return 'motivation';
    }
    if (contentLower.contains('technique') ||
        contentLower.contains('practice') ||
        contentLower.contains('drill')) {
      return 'instruction';
    }

    return 'coaching';
  }

  /// Check if audio should be generated
  bool _shouldGenerateAudio(String response) {
    // Generate audio for longer responses or specific content types
    return response.length > 100 ||
        response.toLowerCase().contains('breathe') ||
        response.toLowerCase().contains('visualize');
  }

  /// Check if interaction should be saved to database
  bool _shouldSaveInteraction(String input, String response) {
    // Save significant interactions (longer than simple greetings)
    return input.length > 10 && response.length > 50;
  }

  /// Save interaction to database
  Future<void> _saveInteractionToDatabase(
      String input, String response, bool isVoice) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final interactionData = {
        'userId': user.uid,
        'userInput': input,
        'aiResponse': response,
        'isVoiceInput': isVoice,
        'thinkingMode': _isThinkingMode,
        'timestamp': FieldValue.serverTimestamp(),
        'location': _currentLocation != null
            ? {
                'latitude': _currentLocation!.latitude,
                'longitude': _currentLocation!.longitude,
              }
            : null,
        'activeRoundId': _activeRoundId,
        'conversationLength': _conversationHistory.length,
      };

      await FirebaseFirestore.instance
          .collection('ai_interactions')
          .add(interactionData);

      debugPrint('💾 Saved interaction to database');
    } catch (e) {
      debugPrint('⚠️ Failed to save interaction: $e');
    }
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _currentLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Could not get location: $e');
    }
  }

  /// Set active round for context
  void setActiveRound(String? roundId) {
    _activeRoundId = roundId;
    debugPrint('🏌️ Active round set: $roundId');
  }

  /// Clear conversation history
  void clearConversation() {
    _conversationHistory.clear();
    debugPrint('🗑️ Conversation history cleared');
  }

  /// Update service state
  void _updateState(VoiceServiceState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('🔄 Voice service state: $newState');
    }
  }

  /// Speech recognition callbacks
  void _onSpeechStatus(String status) {
    debugPrint('🎤 Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_currentState == VoiceServiceState.listening) {
        _updateState(VoiceServiceState.ready);
      }
    }
  }

  void _onSpeechError(dynamic error) {
    debugPrint('❌ Speech error: $error');
    _updateState(VoiceServiceState.error);
  }

  void _onSpeechResult(dynamic result) {
    _currentTranscription = result.recognizedWords;
    _transcriptionController.add(_currentTranscription);
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
    _transcriptionController.close();
    _responseController.close();
    _thinkingModeController.close();
    _ttsService.dispose();
  }
}

/// Voice service states
enum VoiceServiceState {
  uninitialized,
  connecting,
  ready,
  listening,
  thinking,
  speaking,
  error,
}

/// Message types
enum MessageType {
  text,
  voice,
  system,
  error,
}

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
    };
  }
}

/// Voice response model
class VoiceResponse {
  final ChatMessage message;
  final String? audioPath;
  final Duration processingTime;

  VoiceResponse({
    required this.message,
    required this.audioPath,
    required this.processingTime,
  });
}
