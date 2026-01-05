import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/glass_design_system.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '../services/unified_ai_service.dart';
import '../services/cartesia_api_service.dart';
import '../services/permission_service.dart';
import '../services/ai_memory_service.dart';
import '../services/gemini_live_service_simple.dart';
import '../services/gemini_native_audio_service.dart';
import '../services/voice_chat_database_service.dart';
import '../services/enhanced_ai_coaching_service.dart';
import '../services/vertex_ai_gemini_live_service.dart';
import '../config/gemini_live_config.dart';

import '/backend/schema/structs/vark_preferences_struct.dart';

/// Chat message model for voice chat interface
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool? isSystem;
  final String? audioUrl;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isSystem,
    this.audioUrl,
  });
}

/// FoCoCo AI Coach Voice Chat Modal - Unified conversational interface
/// Provides seamless voice and text interaction with the AI mental performance coach
/// Automatically handles voice services in background with VARK learning preferences
class FoCoCoVoiceChatModal extends StatefulWidget {
  final VarkPreferencesStruct? varkPreferences;
  final String? initialRoom;
  final bool initialVoiceMode;

  const FoCoCoVoiceChatModal({
    Key? key,
    this.varkPreferences,
    this.initialRoom,
    this.initialVoiceMode = false, // Default to text mode
  }) : super(key: key);

  @override
  State<FoCoCoVoiceChatModal> createState() => _FoCoCoVoiceChatModalState();
}

// Keep the old name for backward compatibility
@Deprecated('Use FoCoCoVoiceChatModal instead')
class VoiceChatModal extends FoCoCoVoiceChatModal {
  const VoiceChatModal({Key? key}) : super(key: key);
}

