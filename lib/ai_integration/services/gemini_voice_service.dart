import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/gemini_voice_config.dart';
import '../../backend/schema/structs/vark_preferences_struct.dart';

/// Service for handling voice interactions with Gemini AI
class GeminiVoiceService {
  static final GeminiVoiceService _instance = GeminiVoiceService._internal();
  factory GeminiVoiceService() => _instance;
  GeminiVoiceService._internal();

  // Audio components
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;
  
  // State management
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  List<VoiceMessage> _conversationHistory = [];
  
  // Stream controllers
  final StreamController<VoiceServiceState> _stateController = StreamController<VoiceServiceState>.broadcast();
  final StreamController<String> _transcriptController = StreamController<String>.broadcast();
  final StreamController<double> _volumeController = StreamController<double>.broadcast();
  
  // Getters
  Stream<VoiceServiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<double> get volumeStream => _volumeController.stream;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isThinking => _isThinking;
  List<VoiceMessage> get conversationHistory => _conversationHistory;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the voice service
  Future<bool> initialize() async {
    try {
      // Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Initialize components
      _speechToText = stt.SpeechToText();
      _flutterTts = FlutterTts();
      _audioPlayer = AudioPlayer();

      // Initialize speech-to-text
      final speechAvailable = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      
      if (!speechAvailable) {
        throw Exception('Speech recognition not available');
      }

      // Configure TTS
      await _configureTTS();

      // Session initialized successfully

      _updateState(VoiceServiceState.ready);
      
      if (kDebugMode) {
        print('✅ Voice service initialized successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize voice service: $e');
      }
      _updateState(VoiceServiceState.error);
      return false;
    }
  }

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();
    
