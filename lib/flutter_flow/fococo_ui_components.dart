// FoCoCo Enhanced UI Components
// Inspired by: Strava, Oura Ring, Headspace, Calm, Revolut, Duolingo
// Features: VARK learning adaptations, AI integration, gamification

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'flutter_flow_theme.dart';
import 'flutter_flow_util.dart';

// ============================================================================
// CORE CARD COMPONENTS
// ============================================================================

/// Enhanced card component with multiple style variants
class FoCoCoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isInteractive;
  final bool isLoading;
  final FoCoCoCardStyle style;

  const FoCoCoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FlutterFlowTheme.spacingM),
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = FlutterFlowTheme.borderRadiusM,
    this.boxShadow,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.isInteractive = true,
    this.isLoading = false,
    this.style = FoCoCoCardStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    Color cardBackground = backgroundColor ?? theme.primaryBackground;
    List<BoxShadow> cardShadow = boxShadow ?? _getDefaultShadow(theme);
    
    // Style-specific modifications
    switch (style) {
      case FoCoCoCardStyle.elevated:
        cardShadow = theme.shadowM;
        break;
      case FoCoCoCardStyle.outlined:
        cardShadow = [];
        break;
      case FoCoCoCardStyle.wellness:
        cardBackground = theme.calmBackground;
        cardShadow = theme.shadowS;
        break;
      case FoCoCoCardStyle.performance:
        cardBackground = theme.secondaryBackground;
        cardShadow = theme.shadowS;
        break;
      case FoCoCoCardStyle.premium:
        cardBackground = theme.secondaryBackground;
        cardShadow = theme.shadowL;
        break;
      default:
        break;
    }

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? cardBackground : null,
        gradient: gradient,
        border: borderWidth > 0 ? Border.all(
          color: borderColor ?? theme.alternate,
          width: borderWidth,
        ) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: cardShadow,
      ),
      child: isLoading ? _buildLoadingState(theme) : child,
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  List<BoxShadow> _getDefaultShadow(FlutterFlowTheme theme) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return Shimmer.fromColors(
      baseColor: theme.alternate,
      highlightColor: theme.secondaryBackground,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: theme.alternate,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

enum FoCoCoCardStyle {
  standard,
  elevated,
  outlined,
  wellness,
  performance,
  premium,
}

// ============================================================================
// PERFORMANCE & STATS COMPONENTS (Strava-inspired)
// ============================================================================

/// Performance metric card with circular progress indicator
class PerformanceMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double percentage;
  final Color? primaryColor;
  final Color? backgroundColor;
  final IconData icon;
  final String? trend;
  final VoidCallback? onTap;

  const PerformanceMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.percentage,
    this.primaryColor,
    this.backgroundColor,
    required this.icon,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final metricColor = primaryColor ?? theme.golfPrimary;

    return FoCoCoCard(
      onTap: onTap,
      style: FoCoCoCardStyle.performance,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress Circle
          CircularPercentIndicator(
            radius: 45,
            lineWidth: 6,
            animation: true,
            percent: percentage / 100,
            center: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: metricColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: metricColor,
                size: FlutterFlowTheme.iconSizeL,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: metricColor,
            backgroundColor: theme.alternate,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Title
          Text(
            title,
            style: theme.labelMedium.override(
              fontWeight: FontWeight.w600,
              color: metricColor,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingXS),
          
          // Value and Unit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.headlineSmall.override(
                  fontWeight: FontWeight.w700,
                  color: metricColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: FlutterFlowTheme.spacingXS),
              Text(
                unit,
                style: theme.labelSmall.override(
                  color: theme.secondaryText,
                  height: 1.0,
                ),
              ),
            ],
          ),
          
          // Trend indicator
          if (trend != null) ...[
            const SizedBox(height: FlutterFlowTheme.spacingXS),
            Text(
              trend!,
              style: theme.bodySmall.override(
                color: _getTrendColor(theme),
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTrendColor(FlutterFlowTheme theme) {
    if (trend == null) return theme.secondaryText;
    if (trend!.startsWith('+')) return theme.success;
    if (trend!.startsWith('-')) return theme.error;
    return theme.secondaryText;
  }
}

/// Activity streak indicator (Strava-inspired)
class StreakIndicator extends StatelessWidget {
  final int currentStreak;
  final int maxStreak;
  final String streakType;
  final bool isActive;

  const StreakIndicator({
    super.key,
    required this.currentStreak,
    required this.maxStreak,
    required this.streakType,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final streakColor = isActive ? theme.streakActive : theme.streakInactive;

    return FoCoCoCard(
      style: FoCoCoCardStyle.standard,
      child: Row(
        children: [
          // Streak icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: streakColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.fire,
              color: streakColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: FlutterFlowTheme.spacingM),
          
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak Day Streak',
                  style: theme.titleMedium.override(
                    color: streakColor,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingXS),
                Text(
                  '$streakType • Best: $maxStreak days',
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WELLNESS & MENTAL HEALTH COMPONENTS (Oura Ring + Headspace inspired)
// ============================================================================

/// Holistic wellness score display (Oura Ring-inspired)
class WellnessScoreCard extends StatelessWidget {
  final double score;
  final String date;
  final Map<String, double> subScores;
  final VoidCallback? onTap;

  const WellnessScoreCard({
    super.key,
    required this.score,
    required this.date,
    required this.subScores,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final scoreColor = _getScoreColor(theme);

    return FoCoCoCard(
      onTap: onTap,
      style: FoCoCoCardStyle.wellness,
      gradient: LinearGradient(
        colors: [
          theme.mentalWellness.withOpacity(0.1),
          theme.mentalFocus.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mental Performance Index',
                style: theme.titleMedium.override(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                date,
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  height: 1.2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Main score circle
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 8,
            animation: true,
            percent: score / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toInt().toString(),
                  style: theme.displayMedium.override(
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  'MPI',
                  style: theme.labelSmall.override(
                    color: theme.secondaryText,
                    letterSpacing: 1.0,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: scoreColor,
            backgroundColor: theme.alternate,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Sub-scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSubScore(context, 'Focus', subScores['focus'] ?? 0, theme.mentalFocus),
              _buildSubScore(context, 'Calm', subScores['calm'] ?? 0, theme.mentalCalm),
              _buildSubScore(context, 'Energy', subScores['energy'] ?? 0, theme.mentalEnergy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubScore(BuildContext context, String label, double value, Color color) {
    final theme = FlutterFlowTheme.of(context);
    
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 20,
          lineWidth: 4,
          animation: true,
          percent: value / 100,
          center: Text(
            value.toInt().toString(),
            style: theme.bodySmall.override(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 10,
              height: 1.2,
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: color,
          backgroundColor: theme.alternate,
        ),
        const SizedBox(height: FlutterFlowTheme.spacingXS),
        Text(
          label,
          style: theme.labelSmall.override(
            color: theme.secondaryText,
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(FlutterFlowTheme theme) {
    if (score >= 80) return theme.success;
    if (score >= 60) return theme.warning;
    return theme.error;
  }
}

/// Mindfulness session card (Headspace-inspired)
class MindfulnessSessionCard extends StatelessWidget {
  final String title;
  final String duration;
  final String difficulty;
  final String imageUrl;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback? onTap;

  const MindfulnessSessionCard({
    super.key,
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.imageUrl,
    required this.isCompleted,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return FoCoCoCard(
      onTap: isLocked ? null : onTap,
      style: FoCoCoCardStyle.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session image with status overlay
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.mindfulnessPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
                  image: imageUrl.isNotEmpty ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: imageUrl.isEmpty ? Icon(
                  Icons.self_improvement_rounded,
                  size: 48,
                  color: theme.mindfulnessPrimary,
                ) : null,
              ),
              
              // Status indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor(theme),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Session title
          Text(
            title,
            style: theme.titleMedium.override(
              fontWeight: FontWeight.w600,
              color: isLocked ? theme.secondaryText : theme.primaryText,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingS),
          
          // Session details
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: theme.secondaryText,
              ),
              const SizedBox(width: FlutterFlowTheme.spacingXS),
              Text(
                duration,
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: FlutterFlowTheme.spacingM),
              Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: theme.secondaryText,
              ),
              const SizedBox(width: FlutterFlowTheme.spacingXS),
              Text(
                difficulty,
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FlutterFlowTheme theme) {
    if (isLocked) return theme.skillLocked;
    if (isCompleted) return theme.skillComplete;
    return theme.skillInProgress;
  }

  IconData _getStatusIcon() {
    if (isLocked) return Icons.lock_rounded;
    if (isCompleted) return Icons.check_rounded;
    return Icons.play_arrow_rounded;
  }
}

// ============================================================================
// COACHING & LEARNING COMPONENTS (Headspace + Duolingo inspired)
// ============================================================================

/// Skill progress node (Duolingo-inspired)
class SkillProgressNode extends StatelessWidget {
  final String title;
  final int level;
  final int maxLevel;
  final double progress;
  final bool isCompleted;
  final bool isLocked;
  final bool isActive;
  final VoidCallback? onTap;

  const SkillProgressNode({
    super.key,
    required this.title,
    required this.level,
    required this.maxLevel,
    required this.progress,
    required this.isCompleted,
    required this.isLocked,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final nodeColor = _getNodeColor(theme);

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Column(
        children: [
          // Progress node
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
              boxShadow: isActive ? [
                BoxShadow(
                  color: nodeColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                // Progress ring
                if (!isCompleted && !isLocked)
                  Center(
                    child: CircularPercentIndicator(
                      radius: 30,
                      lineWidth: 3,
                      animation: false,
                      percent: progress,
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                
                // Icon
                Center(
                  child: Icon(
                    _getNodeIcon(),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingS),
          
          // Title
          Text(
            title,
            style: theme.bodySmall.override(
              fontWeight: FontWeight.w600,
              color: isLocked ? theme.secondaryText : theme.primaryText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Level indicator
          if (level > 0)
            Text(
              'Level $level',
              style: theme.labelSmall.override(
                color: theme.secondaryText,
                fontSize: 10,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }

  Color _getNodeColor(FlutterFlowTheme theme) {
    if (isLocked) return theme.skillLocked;
    if (isCompleted) return theme.skillComplete;
    if (isActive) return theme.learningPath;
    return theme.skillInProgress;
  }

  IconData _getNodeIcon() {
    if (isLocked) return Icons.lock_rounded;
    if (isCompleted) return Icons.check_rounded;
    return Icons.psychology_rounded;
  }
}

/// Achievement badge (Duolingo-inspired)
class AchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final AchievementTier tier;
  final bool isEarned;
  final DateTime? earnedDate;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.isEarned,
    this.earnedDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final badgeColor = _getBadgeColor(theme);

    return FoCoCoCard(
      onTap: onTap,
      style: FoCoCoCardStyle.standard,
      child: Column(
        children: [
          // Badge icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: isEarned ? [
                BoxShadow(
                  color: badgeColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Badge title
          Text(
            title,
            style: theme.titleSmall.override(
              fontWeight: FontWeight.w600,
              color: isEarned ? theme.primaryText : theme.secondaryText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingXS),
          
          // Badge description
          Text(
            description,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Earned date
          if (isEarned && earnedDate != null) ...[
            const SizedBox(height: FlutterFlowTheme.spacingS),
            Text(
              'Earned ${dateTimeFormat('MMM d, yyyy', earnedDate!)}',
              style: theme.labelSmall.override(
                color: theme.success,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor(FlutterFlowTheme theme) {
    if (!isEarned) return theme.skillLocked;
    
    switch (tier) {
      case AchievementTier.bronze:
        return theme.badgeBronze;
      case AchievementTier.silver:
        return theme.badgeSilver;
      case AchievementTier.gold:
        return theme.badgeGold;
    }
  }
}

enum AchievementTier { bronze, silver, gold }

// ============================================================================
// AI & INSIGHTS COMPONENTS
// ============================================================================

/// AI insight card with conversation interface
class AIInsightCard extends StatelessWidget {
  final String title;
  final String insight;
  final String sentiment;
  final List<String> recommendations;
  final DateTime timestamp;
  final String aiModel;
  final VoidCallback? onFeedback;
  final VoidCallback? onExpand;

  const AIInsightCard({
    super.key,
    required this.title,
    required this.insight,
    required this.sentiment,
    required this.recommendations,
    required this.timestamp,
    required this.aiModel,
    this.onFeedback,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final sentimentColor = theme.getInsightSentimentColor(sentiment);

    return FoCoCoCard(
      style: FoCoCoCardStyle.standard,
      gradient: LinearGradient(
        colors: [
          theme.aiAccent.withOpacity(0.1),
          theme.aiAccent.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.aiPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: FlutterFlowTheme.spacingM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium.override(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'AI Insight • ${dateTimeFormat('MMM d, HH:mm', timestamp)}',
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sentiment indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlutterFlowTheme.spacingS,
                  vertical: FlutterFlowTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: sentimentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
                ),
                child: Text(
                  sentiment.toUpperCase(),
                  style: theme.labelSmall.override(
                    color: sentimentColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Insight content
          Container(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            decoration: BoxDecoration(
              color: theme.conversationAI.withOpacity(0.1),
              borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
            ),
            child: Text(
              insight,
              style: theme.bodyMedium.override(
                height: 1.5,
              ),
            ),
          ),
          
          // Recommendations
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: FlutterFlowTheme.spacingM),
            Text(
              'Recommendations',
              style: theme.titleSmall.override(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: FlutterFlowTheme.spacingS),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingXS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.aiPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingS),
                  Expanded(
                    child: Text(
                      rec,
                      style: theme.bodyMedium.override(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Actions
          Row(
            children: [
              // Feedback button
              if (onFeedback != null)
                TextButton.icon(
                  onPressed: onFeedback,
                  icon: Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: theme.secondaryText,
                  ),
                  label: Text(
                    'Helpful?',
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      height: 1.2,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlutterFlowTheme.spacingS,
                      vertical: FlutterFlowTheme.spacingXS,
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Model info
              Text(
                aiModel,
                style: theme.labelSmall.override(
                  color: theme.secondaryText.withOpacity(0.7),
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VARK LEARNING STYLE COMPONENTS
// ============================================================================

/// VARK-adaptive content container
class VarkContentContainer extends StatelessWidget {
  final String varkStyle;
  final Widget child;
  final bool showIndicator;

  const VarkContentContainer({
    super.key,
    required this.varkStyle,
    required this.child,
    this.showIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final varkColor = theme.getVarkColor(varkStyle);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: varkColor,
            width: 4,
          ),
        ),
        color: varkColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIndicator)
            Container(
              padding: const EdgeInsets.all(FlutterFlowTheme.spacingS),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getVarkIcon(),
                    size: 16,
                    color: varkColor,
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingS),
                  Text(
                    'Optimized for ${varkStyle.toUpperCase()} learning',
                    style: theme.labelSmall.override(
                      color: varkColor,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            child: child,
          ),
        ],
      ),
    );
  }

  IconData _getVarkIcon() {
    switch (varkStyle.toLowerCase()) {
      case 'visual':
        return Icons.visibility_rounded;
      case 'auditory':
        return Icons.volume_up_rounded;
      case 'readwrite':
      case 'read-write':
        return Icons.text_fields_rounded;
      case 'kinesthetic':
        return Icons.touch_app_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }
}

// ============================================================================
// PROFESSIONAL & SUBSCRIPTION COMPONENTS (Revolut-inspired)
// ============================================================================

/// Subscription tier card
class SubscriptionTierCard extends StatelessWidget {
  final String tierName;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrentTier;
  final bool isRecommended;
  final VoidCallback? onSelect;

  const SubscriptionTierCard({
    super.key,
    required this.tierName,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrentTier,
    required this.isRecommended,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final tierColor = theme.getSubscriptionTierColor(tierName);

    return FoCoCoCard(
      style: isRecommended ? FoCoCoCardStyle.premium : FoCoCoCardStyle.standard,
      borderColor: isCurrentTier ? theme.subscriptionActive : null,
      borderWidth: isCurrentTier ? 2 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlutterFlowTheme.spacingS,
                          vertical: FlutterFlowTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: theme.premiumGold,
                          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: theme.labelSmall.override(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: FlutterFlowTheme.spacingS),
                    
                    Text(
                      tierName,
                      style: theme.titleLarge.override(
                        fontWeight: FontWeight.w600,
                        color: tierColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: theme.headlineSmall.override(
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    period,
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Features
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingS),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: theme.success,
                ),
                const SizedBox(width: FlutterFlowTheme.spacingS),
                Expanded(
                  child: Text(
                    feature,
                    style: theme.bodyMedium.override(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentTier ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentTier ? theme.subscriptionActive : tierColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: FlutterFlowTheme.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                ),
              ),
              child: Text(
                isCurrentTier ? 'Current Plan' : 'Select Plan',
                style: theme.titleSmall.override(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UTILITY COMPONENTS
// ============================================================================

/// Loading shimmer effect
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = FlutterFlowTheme.borderRadiusS,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Shimmer.fromColors(
      baseColor: theme.alternate,
      highlightColor: theme.secondaryBackground,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.alternate,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Empty state component
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.secondaryText,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          Text(
            title,
            style: theme.titleLarge.override(
              fontWeight: FontWeight.w600,
              color: theme.secondaryText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingS),
          
          Text(
            subtitle,
            style: theme.bodyMedium.override(
              color: theme.secondaryText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: FlutterFlowTheme.spacingL),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: FlutterFlowTheme.spacingL,
                  vertical: FlutterFlowTheme.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                ),
              ),
              child: Text(
                actionText!,
                style: theme.titleSmall.override(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 