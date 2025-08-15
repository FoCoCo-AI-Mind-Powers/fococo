import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/gemini_voice_service.dart';
import '../config/gemini_voice_config.dart';

/// Voice chat modal providing conversational AI coaching interface
class VoiceChatModal extends StatefulWidget {
  const VoiceChatModal({Key? key}) : super(key: key);

  @override
  State<VoiceChatModal> createState() => _VoiceChatModalState();
}

class _VoiceChatModalState extends State<VoiceChatModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _waveController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _waveAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  
  VoiceServiceState _voiceState = VoiceServiceState.uninitialized;
  String _currentTranscript = '';
  List<VoiceMessage> _messages = [];
  VoiceInteractionType _interactionType = VoiceInteractionType.quickChat;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    
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

    // Initialize voice service and start animations
    _initializeVoiceService();
    _slideController.forward();
    
    // Listen to voice service streams
    _setupVoiceListeners();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceService() async {
    final voiceService = GeminiVoiceService();
    final initialized = await voiceService.initialize();
    
    if (initialized) {
      setState(() {
        _voiceState = VoiceServiceState.ready;
        _messages = voiceService.conversationHistory;
      });
    } else {
      setState(() {
        _voiceState = VoiceServiceState.error;
      });
    }
  }

  void _setupVoiceListeners() {
    final voiceService = GeminiVoiceService();
    
    voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _voiceState = state;
          _messages = voiceService.conversationHistory;
        });
        
        // Auto-scroll to bottom when new messages arrive
        if (state == VoiceServiceState.ready && _messages.isNotEmpty) {
          _scrollToBottom();
        }
        
        // Update wave animation
        if (state == VoiceServiceState.listening || state == VoiceServiceState.speaking) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });
    
    voiceService.transcriptStream.listen((transcript) {
      if (mounted) {
        setState(() {
          _currentTranscript = transcript;
        });
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            _buildInteractionTypeSelector(theme),
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
            color: theme.accent4.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
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
                  style: theme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStateDescription(),
                  style: theme.bodyMedium?.copyWith(
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

  Widget _buildInteractionTypeSelector(FlutterFlowTheme theme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildModeButton(
            theme,
            'Quick Chat',
            VoiceInteractionType.quickChat,
            FontAwesomeIcons.comments,
          ),
          const SizedBox(width: 8),
          _buildModeButton(
            theme,
            'Deep Think',
            VoiceInteractionType.thinkingMode,
            FontAwesomeIcons.lightbulb,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    FlutterFlowTheme theme,
    String label,
    VoiceInteractionType type,
    IconData icon,
  ) {
    final isSelected = _interactionType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _interactionType = type;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected 
              ? theme.primary.withOpacity(0.1)
              : theme.accent4.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? theme.primary 
                : theme.accent4.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? theme.primary : theme.secondaryText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.bodySmall?.copyWith(
                  color: isSelected ? theme.primary : theme.secondaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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
        return _buildMessageBubble(theme, message);
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
              color: theme.primary.withOpacity(0.1),
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
            style: theme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone or type to begin\nyour conversation with the AI coach',
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(
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
      children: prompts.map((prompt) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => _sendTextMessage(prompt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.accent4.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.accent4.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              prompt,
              style: theme.bodySmall?.copyWith(
                color: theme.primary,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMessageBubble(FlutterFlowTheme theme, VoiceMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarIcon(theme, false),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser 
                      ? theme.primary
                      : theme.accent4.withOpacity(0.1),
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
                    style: theme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : theme.primaryText,
                    ),
                  ),
                ),
                if (message.thinkingProcess != null && message.thinkingProcess!.isNotEmpty)
                  _buildThinkingProcess(theme, message.thinkingProcess!),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: theme.bodySmall?.copyWith(
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

  Widget _buildThinkingProcess(FlutterFlowTheme theme, String thinking) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.accent2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.accent2.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.lightbulb,
                size: 14,
                color: theme.accent2,
              ),
              const SizedBox(width: 6),
              Text(
                'AI Thinking Process',
                style: theme.bodySmall?.copyWith(
                  color: theme.accent2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            thinking,
            style: theme.bodySmall?.copyWith(
              color: theme.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
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
          ? theme.primary.withOpacity(0.1)
          : theme.accent3.withOpacity(0.1),
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
    if (_voiceState != VoiceServiceState.listening && 
        _voiceState != VoiceServiceState.speaking) {
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
                (math.sin((_waveAnimation.value * 2 * math.pi) + (index * 0.5)) * 15);
              
              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.7),
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
            color: theme.accent4.withOpacity(0.2),
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
                  color: theme.accent4.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.accent4.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _voiceState == VoiceServiceState.listening 
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
      case VoiceServiceState.listening:
        icon = FontAwesomeIcons.stop;
        color = Colors.red;
        onPressed = _stopListening;
        break;
      case VoiceServiceState.speaking:
        icon = FontAwesomeIcons.volumeXmark;
        color = Colors.orange;
        onPressed = _stopSpeaking;
        break;
      case VoiceServiceState.thinking:
        icon = FontAwesomeIcons.spinner;
        color = Colors.orange;
        onPressed = null;
        break;
      case VoiceServiceState.ready:
        icon = FontAwesomeIcons.microphone;
        color = theme.primary;
        onPressed = _startListening;
        break;
      case VoiceServiceState.error:
        icon = FontAwesomeIcons.exclamationTriangle;
        color = Colors.red;
        onPressed = _initializeVoiceService;
        break;
      case VoiceServiceState.uninitialized:
      default:
        icon = FontAwesomeIcons.microphone;
        color = theme.secondaryText;
        onPressed = _initializeVoiceService;
        break;
    }
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
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

  void _startListening() async {
    HapticFeedback.lightImpact();
    await GeminiVoiceService().startListening(type: _interactionType);
  }

  void _stopListening() async {
    HapticFeedback.lightImpact();
    await GeminiVoiceService().stopListening();
  }

  void _stopSpeaking() async {
    HapticFeedback.lightImpact();
    await GeminiVoiceService().stopAudioPlayback();
  }

  void _sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    _textController.clear();
    setState(() {
      _isTyping = false;
    });
    
    HapticFeedback.selectionClick();
    
    await GeminiVoiceService().processVoiceMessage(
      message: message.trim(),
      type: _interactionType,
      // TODO: Add VARK preferences and user context
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  String _getStateDescription() {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return 'Listening to your message...';
      case VoiceServiceState.thinking:
        return 'Analyzing and preparing response...';
      case VoiceServiceState.speaking:
        return 'Speaking response...';
      case VoiceServiceState.ready:
        return 'Ready to help with your mental game';
      case VoiceServiceState.error:
        return 'Service error - tap to retry';
      case VoiceServiceState.uninitialized:
      default:
        return 'Initializing AI coach...';
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}