    return microphoneStatus.isGranted && speechStatus.isGranted;
  }

  /// Configure TTS settings
  Future<void> _configureTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(0.9);
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.setVolume(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _updateState(VoiceServiceState.ready);
    });
    
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _updateState(VoiceServiceState.error);
    });
  }

  // ============================================================================
  // VOICE INTERACTION METHODS
  // ============================================================================

  /// Start listening for voice input
  Future<void> startListening({
    VoiceInteractionType type = VoiceInteractionType.quickChat,
  }) async {
    if (_isListening || _isSpeaking) return;

    try {
      _isListening = true;
      _updateState(VoiceServiceState.listening);

      await _speechToText.listen(
        onResult: (result) => _onSpeechResult(result, type),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
      
    } catch (e) {
      _isListening = false;
      _updateState(VoiceServiceState.error);
      if (kDebugMode) {
        print('❌ Error starting voice listening: $e');
      }
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;
    _updateState(VoiceServiceState.ready);
  }

  /// Process voice message with AI
  Future<void> processVoiceMessage({
    required String message,
    required VoiceInteractionType type,
    VarkPreferencesStruct? varkPreference,
    Map<String, dynamic>? userContext,
  }) async {
    if (_isSpeaking || _isThinking) return;

    try {
      _isThinking = true;
      _updateState(VoiceServiceState.thinking);

      // Add user message to history
      final userMessage = VoiceMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        type: type,
      );
      _conversationHistory.add(userMessage);

      // Generate AI response
      final response = await _generateAIResponse(
        message: message,
        type: type,
        varkPreference: varkPreference,
        userContext: userContext,
      );

      // Add AI response to history
      final aiMessage = VoiceMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.responseText,
        isUser: false,
        timestamp: DateTime.now(),
        type: type,
        thinkingProcess: response.thinkingProcess,
        audioUrl: response.audioUrl,
      );
      _conversationHistory.add(aiMessage);

      _isThinking = false;

      // Speak the response
      await _speakResponse(response.responseText, response.audioUrl);

    } catch (e) {
      _isThinking = false;
      _updateState(VoiceServiceState.error);
      if (kDebugMode) {
        print('❌ Error processing voice message: $e');
      }
    }
  }

  /// Generate AI response using appropriate model
  Future<VoiceAIResponse> _generateAIResponse({
    required String message,
    required VoiceInteractionType type,
    VarkPreferencesStruct? varkPreference,
    Map<String, dynamic>? userContext,
  }) async {
    final GenerativeModel model;
    String systemPrompt = GeminiVoiceConfig.voiceCoachingSystemPrompt;

    // Adapt system prompt based on VARK preferences
    if (varkPreference != null) {
      systemPrompt = _adaptPromptForVARK(systemPrompt, varkPreference);
    }

    // Choose appropriate model based on interaction type
    switch (type) {
      case VoiceInteractionType.thinkingMode:
        model = GeminiVoiceConfig.createThinkingVoiceModel(
          systemInstruction: systemPrompt,
        );
        break;
      case VoiceInteractionType.quickChat:
      case VoiceInteractionType.liveConversation:
      case VoiceInteractionType.ttsOnly:
        model = GeminiVoiceConfig.createVoiceChatModel(
          systemInstruction: systemPrompt,
        );
        break;
    }

    // Build conversation context
    final conversationContext = _buildConversationContext(userContext);
    final fullPrompt = '$conversationContext\n\nUser: $message\n\nCoach:';

    // Generate response
    final response = await model.generateContent([Content.text(fullPrompt)]);
    final responseText = response.text ?? 'I apologize, but I couldn\'t generate a response right now. Please try again.';

    // For thinking mode, extract thinking process if available
    String? thinkingProcess;
    if (type == VoiceInteractionType.thinkingMode && responseText.contains('[THINKING]')) {
      final parts = responseText.split('[THINKING]');
      if (parts.length > 1) {
        final thinkingPart = parts[1].split('[/THINKING]');
        if (thinkingPart.isNotEmpty) {
          thinkingProcess = thinkingPart[0].trim();
        }
      }
    }

    return VoiceAIResponse(
      responseText: responseText,
      thinkingProcess: thinkingProcess,
      audioUrl: null, // TTS will be handled separately
      tokensUsed: GeminiVoiceConfig.estimateTokenCount(fullPrompt + responseText),
      model: type == VoiceInteractionType.thinkingMode 
        ? GeminiVoiceConfig.nativeAudioThinkingModel 
        : GeminiVoiceConfig.flashLiteModel,
    );
  }

  /// Adapt system prompt based on VARK learning preferences
  String _adaptPromptForVARK(String basePrompt, VarkPreferencesStruct varkPref) {
    final varkAdditions = <String>[];

    if (varkPref.visual) {
      varkAdditions.add('''
VISUAL LEARNER ADAPTATIONS:
- Use visual metaphors and imagery in explanations
- Reference seeing, visualizing, and picturing techniques
- Suggest mental imagery exercises and visualization drills
''');
    }

    if (varkPref.aural) {
      varkAdditions.add('''
AUDITORY LEARNER ADAPTATIONS:
- Emphasize rhythm, tempo, and sound-based techniques
- Use verbal cues and audio-based learning methods
- Reference listening, hearing, and sound-related concepts
''');
    }

    if (varkPref.readWrite) {
      varkAdditions.add('''
READ/WRITE LEARNER ADAPTATIONS:
- Suggest note-taking and written reflection exercises
- Reference journaling, lists, and written practice methods
- Provide structured, step-by-step instructions
''');
    }

    if (varkPref.kinesthetic) {
      varkAdditions.add('''
KINESTHETIC LEARNER ADAPTATIONS:
- Emphasize physical practice and body awareness
- Suggest hands-on drills and movement-based techniques
- Reference feeling, experiencing, and physical sensations
''');
    }

    return varkAdditions.isEmpty 
      ? basePrompt 
      : '$basePrompt\n\n${varkAdditions.join('\n')}';
  }

  /// Build conversation context from history and user data
  String _buildConversationContext(Map<String, dynamic>? userContext) {
    final context = StringBuffer();
    
    context.writeln('CONVERSATION CONTEXT:');
    
    // Add user context if available
    if (userContext != null) {
      if (userContext['recentRounds'] != null) {
        context.writeln('Recent golf performance: ${userContext['recentRounds']}');
      }
      if (userContext['currentGoals'] != null) {
        context.writeln('Current goals: ${userContext['currentGoals']}');
      }
      if (userContext['mentalState'] != null) {
        context.writeln('Current mental state: ${userContext['mentalState']}');
      }
    }

    // Add recent conversation history (last 5 messages)
    if (_conversationHistory.isNotEmpty) {
      context.writeln('\nRECENT CONVERSATION:');
      final recentMessages = _conversationHistory.length > 10 
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;
      
      for (final message in recentMessages) {
        final speaker = message.isUser ? 'User' : 'Coach';
        context.writeln('$speaker: ${message.content}');
      }
    }

    context.writeln('\nCURRENT INTERACTION:');
    
    return context.toString();
  }

  /// Speak AI response using TTS
  Future<void> _speakResponse(String text, String? audioUrl) async {
    if (text.isEmpty) return;

    try {
      _isSpeaking = true;
      _updateState(VoiceServiceState.speaking);

      if (audioUrl != null && audioUrl.isNotEmpty) {
        // Use provided audio URL (from native audio models)
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      } else {
        // Use local TTS
        await _flutterTts.speak(text);
      }
      
    } catch (e) {
      _isSpeaking = false;
      _updateState(VoiceServiceState.error);
      if (kDebugMode) {
        print('❌ Error speaking response: $e');
      }
    }
  }

  // ============================================================================
  // SPEECH RECOGNITION CALLBACKS
  // ============================================================================

  void _onSpeechResult(SpeechRecognitionResult result, VoiceInteractionType type) {
    final recognizedWords = result.recognizedWords;
    _transcriptController.add(recognizedWords);

    if (result.finalResult) {
      _isListening = false;
      if (recognizedWords.isNotEmpty) {
        processVoiceMessage(message: recognizedWords, type: type);
      } else {
        _updateState(VoiceServiceState.ready);
      }
    }
  }

  void _onSpeechStatus(String status) {
    if (kDebugMode) {
      print('Speech status: $status');
    }
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _updateState(VoiceServiceState.ready);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (kDebugMode) {
      print('Speech error: ${error.errorMsg}');
    }
    
    _isListening = false;
    _updateState(VoiceServiceState.error);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Update service state and notify listeners
  void _updateState(VoiceServiceState newState) {
    _stateController.add(newState);
  }

  /// Clear conversation history
  void clearConversation() {
    _conversationHistory.clear();
  }

  /// Get conversation summary
  String getConversationSummary() {
    if (_conversationHistory.isEmpty) return '';
    
    final userMessages = _conversationHistory.where((m) => m.isUser).length;
    final aiMessages = _conversationHistory.where((m) => !m.isUser).length;
    
    return 'Session with $userMessages user messages and $aiMessages coach responses';
  }

  /// Export conversation history
  List<Map<String, dynamic>> exportConversation() {
    return _conversationHistory.map((message) => message.toMap()).toList();
  }

  /// Stop all audio playback
  Future<void> stopAudioPlayback() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      await _audioPlayer.stop();
      _isSpeaking = false;
      _updateState(VoiceServiceState.ready);
    }
  }

  /// Dispose of resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _stateController.close();
    _transcriptController.close();
    _volumeController.close();
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Voice service states
enum VoiceServiceState {
  uninitialized,
  ready,
  listening,
  thinking,
  speaking,
  error,
}

/// Voice message model
class VoiceMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final VoiceInteractionType type;
  final String? thinkingProcess;
  final String? audioUrl;

  VoiceMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.thinkingProcess,
    this.audioUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'thinkingProcess': thinkingProcess,
      'audioUrl': audioUrl,
    };
  }

  factory VoiceMessage.fromMap(Map<String, dynamic> map) {
    return VoiceMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      type: VoiceInteractionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => VoiceInteractionType.quickChat,
      ),
      thinkingProcess: map['thinkingProcess'],
      audioUrl: map['audioUrl'],
    );
  }
}

/// AI response model for voice interactions
class VoiceAIResponse {
  final String responseText;
  final String? thinkingProcess;
  final String? audioUrl;
  final int tokensUsed;
  final String model;

  VoiceAIResponse({
    required this.responseText,
    this.thinkingProcess,
    this.audioUrl,
    required this.tokensUsed,
    required this.model,
  });
}