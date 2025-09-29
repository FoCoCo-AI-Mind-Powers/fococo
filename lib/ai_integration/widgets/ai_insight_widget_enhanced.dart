import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fo_co_co/backend/schema/ai_insights_record.dart';
import 'package:fo_co_co/ai_integration/services/unified_ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dart:ui';
import 'dart:convert';

/// Chat message model for conversations
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.metadata,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'type': type.name,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'],
        content: map['content'],
        isUser: map['isUser'],
        timestamp: DateTime.parse(map['timestamp']),
        metadata: map['metadata'],
        type: MessageType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => MessageType.text,
        ),
      );
}

/// Message types for different content formats
enum MessageType { text, markdown, table, image, diagram }

/// Enhanced AI Insight Widget with dashboard-like features and interactive chat
/// Displays comprehensive AI insights with visual elements and conversations
class EnhancedAIInsightWidget extends StatefulWidget {
  const EnhancedAIInsightWidget({
    Key? key,
    required this.insight,
    this.onTap,
    this.onRate,
    this.enableConversation = true,
  }) : super(key: key);

  final AiInsightsRecord insight;
  final VoidCallback? onTap;
  final Function(int rating, String? feedback)? onRate;
  final bool enableConversation;

  @override
  State<EnhancedAIInsightWidget> createState() =>
      _EnhancedAIInsightWidgetState();
}

