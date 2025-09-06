import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'claude_style_ai_insights_model.dart';
export 'claude_style_ai_insights_model.dart';
import '/services/app_tutorial_service.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class ClaudeStyleAiInsightsWidget extends StatefulWidget {
  const ClaudeStyleAiInsightsWidget({Key? key}) : super(key: key);

  static const String routeName = 'ai_insights';
  static const String routePath = '/ai_insights';

  @override
  State<ClaudeStyleAiInsightsWidget> createState() =>
      _ClaudeStyleAiInsightsWidgetState();
}

class _ClaudeStyleAiInsightsWidgetState
    extends State<ClaudeStyleAiInsightsWidget> with TickerProviderStateMixin {
  late ClaudeStyleAiInsightsModel _model;
  final AppTutorialService _tutorialService = AppTutorialService();

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  // Tutorial keys
  final GlobalKey _chatAreaKey = GlobalKey();
  final GlobalKey _suggestionsKey = GlobalKey();
  final GlobalKey _voiceInputKey = GlobalKey();
  final GlobalKey _insightTypesKey = GlobalKey();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Chat state
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClaudeStyleAiInsightsModel());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    // Add welcome message
    _addWelcomeMessage();

    // Check and show tutorial
    _checkAndShowTutorial();
  }

  Future<void> _checkAndShowTutorial() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    _tutorialService.startAIInsightsTutorial(
      context,
      chatAreaKey: _chatAreaKey,
      suggestionsKey: _suggestionsKey,
      voiceInputKey: _voiceInputKey,
      insightTypesKey: _insightTypesKey,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _model.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            "Hello! I'm your FoCoCo AI coach. I'm here to help you improve your mental game on the golf course. Ask me anything about focus, confidence, course management, or share your recent round for personalized insights!",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.welcome,
      ));
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: _generateAIResponse(userMessage),
          isUser: false,
          timestamp: DateTime.now(),
          messageType: MessageType.insight,
        ));
      });
      _scrollToBottom();
    }
  }

  String _generateAIResponse(String userMessage) {
    // Simple response generation based on keywords
    final message = userMessage.toLowerCase();

    if (message.contains('focus') || message.contains('concentration')) {
      return "Great question about focus! Here are some techniques that can help:\n\n• **Pre-shot routine**: Develop a consistent 15-20 second routine\n• **Breathing technique**: Take 3 deep breaths before each shot\n• **Target visualization**: Pick a specific target, not just the fairway\n• **Present moment awareness**: Focus on what you can control right now\n\nTry implementing one technique at a time. Which aspect of focus challenges you most?";
    } else if (message.contains('confidence') || message.contains('nervous')) {
      return "Building confidence is key to better golf! Here's what I recommend:\n\n• **Positive self-talk**: Replace \"Don't hit it in the water\" with \"Smooth swing to my target\"\n• **Success visualization**: Spend 5 minutes before your round visualizing successful shots\n• **Process over outcome**: Focus on your swing thoughts, not the result\n• **Celebrate small wins**: Acknowledge good decisions, even if the shot isn't perfect\n\nConfidence builds through preparation and positive experiences. What situations make you feel most nervous on the course?";
    } else if (message.contains('pressure') || message.contains('clutch')) {
      return "Performing under pressure is a skill you can develop:\n\n• **Embrace the moment**: Pressure means the shot matters - that's exciting!\n• **Slow down your routine**: Take an extra second to breathe and commit\n• **Trust your preparation**: You've hit this shot thousands of times\n• **Accept the outcome**: Focus on executing, not controlling results\n\nPressure situations are opportunities to grow. What specific pressure situations challenge you most?";
    } else if (message.contains('score') || message.contains('round')) {
      return "I'd love to help analyze your round! Here's what I look for:\n\n• **Mental patterns**: Where did you lose focus or confidence?\n• **Decision making**: Were you aggressive when you should be conservative?\n• **Recovery shots**: How did you handle mistakes?\n• **Momentum shifts**: What triggered good or bad stretches?\n\nShare more details about your recent round - what went well and what was challenging? I can provide specific insights based on your experience.";
    } else {
      return "That's an interesting point! Mental performance in golf involves many factors:\n\n• **Course management**: Playing within your abilities\n• **Emotional regulation**: Staying calm after bad shots\n• **Attention control**: Focusing on the right things at the right time\n• **Confidence building**: Developing trust in your abilities\n\nI'm here to help you improve in any of these areas. What specific aspect of your mental game would you like to work on? Feel free to share details about your recent rounds or specific challenges you're facing.";
    }
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryBackground,
                theme.secondaryBackground.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar
                    _buildCustomAppBar(theme),

                    // Chat Messages
                    Expanded(
                      child: _buildChatArea(theme),
                    ),

                    // Message Input
                    _buildMessageInput(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.goNamed('dashboard'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.glassBackground.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryText,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // AI Avatar and Title
          Expanded(
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.aiPrimary, theme.aiSecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
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
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FoCoCo AI Coach',
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: theme.labelSmall.copyWith(
                            color: theme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Options button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.glassBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.more_vert,
              color: theme.primaryText,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(FlutterFlowTheme theme) {
    return Container(
      key: _chatAreaKey,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isTyping) {
            return _buildTypingIndicator(theme);
          }

          final message = _messages[index];
          return _buildMessageBubble(theme, message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(FlutterFlowTheme theme, ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.aiPrimary, theme.aiSecondary],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.brain,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.primary.withValues(alpha: 0.1)
                    : theme.glassBackground.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: message.isUser
                      ? theme.primary.withValues(alpha: 0.2)
                      : theme.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == MessageType.welcome) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          color: theme.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Welcome!',
                          style: theme.labelMedium.copyWith(
                            color: theme.aiPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: theme.bodyMedium.copyWith(
                      color: theme.primaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: theme.labelSmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.aiPrimary, theme.aiSecondary],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.brain,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.glassBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(theme, 0),
                const SizedBox(width: 4),
                _buildTypingDot(theme, 200),
                const SizedBox(width: 4),
                _buildTypingDot(theme, 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(FlutterFlowTheme theme, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * math.sin(value * math.pi)),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.secondaryText,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about your mental game...',
                  hintStyle: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withValues(alpha: 0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = MessageType.normal,
  });
}

enum MessageType {
  normal,
  welcome,
  insight,
  suggestion,
}
