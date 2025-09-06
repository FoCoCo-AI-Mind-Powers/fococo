import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/gemini_live_service_simple.dart';
import '../services/fococo_voice_service.dart';
import '../services/unified_ai_service.dart';
import '../services/gemini_live_api_service.dart';
import '../services/permission_service.dart';

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

  // Unified voice services - all working in background
  final FoCoCoVoiceService _voiceService = FoCoCoVoiceService();
  final GeminiLiveService _geminiService = GeminiLiveService();
  final UnifiedAIService _aiService = UnifiedAIService();
  final GeminiLiveAPIService _liveAPIService = GeminiLiveAPIService();
  final PermissionService _permissionService = PermissionService();

  GeminiLiveServiceState _voiceState = GeminiLiveServiceState.disconnected;
  String _currentTranscript = '';
  List<ChatMessage> _messages = [];
  String _interactionType = 'quickChat';
  bool _isTyping = false;
  bool _isDeepThinking = false;
  bool _useRealTimeAPI = true;
  PermissionServiceState _microphonePermission = PermissionServiceState.unknown;

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

      // Initialize all voice services in background
      await _voiceService.initialize();
      await _aiService.initialize();
      await _geminiService.initialize();
      await _geminiService.connect();

      // Initialize Gemini Live API service
      await _liveAPIService.initialize(
        config: GeminiLiveConfig(
          enableThinking: _isDeepThinking,
          audioArchitecture: AudioArchitecture.nativeAudio,
        ),
        varkPreferences: _varkPrefs,
      );

      if (_useRealTimeAPI) {
        await _liveAPIService.connect();
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
      if (micState == PermissionServiceState.granted) {
        welcomeMessage =
            '🎤 AI Coach ready! You can speak or type your message.';
      } else {
        welcomeMessage =
            '📝 AI Coach ready! You can type your message. Tap microphone to enable voice.';
      }

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

      // More user-friendly error message
      String errorMessage = 'AI Coach is ready for text chat. ';
      if (e.toString().contains('Microphone')) {
        errorMessage += 'Voice features need microphone permission.';
      } else {
        errorMessage += 'Some features may be limited.';
      }

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
    // Listen to Live API service state
    _liveAPIService.stateStream.listen((liveState) {
      if (mounted) {
        // Convert Live API state to legacy state for UI compatibility
        GeminiLiveServiceState uiState;
        switch (liveState) {
          case GeminiLiveState.disconnected:
            uiState = GeminiLiveServiceState.disconnected;
            break;
          case GeminiLiveState.connecting:
            uiState = GeminiLiveServiceState.connecting;
            break;
          case GeminiLiveState.connected:
            uiState = GeminiLiveServiceState.connected;
            break;
          case GeminiLiveState.listening:
            uiState = GeminiLiveServiceState.listening;
            break;
          case GeminiLiveState.thinking:
            uiState = GeminiLiveServiceState.thinking;
            break;
          case GeminiLiveState.speaking:
            uiState = GeminiLiveServiceState.speaking;
            break;
          case GeminiLiveState.error:
            uiState = GeminiLiveServiceState.error;
            break;
        }

        setState(() {
          _voiceState = uiState;
        });

        // Auto-scroll to bottom when new messages arrive
        if (uiState == GeminiLiveServiceState.connected &&
            _messages.isNotEmpty) {
          _scrollToBottom();
        }

        // Update wave animation
        if (uiState == GeminiLiveServiceState.listening ||
            uiState == GeminiLiveServiceState.speaking) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });

    // Listen to Live API responses
    _liveAPIService.responseStream.listen((response) {
      if (mounted && response.isNotEmpty) {
        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _addMessage(aiMessage);
      }
    });

    // Fallback to legacy service if Live API is not available
    _geminiService.stateStream.listen((state) {
      if (mounted && !_useRealTimeAPI) {
        setState(() {
          _voiceState = state;
        });

        // Update wave animation
        if (state == GeminiLiveServiceState.listening ||
            state == GeminiLiveServiceState.speaking) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });

    // Listen to legacy voice transcripts
    _geminiService.transcriptStream.listen((transcript) {
      if (mounted && transcript.isNotEmpty && !_useRealTimeAPI) {
        setState(() {
          _currentTranscript = transcript;
        });
        _processVoiceInput(transcript);
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
  }

  Future<void> _processVoiceInput(String transcript) async {
    if (transcript.isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: transcript,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);

    try {
      // Generate AI response using unified AI service
      final aiResponse = await _generateAIResponse(transcript);

      // Speak the response using unified AI service
      try {
        await _aiService.speak(aiResponse);
      } catch (e) {
        debugPrint('TTS error: $e');
      }

      // Add AI response to chat
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '❌ Error processing voice input: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      );
      _addMessage(errorMessage);
    }
  }

  Future<String> _generateAIResponse(String userInput) async {
    try {
      // Build conversation context from recent messages
      final conversationContext = _buildConversationContext();

      // Generate response using unified AI service
      final response = await _aiService.generateResponse(
        userMessage: userInput,
        conversationContext: conversationContext,
        varkPreferences: _varkPrefs,
        interactionType: _interactionType,
      );

      return response;
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      return 'I\'m experiencing some technical difficulties. Please try again in a moment.';
    }
  }

  /// Build conversation context from recent messages
  String _buildConversationContext() {
    if (_messages.isEmpty) return '';

    final context = StringBuffer();
    final recentMessages = _messages.take(6).toList();

    for (final message in recentMessages) {
      final role = message.isUser ? 'Golfer' : 'Coach';
      context.writeln('$role: ${message.content}');
    }

    return context.toString();
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
                          hintText:
                              _voiceState == GeminiLiveServiceState.listening
                                  ? _currentTranscript.isEmpty
                                      ? 'Listening...'
                                      : _currentTranscript
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

    switch (_voiceState) {
      case GeminiLiveServiceState.listening:
        icon = FontAwesomeIcons.stop;
        color = Colors.red;
        onPressed = _stopListening;
        break;
      case GeminiLiveServiceState.speaking:
        icon = FontAwesomeIcons.volumeXmark;
        color = Colors.orange;
        onPressed = _stopSpeaking;
        break;
      case GeminiLiveServiceState.thinking:
        icon = FontAwesomeIcons.spinner;
        color = Colors.orange;
        onPressed = null;
        break;
      case GeminiLiveServiceState.connected:
        icon = FontAwesomeIcons.microphone;
        color = theme.primary;
        onPressed = _startListening;
        break;
      case GeminiLiveServiceState.error:
        icon = FontAwesomeIcons.triangleExclamation;
        color = Colors.red;
        onPressed = _initializeVoiceServices;
        break;
      case GeminiLiveServiceState.connecting:
      case GeminiLiveServiceState.disconnected:
        icon = FontAwesomeIcons.microphone;
        color = theme.secondaryText;
        onPressed = _initializeVoiceServices;
        break;
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

    // Update Live API service configuration
    _liveAPIService.setThinkingMode(_isDeepThinking);

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

    if (_useRealTimeAPI && _liveAPIService.isConnected) {
      await _liveAPIService.startListening();
    } else {
      await _geminiService.startListening();
    }
  }

  /// Request microphone permission with user feedback
  Future<void> _requestMicrophonePermission() async {
    try {
      final granted = await _permissionService.requestMicrophoneWithRetry();

      if (!granted) {
        final state = _permissionService.microphoneState;

        if (state == PermissionServiceState.permanentlyDenied) {
          // Show dialog to open settings
          _showPermissionDialog();
        } else {
          _addMessage(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '🎤 Microphone permission is needed for voice features. You can continue using text chat.',
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
    }
  }

  /// Show permission dialog for permanently denied permissions
  void _showPermissionDialog() {
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '⚙️ To use voice features, please enable microphone permission in your device settings.',
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      ),
    );
  }

  void _stopListening() async {
    HapticFeedback.lightImpact();

    if (_useRealTimeAPI && _liveAPIService.isConnected) {
      await _liveAPIService.stopListening();
    } else {
      await _geminiService.stopListening();
    }
  }

  void _stopSpeaking() async {
    HapticFeedback.lightImpact();

    if (_useRealTimeAPI && _liveAPIService.isConnected) {
      await _liveAPIService.stopListening();
    } else {
      await _geminiService.stopListening();
    }
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
      // Send message via Live API if available, otherwise use fallback
      if (_useRealTimeAPI && _liveAPIService.isConnected) {
        await _liveAPIService.sendTextMessage(message.trim());
        // Response will be handled by the response stream listener
      } else {
        // Fallback to unified AI service
        final aiResponse = await _generateAIResponse(message.trim());

        // Speak the response using unified AI service
        try {
          await _aiService.speak(aiResponse);
        } catch (e) {
          debugPrint('TTS error: $e');
        }

        // Add AI response to chat
        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _addMessage(aiMessage);
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
    switch (_voiceState) {
      case GeminiLiveServiceState.listening:
        return 'Listening to your message...';
      case GeminiLiveServiceState.thinking:
        return 'Analyzing and preparing response...';
      case GeminiLiveServiceState.speaking:
        return 'Speaking response...';
      case GeminiLiveServiceState.connected:
        return 'Ready to help with your mental game';
      case GeminiLiveServiceState.error:
        return 'Service error - tap to retry';
      case GeminiLiveServiceState.connecting:
        return 'Connecting to AI coach...';
      case GeminiLiveServiceState.disconnected:
        return 'Initializing AI coach...';
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
}
