import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/ai_integration/index.dart';
import '/backend/schema/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> with TickerProviderStateMixin {
  late DashboardModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
    
    // Initialize animations
    _animationController = AnimationController(
      duration: FlutterFlowTheme.animationNormal,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.dispose();
    super.dispose();
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Enhanced App Bar
                _buildEnhancedAppBar(theme),
                
                // Main Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mental Performance Index (Oura Ring-inspired)
                        _buildMentalPerformanceIndex(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Today's Highlights
                        _buildTodaysHighlights(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Performance Metrics Grid (Strava-inspired)
                        _buildPerformanceMetrics(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Recent Activity & Insights
                        _buildRecentActivity(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Achievement Showcase (Duolingo-inspired)
                        _buildAchievementShowcase(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Quick Actions
                        _buildQuickActions(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingXXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildEnhancedBottomNav(theme),
      ),
    );
  }

  /// Enhanced App Bar with gradient and user info
  Widget _buildEnhancedAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: theme.golfGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(FlutterFlowTheme.borderRadiusXXL),
              bottomRight: Radius.circular(FlutterFlowTheme.borderRadiusXXL),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: currentUserPhoto.isNotEmpty
                              ? Image.network(
                                  currentUserPhoto,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                      
                      const SizedBox(width: FlutterFlowTheme.spacingM),
                      
                      // Welcome Message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_getTimeOfDayGreeting()}',
                              style: theme.bodyMedium.override(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: FlutterFlowTheme.spacingXS),
                            Text(
                              currentUserDisplayName.isNotEmpty 
                                  ? currentUserDisplayName 
                                  : 'Golfer',
                              style: theme.headlineMedium.override(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Notification Bell
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            // TODO: Navigate to notifications
                          },
                          icon: Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mental Performance Index - Oura Ring inspired
  Widget _buildMentalPerformanceIndex(FlutterFlowTheme theme) {
    return WellnessScoreCard(
      score: 78.0, // TODO: Get from actual data
      date: dateTimeFormat('MMM d, yyyy', DateTime.now()),
      subScores: {
        'focus': 82.0,
        'calm': 75.0,
        'energy': 77.0,
      },
      onTap: () => context.goNamed('ai_insights'),
    );
  }

  /// Today's Highlights with streak and goals
  Widget _buildTodaysHighlights(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Highlights',
          style: theme.headlineSmall.override(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Active Streak
        StreakIndicator(
          currentStreak: 7, // TODO: Get from actual data
          maxStreak: 15,
          streakType: 'Practice Sessions',
          isActive: true,
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Daily Goals Progress
        FoCoCoCard(
          style: FoCoCoCardStyle.standard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Goals',
                    style: theme.titleMedium.override(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '2 of 3 complete',
                    style: theme.bodySmall.override(
                      color: theme.success,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: FlutterFlowTheme.spacingM),
              
              _buildGoalItem(
                theme,
                'Complete mental training session',
                true,
                Icons.psychology_rounded,
              ),
              _buildGoalItem(
                theme,
                'Log golf round with mindset notes',
                true,
                FontAwesomeIcons.golfBall,
              ),
              _buildGoalItem(
                theme,
                'Practice breathing exercise',
                false,
                Icons.air_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(FlutterFlowTheme theme, String title, bool isComplete, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlutterFlowTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isComplete 
                  ? theme.success 
                  : theme.alternate,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.check_rounded : icon,
              color: isComplete ? Colors.white : theme.secondaryText,
              size: 18,
            ),
          ),
          
          const SizedBox(width: FlutterFlowTheme.spacingM),
          
          Expanded(
            child: Text(
              title,
              style: theme.bodyMedium.override(
                color: isComplete 
                    ? theme.secondaryText 
                    : theme.primaryText,
                decoration: isComplete 
                    ? TextDecoration.lineThrough 
                    : null,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Performance Metrics Grid - Strava inspired
  Widget _buildPerformanceMetrics(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: theme.headlineSmall.override(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          mainAxisSpacing: FlutterFlowTheme.spacingM,
          crossAxisSpacing: FlutterFlowTheme.spacingM,
          children: [
            PerformanceMetricCard(
              title: 'Avg Score',
              value: '84',
              unit: 'strokes',
              percentage: 73.0,
              icon: FontAwesomeIcons.golfBall,
              trend: '-2.3',
              onTap: () => context.goNamed('golf_rounds'),
            ),
            PerformanceMetricCard(
              title: 'Mental Focus',
              value: '8.2',
              unit: '/10',
              percentage: 82.0,
              primaryColor: theme.mentalFocus,
              icon: Icons.psychology_rounded,
              trend: '+0.5',
              onTap: () => context.goNamed('progress'),
            ),
            PerformanceMetricCard(
              title: 'Sessions',
              value: '12',
              unit: 'this week',
              percentage: 85.0,
              primaryColor: theme.coachingPrimary,
              icon: Icons.self_improvement_rounded,
              trend: '+3',
              onTap: () => context.goNamed('coaching_modules'),
            ),
            PerformanceMetricCard(
              title: 'Consistency',
              value: '76',
              unit: '%',
              percentage: 76.0,
              primaryColor: theme.streakActive,
              icon: Icons.trending_up_rounded,
              trend: '+5.2',
              onTap: () => context.goNamed('progress'),
            ),
          ],
        ),
      ],
    );
  }

  /// Recent Activity with AI insights
  Widget _buildRecentActivity(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.headlineSmall.override(
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                height: 1.2,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('ai_insights'),
              child: Text(
                'View All',
                style: theme.titleSmall.override(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Recent Golf Round
        FoCoCoCard(
          onTap: () => context.goNamed('golf_rounds'),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.golfPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.golfBall,
                  color: theme.golfPrimary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: FlutterFlowTheme.spacingM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pebble Beach Golf Links',
                      style: theme.titleMedium.override(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: FlutterFlowTheme.spacingXS),
                    Text(
                      'Shot 82 • Great mental focus on back 9',
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlutterFlowTheme.spacingS,
                  vertical: FlutterFlowTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusS),
                ),
                child: Text(
                  '82',
                  style: theme.titleSmall.override(
                    color: theme.success,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Recent AI Insight
        AIInsightCard(
          title: 'Mental Performance Analysis',
          insight: 'Your focus improved significantly during pressure situations. The breathing technique you practiced is showing great results on approach shots.',
          sentiment: 'positive',
          recommendations: [
            'Continue practicing pre-shot routine',
            'Focus on visualization before long putts',
          ],
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          aiModel: 'Gemini 2.5 Flash',
          onFeedback: () {
            // TODO: Handle feedback
          },
        ),
      ],
    );
  }

  /// Achievement Showcase - Duolingo inspired
  Widget _buildAchievementShowcase(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Achievements',
              style: theme.headlineSmall.override(
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                height: 1.2,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('achievements'),
              child: Text(
                'View All',
                style: theme.titleSmall.override(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(
                width: 160,
                child: AchievementBadge(
                  title: 'Focus Master',
                  description: 'Completed 10 mindfulness sessions',
                  icon: Icons.psychology_rounded,
                  tier: AchievementTier.gold,
                  isEarned: true,
                  earnedDate: DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
              const SizedBox(width: FlutterFlowTheme.spacingM),
              SizedBox(
                width: 160,
                child: AchievementBadge(
                  title: 'Consistent Player',
                  description: 'Logged rounds for 7 days straight',
                  icon: FontAwesomeIcons.fire,
                  tier: AchievementTier.silver,
                  isEarned: true,
                  earnedDate: DateTime.now().subtract(const Duration(days: 3)),
                ),
              ),
              const SizedBox(width: FlutterFlowTheme.spacingM),
              SizedBox(
                width: 160,
                child: AchievementBadge(
                  title: 'Score Improver',
                  description: 'Beat personal best by 5 strokes',
                  icon: Icons.trending_up_rounded,
                  tier: AchievementTier.bronze,
                  isEarned: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Enhanced Quick Actions
  Widget _buildQuickActions(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.headlineSmall.override(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: FlutterFlowTheme.spacingM,
          crossAxisSpacing: FlutterFlowTheme.spacingM,
          children: [
            _buildQuickActionCard(
              theme,
              icon: FontAwesomeIcons.golfBall,
              title: 'Log Round',
              subtitle: 'Track your game',
              color: theme.golfPrimary,
              onTap: () => context.goNamed('golf_rounds'),
            ),
            _buildQuickActionCard(
              theme,
              icon: Icons.psychology_rounded,
              title: 'Mental Training',
              subtitle: 'Practice focus',
              color: theme.coachingPrimary,
              onTap: () => context.goNamed('coaching_modules'),
            ),
            _buildQuickActionCard(
              theme,
              icon: Icons.insights_rounded,
              title: 'AI Insights',
              subtitle: 'Get analysis',
              color: theme.aiPrimary,
              onTap: () => context.goNamed('ai_insights'),
            ),
            _buildQuickActionCard(
              theme,
              icon: Icons.trending_up_rounded,
              title: 'Progress',
              subtitle: 'View stats',
              color: theme.streakActive,
              onTap: () => context.goNamed('progress'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FoCoCoCard(
      onTap: onTap,
      style: FoCoCoCardStyle.standard,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: FlutterFlowTheme.spacingM),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.titleSmall.override(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced Bottom Navigation
  Widget _buildEnhancedBottomNav(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusXL),
        boxShadow: theme.shadowL,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlutterFlowTheme.spacingM,
            vertical: FlutterFlowTheme.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(theme, Icons.home_rounded, 'Home', 'dashboard', true),
              _buildNavItem(theme, FontAwesomeIcons.golfBall, 'Rounds', 'golf_rounds', false),
              _buildNavItem(theme, Icons.psychology_rounded, 'Train', 'coaching_modules', false),
              _buildNavItem(theme, Icons.trending_up_rounded, 'Progress', 'progress', false),
              _buildNavItem(theme, Icons.insights_rounded, 'Insights', 'ai_insights', false),
              _buildNavItem(theme, Icons.person_rounded, 'Profile', 'profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(FlutterFlowTheme theme, IconData icon, String label, String page, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          context.goNamed(page);
        }
      },
      child: AnimatedContainer(
        duration: FlutterFlowTheme.animationFast,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? FlutterFlowTheme.spacingM : FlutterFlowTheme.spacingS,
          vertical: FlutterFlowTheme.spacingS,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? theme.golfGradient : null,
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : theme.secondaryText,
              size: 20,
            ),
            if (isActive) ...[
              const SizedBox(width: FlutterFlowTheme.spacingS),
              Text(
                label,
                style: theme.bodySmall.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
} 