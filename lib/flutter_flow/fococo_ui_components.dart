import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'flutter_flow_theme.dart';
import 'flutter_flow_util.dart';
import 'package:go_router/go_router.dart';

/// FoCoCo Enhanced UI Components - Strava + Calm Inspired
/// Using the brand colors: #fea400, #0a3669, #017b3d
/// Features: Activity feeds, Performance metrics, Coaching modules, Mindfulness components

// ============================================================================
// STRAVA-INSPIRED ACTIVITY & PERFORMANCE COMPONENTS
// ============================================================================

/// Strava-inspired Activity Card for Golf Rounds
class FoCoCoActivityCard extends StatelessWidget {
  const FoCoCoActivityCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.date,
    this.courseImage,
    this.onTap,
    this.showStats = true,
    this.stats = const [],
    this.achievements = const [],
    this.isPersonalRecord = false,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final String score;
  final String date;
  final String? courseImage;
  final VoidCallback? onTap;
  final bool showStats;
  final List<ActivityStat> stats;
  final List<Achievement> achievements;
  final bool isPersonalRecord;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.activityCardBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        boxShadow: [theme.activityCardShadow],
        border: isPersonalRecord ? Border.all(
          color: theme.personalRecord,
          width: 2,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
          child: Padding(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and personal record badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.headlineSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: FlutterFlowTheme.spacingXS),
                          Text(
                            subtitle,
                            style: theme.bodyMedium.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPersonalRecord)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlutterFlowTheme.spacingS,
                          vertical: FlutterFlowTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: theme.personalRecord,
                          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: FlutterFlowTheme.iconSizeS,
                              color: Colors.white,
                            ),
                            const SizedBox(width: FlutterFlowTheme.spacingXS),
                            Text(
                              'PR',
                              style: theme.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: FlutterFlowTheme.spacingM),
                
