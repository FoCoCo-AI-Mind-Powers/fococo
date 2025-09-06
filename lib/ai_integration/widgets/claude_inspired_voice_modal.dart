import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/fococo_voice_service.dart';

/// Claude AI-inspired voice chat modal with sophisticated UI and animations
/// Features thinking mode toggle and production-ready voice integration
class ClaudeInspiredVoiceModal extends StatefulWidget {
  final FoCoCoVoiceService voiceService;

  const ClaudeInspiredVoiceModal({
    Key? key,
    required this.voiceService,
  }) : super(key: key);

  @override
  State<ClaudeInspiredVoiceModal> createState() =>
      _ClaudeInspiredVoiceModalState();
}

class _ClaudeInspiredVoiceModalState extends State<ClaudeInspiredVoiceModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _waveController;
  late AnimationController _thinkingController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _thinkingAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  VoiceServiceState _voiceState = VoiceServiceState.uninitialized;
  bool _isThinkingMode = false;
  String _currentTranscript = '';
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVoiceListeners();
    _loadConversationHistory();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _thinkingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _thinkingController, curve: Curves.linear),
    );

    _slideController.forward();
  }

  void _setupVoiceListeners() {
    widget.voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _voiceState = state;
        });
        _updateAnimationsForState(state);
      }
    });

    widget.voiceService.thinkingModeStream.listen((isThinking) {
      if (mounted) {
        setState(() {
          _isThinkingMode = isThinking;
        });
        _updateThinkingAnimation();
      }
    });

    widget.voiceService.transcriptionStream.listen((transcript) {
      if (mounted) {
        setState(() {
          _currentTranscript = transcript;
        });
      }
    });

    widget.voiceService.responseStream.listen((response) {
      if (mounted) {
        setState(() {
          _messages = List.from(widget.voiceService.conversationHistory);
        });
        _scrollToBottom();
      }
    });
  }

  void _updateAnimationsForState(VoiceServiceState state) {
    switch (state) {
      case VoiceServiceState.listening:
        _waveController.repeat(reverse: true);
        break;
      case VoiceServiceState.thinking:
        _waveController.stop();
        _thinkingController.repeat();
        break;
      case VoiceServiceState.speaking:
        _waveController.repeat(reverse: true);
        _thinkingController.stop();
        break;
      case VoiceServiceState.ready:
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.connecting:
      case VoiceServiceState.error:
        _waveController.stop();
        _thinkingController.stop();
        break;
    }
  }

  void _updateThinkingAnimation() {
    if (_isThinkingMode && _voiceState == VoiceServiceState.thinking) {
      _thinkingController.repeat();
    } else {
      _thinkingController.stop();
    }
  }

  void _loadConversationHistory() {
    setState(() {
      _messages = List.from(widget.voiceService.conversationHistory);
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
  void dispose() {
    _slideController.dispose();
    _waveController.dispose();
    _thinkingController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: screenHeight * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryBackground,
              theme.secondaryBackground.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildHeader(theme),
                _buildModeToggle(theme),
                Expanded(child: _buildChatInterface(theme)),
                _buildVoiceVisualization(theme),
                _buildInputArea(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.secondaryText.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // AI Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.aiPrimary,
                  theme.aiSecondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.aiPrimary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              FontAwesomeIcons.brain,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Title and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FoCoCo AI Coach',
                  style: theme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStateDescription(),
                  style: theme.bodySmall?.copyWith(
                    color: _getStateColor(theme),
                    fontWeight: FontWeight.w500,
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.secondaryText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildModeButton(
            theme: theme,
            label: 'Quick Chat',
            icon: FontAwesomeIcons.bolt,
            isSelected: !_isThinkingMode,
            onTap: () {
              if (_isThinkingMode) {
                widget.voiceService.toggleThinkingMode();
              }
            },
          ),
          _buildModeButton(
            theme: theme,
            label: 'Deep Think',
            icon: FontAwesomeIcons.brain,
            isSelected: _isThinkingMode,
            onTap: () {
              if (!_isThinkingMode) {
                widget.voiceService.toggleThinkingMode();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required FlutterFlowTheme theme,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: theme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
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
                style: theme.bodyMedium?.copyWith(
                  color: isSelected ? theme.primary : theme.secondaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(theme, message, index);
      },
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.primary.withValues(alpha: 0.1),
                  theme.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              FontAwesomeIcons.microphone,
              size: 32,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your AI Mental Coach',
            style: theme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to help improve your mental game.\nTap the microphone or type to start.',
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildSamplePrompts(theme),
        ],
      ),
    );
  }

  Widget _buildSamplePrompts(FlutterFlowTheme theme) {
    final prompts = [
      'Help me with pre-shot routine',
      'I struggle with pressure putts',
      'How to stay focused on course',
      'Building confidence after bad shots',
    ];

    return Column(
      children: prompts
          .map((prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _sendTextMessage(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      prompt,
                      style: theme.bodySmall?.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMessageBubble(
      FlutterFlowTheme theme, ChatMessage message, int index) {
    final isUser = message.isUser;
    final isSystem = message.messageType == MessageType.system;

    if (isSystem) {
      return _buildSystemMessage(theme, message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarIcon(theme, false),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? theme.primary : theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                      bottomLeft: !isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    border: !isUser
                        ? Border.all(
                            color: theme.secondaryText.withValues(alpha: 0.1),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Text(
                    message.content,
                    style: theme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : theme.primaryText,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.messageType == MessageType.voice)
                      Icon(
                        FontAwesomeIcons.microphone,
                        size: 10,
                        color: theme.secondaryText,
                      ),
                    if (message.messageType == MessageType.voice)
                      const SizedBox(width: 4),
                    Text(
                      _formatMessageTime(message.timestamp),
                      style: theme.labelSmall?.copyWith(
                        color: theme.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildAvatarIcon(theme, true),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(FlutterFlowTheme theme, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.aiPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: theme.bodySmall?.copyWith(
              color: theme.aiPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarIcon(FlutterFlowTheme theme, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser
            ? theme.primary.withValues(alpha: 0.1)
            : theme.aiPrimary.withValues(alpha: 0.1),
      ),
      child: Icon(
        isUser ? Icons.person : FontAwesomeIcons.brain,
        size: 16,
        color: isUser ? theme.primary : theme.aiPrimary,
      ),
    );
  }

  Widget _buildVoiceVisualization(FlutterFlowTheme theme) {
    if (_voiceState != VoiceServiceState.listening &&
        _voiceState != VoiceServiceState.speaking &&
        _voiceState != VoiceServiceState.thinking) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          if (_voiceState == VoiceServiceState.thinking && _isThinkingMode) {
            return _buildThinkingVisualization(theme);
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(9, (index) {
              final height = 8 +
                  (math.sin((_waveAnimation.value * 2 * math.pi) +
                          (index * 0.5)) *
                      20);

              return Container(
                width: 3,
                height: height.abs(),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _getStateColor(theme).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildThinkingVisualization(FlutterFlowTheme theme) {
    return AnimatedBuilder(
      animation: _thinkingAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.brain,
              size: 20,
              color: theme.aiPrimary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            ...List.generate(3, (index) {
              final delay = index * 0.3;
              final opacity =
                  (math.sin((_thinkingAnimation.value * 2 * math.pi) + delay) +
                          1) /
                      2;

              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.aiPrimary.withValues(alpha: opacity * 0.8),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildInputArea(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: theme.secondaryText.withValues(alpha: 0.1),
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
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.secondaryText.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _textFocusNode,
                        decoration: InputDecoration(
                          hintText: _getInputHint(),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          hintStyle: theme.bodyMedium?.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                        style: theme.bodyMedium?.copyWith(
                          color: theme.primaryText,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
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
                          Icons.send_rounded,
                          color: theme.primary,
                          size: 20,
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
    return GestureDetector(
      onTap: _handleVoiceButtonTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getStateColor(theme),
          boxShadow: [
            BoxShadow(
              color: _getStateColor(theme).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _getVoiceButtonIcon(),
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  IconData _getVoiceButtonIcon() {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return FontAwesomeIcons.stop;
      case VoiceServiceState.thinking:
        return FontAwesomeIcons.spinner;
      case VoiceServiceState.speaking:
        return FontAwesomeIcons.volumeXmark;
      case VoiceServiceState.error:
        return FontAwesomeIcons.triangleExclamation;
      case VoiceServiceState.connecting:
        return FontAwesomeIcons.spinner;
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.ready:
        return FontAwesomeIcons.microphone;
    }
  }

  String _getInputHint() {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return _currentTranscript.isEmpty ? 'Listening...' : _currentTranscript;
      case VoiceServiceState.thinking:
        return 'Processing your message...';
      case VoiceServiceState.speaking:
        return 'AI is responding...';
      default:
        return 'Type your message or tap the mic...';
    }
  }

  Color _getStateColor(FlutterFlowTheme theme) {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return const Color(0xFF4CAF50);
      case VoiceServiceState.thinking:
        return const Color(0xFFFF9800);
      case VoiceServiceState.speaking:
        return const Color(0xFF2196F3);
      case VoiceServiceState.error:
        return const Color(0xFFF44336);
      case VoiceServiceState.connecting:
        return theme.secondary;
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.ready:
        return theme.primary;
    }
  }

  String _getStateDescription() {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return 'Listening to your message...';
      case VoiceServiceState.thinking:
        return _isThinkingMode
            ? 'Deep thinking in progress...'
            : 'Processing your message...';
      case VoiceServiceState.speaking:
        return 'Speaking response...';
      case VoiceServiceState.connecting:
        return 'Connecting to AI coach...';
      case VoiceServiceState.error:
        return 'Service error - tap to retry';
      case VoiceServiceState.ready:
        return 'Ready to help with your mental game';
      case VoiceServiceState.uninitialized:
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
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleVoiceButtonTap() async {
    HapticFeedback.lightImpact();

    switch (_voiceState) {
      case VoiceServiceState.listening:
        await widget.voiceService.stopListening();
        break;
      case VoiceServiceState.speaking:
        // Stop TTS playback
        break;
      case VoiceServiceState.ready:
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.error:
        await widget.voiceService.startListening();
        break;
      case VoiceServiceState.thinking:
      case VoiceServiceState.connecting:
        // Do nothing during these states
        break;
    }
  }

  void _sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _isTyping = false;
    });

    _textFocusNode.unfocus();
    HapticFeedback.selectionClick();

    await widget.voiceService.sendTextMessage(message.trim());
  }
}
