import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/unified_ai_service.dart';
import '../services/cartesia_api_service.dart';
import '../services/permission_service.dart';
import '../services/ai_memory_service.dart';
import '../services/gemini_live_service_simple.dart';
import '../services/gemini_native_audio_service.dart';
import '../services/voice_chat_database_service.dart';
import '../services/enhanced_ai_coaching_service.dart';

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

  const FoCoCoVoiceChatModal({
    Key? key,
    this.varkPreferences,
    this.initialRoom,
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
    with TickerProviderStateMixin {
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

  // Streamlined service status
  bool _isAISpeaking = false;
  bool _isListening = false;

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

    // Initialize voice services and start animations
    _initializeVoiceServices();
    _slideController.forward();

    // Listen to voice service streams
    _setupVoiceListeners();

    // Listen to permission changes
    _setupPermissionListeners();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    _textController.dispose();

    // Clean up voice services
    _nativeAudioService.dispose();

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

      // Initialize database service and start session
      await _databaseService.initialize();
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

        // Show thinking process if available
        if (response.isThinking && response.thinkingProcess != null) {
          final thinkingMessage = ChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_thinking',
            content: '🧠 **Thinking Process:** ${response.thinkingProcess}',
            isUser: false,
            timestamp: DateTime.now(),
            isSystem: true,
          );
          _addMessage(thinkingMessage);
        }
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

  /// Start a new voice chat session in the database
  Future<void> _startNewSession() async {
    try {
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

      if (kDebugMode) {
        print('📊 Started database session: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting database session: $e');
      }
    }
  }

  /// Save message to database
  Future<void> _saveMessageToDatabase(ChatMessage message) async {
    if (_currentSessionId == null) return;

    try {
      final dbMessage = VoiceChatMessage(
        id: message.id,
        userId: '', // Will be set by the database service
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

${_isDeepThinking ? 'DEEP THINKING MODE: Provide thorough analysis with detailed explanations, structured content, and actionable insights.' : 'QUICK CHAT MODE: Provide concise, focused advice with key highlights.'}

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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
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
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.accent4.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FontAwesomeIcons.brain,
              color: theme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Mental Coach',
                  style: theme.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStateDescription(),
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
                Text(
                  'Using $_voiceName',
                  style: theme.bodySmall.copyWith(
                    color: theme.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: theme.secondaryText,
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
    final statusText =
        isListening ? 'Listening...' : 'Speaking via Cartesia Voice';

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

  Widget _buildDeepThinkingToggle(FlutterFlowTheme theme) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.accent4.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.accent4.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDeepThinking
                  ? theme.primary.withValues(alpha: 0.1)
                  : theme.accent4.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              FontAwesomeIcons.brain,
              color: _isDeepThinking ? theme.primary : theme.secondaryText,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Deep Thinking Mode',
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  _isDeepThinking
                      ? 'AI will think deeply before responding'
                      : 'Quick responses for faster conversation',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleDeepThinking,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isDeepThinking
                    ? theme.primary
                    : theme.accent4.withValues(alpha: 0.3),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isDeepThinking
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
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
          const SizedBox(height: 24),
          _buildSamplePrompts(theme),
        ],
      ),
    );
  }

  Widget _buildSamplePrompts(FlutterFlowTheme theme) {
    final prompts = [
      'Help me with pre-shot routine',
      'I struggle with pressure putts',
      'How to recover from bad shots',
      'Building confidence on course',
    ];

    return Column(
      children: prompts
          .map((prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _sendTextMessage(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.accent4.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.accent4.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      prompt,
                      style: theme.bodySmall.copyWith(
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSimpleMessageBubble(
      FlutterFlowTheme theme, ChatMessage message, int index) {
    final isUser = message.isUser;
    final isSystem = message.isSystem ?? false;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accent4.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _cleanMarkdownText(message.content),
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
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
                Container(
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

  Widget _buildInputArea(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.accent4.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.accent4.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening...'
                              : 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: theme.bodyMedium,
                        onChanged: (value) {
                          setState(() {
                            _isTyping = value.isNotEmpty;
                          });
                        },
                        onSubmitted: _sendTextMessage,
                      ),
                    ),
                    if (_isTyping)
                      IconButton(
                        onPressed: () => _sendTextMessage(_textController.text),
                        icon: Icon(
                          Icons.send,
                          color: theme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildVoiceActionButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceActionButton(FlutterFlowTheme theme) {
    IconData icon;
    Color color;
    VoidCallback? onPressed;

    if (_isListening) {
      icon = FontAwesomeIcons.stop;
      color = Colors.red;
      onPressed = _stopListening;
    } else if (_isAISpeaking) {
      icon = FontAwesomeIcons.volumeXmark;
      color = Colors.orange;
      onPressed = _stopSpeaking;
    } else {
      icon = FontAwesomeIcons.microphone;
      color = theme.primary;
      onPressed = _startListening;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
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
      // Use native audio service for speech-to-speech if available
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

        // Simulate listening for demo (in real app, this would be actual voice recognition)
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isListening) {
            _stopListening();
            _simulateVoiceInput();
          }
        });
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
          _showPermissionSettingsDialog();
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
      // Stop native audio service listening if active
      if (_nativeAudioService.isListening) {
        _nativeAudioService.stopListening();

        if (kDebugMode) {
          print('🛑 Stopped native audio listening');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping native audio listening: $e');
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

      // Add AI response to chat first
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);

      // Speak the response using Cartesia if available
      if (_cartesiaService.isInitialized) {
        try {
          setState(() {
            _isAISpeaking = true;
          });

          await _cartesiaService.speakText(
            text: aiResponse,
            voiceId: _selectedVoiceId,
            contentType: 'coaching',
            varkPreferences: _varkPrefs,
          );
        } catch (e) {
          debugPrint('Cartesia TTS error: $e');
          // Fallback to system TTS
          try {
            await _aiService.speak(aiResponse);
          } catch (e2) {
            debugPrint('System TTS error: $e2');
          }
        }
      } else {
        // Fallback to system TTS
        try {
          await _aiService.speak(aiResponse);
        } catch (e) {
          debugPrint('System TTS error: $e');
        }
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
    String cleaned = text.replaceAll(RegExp(r'\*{2,3}([^*]+)\*{2,3}'), r'$1');

    // Remove italic formatting (*text*)
    cleaned = cleaned.replaceAll(RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)'), r'$1');

    // Remove code formatting (`text`)
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove heading symbols (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // Clean up extra spaces and line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

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

    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
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
      return 'Speaking response via Cartesia...';
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
        } else if (state == PermissionServiceState.denied) {
          _addMessage(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '⚠️ Microphone permission needed for voice features. You can still use text chat.',
              isUser: false,
              timestamp: DateTime.now(),
              isSystem: true,
            ),
          );
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
    buffer.writeln('Voice Service: Cartesia + Gemini AI');
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

  // Sample conversation method removed - chat starts clean

  /// Simulate voice input for demonstration
  void _simulateVoiceInput() {
    final sampleQuestions = [
      "How can I stay focused during my swing?",
      "I get nervous on the first tee, any advice?",
      "What's the best way to recover from a bad shot?",
      "How do I build confidence in my short game?",
    ];

    final randomQuestion =
        sampleQuestions[DateTime.now().millisecond % sampleQuestions.length];

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: randomQuestion,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);

    // Generate and speak AI response
    _sendTextMessage(randomQuestion);
  }
}
