import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/unified_ai_service.dart';
import '../services/cartesia_api_service.dart';
import '../services/permission_service.dart';
import '../services/ai_memory_service.dart';
import '../services/gemini_live_service_simple.dart';

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

  // Streamlined voice services - Gemini for responses, Cartesia for speech
  final UnifiedAIService _aiService = UnifiedAIService();
  final CartesiaAPIService _cartesiaService = CartesiaAPIService.instance;
  final PermissionService _permissionService = PermissionService();
  final AIMemoryService _memoryService = AIMemoryService();

  GeminiLiveServiceState _voiceState = GeminiLiveServiceState.disconnected;
  List<ChatMessage> _messages = [];
  String _interactionType = 'quickChat';
  bool _isTyping = false;
  bool _isDeepThinking = false;
  PermissionServiceState _microphonePermission = PermissionServiceState.unknown;

  // Streamlined service status
  bool _isAISpeaking = false;
  bool _isListening = false;

  // Voice selection - only two male voices
  static const Map<String, String> _availableVoices = {
    'Voice 1 (Male)': 'da3224fe-d8d1-4774-8902-e6a7115f5132',
    'Voice 2 (Male)': 'c7c1f6e5-cf61-4c16-b13b-ca4b0e34c423',
  };
  String _selectedVoiceName = 'Voice 1 (Male)';
  String get _selectedVoiceId => _availableVoices[_selectedVoiceName]!;

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
    super.dispose();
  }

  Future<void> _initializeVoiceServices() async {
    try {
      // Initialize permission service first
      await _permissionService.initialize();

      // Initialize AI memory service
      await _memoryService.initialize();

      // Initialize unified AI service for generating responses
      await _aiService.initialize();
      if (kDebugMode) {
        print('✅ Unified AI service initialized');
      }

      // Initialize Cartesia for speech synthesis with selected voice
      try {
        await _cartesiaService.initialize();
        _cartesiaService.setVoiceId(_selectedVoiceId);
        if (kDebugMode) {
          print(
              '✅ Cartesia voice service initialized with $_selectedVoiceName ($_selectedVoiceId)');
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

      String welcomeMessage;
      if (_cartesiaService.isInitialized) {
        welcomeMessage = micState == PermissionServiceState.granted
            ? '🎤 FoCoCo AI Coach ready! Using $_selectedVoiceName. Speak or type your message.'
            : '📝 FoCoCo AI Coach ready! Using $_selectedVoiceName. Type your message or tap microphone to enable voice.';
      } else {
        welcomeMessage = micState == PermissionServiceState.granted
            ? '🎤 FoCoCo AI Coach ready! Voice features limited. Speak or type your message.'
            : '📝 FoCoCo AI Coach ready! Text chat available. Type your message.';
      }

      // Add some sample conversation to show functionality
      _addSampleConversation();

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: welcomeMessage,
          isUser: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );
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
    // Simplified voice state management
    setState(() {
      _voiceState = GeminiLiveServiceState.connected;
    });

    // Listen to Cartesia speaking state
    _cartesiaService.speakingStream.listen((isSpeaking) {
      if (mounted) {
        setState(() {
          _isAISpeaking = isSpeaking;
          _voiceState = isSpeaking
              ? GeminiLiveServiceState.speaking
              : GeminiLiveServiceState.connected;
        });

        // Update wave animation
        if (isSpeaking) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });

    // Voice listeners are now simplified and handled by Cartesia service
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

      // Generate response using unified AI service with enhanced context
      final response = await _aiService.generateResponse(
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
            _buildVoiceSelector(theme),
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
                  'Using $_selectedVoiceName',
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

  Widget _buildVoiceSelector(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              FontAwesomeIcons.userTie,
              color: theme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Voice Selection',
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  'Choose your preferred male coach voice',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.accent4.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedVoiceName,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: theme.bodySmall.copyWith(
                color: theme.primaryText,
                fontSize: 12,
              ),
              items: _availableVoices.keys.map((String voiceName) {
                return DropdownMenuItem<String>(
                  value: voiceName,
                  child: Text(
                    voiceName,
                    style: theme.bodySmall.copyWith(
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _changeVoice,
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
              message.content,
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
                  child: Text(
                    message.content,
                    style: theme.bodyMedium.copyWith(
                      color: isUser ? Colors.white : theme.primaryText,
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

  /// Change voice selection
  void _changeVoice(String? newVoiceName) async {
    if (newVoiceName == null || newVoiceName == _selectedVoiceName) return;

    setState(() {
      _selectedVoiceName = newVoiceName;
    });

    // Update Cartesia service with new voice
    _cartesiaService.setVoiceId(_selectedVoiceId);

    HapticFeedback.selectionClick();

    // Add system message about voice change
    final voiceMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          '🎭 Voice changed to $_selectedVoiceName. Your AI coach will now use this voice for responses.',
      isUser: false,
      timestamp: DateTime.now(),
      isSystem: true,
    );
    _addMessage(voiceMessage);

    // Play a sample message with the new voice
    if (_cartesiaService.isInitialized) {
      try {
        await _cartesiaService.speakText(
          text:
              "Hello! I'm your AI mental performance coach speaking with the new voice. How can I help you today?",
          voiceId: _selectedVoiceId,
          contentType: 'coaching',
          varkPreferences: _varkPrefs,
        );
      } catch (e) {
        debugPrint('Error playing voice sample: $e');
      }
    }

    if (kDebugMode) {
      print('🎭 Voice changed to $_selectedVoiceName ($_selectedVoiceId)');
    }
  }

  /// Toggle deep thinking mode
  void _toggleDeepThinking() async {
    setState(() {
      _isDeepThinking = !_isDeepThinking;
      _interactionType = _isDeepThinking ? 'thinkingMode' : 'quickChat';
    });

    HapticFeedback.selectionClick();

    // Add system message about mode change
    final modeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _isDeepThinking
          ? '🧠 Deep thinking mode enabled - AI will analyze more thoroughly'
          : '⚡ Quick chat mode enabled - AI will respond faster',
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

    // Simplified listening - just show listening state
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

  /// Add sample conversation to demonstrate functionality
  void _addSampleConversation() {
    // Add a sample conversation to show how it works
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _addMessage(
          ChatMessage(
            id: 'sample_user_1',
            content: 'I struggle with putting under pressure',
            isUser: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _addMessage(
          ChatMessage(
            id: 'sample_ai_1',
            content:
                "I understand that pressure putting can be challenging! Here's what I recommend:\n\n1. **Develop a consistent pre-putt routine** - This gives you something to focus on instead of the pressure\n2. **Use the 4-7-8 breathing technique** - Inhale for 4, hold for 7, exhale for 8 to calm your nerves\n3. **Visualize success** - See the ball going in before you putt\n\nWhat specific situations make you feel the most pressure when putting?",
            isUser: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        );
      }
    });
  }

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
