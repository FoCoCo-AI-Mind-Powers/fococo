import 'package:flutter/material.dart';
import 'package:fo_co_co/backend/schema/ai_insights_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dart:ui';

/// Enhanced AI Insight Widget with dashboard-like features
/// Displays comprehensive AI insights with visual elements and interactions
/// For full conversation features, use EnhancedAIInsightWidget
class AIInsightWidget extends StatefulWidget {
  const AIInsightWidget({
    Key? key,
    required this.insight,
    this.onTap,
    this.onRate,
  }) : super(key: key);

  final AiInsightsRecord insight;
  final VoidCallback? onTap;
  final Function(int rating, String? feedback)? onRate;

  @override
  State<AIInsightWidget> createState() => _AIInsightWidgetState();
}

class _AIInsightWidgetState extends State<AIInsightWidget>
    with TickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

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

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
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
                    // Conversation section available in EnhancedAIInsightWidget
                    // if (widget.enableConversation) ...[
                    //   const SizedBox(height: 16),
                    //   _buildConversationSection(theme),
                    // ],
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
            child: Icon(
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
            value: widget.insight.userRating > 0
                ? '${widget.insight.userRating}/5'
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
        if (widget.insight.userRating == 0) ...[
          Expanded(
            child: _buildActionButton(
              theme: theme,
              label: 'Rate Insight',
              icon: FontAwesomeIcons.thumbsUp,
              color: theme.performanceGood,
              onPressed: () => _showRatingDialog(theme),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildActionButton(
            theme: theme,
            label: 'View Details',
            icon: FontAwesomeIcons.arrowRight,
            color: theme.aiPrimary,
            onPressed: () => widget.onTap?.call(),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.secondaryText.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => _showShareOptions(theme),
            icon: Icon(
              FontAwesomeIcons.share,
              color: theme.secondaryText,
              size: 16,
            ),
          ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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

  void _showRatingDialog(FlutterFlowTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate this Insight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How helpful was this AI insight?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    widget.onRate?.call(index + 1, null);
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    FontAwesomeIcons.star,
                    color: theme.warning,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(FlutterFlowTheme theme) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: theme.aiPrimary,
      ),
    );
  }
}