class _FoCoCoVoiceChatModalState extends State<FoCoCoVoiceChatModal>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _slideController;
  late AnimationController _waveController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _waveAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  // Enhanced voice services - Native Audio + Cartesia for speech + Database
  final UnifiedAIService _aiService = UnifiedAIService();
  final CartesiaAPIService _cartesiaService = CartesiaAPIService.instance;
  final PermissionService _permissionService = PermissionService();
  final AIMemoryService _memoryService = AIMemoryService();
  final GeminiNativeAudioService _nativeAudioService =
      GeminiNativeAudioService();
  final VoiceChatDatabaseService _databaseService = VoiceChatDatabaseService();

  GeminiLiveServiceState _voiceState = GeminiLiveServiceState.disconnected;
  List<ChatMessage> _messages = [];
  String _interactionType = 'quickChat';
  bool _isTyping = false;
  bool _isDeepThinking = false;
  PermissionServiceState _microphonePermission = PermissionServiceState.unknown;

  // Database session management
  VoiceChatSession? _currentSession;
  String? _currentSessionId;
  List<VoiceChatSession> _conversationHistory = [];
  bool _isLoadingHistory = false;
  bool _showHistoryDrawer = false;

  // Streamlined service status
  bool _isAISpeaking = false;
  bool _isListening = false;
  bool _isVoiceEnabled = true; // Voice toggle state
  bool _isAutoReadEnabled =
      false; // Auto-read toggle state (disabled by default)
  bool _isVoiceMode = false; // Speech-to-speech mode (Gemini Live)
  bool _isLocationEnabled = false; // Location toggle state

  // Vertex AI Gemini Live service for speech-to-speech
  final VertexAIGeminiLiveService _vertexAILiveService =
      VertexAIGeminiLiveService();

  // Voice selection - hardcoded to Cartesia Custom Voice 3 (sonic-2 model)
  static const String _voiceId = '7442d6b8-ff51-4477-bd30-0c0d16df84eb';
  static const String _voiceName = 'FoCoCo AI Coach Voice';
  String get _selectedVoiceId => _voiceId;

  // VARK preferences with default values
  late VarkPreferencesStruct _varkPrefs;

  @override
  void initState() {
    super.initState();

    // Initialize VARK preferences
    _varkPrefs = widget.varkPreferences ??
        VarkPreferencesStruct(
          visual: false,
          aural: true, // Default to auditory for voice chat
          readWrite: false,
          kinesthetic: false,
        );

    // Initialize voice mode from widget parameter
    _isVoiceMode = widget.initialVoiceMode;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Add lifecycle observer to refresh permissions when app resumes
    WidgetsBinding.instance.addObserver(this);

    // Initialize voice services and start animations
    _initializeVoiceServices();
    _slideController.forward();

    // Listen to voice service streams
    _setupVoiceListeners();

    // Listen to permission changes
    _setupPermissionListeners();

    // Load preferences
    _loadVoicePreference();
    _loadAutoReadPreference();

    // Initialize Vertex AI Live service if voice mode is enabled
    if (_isVoiceMode) {
      _initializeVertexAILiveService();
    }
  }

  Future<void> _loadVoicePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voiceEnabled = prefs.getBool('voice_chat_voice_enabled') ?? true;
      if (mounted) {
        setState(() {
          _isVoiceEnabled = voiceEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading voice preference: $e');
    }
  }

  Future<void> _saveVoicePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_chat_voice_enabled', _isVoiceEnabled);
    } catch (e) {
      debugPrint('Error saving voice preference: $e');
    }
  }

  Future<void> _loadAutoReadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoReadEnabled =
          prefs.getBool('voice_chat_auto_read_enabled') ?? false;
      if (mounted) {
        setState(() {
          _isAutoReadEnabled = autoReadEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading auto-read preference: $e');
    }
  }

  Future<void> _saveAutoReadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_chat_auto_read_enabled', _isAutoReadEnabled);
    } catch (e) {
      debugPrint('Error saving auto-read preference: $e');
    }
  }

  @override
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes, refresh microphone permission status
    // This handles the case where user grants permission in Settings and returns
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('🔄 App resumed - refreshing microphone permission status');
      }

      // Store previous state to detect changes
      final previousState = _microphonePermission;

      _permissionService.refreshMicrophonePermission().then((permissionState) {
        if (mounted) {
          setState(() {
            _microphonePermission = permissionState;
          });

          // If permission was just granted (changed from denied/permanentlyDenied to granted)
          if (permissionState == PermissionServiceState.granted &&
              previousState != PermissionServiceState.granted) {
            _addMessage(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content:
                    '✅ Microphone permission granted! Voice features are now available.',
                isUser: false,
                timestamp: DateTime.now(),
                isSystem: true,
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _slideController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    _textController.dispose();

    // Disconnect voice services (don't dispose singletons)
    try {
      if (_vertexAILiveService.isConnected) {
        _vertexAILiveService.disconnect();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting Vertex AI Live: $e');
      }
    }

    try {
      if (_nativeAudioService.isConnected) {
        _nativeAudioService.disconnect();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting native audio: $e');
      }
    }

    // End database session
    _endCurrentSession();

    super.dispose();
  }

  /// End the current database session
  Future<void> _endCurrentSession() async {
    if (_currentSessionId != null) {
      try {
        await _databaseService.endSession(_currentSessionId!);
        if (kDebugMode) {
          print('📊 Ended database session: $_currentSessionId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error ending database session: $e');
        }
      }
    }
  }

  Future<void> _initializeVoiceServices() async {
    try {
      // Initialize permission service first
      await _permissionService.initialize();

      // Initialize AI memory service
      await _memoryService.initialize();

      // Initialize database service and load conversation history
      await _databaseService.initialize();
      await _loadConversationHistory();
      await _startNewSession();

      // Initialize unified AI service for generating responses
      await _aiService.initialize();
      if (kDebugMode) {
        print('✅ Unified AI service initialized');
      }

      // Initialize Enhanced AI Coaching service (uses Firebase AI Logic)
      final _enhancedCoachingService = EnhancedAICoachingService();
      try {
        await _enhancedCoachingService.initialize();
        if (kDebugMode) {
          print('✅ Enhanced AI Coaching service initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Enhanced AI Coaching service failed: $e');
        }
      }

      // Note: Gemini Native Audio requires direct API access
      // For now, we'll use Firebase AI Logic with enhanced structured responses
      if (kDebugMode) {
        print('ℹ️ Using Firebase AI Logic for enhanced coaching features');
      }

      // Initialize Cartesia for speech synthesis with selected voice
      try {
        await _cartesiaService.initialize();
        _cartesiaService.setVoiceId(_selectedVoiceId);
        if (kDebugMode) {
          print(
              '✅ Cartesia voice service initialized with $_voiceName ($_selectedVoiceId)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cartesia service failed: $e');
        }
        // Continue with text-only mode
      }

      setState(() {
        _voiceState = GeminiLiveServiceState.connected;
      });

      // Check microphone permission and show appropriate message
      final micState = await _permissionService.checkMicrophonePermission();
      setState(() {
        _microphonePermission = micState;
      });

      // Voice services initialized - chat is ready but starts clean
      if (kDebugMode) {
        final status = _cartesiaService.isInitialized
            ? 'Voice ready with $_voiceName'
            : 'Text chat ready';
        print('✅ FoCoCo AI Coach: $status');
      }

      // Clean chat - no sample conversation

      // Start with clean chat - no automatic messages
      // Welcome message will be shown only in empty state
    } catch (e) {
      setState(() {
        _voiceState = GeminiLiveServiceState.error;
      });

      // Simplified error handling
      String errorMessage =
          '📝 FoCoCo AI Coach ready for text chat! I\'m here to help with your mental game. Some voice features may be limited, but you can always type your questions.';

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );
    }
  }

  /// Initialize Vertex AI Gemini Live service for speech-to-speech
  Future<void> _initializeVertexAILiveService() async {
    try {
      // Get project ID from Firebase configuration
      final projectId = Firebase.app().options.projectId;
      
      await _vertexAILiveService.initialize(
        projectId: projectId,
        varkPreferences: _varkPrefs,
      );

      // Listen to Vertex AI Live service state changes
      _vertexAILiveService.stateStream.listen((state) {
        if (mounted) {
          setState(() {
            switch (state) {
              case VertexAIGeminiLiveState.listening:
                _voiceState = GeminiLiveServiceState.listening;
                _isListening = true;
                _isAISpeaking = false;
                break;
              case VertexAIGeminiLiveState.speaking:
                _voiceState = GeminiLiveServiceState.speaking;
                _isListening = false;
                _isAISpeaking = true;
                break;
              case VertexAIGeminiLiveState.thinking:
                _voiceState = GeminiLiveServiceState.speaking;
                _isListening = false;
                _isAISpeaking = true;
                break;
              case VertexAIGeminiLiveState.connected:
                _voiceState = GeminiLiveServiceState.connected;
                _isListening = false;
                _isAISpeaking = false;
                break;
              case VertexAIGeminiLiveState.disconnected:
                _voiceState = GeminiLiveServiceState.disconnected;
                _isListening = false;
                _isAISpeaking = false;
                break;
              case VertexAIGeminiLiveState.error:
                _voiceState = GeminiLiveServiceState.error;
                _isListening = false;
                _isAISpeaking = false;
                break;
              default:
                break;
            }
          });

          // Update wave animation based on state
          if (state == VertexAIGeminiLiveState.listening ||
              state == VertexAIGeminiLiveState.speaking ||
              state == VertexAIGeminiLiveState.thinking) {
            _waveController.repeat(reverse: true);
          } else {
            _waveController.stop();
          }
        }
      });

      // Listen to Vertex AI Live responses
      _vertexAILiveService.responseStream.listen((response) async {
        if (mounted && response.text != null && response.text!.isNotEmpty) {
          // Add AI response to chat
          final aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response.text!,
            isUser: false,
            timestamp: DateTime.now(),
          );
          _addMessage(aiMessage);

          // Store in memory
          _memoryService.addConversationTurn(
            userMessage: '',
            aiResponse: response.text!,
            messageType: 'vertex_ai_live',
          );

          // Thinking process removed - body should only show responses

          // Convert text response to speech using Cartesia TTS
          // Auto-play response when voice mode is active or auto-read is enabled
          if ((_isVoiceMode || (_isVoiceEnabled && _isAutoReadEnabled)) &&
              _cartesiaService.isInitialized) {
            setState(() {
              _isAISpeaking = true;
            });

            // Strip markdown for TTS
            final cleanTextForTTS = _stripMarkdownForTTS(response.text!);

            // Use Cartesia to speak the response
            _cartesiaService
                .speakText(
              text: cleanTextForTTS,
              voiceId: _selectedVoiceId,
              contentType: 'coaching',
              varkPreferences: _varkPrefs,
            )
                .then((_) {
              // Update state when TTS completes
              if (mounted) {
                setState(() {
                  _isAISpeaking = false;
                });
              }
            }).catchError((e) {
              debugPrint('Cartesia TTS error: $e');
              if (mounted) {
                setState(() {
                  _isAISpeaking = false;
                });
              }
            });
          }
        }
      });

      // Listen to transcripts
      _vertexAILiveService.transcriptStream.listen((transcript) {
        if (mounted && transcript.isNotEmpty) {
          if (kDebugMode) {
            print('📝 Vertex AI Live Transcript: $transcript');
          }
        }
      });

      if (kDebugMode) {
        print('✅ Vertex AI Gemini Live service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Vertex AI Gemini Live service failed: $e');
      }
    }
  }

  void _setupVoiceListeners() {
    // Listen to Native Audio service state changes
    _nativeAudioService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          switch (state) {
            case GeminiNativeAudioState.listening:
              _voiceState = GeminiLiveServiceState.listening;
              _isListening = true;
              _isAISpeaking = false;
              break;
            case GeminiNativeAudioState.speaking:
              _voiceState = GeminiLiveServiceState.speaking;
              _isListening = false;
              _isAISpeaking = true;
              break;
            case GeminiNativeAudioState.thinking:
              _voiceState = GeminiLiveServiceState.speaking;
              _isListening = false;
              _isAISpeaking = true;
              break;
            case GeminiNativeAudioState.connected:
              _voiceState = GeminiLiveServiceState.connected;
              _isListening = false;
              _isAISpeaking = false;
              break;
            case GeminiNativeAudioState.disconnected:
              _voiceState = GeminiLiveServiceState.disconnected;
              _isListening = false;
              _isAISpeaking = false;
              break;
            case GeminiNativeAudioState.error:
              _voiceState = GeminiLiveServiceState.error;
              _isListening = false;
              _isAISpeaking = false;
              break;
            default:
              break;
          }
        });

        // Update wave animation based on state
        if (state == GeminiNativeAudioState.listening ||
            state == GeminiNativeAudioState.speaking ||
            state == GeminiNativeAudioState.thinking) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });

    // Listen to Native Audio responses
    _nativeAudioService.responseStream.listen((response) {
      if (mounted && response.text.isNotEmpty) {
        // Add AI response to chat
        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response.text,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _addMessage(aiMessage);

        // Store in memory
        _memoryService.addConversationTurn(
          userMessage: '', // Previous user message already stored
          aiResponse: response.text,
          messageType: 'native_audio',
        );

        // Thinking process removed - body should only show responses
      }
    });

    // Listen to Native Audio transcripts
    _nativeAudioService.transcriptStream.listen((transcript) {
      if (mounted && transcript.isNotEmpty) {
        if (kDebugMode) {
          print('📝 Native Audio Transcript: $transcript');
        }
      }
    });

    // Listen to Cartesia speaking state (fallback TTS)
    _cartesiaService.speakingStream.listen((isSpeaking) {
      if (mounted && !_nativeAudioService.isConnected) {
        setState(() {
          _isAISpeaking = isSpeaking;
          _voiceState = isSpeaking
              ? GeminiLiveServiceState.speaking
              : GeminiLiveServiceState.connected;
        });

        // Update wave animation for fallback TTS
        if (isSpeaking) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();

    // Save message to database
    _saveMessageToDatabase(message);
  }

  /// Load conversation history
  Future<void> _loadConversationHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final sessions = await _databaseService.getUserSessions(limit: 20);
      if (mounted) {
        setState(() {
          _conversationHistory = sessions;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading conversation history: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  /// Start a new voice chat session in the database
  Future<void> _startNewSession() async {
    try {
      // End current session if exists
      if (_currentSessionId != null) {
        await _endCurrentSession();
      }

      // Clear current messages for new session
      setState(() {
        _messages.clear();
      });

      final session = await _databaseService.startSession(
        title: widget.initialRoom ?? 'Voice Chat Session',
        varkPreferences: _varkPrefs,
        isDeepThinking: _isDeepThinking,
        metadata: {
          'voiceService': 'FoCoCo Native Audio + Cartesia',
          'startedAt': DateTime.now().toIso8601String(),
          'platform': defaultTargetPlatform.toString(),
        },
      );

      _currentSession = session;
      _currentSessionId = session.id;

      // Reload history to include new session
      await _loadConversationHistory();

      if (kDebugMode) {
        print('📊 Started database session: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting database session: $e');
      }
    }
  }

  /// Load messages for a specific session
  Future<void> _loadSessionMessages(String sessionId) async {
    try {
      setState(() {
        _isLoadingHistory = true;
      });

      // End current session
      if (_currentSessionId != null && _currentSessionId != sessionId) {
        await _endCurrentSession();
      }

      // Load messages for selected session
      final messages = await _databaseService.getSessionMessages(
        sessionId: sessionId,
        limit: 100,
      );

      // Convert VoiceChatMessage to ChatMessage
      final chatMessages = messages.map((msg) {
        return ChatMessage(
          id: msg.id,
          content: msg.content,
          isUser: msg.isUser,
          timestamp: msg.timestamp,
          isSystem: msg.isSystem,
          audioUrl: msg.audioUrl,
        );
      }).toList();

      // Find session details
      final session = _conversationHistory.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => _currentSession!,
      );

      if (mounted) {
        setState(() {
          _messages = chatMessages;
          _currentSession = session;
          _currentSessionId = sessionId;
          _isDeepThinking = session.isDeepThinking;
          _isLoadingHistory = false;
          _showHistoryDrawer = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading session messages: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  /// Save message to database
  Future<void> _saveMessageToDatabase(ChatMessage message) async {
    if (_currentSessionId == null) return;

    try {
      // Get current user ID from Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ User not authenticated, skipping database save');
        }
        return;
      }

      final dbMessage = VoiceChatMessage(
        id: message.id,
        userId: userId,
        sessionId: _currentSessionId!,
        content: message.content,
        isUser: message.isUser,
        timestamp: message.timestamp,
        isSystem: message.isSystem,
        audioUrl: message.audioUrl,
        messageType: _determineMessageType(message),
        metadata: {
          'interactionType': _interactionType,
          'isDeepThinking': _isDeepThinking,
          'voiceState': _voiceState.toString(),
        },
      );

      await _databaseService.saveMessage(dbMessage);

      if (kDebugMode) {
        print('💾 Saved message to database: ${message.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving message to database: $e');
      }
    }
  }

  /// Determine message type for database classification
  String _determineMessageType(ChatMessage message) {
    if (message.isSystem == true) return 'system';
    if (message.audioUrl != null) return 'audio';
    if (message.content.contains('![') && message.content.contains(']('))
      return 'image';
    if (_nativeAudioService.isConnected && !message.isUser)
      return 'native_audio';
    return 'text';
  }

  Future<String> _generateAIResponse(String userInput) async {
    try {
      // Build conversation context from recent messages and AI memory
      final conversationContext =
          _memoryService.getConversationContext(maxTurns: 8); // More context
      final userInsights = _memoryService.getUserInsights();
      final personalizedPrompt = _memoryService.getPersonalizedSystemPrompt();

      // Enhanced context with chat history
      final fullContext =
          _buildEnhancedContext(conversationContext, personalizedPrompt);

      // Check if user is requesting image generation
      if (_shouldGenerateImage(userInput)) {
        return await _generateResponseWithImage(
          userInput: userInput,
          conversationContext: fullContext,
          userInsights: userInsights,
        );
      }

      // Generate regular text response using unified AI service with enhanced context
      final response = await _generateEnhancedAIResponse(
        userMessage: userInput,
        conversationContext: fullContext,
        varkPreferences: _varkPrefs,
        interactionType: _interactionType,
        userInsights: userInsights,
      );

      // Validate response
      if (response.trim().isEmpty) {
        throw Exception('Empty response from AI service');
      }

      // Store conversation turn in AI memory for learning
      await _memoryService.addConversationTurn(
        userMessage: userInput,
        aiResponse: response,
        messageType: 'text',
      );

      // Update speaking indicator
      setState(() {
        _isAISpeaking = true;
      });

      // Reset after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAISpeaking = false;
          });
        }
      });

      return response;
    } catch (e) {
      debugPrint('Error generating AI response: $e');

      // Provide contextual fallback responses
      final fallbackResponse = _generateContextualFallback(userInput);

      // Still store the interaction for learning
      try {
        await _memoryService.addConversationTurn(
          userMessage: userInput,
          aiResponse: fallbackResponse,
          messageType: 'text',
        );
      } catch (_) {
        // Ignore memory errors in fallback
      }

      return fallbackResponse;
    }
  }

  /// Generate enhanced AI response with rich formatting and context
  Future<String> _generateEnhancedAIResponse({
    required String userMessage,
    String? conversationContext,
    VarkPreferencesStruct? varkPreferences,
    String interactionType = 'quickChat',
    Map<String, dynamic>? userInsights,
  }) async {
    // Enhanced prompt that encourages rich formatting
    final enhancedPrompt = '''
$conversationContext

You are an AI mental performance coach for golf. Respond with rich markdown formatting including:
- Use **bold** for key points
- Use *italics* for emphasis
- Use headers (## for main topics, ### for subtopics)
- Use bullet points and numbered lists
- Use > blockquotes for important insights
- Use tables when presenting data or comparisons
- Use `code blocks` for specific techniques or exercises

${_isDeepThinking ? 'DEEP THINKING MODE: Provide thorough analysis with detailed explanations, structured content, and actionable insights. Keep responses under 500 words.' : 'QUICK CHAT MODE: Provide concise, focused advice with key highlights. Keep responses brief and under 300 words.'}

VARK Learning Style: ${_getVarkDescription()}

User Message: $userMessage

Respond as a professional golf mental coach with expertise in sports psychology:''';

    final response = await _aiService.generateResponse(
      userMessage: enhancedPrompt,
      conversationContext: conversationContext,
      varkPreferences: varkPreferences,
      interactionType: interactionType,
      userInsights: userInsights,
    );

    // Limit response length - keep responses concise
    // For quick chat: max 300 words, for deep thinking: max 500 words
    final maxWords = _isDeepThinking ? 500 : 300;
    final words = response.split(' ');
    if (words.length > maxWords) {
      final truncated = words.take(maxWords).join(' ');
      return '$truncated...\n\n[Response truncated for brevity]';
    }

    return response;
  }

  /// Check if user input suggests they want an image generated
  bool _shouldGenerateImage(String input) {
    final imageKeywords = [
      'draw',
      'picture',
      'image',
      'visual',
      'diagram',
      'chart',
      'graph',
      'illustration',
      'sketch',
      'show me',
      'visualize',
      'create image',
      'generate picture',
      'make diagram'
    ];

    final lowercaseInput = input.toLowerCase();
    return imageKeywords.any((keyword) => lowercaseInput.contains(keyword));
  }

  /// Generate response with image using Gemini 2.5 Flash Image Preview
  Future<String> _generateResponseWithImage({
    required String userInput,
    required String conversationContext,
    required Map<String, dynamic>? userInsights,
  }) async {
    try {
      // First, generate a text response with image description
      final textResponse = await _generateEnhancedAIResponse(
        userMessage: userInput,
        conversationContext: conversationContext,
        varkPreferences: _varkPrefs,
        interactionType: _interactionType,
        userInsights: userInsights,
      );

      // Generate image using Gemini 2.5 Flash Image Preview
      final imagePrompt = _extractImagePromptFromInput(userInput);
      final imageUrl = await _generateImageWithGemini(imagePrompt);

      if (imageUrl != null) {
        // Combine text response with image in markdown format
        return '''$textResponse

## Visual Illustration

![Generated coaching visualization]($imageUrl)

*This image was generated to help visualize the concept based on your request.*''';
      } else {
        // If image generation fails, return text response with explanation
        return '''$textResponse

> *I'd love to create a visual illustration for you, but I'm having some technical difficulties with image generation right now. The detailed explanation above should still be very helpful!*''';
      }
    } catch (e) {
      debugPrint('Error generating response with image: $e');
      // Fallback to regular text response
      return await _generateEnhancedAIResponse(
        userMessage: userInput,
        conversationContext: conversationContext,
        varkPreferences: _varkPrefs,
        interactionType: _interactionType,
        userInsights: userInsights,
      );
    }
  }

  /// Extract image prompt from user input
  String _extractImagePromptFromInput(String input) {
    // Create a focused prompt for image generation based on golf coaching context
    final basePrompt =
        '''Create a professional golf mental training illustration showing ''';

    final cleanInput = input
        .toLowerCase()
        .replaceAll(
            RegExp(
                r'\b(draw|picture|image|visual|diagram|show me|visualize|create|generate)\b'),
            '')
        .trim();

    if (cleanInput.contains('putting')) {
      return '$basePrompt a golfer in proper putting stance with mental focus visualization, showing confidence and concentration techniques';
    } else if (cleanInput.contains('swing')) {
      return '$basePrompt a golfer mid-swing with mental imagery overlay showing focus points and confidence building elements';
    } else if (cleanInput.contains('pressure') ||
        cleanInput.contains('nerves')) {
      return '$basePrompt breathing techniques and mental calmness strategies for golf, with visual representations of relaxation and focus';
    } else if (cleanInput.contains('routine') ||
        cleanInput.contains('pre-shot')) {
      return '$basePrompt a step-by-step pre-shot routine with mental checkpoints and visualization elements for golf';
    } else {
      return '$basePrompt mental performance techniques for golf including visualization, focus, and confidence building strategies';
    }
  }

  /// Generate image using Gemini 2.5 Flash Image Preview
  Future<String?> _generateImageWithGemini(String prompt) async {
    try {
      // This would integrate with Gemini 2.5 Flash Image Preview API
      // For now, return a placeholder that indicates image generation capability
      // In a real implementation, you would call the Gemini Image API here

      // Placeholder implementation - replace with actual Gemini Image API call
      debugPrint('🎨 Generating image with prompt: $prompt');

      // Return null for now - actual implementation would return the generated image URL
      return null;
    } catch (e) {
      debugPrint('Error generating image: $e');
      return null;
    }
  }

  /// Get VARK learning style description for prompts
  String _getVarkDescription() {
    if (_varkPrefs.visual)
      return 'Visual learner - prefer diagrams, charts, and visual explanations';
    if (_varkPrefs.aural)
      return 'Auditory learner - prefer spoken explanations and sound-based learning';
    if (_varkPrefs.readWrite)
      return 'Read/Write learner - prefer text, lists, and written instructions';
    if (_varkPrefs.kinesthetic)
      return 'Kinesthetic learner - prefer hands-on practice and physical demonstrations';
    return 'Balanced learning style - appreciate multiple learning approaches';
  }

  Widget _buildHistoryDrawer(FlutterFlowTheme theme) {
    if (!_showHistoryDrawer) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showHistoryDrawer = false;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.glassBackground.withValues(
                        alpha: GlassDesignSystem.glassOpacity + 0.2),
                    theme.glassTint.withValues(
                        alpha: GlassDesignSystem.glassOpacity + 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.glassBorder.withValues(
                      alpha: GlassDesignSystem.glassBorderOpacity + 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: GlassDesignSystem.glassBlur,
                    sigmaY: GlassDesignSystem.glassBlur,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Conversation History',
                                style: theme.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showHistoryDrawer = false;
                                });
                              },
                              icon: const Icon(Icons.close),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              onPressed: _startNewSession,
                              icon: const Icon(Icons.add),
                              tooltip: 'New Conversation',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoadingHistory
                            ? const Center(child: CircularProgressIndicator())
                            : _conversationHistory.isEmpty
                                ? Center(
                                    child: Text(
                                      'No previous conversations',
                                      style: theme.bodyMedium.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: _conversationHistory.length,
                                    itemBuilder: (context, index) {
                                      final session =
                                          _conversationHistory[index];
                                      final isActive =
                                          session.id == _currentSessionId;
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? theme.primary
                                                  .withValues(alpha: 0.1)
                                              : theme.accent4
                                                  .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isActive
                                                ? theme.primary
                                                    .withValues(alpha: 0.3)
                                                : theme.accent4
                                                    .withValues(alpha: 0.2),
                                            width: isActive ? 2 : 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            session.title,
                                            style: theme.bodyMedium.copyWith(
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isActive
                                                  ? theme.primary
                                                  : theme.primaryText,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${session.messageCount} messages • ${_formatSessionDate(session.startTime)}',
                                            style: theme.bodySmall.copyWith(
                                              color: theme.secondaryText,
                                            ),
                                          ),
                                          trailing: isActive
                                              ? Icon(
                                                  Icons.check_circle,
                                                  color: theme.primary,
                                                  size: 20,
                                                )
                                              : null,
                                          onTap: () {
                                            _loadSessionMessages(session.id);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: screenHeight * 0.85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryBackground,
                  theme.secondaryBackground,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(theme),
                _buildServiceIndicator(theme),
                _buildDeepThinkingToggle(theme),
                Expanded(child: _buildChatInterface(theme)),
                _buildVoiceVisualization(theme),
                _buildBottomInput(theme),
              ],
            ),
          ),
        ),
        _buildHistoryDrawer(theme),
      ],
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.accent4.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Logo + Title/Subtitle on left, Close button on right
          Row(
            children: [
              // Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo/Logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          FontAwesomeIcons.brain,
                          color: theme.primary,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShimmerTitle(theme),
                    const SizedBox(height: 4),
                    Text(
                      'Featuring Carter, your AI Coach',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ready to help strengthen your mind and game.',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Close button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: theme.secondaryText,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Voice mode toggle, Auto-read toggle, Voice toggle, and History button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice Mode toggle (Speech-to-Speech)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isVoiceMode
                        ? theme.primary.withValues(alpha: 0.1)
                        : theme.accent4.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isVoiceMode
                          ? theme.primary.withValues(alpha: 0.3)
                          : theme.accent4.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic_external_on,
                        color:
                            _isVoiceMode ? theme.primary : theme.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live',
                        style: theme.bodySmall.copyWith(
                          color: _isVoiceMode
                              ? theme.primary
                              : theme.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            _isVoiceMode = !_isVoiceMode;
                          });
                          HapticFeedback.selectionClick();

                          // Initialize or disconnect Vertex AI Live based on mode
                          if (_isVoiceMode) {
                            await _initializeVertexAILiveService();
                            _addMessage(
                              ChatMessage(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                content:
                                    '🎤 **Voice Mode Enabled** - Speak your question!',
                                isUser: false,
                                timestamp: DateTime.now(),
                                isSystem: true,
                              ),
                            );
                          } else {
                            await _vertexAILiveService.disconnect();
                            _addMessage(
                              ChatMessage(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                content: '📝 **Text Mode Enabled**',
                                isUser: false,
                                timestamp: DateTime.now(),
                                isSystem: true,
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: _isVoiceMode
                                ? theme.primary
                                : theme.accent4.withValues(alpha: 0.3),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isVoiceMode
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Auto-read toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAutoReadEnabled
                        ? theme.primary.withValues(alpha: 0.1)
                        : theme.accent4.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAutoReadEnabled
                          ? theme.primary.withValues(alpha: 0.3)
                          : theme.accent4.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: _isAutoReadEnabled
                            ? theme.primary
                            : theme.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-read',
                        style: theme.bodySmall.copyWith(
                          color: _isAutoReadEnabled
                              ? theme.primary
                              : theme.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAutoReadEnabled = !_isAutoReadEnabled;
                          });
                          HapticFeedback.selectionClick();
                          _saveAutoReadPreference();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: _isAutoReadEnabled
                                ? theme.primary
                                : theme.accent4.withValues(alpha: 0.3),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isAutoReadEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Voice toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isVoiceEnabled
                        ? theme.primary.withValues(alpha: 0.1)
                        : theme.accent4.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isVoiceEnabled
                          ? theme.primary.withValues(alpha: 0.3)
                          : theme.accent4.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                        color: _isVoiceEnabled
                            ? theme.primary
                            : theme.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Voice',
                        style: theme.bodySmall.copyWith(
                          color: _isVoiceEnabled
                              ? theme.primary
                              : theme.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isVoiceEnabled = !_isVoiceEnabled;
                          });
                          HapticFeedback.selectionClick();
                          _saveVoicePreference();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: _isVoiceEnabled
                                ? theme.primary
                                : theme.accent4.withValues(alpha: 0.3),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isVoiceEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // More icon button (moved to right side)
                IconButton(
                  onPressed: () {
                    _showQuickActionsMenu(theme);
                  },
                  icon: Icon(
                    Icons.more_horiz,
                    color: theme.secondaryText,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'More Options',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIndicator(FlutterFlowTheme theme) {
    if (!_isAISpeaking && !_isListening) {
      return const SizedBox.shrink();
    }

    final isListening = _isListening;
    final indicatorColor = isListening
        ? const Color(0xFF10B981) // Green for listening
        : const Color(0xFF6366F1); // Indigo for speaking
    final indicatorIcon =
        isListening ? FontAwesomeIcons.microphone : FontAwesomeIcons.waveSquare;
    final statusText = isListening ? 'Listening...' : 'Speaking...';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicatorIcon,
            color: indicatorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: theme.bodySmall.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Build shimmer gradient title
  Widget _buildShimmerTitle(FlutterFlowTheme theme) {
    return Shimmer.fromColors(
      baseColor: theme.primary.withValues(alpha: 0.5),
      highlightColor: theme.primary,
      period: const Duration(milliseconds: 1500),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary,
            theme.primary.withValues(alpha: 0.8),
            theme.secondary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: Text(
          'JustTalk',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDeepThinkingToggle(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDeepThinking
              ? [
                  theme.primary.withValues(alpha: 0.15),
                  theme.primary.withValues(alpha: 0.08),
                ]
              : [
                  theme.accent4.withValues(alpha: 0.08),
                  theme.accent4.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDeepThinking
              ? theme.primary.withValues(alpha: 0.4)
              : theme.accent4.withValues(alpha: 0.3),
          width: _isDeepThinking ? 2 : 1.5,
        ),
        boxShadow: _isDeepThinking
            ? [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDeepThinking
                  ? theme.primary.withValues(alpha: 0.2)
                  : theme.accent4.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _isDeepThinking
                  ? [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                FontAwesomeIcons.brain,
                key: ValueKey(_isDeepThinking),
                color: _isDeepThinking ? theme.primary : theme.secondaryText,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deep Thinking Mode',
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isDeepThinking ? theme.primary : theme.primaryText,
                    fontSize: 14,
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isDeepThinking
                      ? 'Takes longer, uses more data'
                      : 'Quick responses',
                  style: theme.bodySmall.copyWith(
                    color: _isDeepThinking
                        ? theme.primary.withValues(alpha: 0.9)
                        : theme.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleDeepThinking,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _isDeepThinking
                    ? theme.primary
                    : theme.accent4.withValues(alpha: 0.4),
                boxShadow: _isDeepThinking
                    ? [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: _isDeepThinking
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(FlutterFlowTheme theme) {
    if (_messages.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Filter out system messages - body should only show responses
    final responseMessages = _messages.where((msg) => msg.isSystem != true).toList();
    
    if (responseMessages.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: responseMessages.length,
      itemBuilder: (context, index) {
        final message = responseMessages[index];
        return _buildSimpleMessageBubble(theme, message, index);
      },
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.microphone,
              size: 48,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Your Mental Training',
            style: theme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone or type to begin\nyour conversation with the AI coach',
            textAlign: TextAlign.center,
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMessageBubble(
      FlutterFlowTheme theme, ChatMessage message, int index) {
    final isUser = message.isUser;
    final isSystem = message.isSystem ?? false;

    // Hide system messages - body should only show responses
    if (isSystem) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarIcon(theme, false),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.primary
                          : theme.accent4.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(20),
                        bottomLeft: !isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(20),
                      ),
                    ),
                    child: !isUser
                        ? _buildRichMarkdownText(theme, message.content)
                        : Text(
                            _cleanMarkdownText(message.content),
                            style: theme.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatarIcon(theme, true),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon(FlutterFlowTheme theme, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? theme.primary.withValues(alpha: 0.1)
            : theme.accent3.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : FontAwesomeIcons.robot,
        size: 16,
        color: isUser ? theme.primary : theme.accent3,
      ),
    );
  }

  Widget _buildVoiceVisualization(FlutterFlowTheme theme) {
    if (_voiceState != GeminiLiveServiceState.listening &&
        _voiceState != GeminiLiveServiceState.speaking) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final height = 20 +
                  (math.sin((_waveAnimation.value * 2 * math.pi) +
                          (index * 0.5)) *
                      15);

              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildBottomInput(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(
          top: BorderSide(
            color: theme.accent4.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // TextField
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: theme.accent4.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.accent4.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendTextMessage(text.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: theme.bodyMedium.copyWith(
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: theme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Audio/Voice button
            GestureDetector(
              onTap: () {
                if (_microphonePermission == PermissionServiceState.granted) {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                } else {
                  _requestMicrophonePermission();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isListening
                      ? theme.primary
                      : theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isListening
                        ? theme.primary
                        : theme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _isListening
                      ? FontAwesomeIcons.stop
                      : FontAwesomeIcons.microphone,
                  color: _isListening ? Colors.white : theme.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextInputDialog(FlutterFlowTheme theme) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.primaryBackground,
        title: Text(
          'Send Message',
          style: theme.headlineSmall,
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                _sendTextMessage(textController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu(FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.history, color: theme.primary),
              title: Text('Conversation History'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _showHistoryDrawer = !_showHistoryDrawer;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.primary),
              title: Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                // Show settings
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: theme.primary),
              title: Text('Help'),
              onTap: () {
                Navigator.of(context).pop();
                // Show help
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ACTION METHODS
  // ============================================================================

  /// Toggle deep thinking mode
  void _toggleDeepThinking() async {
    setState(() {
      _isDeepThinking = !_isDeepThinking;
      _interactionType = _isDeepThinking ? 'thinkingMode' : 'quickChat';
    });

    HapticFeedback.selectionClick();

    // Update native audio service thinking mode
    try {
      await _nativeAudioService.setThinkingMode(_isDeepThinking);
      if (kDebugMode) {
        print('🧠 Native Audio thinking mode: $_isDeepThinking');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error updating native audio thinking mode: $e');
      }
    }

    // Add system message about mode change
    final modeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _isDeepThinking
          ? '🧠 Deep thinking mode enabled - AI will analyze more thoroughly with internal reasoning'
          : '⚡ Quick chat mode enabled - AI will respond faster with direct answers',
      isUser: false,
      timestamp: DateTime.now(),
      isSystem: true,
    );
    _addMessage(modeMessage);
  }

  void _startListening() async {
    HapticFeedback.lightImpact();

    // Check microphone permission first
    if (_microphonePermission != PermissionServiceState.granted) {
      await _requestMicrophonePermission();
      return;
    }

    try {
      // Use Vertex AI Live for speech-to-speech if voice mode is enabled
      if (_isVoiceMode) {
        try {
          if (!_vertexAILiveService.isConnected) {
            await _vertexAILiveService.connect();
          }
          await _vertexAILiveService.startListening();
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error starting listening: $e');
          }
          // If service is disposed, try to reconnect
          if (e.toString().contains('close') || e.toString().contains('disposed')) {
            // Service was disposed, need to reinitialize
            _addMessage(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: '⚠️ Voice service needs to be reinitialized. Please close and reopen the chat.',
                isUser: false,
                timestamp: DateTime.now(),
                isSystem: true,
              ),
            );
            return;
          }
          rethrow;
        }

        // Add Vertex AI Live listening indicator
        _addMessage(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '🎤 **Voice Mode Active** - Speak your question!',
            isUser: false,
            timestamp: DateTime.now(),
            isSystem: true,
          ),
        );

        if (kDebugMode) {
          print('🎤 Started Vertex AI Live listening');
        }
        return;
      }

      // Fallback to native audio service for speech-to-speech if available
      try {
        // Initialize native audio service with API key if not already initialized
        if (!_nativeAudioService.isConnected) {
          final apiKey = GeminiLiveAPIConfig.apiKey;
          if (apiKey.isEmpty) {
            throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY environment variable.');
          }
          await _nativeAudioService.initialize(
            apiKey: apiKey,
            thinkingMode: _isDeepThinking,
            varkPreferences: _varkPrefs,
          );
        }
        
        if (_nativeAudioService.isConnected ||
            await _nativeAudioService.connect()) {
          await _nativeAudioService.startListening();

          // Add native listening indicator
          _addMessage(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '🎤 **Native Audio Listening** - Speak your question for direct speech-to-speech conversation!',
              isUser: false,
              timestamp: DateTime.now(),
              isSystem: true,
            ),
          );

          if (kDebugMode) {
            print('🎤 Started native audio listening');
          }
        } else {
          throw Exception('Failed to connect native audio service');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error starting native audio listening: $e');
        }
        // If service is disposed, handle gracefully
        if (e.toString().contains('close') || e.toString().contains('disposed')) {
          _addMessage(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: '⚠️ Audio service needs to be reinitialized. Please close and reopen the chat.',
              isUser: false,
              timestamp: DateTime.now(),
              isSystem: true,
            ),
          );
          return;
        }
        // Fallback to simulated listening
        setState(() {
          _isListening = true;
          _voiceState = GeminiLiveServiceState.listening;
        });

        _waveController.repeat(reverse: true);

        // Add listening indicator
        _addMessage(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                '🎤 Listening... Speak your question and I\'ll respond with voice!',
            isUser: false,
            timestamp: DateTime.now(),
            isSystem: true,
          ),
        );

        // Voice recognition would be handled by native audio service
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting voice listening: $e');
      }

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              '⚠️ Voice recognition not available right now. Please use text input.',
          isUser: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );
    }
  }

  /// Request microphone permission with enhanced user feedback
  Future<void> _requestMicrophonePermission() async {
    try {
      // Show requesting message
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '🎤 Requesting microphone permission for voice features...',
          isUser: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );

      final granted = await _permissionService.requestMicrophoneWithRetry();

      if (granted) {
        setState(() {
          _microphonePermission = PermissionServiceState.granted;
        });

        _addMessage(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                '✅ Microphone permission granted! Voice features are now available. Tap the microphone to start speaking.',
            isUser: false,
            timestamp: DateTime.now(),
            isSystem: true,
          ),
        );

        // Auto-start listening if permission was just granted
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted &&
              _microphonePermission == PermissionServiceState.granted) {
            _startListening();
          }
        });
      } else {
        final state = _permissionService.microphoneState;
        setState(() {
          _microphonePermission = state;
        });

        if (state == PermissionServiceState.permanentlyDenied) {
          // Show dialog asking if user wants to open settings (better UX)
          final dialogTheme = FlutterFlowTheme.of(context);
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Microphone Permission Required',
                style: dialogTheme.headlineSmall,
              ),
              content: Text(
                'Microphone access is required for voice input. Please enable it in your device settings.\n\nAfter enabling, return to the app and try again.',
                style: dialogTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: dialogTheme.bodyMedium.copyWith(
                      color: dialogTheme.secondaryText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Open Settings',
                    style: dialogTheme.bodyMedium.copyWith(
                      color: dialogTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldOpen == true) {
            final opened = await _permissionService.openAppSettings();
            if (opened && mounted) {
              _addMessage(
                ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  content:
                      '⚙️ Opening Settings... Please enable Microphone permission for FoCoCo, then return to the app.',
                  isUser: false,
                  timestamp: DateTime.now(),
                  isSystem: true,
                ),
              );
            }
          }
        } else {
          _addMessage(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '❌ Microphone permission declined. You can continue using text chat or tap the microphone again to retry.',
              isUser: false,
              timestamp: DateTime.now(),
              isSystem: true,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting microphone permission: $e');
      }

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content:
              '⚠️ Error requesting microphone permission. You can continue using text chat.',
          isUser: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );
    }
  }

  /// Show permission settings dialog for permanently denied permissions
  void _showPermissionSettingsDialog() {
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '⚙️ Microphone permission was permanently denied. To enable voice features:\n\n1. Go to your device Settings\n2. Find FoCoCo app\n3. Enable Microphone permission\n4. Return to the app\n\nYou can continue using text chat in the meantime.',
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      ),
    );

    // Optionally show a button to open settings
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '📱 Tap here to open app settings (if available on your device)',
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      ),
    );
  }

  void _stopListening() async {
    HapticFeedback.lightImpact();

    try {
      // Stop Vertex AI Live listening if active
      if (_isVoiceMode && _vertexAILiveService.isListening) {
        await _vertexAILiveService.stopListening();

        if (kDebugMode) {
          print('🛑 Stopped Vertex AI Live listening');
        }
      }

      // Stop native audio service listening if active
      if (_nativeAudioService.isListening) {
        _nativeAudioService.stopListening();

        if (kDebugMode) {
          print('🛑 Stopped native audio listening');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping listening: $e');
      }
    }

    setState(() {
      _isListening = false;
      _voiceState = GeminiLiveServiceState.connected;
    });

    _waveController.stop();
  }

  void _stopSpeaking() async {
    HapticFeedback.lightImpact();
    await _cartesiaService.stopSpeaking();
  }

  void _sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _isTyping = false;
    });

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);

    HapticFeedback.selectionClick();

    try {
      // Generate AI response using Gemini
      final aiResponse = await _generateAIResponse(message.trim());

      // Add AI response to chat immediately (text appears instantly)
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);

      // Start TTS generation in parallel (don't wait for it)
      // This makes text and voice work simultaneously
      // Auto-play response when voice mode is active or auto-read is enabled
      if ((_isVoiceMode || (_isVoiceEnabled && _isAutoReadEnabled)) &&
          _cartesiaService.isInitialized) {
        // Set speaking state immediately
        setState(() {
          _isAISpeaking = true;
        });

        // Strip markdown for TTS
        final cleanTextForTTS = _stripMarkdownForTTS(aiResponse);

        // Start TTS in background (don't await)
        _cartesiaService
            .speakText(
          text: cleanTextForTTS,
          voiceId: _selectedVoiceId,
          contentType: 'coaching',
          varkPreferences: _varkPrefs,
        )
            .then((_) {
          // Update state when TTS completes
          if (mounted) {
            setState(() {
              _isAISpeaking = false;
            });
          }
        }).catchError((e) {
          debugPrint('Cartesia TTS error: $e');
          // Fallback to system TTS
          if (_isVoiceEnabled && _isAutoReadEnabled) {
            _aiService.speak(cleanTextForTTS).catchError((e2) {
              debugPrint('System TTS error: $e2');
            });
          }
          if (mounted) {
            setState(() {
              _isAISpeaking = false;
            });
          }
        });
      } else if (_isVoiceEnabled) {
        // Fallback to system TTS when voice is enabled (even without auto-read)
        // This ensures responses are played when user uses voice input
        final cleanTextForTTS = _stripMarkdownForTTS(aiResponse);
        setState(() {
          _isAISpeaking = true;
        });
        _aiService.speak(cleanTextForTTS).then((_) {
          if (mounted) {
            setState(() {
              _isAISpeaking = false;
            });
          }
        }).catchError((e) {
          debugPrint('System TTS error: $e');
          if (mounted) {
            setState(() {
              _isAISpeaking = false;
            });
          }
        });
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '❌ Error processing message: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      );
      _addMessage(errorMessage);
    }

    _scrollToBottom();
  }

  // ============================================================================
  // TEXT FORMATTING METHODS
  // ============================================================================

  /// Clean markdown text by removing common formatting symbols
  String _cleanMarkdownText(String text) {
    if (text.isEmpty) return text;

    // Remove bold formatting (**text** and ***text***)
    String cleaned = text.replaceAll(RegExp(r'\*{2,3}([^*]+)\*{2,3}'), r'\$1');

    // Remove italic formatting (*text*)
    cleaned = cleaned.replaceAll(RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)'), r'\$1');

    // Remove code formatting (`text`)
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'\$1');

    // Remove heading symbols (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // Clean up extra spaces and line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

    return cleaned.trim();
  }

  /// Strip all markdown formatting for TTS (more aggressive than _cleanMarkdownText)
  /// Removes all formatting that could cause TTS to say "asterisks" or other unwanted words
  String _stripMarkdownForTTS(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // Remove all bold formatting (**text**, ***text***, __text__)
    cleaned = cleaned.replaceAll(RegExp(r'\*{2,3}([^*]+)\*{2,3}'), r'\$1');
    cleaned = cleaned.replaceAll(RegExp(r'_{2}([^_]+)_{2}'), r'\$1');

    // Remove all italic formatting (*text*, _text_)
    cleaned = cleaned.replaceAll(RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'), r'\$1');
    cleaned = cleaned.replaceAll(RegExp(r'(?<!_)_([^_\n]+)_(?!_)'), r'\$1');

    // Remove all code formatting (`text`, ```text```)
    cleaned = cleaned.replaceAll(RegExp(r'`+([^`]+)`+'), r'\$1');

    // Remove all heading symbols (# ## ### #### ##### ######)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Remove blockquotes (> text)
    cleaned = cleaned.replaceAll(RegExp(r'^>\s+', multiLine: true), '');

    // Remove links [text](url) -> text
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\$1');

    // Remove images ![alt](url) -> alt
    cleaned = cleaned.replaceAll(RegExp(r'!\[([^\]]+)\]\([^\)]+\)'), r'\$1');

    // Remove horizontal rules (---, ***)
    cleaned = cleaned.replaceAll(RegExp(r'^[-*]{3,}$', multiLine: true), '');

    // Remove list markers (-, *, +, 1., 2., etc.)
    cleaned =
        cleaned.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '');

    // Clean up extra spaces and line breaks
    cleaned = cleaned.replaceAll(
        RegExp(r'\n\s*\n\s*\n'), '\n\n'); // Max 2 line breaks
    cleaned =
        cleaned.replaceAll(RegExp(r'[ \t]+'), ' '); // Multiple spaces to single

    // Remove any remaining asterisks that might be standalone
    cleaned = cleaned.replaceAll(RegExp(r'\*+'), '');

    return cleaned.trim();
  }

  /// Build rich markdown text with advanced formatting, colors, tables, and images
  Widget _buildRichMarkdownText(FlutterFlowTheme theme, String text) {
    if (text.isEmpty) {
      return Text(
        text,
        style: theme.bodyMedium.copyWith(color: theme.primaryText),
      );
    }

    return SingleChildScrollView(
      child: Markdown(
        data: text,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          // Paragraph styling
          p: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            height: 1.5,
            fontSize: 14,
          ),

          // Headers
          h1: theme.headlineLarge.copyWith(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          h2: theme.headlineMedium.copyWith(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          h3: theme.headlineSmall.copyWith(
            color: theme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),

          // Lists
          listBullet: theme.bodyMedium.copyWith(
            color: theme.accent1,
            fontSize: 14,
          ),

          // Code
          code: theme.bodyMedium.copyWith(
            backgroundColor: theme.accent4.withValues(alpha: 0.1),
            color: theme.accent1,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: theme.accent4.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.accent4.withValues(alpha: 0.2),
            ),
          ),

          // Links
          a: theme.bodyMedium.copyWith(
            color: theme.primary,
            decoration: TextDecoration.underline,
          ),

          // Tables
          tableHead: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.bold,
            backgroundColor: theme.accent4.withValues(alpha: 0.1),
          ),
          tableBody: theme.bodyMedium.copyWith(
            color: theme.primaryText,
          ),
          tableBorder: TableBorder.all(
            color: theme.accent4.withValues(alpha: 0.3),
            width: 1,
          ),

          // Blockquotes
          blockquote: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            color: theme.accent4.withValues(alpha: 0.05),
            border: Border(
              left: BorderSide(
                color: theme.primary,
                width: 4,
              ),
            ),
          ),

          // Strong/Bold
          strong: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.bold,
          ),

          // Emphasis/Italic
          em: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontStyle: FontStyle.italic,
          ),
        ),

        // Handle link taps
        onTapLink: (text, href, title) async {
          if (href != null) {
            final uri = Uri.parse(href);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        },

        // Image builder for AI-generated images
        imageBuilder: (uri, title, alt) {
          return _buildImageWidget(theme, uri, title, alt);
        },

        // Extension support
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          [
            md.EmojiSyntax(),
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ],
        ),
      ),
    );
  }

  /// Build image widget for AI-generated or embedded images
  Widget _buildImageWidget(
      FlutterFlowTheme theme, Uri uri, String? title, String? alt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          uri.toString(),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: theme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading image...',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.accent4.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: theme.secondaryText,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alt ?? 'Failed to load image',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  String _getStateDescription() {
    if (_isListening) {
      return 'Listening to your message...';
    } else if (_isAISpeaking) {
      return 'Speaking response...';
    } else {
      return 'Ready to help with your mental game';
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Setup permission listeners
  void _setupPermissionListeners() {
    _permissionService.microphoneStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _microphonePermission = state;
        });

        // Show permission status message
        if (state == PermissionServiceState.granted) {
          _addMessage(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '✅ Microphone permission granted! Voice features now available.',
              isUser: false,
              timestamp: DateTime.now(),
              isSystem: true,
            ),
          );
        } else if (state == PermissionServiceState.permanentlyDenied) {
          // Don't spam messages, but show helpful info if user tries to use voice
          if (kDebugMode) {
            print(
                '⚠️ Microphone permission permanently denied. User needs to enable in Settings.');
          }
        } else if (state == PermissionServiceState.denied) {
          // Only show message if not already shown
          if (kDebugMode) {
            print(
                '⚠️ Microphone permission denied. User can still use text chat.');
          }
        }
      }
    });
  }

  /// Build enhanced context with chat history and user insights
  String _buildEnhancedContext(
      String conversationContext, String personalizedPrompt) {
    final buffer = StringBuffer();

    // Add recent conversation history
    if (conversationContext.isNotEmpty) {
      buffer.writeln('=== RECENT CONVERSATION ===');
      buffer.writeln(conversationContext);
      buffer.writeln();
    }

    // Add personalized insights
    if (personalizedPrompt.isNotEmpty) {
      buffer.writeln(personalizedPrompt);
    }

    // Add current session context
    buffer.writeln('=== CURRENT SESSION ===');
    buffer.writeln('Session ID: ${_memoryService.currentSessionId}');
    buffer.writeln('Deep Thinking Mode: ${_isDeepThinking ? "ON" : "OFF"}');
    buffer.writeln('Voice Service: Active');
    buffer.writeln();

    return buffer.toString();
  }

  /// Generate contextual fallback response based on user input
  String _generateContextualFallback(String userInput) {
    final input = userInput.toLowerCase();

    // Golf-specific responses
    if (input.contains('putt') || input.contains('putting')) {
      return "I understand you're working on your putting. Focus on your pre-putt routine: read the green, visualize the ball's path, take a deep breath, and trust your stroke. What specific aspect of putting would you like to work on?";
    }

    if (input.contains('drive') ||
        input.contains('driving') ||
        input.contains('tee')) {
      return "Driving can be challenging! Remember the fundamentals: balanced setup, smooth tempo, and commit to your swing. Visualize your target and trust your preparation. What's been happening with your drives lately?";
    }

    if (input.contains('nervous') ||
        input.contains('pressure') ||
        input.contains('anxiety')) {
      return "Feeling pressure is normal - it shows you care! Try the 4-7-8 breathing technique: inhale for 4 counts, hold for 7, exhale for 8. This activates your parasympathetic nervous system and helps you stay calm. What situation is making you feel most nervous?";
    }

    if (input.contains('confidence') || input.contains('doubt')) {
      return "Confidence comes from preparation and positive self-talk. Recall your best shots and the feeling of success. Create a personal mantra like 'I am prepared and capable.' What has been shaking your confidence on the course?";
    }

    if (input.contains('focus') || input.contains('concentration')) {
      return "Focus is like a muscle that needs training. Try the 'target focus' technique: pick a specific spot on your target and keep your eyes there throughout your pre-shot routine. What tends to distract you most during your rounds?";
    }

    // General supportive response
    return "I'm here to help you develop your mental game and unlock your potential on the course. While I'm experiencing some technical difficulties with my advanced features, I can still provide guidance on focus, confidence, and control. What specific aspect of your golf psychology would you like to work on?";
  }
}