class _EnhancedAIInsightWidgetState extends State<EnhancedAIInsightWidget>
    with TickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _conversationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  // Animation for conversation expansion (for future use)
  // late Animation<double> _conversationAnimation;

  List<ChatMessage> _chatMessages = [];
  bool _isLoadingResponse = false;
  bool _conversationExpanded = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  int _userRating = 0;

  final UnifiedAIService _aiService = UnifiedAIService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _conversationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Future conversation animation
    // _conversationAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(CurvedAnimation(
    //   parent: _conversationController,
    //   curve: Curves.easeInOut,
    // ));

    _slideController.forward();
    _pulseController.repeat(reverse: true);

    // Initialize conversation with initial AI message
    _initializeConversation();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _conversationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.aiPrimary.withValues(alpha: 0.1),
                    theme.aiSecondary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.aiPrimary.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightHeader(theme),
                    const SizedBox(height: 16),
                    _buildInsightContent(theme),
                    const SizedBox(height: 20),
                    _buildInsightMetrics(theme),
                    const SizedBox(height: 16),
                    _buildInsightActions(theme),
                    if (widget.enableConversation) ...[
                      const SizedBox(height: 16),
                      _buildConversationSection(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightHeader(FlutterFlowTheme theme) {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.aiPrimary,
                  theme.aiSecondary,
                ],
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
            child: const Icon(
              FontAwesomeIcons.brain,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.insight.insightTitle,
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: theme.aiPrimary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'AI Generated Insight',
                        style: theme.bodySmall.copyWith(
                          color: theme.aiPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getInsightTypeColor(theme).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getInsightTypeLabel(),
            style: theme.labelSmall.copyWith(
              color: _getInsightTypeColor(theme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightContent(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        widget.insight.insightContent,
        style: theme.bodyMedium.copyWith(
          color: theme.primaryText,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInsightMetrics(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme: theme,
            icon: FontAwesomeIcons.chartLine,
            label: 'Confidence',
            value: '85%', // TODO: Add confidence field to AiInsightsRecord
            color: theme.performanceGood,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme: theme,
            icon: FontAwesomeIcons.star,
            label: 'Rating',
            value: (_userRating > 0 ? _userRating : widget.insight.userRating) >
                    0
                ? '${(_userRating > 0 ? _userRating : widget.insight.userRating)}/5'
                : 'Not rated',
            color: theme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme: theme,
            icon: FontAwesomeIcons.clock,
            label: 'Generated',
            value: _formatTimestamp(widget.insight.createdTime),
            color: theme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightActions(FlutterFlowTheme theme) {
    return Row(
      children: [
        // Like/Dislike buttons
        _buildLikeDislikeButtons(theme),
        const SizedBox(width: 8),

        // Share button
        _buildActionIconButton(
          theme: theme,
          icon: FontAwesomeIcons.share,
          onPressed: () => _showShareOptions(theme),
          color: theme.secondary,
        ),
        const SizedBox(width: 8),

        // Copy button
        _buildActionIconButton(
          theme: theme,
          icon: FontAwesomeIcons.copy,
          onPressed: () => _copyInsightContent(),
          color: theme.secondary,
        ),
        const SizedBox(width: 8),

        // Feedback button
        _buildActionIconButton(
          theme: theme,
          icon: FontAwesomeIcons.comment,
          onPressed: () => _showFeedbackDialog(theme),
          color: theme.coachingPrimary,
        ),
        const SizedBox(width: 8),

        // Report button
        _buildActionIconButton(
          theme: theme,
          icon: FontAwesomeIcons.flag,
          onPressed: () => _showReportDialog(theme),
          color: theme.error,
        ),

        const Spacer(),

        // Chat toggle button
        if (widget.enableConversation)
          _buildActionButton(
            theme: theme,
            label: _conversationExpanded ? 'Hide Chat' : 'Ask AI',
            icon: _conversationExpanded
                ? FontAwesomeIcons.chevronUp
                : FontAwesomeIcons.comments,
            color: theme.aiPrimary,
            onPressed: _toggleConversation,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required FlutterFlowTheme theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build conversation section
  Widget _buildConversationSection(FlutterFlowTheme theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: _conversationExpanded ? 400 : 0,
      child: _conversationExpanded
          ? Column(
              children: [
                const Divider(),
                const SizedBox(height: 12),

                // Chat header
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.brain,
                      color: theme.aiPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Discussion',
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.aiPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _clearChat,
                      icon: Icon(
                        FontAwesomeIcons.trash,
                        size: 16,
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),

                // Chat messages
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _chatMessages.length,
                            itemBuilder: (context, index) {
                              final message = _chatMessages[index];
                              return _buildChatMessage(theme, message);
                            },
                          ),
                        ),

                        if (_isLoadingResponse)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.aiPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'AI is thinking...',
                                  style: theme.bodySmall.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Message input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Ask about this insight...',
                                    hintStyle: theme.bodySmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: theme.secondaryText
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: theme.secondaryText
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: theme.aiPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.aiPrimary,
                                      theme.aiSecondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  onPressed:
                                      _isLoadingResponse ? null : _sendMessage,
                                  icon: const Icon(
                                    FontAwesomeIcons.paperPlane,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox(),
    );
  }

  /// Build individual chat message
  Widget _buildChatMessage(FlutterFlowTheme theme, ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.aiPrimary,
                    theme.aiSecondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                FontAwesomeIcons.brain,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.aiPrimary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser
                      ? theme.aiPrimary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(theme, message),
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: theme.labelSmall.copyWith(
                            color: theme.secondaryText.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Message actions
                        _buildMessageActionButton(
                          theme: theme,
                          icon: FontAwesomeIcons.copy,
                          onPressed: () => _copyMessage(message.content),
                        ),
                        const SizedBox(width: 8),
                        _buildMessageActionButton(
                          theme: theme,
                          icon: FontAwesomeIcons.thumbsUp,
                          onPressed: () => _likeMessage(message.id),
                        ),
                        const SizedBox(width: 8),
                        _buildMessageActionButton(
                          theme: theme,
                          icon: FontAwesomeIcons.thumbsDown,
                          onPressed: () => _dislikeMessage(message.id),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                FontAwesomeIcons.user,
                color: theme.primary,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build message content based on type
  Widget _buildMessageContent(FlutterFlowTheme theme, ChatMessage message) {
    switch (message.type) {
      case MessageType.markdown:
        return MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: theme.bodyMedium.copyWith(color: theme.primaryText),
            h1: theme.titleLarge.copyWith(color: theme.primaryText),
            h2: theme.titleMedium.copyWith(color: theme.primaryText),
            h3: theme.titleSmall.copyWith(color: theme.primaryText),
            code: theme.bodySmall.copyWith(
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              fontFamily: 'monospace',
            ),
          ),
        );
      case MessageType.table:
        return _buildTableContent(theme, message.content);
      case MessageType.image:
        return _buildImageContent(theme, message.content);
      case MessageType.diagram:
        return _buildDiagramContent(theme, message.content);
      default:
        return Text(
          message.content,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            height: 1.4,
          ),
        );
    }
  }

  /// Build table content from markdown table
  Widget _buildTableContent(FlutterFlowTheme theme, String content) {
    // Simple table parser for basic markdown tables
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) return Text(content);

    final headers = lines[0]
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final rows = lines
        .skip(2)
        .map((line) => line
            .split('|')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList())
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(
          theme.aiPrimary.withValues(alpha: 0.1),
        ),
        columns: headers
            .map((header) => DataColumn(
                  label: Text(
                    header,
                    style: theme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                ))
            .toList(),
        rows: rows
            .map((row) => DataRow(
                  cells: row
                      .map((cell) => DataCell(
                            Text(
                              cell,
                              style: theme.bodySmall.copyWith(
                                color: theme.primaryText,
                              ),
                            ),
                          ))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }

  /// Build image content placeholder
  Widget _buildImageContent(FlutterFlowTheme theme, String content) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.secondaryText.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.image,
            size: 48,
            color: theme.secondaryText,
          ),
          const SizedBox(height: 8),
          Text(
            'Generated Image',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
          Text(
            content,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build diagram content placeholder
  Widget _buildDiagramContent(FlutterFlowTheme theme, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.aiPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartLine,
                color: theme.aiPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Generated Diagram',
                style: theme.titleSmall.copyWith(
                  color: theme.aiPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.bodyMedium.copyWith(
              color: theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// Build like/dislike buttons
  Widget _buildLikeDislikeButtons(FlutterFlowTheme theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isLiked
                  ? theme.performanceGood.withValues(alpha: 0.2)
                  : theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isLiked
                    ? theme.performanceGood
                    : theme.secondaryText.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              FontAwesomeIcons.thumbsUp,
              size: 14,
              color: _isLiked ? theme.performanceGood : theme.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _toggleDislike,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDisliked
                  ? theme.error.withValues(alpha: 0.2)
                  : theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDisliked
                    ? theme.error
                    : theme.secondaryText.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              FontAwesomeIcons.thumbsDown,
              size: 14,
              color: _isDisliked ? theme.error : theme.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  /// Build action icon button
  Widget _buildActionIconButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.secondaryText.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color,
          size: 14,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Build message action button
  Widget _buildMessageActionButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 12,
          color: theme.secondaryText.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Build share option in share modal
  Widget _buildShareOption({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.aiPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: theme.aiPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.bodySmall.copyWith(
              color: theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Color _getInsightTypeColor(FlutterFlowTheme theme) {
    // Determine color based on insight type or content
    final content = widget.insight.insightContent.toLowerCase();

    if (content.contains('focus') || content.contains('concentration')) {
      return theme.aiPrimary;
    } else if (content.contains('confidence') || content.contains('mental')) {
      return theme.coachingPrimary;
    } else if (content.contains('performance') ||
        content.contains('improvement')) {
      return theme.performanceGood;
    }

    return theme.secondary;
  }

  String _getInsightTypeLabel() {
    final content = widget.insight.insightContent.toLowerCase();

    if (content.contains('focus') || content.contains('concentration')) {
      return 'Focus';
    } else if (content.contains('confidence') || content.contains('mental')) {
      return 'Mental';
    } else if (content.contains('performance') ||
        content.contains('improvement')) {
      return 'Performance';
    }

    return 'General';
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Initialize conversation with loading state and first AI message
  void _initializeConversation() async {
    if (!widget.enableConversation) return;

    // Add loading message
    final loadingMessage = ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content:
          '🤔 Analyzing your recent activities to provide personalized insights...',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    setState(() {
      _chatMessages.add(loadingMessage);
    });

    // Simulate AI analysis and generate first message
    await Future.delayed(const Duration(seconds: 2));

    try {
      final welcomeResponse = await _aiService.generateResponse(
        userMessage:
            'Generate an opening conversational message about the insight: "${widget.insight.insightTitle}". Ask an engaging question to start a discussion.',
        interactionType: 'insightDiscussion',
        conversationContext:
            'New insight discussion about: ${widget.insight.insightContent}',
      );

      // Remove loading message and add AI response
      setState(() {
        _chatMessages.removeWhere((msg) => msg.id.startsWith('loading_'));
        _chatMessages.add(ChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          content: welcomeResponse,
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ));
      });

      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _chatMessages.removeWhere((msg) => msg.id.startsWith('loading_'));
        _chatMessages.add(ChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          content:
              'Hi! I\'m ready to discuss this insight with you. What questions do you have about improving your mental game?',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ));
      });
    }
  }

  /// Toggle conversation section
  void _toggleConversation() {
    setState(() {
      _conversationExpanded = !_conversationExpanded;
    });

    if (_conversationExpanded) {
      _conversationController.forward();
    } else {
      _conversationController.reverse();
    }
  }

  /// Send message to AI
  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoadingResponse) return;

    // Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _chatMessages.add(userMessage);
      _messageController.clear();
      _isLoadingResponse = true;
    });

    _scrollToBottom();

    try {
      // Generate structured AI response
      final aiResponse = await _generateStructuredResponse(message);

      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: aiResponse['content'],
        isUser: false,
        timestamp: DateTime.now(),
        type: _getMessageTypeFromResponse(aiResponse),
        metadata: aiResponse['metadata'],
      );

      setState(() {
        _chatMessages.add(aiMessage);
        _isLoadingResponse = false;
      });

      _scrollToBottom();
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          content:
              'I apologize, but I encountered an error. Please try asking your question again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoadingResponse = false;
      });
    }
  }

  /// Generate structured response using Gemini with structured output
  Future<Map<String, dynamic>> _generateStructuredResponse(
      String userMessage) async {
    try {
      // Build conversation context
      final conversationHistory = _chatMessages
          .take(_chatMessages.length - 1)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      // Use structured output for enhanced responses
      final response = await _aiService.generateResponse(
        userMessage: userMessage,
        conversationContext: jsonEncode(conversationHistory),
        interactionType: 'insightDiscussion',
        userInsights: {
          'currentInsight': {
            'title': widget.insight.insightTitle,
            'content': widget.insight.insightContent,
            'category': widget.insight.category,
          },
        },
      );

      // Parse response for structured content
      return _parseStructuredResponse(response);
    } catch (e) {
      throw Exception('Failed to generate AI response: $e');
    }
  }

  /// Parse structured response from AI
  Map<String, dynamic> _parseStructuredResponse(String response) {
    // Check for different content types
    if (response.contains('|') && response.contains('---')) {
      // Table detected
      return {
        'content': response,
        'type': 'table',
        'metadata': {'format': 'markdown_table'},
      };
    } else if (response.contains('```') ||
        response.contains('**') ||
        response.contains('*')) {
      // Markdown detected
      return {
        'content': response,
        'type': 'markdown',
        'metadata': {'format': 'markdown'},
      };
    } else if (response.toLowerCase().contains('diagram') ||
        response.toLowerCase().contains('chart')) {
      // Diagram request detected
      return {
        'content': response,
        'type': 'diagram',
        'metadata': {'format': 'diagram'},
      };
    } else if (response.toLowerCase().contains('image') ||
        response.toLowerCase().contains('visual')) {
      // Image request detected
      return {
        'content': response,
        'type': 'image',
        'metadata': {'format': 'image'},
      };
    }

    return {
      'content': response,
      'type': 'text',
      'metadata': {'format': 'plain_text'},
    };
  }

  /// Get message type from response
  MessageType _getMessageTypeFromResponse(Map<String, dynamic> response) {
    switch (response['type']) {
      case 'markdown':
        return MessageType.markdown;
      case 'table':
        return MessageType.table;
      case 'image':
        return MessageType.image;
      case 'diagram':
        return MessageType.diagram;
      default:
        return MessageType.text;
    }
  }

  /// Save chat history to Firestore
  Future<void> _saveChatHistory() async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true) return;

      final chatData = {
        'insightId': widget.insight.reference.id,
        'userId': userId,
        'messages': _chatMessages.map((msg) => msg.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'messageCount': _chatMessages.length,
      };

      await FirebaseFirestore.instance
          .collection('ai_insight_conversations')
          .doc('${widget.insight.reference.id}_$currentUserUid')
          .set(chatData, SetOptions(merge: true));
    } catch (e) {
      // Silent fail for chat history
    }
  }

  // Future feature: Load existing chat history
  // Future<void> _loadChatHistory() async {
  //   try {
  //     final userId = currentUserUid;
  //     if (userId == null) return;

  //     final doc = await FirebaseFirestore.instance
  //         .collection('ai_insight_conversations')
  //         .doc('${widget.insight.reference.id}_$userId')
  //         .get();

  //     if (doc.exists) {
  //       final data = doc.data()!;
  //       final messages = (data['messages'] as List? ?? [])
  //           .map((msg) => ChatMessage.fromMap(msg))
  //           .toList();

  //       if (messages.isNotEmpty) {
  //         setState(() {
  //           _chatMessages = messages;
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     // Continue with empty chat if loading fails
  //   }
  // }

  /// Clear chat history
  void _clearChat() {
    setState(() {
      _chatMessages.clear();
    });
    _initializeConversation();
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Toggle like state
  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) _isDisliked = false;
    });

    await _updateInsightReaction('like', _isLiked);
  }

  /// Toggle dislike state
  void _toggleDislike() async {
    setState(() {
      _isDisliked = !_isDisliked;
      if (_isDisliked) _isLiked = false;
    });

    await _updateInsightReaction('dislike', _isDisliked);
  }

  /// Update insight reaction in Firestore
  Future<void> _updateInsightReaction(String type, bool value) async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true) return;

      final reactionData = {
        'userId': userId,
        'insightId': widget.insight.reference.id,
        'reactionType': type,
        'value': value,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('ai_insight_reactions')
          .doc('${widget.insight.reference.id}_$currentUserUid')
          .set(reactionData, SetOptions(merge: true));
    } catch (e) {
      // Silent fail for reactions
    }
  }

  /// Copy insight content to clipboard
  void _copyInsightContent() {
    Clipboard.setData(ClipboardData(text: widget.insight.insightContent));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Insight copied to clipboard'),
        backgroundColor: FlutterFlowTheme.of(context).aiPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Copy message content to clipboard
  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        backgroundColor: FlutterFlowTheme.of(context).aiPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Share insight content
  void _shareInsight() {
    // TODO: Implement native sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        backgroundColor: FlutterFlowTheme.of(context).secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Save insight for later
  void _saveInsight() async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true) return;

      final saveData = {
        'userId': userId,
        'insightId': widget.insight.reference.id,
        'savedAt': FieldValue.serverTimestamp(),
        'insightTitle': widget.insight.insightTitle,
        'insightContent': widget.insight.insightContent,
      };

      await FirebaseFirestore.instance
          .collection('saved_insights')
          .add(saveData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insight saved successfully'),
          backgroundColor: FlutterFlowTheme.of(context).performanceGood,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save insight'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show share options
  void _showShareOptions(FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share Insight',
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  theme: theme,
                  icon: Icons.copy,
                  label: 'Copy',
                  onTap: () {
                    Navigator.pop(context);
                    _copyInsightContent();
                  },
                ),
                _buildShareOption(
                  theme: theme,
                  icon: Icons.ios_share,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    _shareInsight();
                  },
                ),
                _buildShareOption(
                  theme: theme,
                  icon: Icons.bookmark_add,
                  label: 'Save',
                  onTap: () {
                    Navigator.pop(context);
                    _saveInsight();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Show feedback dialog
  void _showFeedbackDialog(FlutterFlowTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.primaryBackground,
        title: Text(
          'Provide Feedback',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Help us improve this AI insight',
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitFeedback(_feedbackController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.aiPrimary,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  /// Show report dialog
  void _showReportDialog(FlutterFlowTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.primaryBackground,
        title: Text(
          'Report Issue',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report inappropriate or inaccurate content',
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                'Inappropriate Content',
                'Inaccurate Information',
                'Spam',
                'Other',
              ]
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
              onChanged: (value) => _feedbackController.text = value ?? '',
              hint: const Text('Select reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitReport(_feedbackController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  /// Submit feedback to Firestore
  Future<void> _submitFeedback(String feedback) async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true || feedback.trim().isEmpty) return;

      final feedbackData = {
        'userId': userId,
        'insightId': widget.insight.reference.id,
        'feedback': feedback.trim(),
        'type': 'feedback',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('ai_insight_feedback')
          .add(feedbackData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Feedback submitted successfully'),
          backgroundColor: FlutterFlowTheme.of(context).performanceGood,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _feedbackController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit feedback'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Submit report to Firestore
  Future<void> _submitReport(String reason) async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true || reason.trim().isEmpty) return;

      final reportData = {
        'userId': userId,
        'insightId': widget.insight.reference.id,
        'reason': reason.trim(),
        'type': 'report',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await FirebaseFirestore.instance
          .collection('ai_insight_reports')
          .add(reportData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted successfully'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _feedbackController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit report'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Like a specific message
  void _likeMessage(String messageId) async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true) return;

      final reactionData = {
        'userId': userId,
        'messageId': messageId,
        'insightId': widget.insight.reference.id,
        'reactionType': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('message_reactions')
          .doc('${messageId}_$userId')
          .set(reactionData);
    } catch (e) {
      // Silent fail
    }
  }

  /// Dislike a specific message
  void _dislikeMessage(String messageId) async {
    try {
      final userId = currentUserUid;
      if (userId?.isEmpty ?? true) return;

      final reactionData = {
        'userId': userId,
        'messageId': messageId,
        'insightId': widget.insight.reference.id,
        'reactionType': 'dislike',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('message_reactions')
          .doc('${messageId}_$userId')
          .set(reactionData);
    } catch (e) {
      // Silent fail
    }
  }
}