                // Main score display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score,
                      style: theme.displayMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.activityPrimary,
                      ),
                    ),
                    const SizedBox(width: FlutterFlowTheme.spacingS),
                    Padding(
                      padding: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingS),
                      child: Text(
                        date,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (showStats && stats.isNotEmpty) ...[
                  const SizedBox(height: FlutterFlowTheme.spacingM),
                  
                  // Stats row
                  Row(
                    children: stats.map((stat) => Expanded(
                      child: _buildStatItem(theme, stat),
                    )).toList(),
                  ),
                ],
                
                if (achievements.isNotEmpty) ...[
                  const SizedBox(height: FlutterFlowTheme.spacingM),
                  
                  // Achievements row
                  Row(
                    children: achievements.map((achievement) => 
                      Container(
                        margin: const EdgeInsets.only(right: FlutterFlowTheme.spacingS),
                        child: _buildAchievementBadge(theme, achievement),
                      ),
                    ).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(FlutterFlowTheme theme, ActivityStat stat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.value,
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: FlutterFlowTheme.spacingXS),
        Text(
          stat.label,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(FlutterFlowTheme theme, Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingXS),
      decoration: BoxDecoration(
        color: theme.getAchievementColor(achievement.tier),
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
      ),
      child: Icon(
        achievement.icon,
        size: FlutterFlowTheme.iconSizeS,
        color: Colors.white,
      ),
    );
  }
}

/// Strava-inspired Performance Metrics Widget
class FoCoCoPerformanceMetrics extends StatelessWidget {
  const FoCoCoPerformanceMetrics({
    Key? key,
    required this.metrics,
    this.showTrend = true,
    this.compactView = false,
  }) : super(key: key);

  final List<PerformanceMetric> metrics;
  final bool showTrend;
  final bool compactView;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.performanceBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        boxShadow: [theme.performanceCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: FlutterFlowTheme.iconSizeM,
                color: theme.activityPrimary,
              ),
              const SizedBox(width: FlutterFlowTheme.spacingS),
              Text(
                'Performance Metrics',
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          if (compactView)
            _buildCompactMetrics(theme)
          else
            _buildDetailedMetrics(theme),
        ],
      ),
    );
  }

  Widget _buildCompactMetrics(FlutterFlowTheme theme) {
    return Row(
      children: metrics.map((metric) => Expanded(
        child: _buildMetricItem(theme, metric, true),
      )).toList(),
    );
  }

  Widget _buildDetailedMetrics(FlutterFlowTheme theme) {
    return Column(
      children: metrics.map((metric) => 
        Container(
          margin: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingM),
          child: _buildMetricItem(theme, metric, false),
        ),
      ).toList(),
    );
  }

  Widget _buildMetricItem(FlutterFlowTheme theme, PerformanceMetric metric, bool compact) {
    final Color metricColor = theme.getPerformanceColor(metric.score);
    
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
        border: Border.all(
          color: metricColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: compact ? _buildCompactMetricContent(theme, metric, metricColor) 
                    : _buildDetailedMetricContent(theme, metric, metricColor),
    );
  }

  Widget _buildCompactMetricContent(FlutterFlowTheme theme, PerformanceMetric metric, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.value,
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: FlutterFlowTheme.spacingXS),
        Text(
          metric.label,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetricContent(FlutterFlowTheme theme, PerformanceMetric metric, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: FlutterFlowTheme.spacingXS),
              Text(
                metric.value,
                style: theme.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (showTrend && metric.trend != null)
          Container(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingS),
            decoration: BoxDecoration(
              color: metric.trend! > 0 ? theme.performanceGood.withValues(alpha: 0.1) 
                                      : theme.performancePoor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  metric.trend! > 0 ? Icons.trending_up : Icons.trending_down,
                  size: FlutterFlowTheme.iconSizeS,
                  color: metric.trend! > 0 ? theme.performanceGood : theme.performancePoor,
                ),
                const SizedBox(width: FlutterFlowTheme.spacingXS),
                Text(
                  '${metric.trend!.abs().toStringAsFixed(1)}%',
                  style: theme.bodySmall.copyWith(
                    color: metric.trend! > 0 ? theme.performanceGood : theme.performancePoor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Strava-inspired Streak Widget
class FoCoCoStreakWidget extends StatelessWidget {
  const FoCoCoStreakWidget({
    Key? key,
    required this.currentStreak,
    required this.longestStreak,
    this.streakType = 'Training',
    this.isActive = true,
  }) : super(key: key);

  final int currentStreak;
  final int longestStreak;
  final String streakType;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.streakActive.withValues(alpha: 0.1),
            theme.streakActive.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        border: Border.all(
          color: theme.streakActive.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Streak fire icon
          Container(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            decoration: BoxDecoration(
              color: theme.streakActive,
              borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
            ),
            child: Icon(
              Icons.local_fire_department,
              size: FlutterFlowTheme.iconSizeL,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: FlutterFlowTheme.spacingM),
          
          // Streak information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak Day Streak',
                  style: theme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingXS),
                Text(
                  '$streakType ${isActive ? '• Active' : '• Inactive'}',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingS),
                Text(
                  'Longest: $longestStreak days',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
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
// CALM-INSPIRED WELLNESS & MINDFULNESS COMPONENTS
// ============================================================================

/// Calm-inspired Mindfulness Session Card
class FoCoCoMindfulnessCard extends StatelessWidget {
  const FoCoCoMindfulnessCard({
    Key? key,
    required this.title,
    required this.description,
    required this.duration,
    required this.sessionType,
    this.backgroundImage,
    this.progress,
    this.isLocked = false,
    this.onTap,
  }) : super(key: key);

  final String title;
  final String description;
  final String duration;
  final String sessionType;
  final String? backgroundImage;
  final double? progress;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      height: FlutterFlowTheme.moduleCardHeight,
      margin: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        boxShadow: [theme.coachingModuleShadow],
        image: backgroundImage != null ? DecorationImage(
          image: AssetImage(backgroundImage!),
          fit: BoxFit.cover,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
              gradient: LinearGradient(
                colors: [
                  theme.getMindfulnessColor(sessionType).withValues(alpha: 0.8),
                  theme.getMindfulnessColor(sessionType).withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlutterFlowTheme.spacingS,
                          vertical: FlutterFlowTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
                        ),
                        child: Text(
                          sessionType.toUpperCase(),
                          style: theme.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Title and description
                      Text(
                        title,
                        style: theme.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: FlutterFlowTheme.spacingS),
                      Text(
                        description,
                        style: theme.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: FlutterFlowTheme.spacingM),
                      
                      // Duration and progress
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: FlutterFlowTheme.iconSizeS,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: FlutterFlowTheme.spacingXS),
                          Text(
                            duration,
                            style: theme.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const Spacer(),
                          if (progress != null)
                            Text(
                              '${(progress! * 100).toInt()}%',
                              style: theme.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      
                      if (progress != null) ...[
                        const SizedBox(height: FlutterFlowTheme.spacingS),
                        LinearProgressIndicator(
                          value: progress!,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: FlutterFlowTheme.moduleProgressHeight,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Lock overlay
                if (isLocked)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: FlutterFlowTheme.iconSizeL,
                            color: Colors.white,
                          ),
                          const SizedBox(height: FlutterFlowTheme.spacingS),
                          Text(
                            'LOCKED',
                            style: theme.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Calm-inspired Breathing Exercise Widget
class FoCoCoBreathingWidget extends StatefulWidget {
  const FoCoCoBreathingWidget({
    Key? key,
    this.duration = 60,
    this.inhaleTime = 4,
    this.holdTime = 4,
    this.exhaleTime = 4,
    this.onStart,
    this.onStop,
    this.onComplete,
  }) : super(key: key);

  final int duration;
  final int inhaleTime;
  final int holdTime;
  final int exhaleTime;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onComplete;

  @override
  State<FoCoCoBreathingWidget> createState() => _FoCoCoBreathingWidgetState();
}

class _FoCoCoBreathingWidgetState extends State<FoCoCoBreathingWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isActive = false;
  String _currentPhase = 'Inhale';
  
  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: Duration(seconds: widget.inhaleTime + widget.holdTime + widget.exhaleTime),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
    });
    
    _breathingController.repeat();
    widget.onStart?.call();
  }

  void _stopBreathing() {
    setState(() {
      _isActive = false;
    });
    
    _breathingController.stop();
    widget.onStop?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingXL),
      decoration: BoxDecoration(
        gradient: theme.mindfulnessGradient,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
      ),
      child: Column(
        children: [
          // Breathing visualization
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Container(
                width: 200 * _breathingAnimation.value,
                height: 200 * _breathingAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 150 * _breathingAnimation.value,
                    height: 150 * _breathingAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: Center(
                      child: Text(
                        _currentPhase,
                        style: theme.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Instructions
          Text(
            _isActive ? 'Follow the circle' : 'Tap to start breathing',
            style: theme.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Control button
          ElevatedButton(
            onPressed: _isActive ? _stopBreathing : _startBreathing,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.breathingActive,
              padding: const EdgeInsets.symmetric(
                horizontal: FlutterFlowTheme.spacingL,
                vertical: FlutterFlowTheme.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusButton),
              ),
            ),
            child: Text(
              _isActive ? 'STOP' : 'START',
              style: theme.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SUPPORTING DATA MODELS
// ============================================================================

class ActivityStat {
  final String label;
  final String value;
  
  ActivityStat({required this.label, required this.value});
}

class Achievement {
  final String tier;
  final IconData icon;
  final String name;
  
  Achievement({required this.tier, required this.icon, required this.name});
}

class PerformanceMetric {
  final String label;
  final String value;
  final double score;
  final double? trend;
  
  PerformanceMetric({
    required this.label,
    required this.value,
    required this.score,
    this.trend,
  });
}

// ============================================================================
// GRADIENT ENUMS
// ============================================================================

enum GradientType {
  primary,
  secondary,
  tertiary,
  mental,
  coaching,
  calm,
}

enum LogoSize {
  small,
  medium,
  large,
  extraLarge,
}

enum FoCoCoCardStyle {
  standard,
  elevated,
  outlined,
  filled,
  premium,
  wellness,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  diamond,
}

/// FoCoCo Brand Colors Helper
class FoCoCoColors {
  static const Color brandOrange = Color(0xFFFEA400);
  static const Color brandBlue = Color(0xFF0A3669);
  static const Color brandGreen = Color(0xFF017B3D);
} 

// ============================================================================
// MISSING UI COMPONENTS - CORE FOCOCO WIDGETS
// ============================================================================

/// FoCoCo Logo Widget with SVG Support
class FoCoCoLogo extends StatelessWidget {
  final LogoSize size;
  final Color? color;
  final double? customSize;
  // Additional parameters for backward compatibility
  final bool? showText;
  final bool? animated;

  const FoCoCoLogo({
    super.key,
    required this.size,
    this.color,
    this.customSize,
    this.showText,
    this.animated,
  });

  double get _logoSize {
    if (customSize != null) return customSize!;
    switch (size) {
      case LogoSize.small:
        return 40.0;
      case LogoSize.medium:
        return 60.0;
      case LogoSize.large:
        return 80.0;
      case LogoSize.extraLarge:
        return 120.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use PNG logo as fallback due to SVG transparency issues
    return Image.asset(
      'assets/images/fococo logo.png',
      width: _logoSize,
      height: _logoSize,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to a simple icon if image fails to load
        return Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF0A3669),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sports_golf,
            size: _logoSize * 0.6,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// FoCoCo Animated Splash Screen
class FoCoCoAnimatedSplash extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final Duration? duration;

  const FoCoCoAnimatedSplash({
    super.key,
    this.onAnimationComplete,
    this.duration,
  });

  @override
  State<FoCoCoAnimatedSplash> createState() => _FoCoCoAnimatedSplashState();
}

class _FoCoCoAnimatedSplashState extends State<FoCoCoAnimatedSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward().then((_) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FlutterFlowTheme.of(context).primary,
              FlutterFlowTheme.of(context).secondary,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FoCoCoLogo(size: LogoSize.extraLarge),
                      const SizedBox(height: 24),
                      Text(
                        'FoCoCo',
                        style: FlutterFlowTheme.of(context).headlineLarge.override(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Focus • Confidence • Control',
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                          color: Colors.white70,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// FoCoCo Animated Gradient Background
class FoCoCoAnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final GradientType gradientType;
  // Additional parameters for backward compatibility
  final double? opacity;

  const FoCoCoAnimatedGradientBackground({
    super.key,
    required this.child,
    this.gradientType = GradientType.primary,
    this.opacity,
  });

  @override
  State<FoCoCoAnimatedGradientBackground> createState() =>
      _FoCoCoAnimatedGradientBackgroundState();
}

class _FoCoCoAnimatedGradientBackgroundState
    extends State<FoCoCoAnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _gradientColors {
    switch (widget.gradientType) {
      case GradientType.primary:
        return [
          FlutterFlowTheme.of(context).primary,
          FlutterFlowTheme.of(context).secondary,
        ];
      case GradientType.secondary:
        return [
          FlutterFlowTheme.of(context).secondary,
          FlutterFlowTheme.of(context).tertiary,
        ];
      case GradientType.mental:
        return [
          const Color(0xFF6B73FF),
          const Color(0xFF9DCEFF),
        ];
      case GradientType.coaching:
        return [
          const Color(0xFF11998E),
          const Color(0xFF38EF7D),
        ];
      case GradientType.calm:
        return [
          const Color(0xFF667EEA),
          const Color(0xFF764BA2),
        ];
      default:
        return [
          FlutterFlowTheme.of(context).primary,
          FlutterFlowTheme.of(context).secondary,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradientColors,
              stops: [_animation.value, 1.0 - _animation.value],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// FoCoCo Card Component
class FoCoCoCard extends StatelessWidget {
  final Widget child;
  final FoCoCoCardStyle style;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const FoCoCoCard({
    super.key,
    required this.child,
    this.style = FoCoCoCardStyle.standard,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        elevation: _getElevation(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _getBorder(context),
              gradient: _getGradient(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (style) {
      case FoCoCoCardStyle.standard:
        return FlutterFlowTheme.of(context).secondaryBackground;
      case FoCoCoCardStyle.elevated:
        return FlutterFlowTheme.of(context).primaryBackground;
      case FoCoCoCardStyle.outlined:
        return Colors.transparent;
      case FoCoCoCardStyle.filled:
        return FlutterFlowTheme.of(context).primary.withOpacity(0.1);
      case FoCoCoCardStyle.premium:
        return const Color(0xFFF8F9FA);
      case FoCoCoCardStyle.wellness:
        return const Color(0xFFF0F8FF);
    }
  }

  double _getElevation() {
    switch (style) {
      case FoCoCoCardStyle.elevated:
        return 8;
      case FoCoCoCardStyle.premium:
        return 12;
      case FoCoCoCardStyle.outlined:
        return 0;
      default:
        return 4;
    }
  }

  Border? _getBorder(BuildContext context) {
    if (style == FoCoCoCardStyle.outlined) {
      return Border.all(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
        width: 1,
      );
    }
    return null;
  }

  Gradient? _getGradient(BuildContext context) {
    if (style == FoCoCoCardStyle.premium) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FlutterFlowTheme.of(context).primary.withOpacity(0.05),
          FlutterFlowTheme.of(context).secondary.withOpacity(0.05),
        ],
      );
    }
    return null;
  }
}

/// AI Insight Card Component
class AIInsightCard extends StatelessWidget {
  final String title;
  final String content;
  final String? category;
  final VoidCallback? onTap;
  // Additional parameters for backward compatibility
  final String? insight;
  final String? sentiment;
  final List<String>? recommendations;
  final DateTime? timestamp;
  final String? aiModel;
  final VoidCallback? onFeedback;
  final VoidCallback? onExpand;

  const AIInsightCard({
    super.key,
    required this.title,
    required this.content,
    this.category,
    this.onTap,
    this.insight,
    this.sentiment,
    this.recommendations,
    this.timestamp,
    this.aiModel,
    this.onFeedback,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return FoCoCoCard(
      style: FoCoCoCardStyle.premium,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: FlutterFlowTheme.of(context).primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
              if (category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category!,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: FlutterFlowTheme.of(context).primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Performance Metric Card Component
class PerformanceMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final IconData icon;
  final Color? color;
  // Additional parameters for backward compatibility
  final String? unit;
  final double? percentage;
  final double? trendValue;
  final Color? primaryColor;

  const PerformanceMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    required this.icon,
    this.color,
    this.unit,
    this.percentage,
    this.trendValue,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? FlutterFlowTheme.of(context).primary;
    
    return FoCoCoCard(
      style: FoCoCoCardStyle.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: cardColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTrendColor(trend!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend!,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: _getTrendColor(trend!),
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              color: cardColor,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              color: FlutterFlowTheme.of(context).secondaryText,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(String trend) {
    if (trend.startsWith('+')) {
      return const Color(0xFF10B981); // Green for positive
    } else if (trend.startsWith('-')) {
      return const Color(0xFFEF4444); // Red for negative
    }
    return const Color(0xFF6B7280); // Gray for neutral
  }
}

/// Achievement Badge Component
class AchievementBadge extends StatelessWidget {
  final String title;
  final AchievementTier tier;
  final IconData icon;
  final bool isUnlocked;
  // Additional parameters for backward compatibility
  final String? description;
  final bool? isEarned;
  final DateTime? earnedDate;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.tier,
    required this.icon,
    this.isUnlocked = true,
    this.description,
    this.isEarned,
    this.earnedDate,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getTierColor();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? badgeColor.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? badgeColor : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isUnlocked ? badgeColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: FlutterFlowTheme.of(context).bodySmall.override(
              color: isUnlocked ? badgeColor : Colors.grey,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTierColor() {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }
}

/// Wellness Score Card Component
class WellnessScoreCard extends StatelessWidget {
  final int score;
  final String title;
  final String? subtitle;
  // Additional parameters for backward compatibility
  final int? maxScore;
  final DateTime? date;
  final Map<String, double>? subScores;

  const WellnessScoreCard({
    super.key,
    required this.score,
    required this.title,
    this.subtitle,
    this.maxScore,
    this.date,
    this.subScores,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score);
    
    return FoCoCoCard(
      style: FoCoCoCardStyle.wellness,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  scoreColor.withOpacity(0.2),
                  scoreColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                score.toString(),
                style: FlutterFlowTheme.of(context).headlineLarge.override(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: FlutterFlowTheme.of(context).secondaryText,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }
}

/// Subscription Tier Card Component
class SubscriptionTierCard extends StatelessWidget {
  final String tierName;
  final String price;
  final List<String> features;
  final bool isCurrentTier;
  final VoidCallback? onTap;
  // Additional parameters for backward compatibility
  final String? title;
  final String? period;
  final bool? isRecommended;
  final VoidCallback? onSelect;

  const SubscriptionTierCard({
    super.key,
    required this.tierName,
    required this.price,
    required this.features,
    this.isCurrentTier = false,
    this.onTap,
    this.title,
    this.period,
    this.isRecommended,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return FoCoCoCard(
      style: isCurrentTier ? FoCoCoCardStyle.premium : FoCoCoCardStyle.standard,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tierName,
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              if (isCurrentTier)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Current',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              color: FlutterFlowTheme.of(context).primary,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ============================================================================
// ENHANCED ANIMATED BOTTOM NAVIGATION BAR
// ============================================================================

/// Enhanced Glass Animated Bottom Navigation Bar for FoCoCo
/// Modern glassmorphism design with 3D effects and smooth animations
class FoCoCoAnimatedBottomNavBar extends StatefulWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool showLabels;
  final double height;
  final EdgeInsets margin;

  const FoCoCoAnimatedBottomNavBar({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = true,
    this.height = 85.0,
    this.margin = const EdgeInsets.only(left: 16, right: 16, bottom: 20),
  }) : super(key: key);

  @override
  State<FoCoCoAnimatedBottomNavBar> createState() => _FoCoCoAnimatedBottomNavBarState();
}

class _FoCoCoAnimatedBottomNavBarState extends State<FoCoCoAnimatedBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;
  
  // Navigation items configuration
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home,
      label: 'Home',
      route: 'dashboard',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.golfBallTee,
      activeIcon: FontAwesomeIcons.golfBallTee,
      label: 'Rounds',
      route: 'golf_rounds',
    ),
    NavigationItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Train',
      route: 'coaching_modules',
    ),
    NavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up,
      label: 'Progress',
      route: 'progress',
    ),
    NavigationItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights,
      label: 'Insights',
      route: 'ai_insights',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: 'profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Set initial index based on current route
    _currentIndex = _getIndexFromRoute(widget.currentRoute);
    
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void didUpdateWidget(FoCoCoAnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      final newIndex = _getIndexFromRoute(widget.currentRoute);
      if (newIndex != _currentIndex) {
        _animateToIndex(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  int _getIndexFromRoute(String route) {
    final index = _navItems.indexWhere((item) => item.route == route);
    return index >= 0 ? index : 0;
  }

  void _animateToIndex(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      
      _scaleController.reset();
      _scaleController.forward();
      
      // Haptic feedback for better UX
      HapticFeedback.lightImpact();
    }
  }

  void _onItemTapped(int index) {
    final item = _navItems[index];
    
    if (index != _currentIndex) {
      _animateToIndex(index);
      
      // Navigate to the new route
      if (widget.onTap != null) {
        widget.onTap!(item.route);
      } else {
        context.goNamed(item.route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Container(
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryBackground,
                  theme.secondaryBackground,
                ],
                stops: const [0.0, 1.0],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: theme.alternate.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.primaryBackground.withValues(alpha: 0.9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_navItems.length, (index) {
                      return _buildNavItem(
                        context,
                        theme,
                        _navItems[index],
                        index,
                        index == _currentIndex,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    FlutterFlowTheme theme,
    NavigationItem item,
    int index,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: isActive ? 70 : 50,
            height: isActive ? 70 : 50,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primary,
                        theme.secondary,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Transform.scale(
              scale: isActive ? _scaleAnimation.value : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      key: ValueKey('${item.route}_${isActive}'),
                      color: isActive ? Colors.white : theme.secondaryText,
                      size: isActive ? 26 : 22,
                    ),
                  ),
                  if (widget.showLabels) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: theme.labelSmall.override(
                        fontFamily: 'Inter',
                        color: isActive ? Colors.white : theme.secondaryText,
                        fontSize: isActive ? 10 : 9,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        height: 1.0,
                      ),
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced Bottom Navigation Bar with Indicator Animation
class FoCoCoIndicatorBottomNavBar extends StatefulWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool showLabels;
  final double height;
  final EdgeInsets margin;

  const FoCoCoIndicatorBottomNavBar({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = false,
    this.height = 75.0,
    this.margin = const EdgeInsets.only(left: 20, right: 20, bottom: 25),
  }) : super(key: key);

  @override
  State<FoCoCoIndicatorBottomNavBar> createState() => _FoCoCoIndicatorBottomNavBarState();
}

class _FoCoCoIndicatorBottomNavBarState extends State<FoCoCoIndicatorBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  
  int _currentIndex = 0;
  double _indicatorPosition = 0.0;
  
  // Navigation items configuration
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: 'dashboard',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.golfBallTee,
      activeIcon: FontAwesomeIcons.golfBallTee,
      label: 'Rounds',
      route: 'golf_rounds',
    ),
    NavigationItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      label: 'Train',
      route: 'coaching_modules',
    ),
    NavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      label: 'Progress',
      route: 'progress',
    ),
    NavigationItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Insights',
      route: 'ai_insights',
    ),
    NavigationItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: 'profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Set initial index based on current route
    _currentIndex = _getIndexFromRoute(widget.currentRoute);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition();
      _indicatorController.forward();
    });
  }

  @override
  void didUpdateWidget(FoCoCoIndicatorBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      final newIndex = _getIndexFromRoute(widget.currentRoute);
      if (newIndex != _currentIndex) {
        _animateToIndex(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  int _getIndexFromRoute(String route) {
    final index = _navItems.indexWhere((item) => item.route == route);
    return index >= 0 ? index : 0;
  }

  void _updateIndicatorPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final navBarWidth = screenWidth - (widget.margin.left + widget.margin.right);
    final itemWidth = navBarWidth / _navItems.length;
    
    setState(() {
      _indicatorPosition = (_currentIndex * itemWidth) + (itemWidth / 2) - 20;
    });
  }

  void _animateToIndex(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      
      _updateIndicatorPosition();
      _indicatorController.reset();
      _indicatorController.forward();
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _onItemTapped(int index) {
    final item = _navItems[index];
    
    if (index != _currentIndex) {
      _animateToIndex(index);
      
      // Navigate to the new route
      if (widget.onTap != null) {
        widget.onTap!(item.route);
      } else {
        context.goNamed(item.route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: theme.alternate.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Animated indicator
          AnimatedBuilder(
            animation: _indicatorAnimation,
            builder: (context, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                left: _indicatorPosition,
                top: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(
                context,
                theme,
                _navItems[index],
                index,
                index == _currentIndex,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    FlutterFlowTheme theme,
    NavigationItem item,
    int index,
    bool isActive,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8), // Space for indicator
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey('${item.route}_${isActive}'),
                    color: isActive ? theme.primary : theme.secondaryText,
                    size: isActive ? 26 : 22,
                  ),
                ),
              ),
              
              if (widget.showLabels) ...[
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.labelSmall.override(
                    fontFamily: 'Inter',
                    color: isActive ? theme.primary : theme.secondaryText,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    height: 1.0,
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}