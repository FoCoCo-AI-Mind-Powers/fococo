import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/ai_integration/widgets/enhanced_navigation_with_voice.dart';
import 'package:flutter/material.dart';

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
        backgroundColor: theme.activityBackground,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Enhanced App Bar with Strava-inspired design
                _buildStravaInspiredAppBar(theme),
                
                // Main Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Streak Widget (Strava-inspired)
                        _buildStravaInspiredStreak(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Performance Metrics (Strava-inspired)
                        _buildStravaInspiredPerformanceMetrics(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Recent Activity Feed (Strava-inspired)
                        _buildStravaInspiredActivityFeed(theme),
                        
                        const SizedBox(height: FlutterFlowTheme.spacingL),
                        
                        // Mindfulness Section (Calm-inspired)
                        _buildCalmInspiredMindfulness(theme),
                        
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
        bottomNavigationBar: FoCoCoNavBar(
          currentRoute: 'dashboard',
          enableVoiceButton: true,
          onTap: (route) => context.goNamed(route),
        ),
      ),
    );
  }

  /// Enhanced App Bar with Strava-inspired gradient and user info
  Widget _buildStravaInspiredAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: theme.activityGradient,
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
                      // User Avatar with Strava-inspired border
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                      
                      // Welcome Message with Strava-inspired styling
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_getTimeOfDayGreeting()}',
                              style: theme.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: FlutterFlowTheme.spacingXS),
                            Text(
                              currentUserDisplayName.isNotEmpty 
                                  ? currentUserDisplayName 
                                  : 'Golfer',
                              style: theme.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: FlutterFlowTheme.spacingXS),
                            Text(
                              'Ready for today\'s training?',
                              style: theme.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Notification Bell with Strava-inspired design
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
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

  /// Strava-inspired Streak Widget
  Widget _buildStravaInspiredStreak(FlutterFlowTheme theme) {
    return FoCoCoStreakWidget(
      currentStreak: 7, // TODO: Get from user data
      longestStreak: 15, // TODO: Get from user data
      streakType: 'Training',
      isActive: true,
    );
  }

  /// Strava-inspired Performance Metrics
  Widget _buildStravaInspiredPerformanceMetrics(FlutterFlowTheme theme) {
    final metrics = [
      PerformanceMetric(
        label: 'Mental Focus',
        value: '85%',
        score: 85,
        trend: 5.2,
      ),
      PerformanceMetric(
        label: 'Confidence',
        value: '78%',
        score: 78,
        trend: -2.1,
      ),
      PerformanceMetric(
        label: 'Control',
        value: '92%',
        score: 92,
        trend: 8.5,
      ),
    ];

    return FoCoCoPerformanceMetrics(
      metrics: metrics,
      showTrend: true,
      compactView: true,
    );
  }

  /// Strava-inspired Activity Feed
  Widget _buildStravaInspiredActivityFeed(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline,
              size: FlutterFlowTheme.iconSizeM,
              color: theme.activityPrimary,
            ),
            const SizedBox(width: FlutterFlowTheme.spacingS),
            Text(
              'Recent Activity',
              style: theme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all activities
              },
              child: Text(
                'View All',
                style: theme.bodyMedium.copyWith(
                  color: theme.activityPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Activity Cards
        FoCoCoActivityCard(
          title: 'Morning Practice Round',
          subtitle: 'Pebble Beach Golf Links',
          score: '78',
          date: '2 hours ago',
          stats: [
            ActivityStat(label: 'Fairways', value: '12/14'),
            ActivityStat(label: 'Greens', value: '15/18'),
            ActivityStat(label: 'Putts', value: '32'),
          ],
          achievements: [
            Achievement(tier: 'gold', icon: Icons.emoji_events, name: 'Best Round'),
          ],
          isPersonalRecord: true,
          onTap: () {
            // TODO: Navigate to round details
          },
        ),
        
        FoCoCoActivityCard(
          title: 'Mental Training Session',
          subtitle: 'Focus & Concentration',
          score: '45 min',
          date: 'Yesterday',
          stats: [
            ActivityStat(label: 'Focus', value: '87%'),
            ActivityStat(label: 'Completed', value: '100%'),
          ],
          achievements: [
            Achievement(tier: 'silver', icon: Icons.psychology, name: 'Mindful'),
          ],
          onTap: () {
            // TODO: Navigate to session details
          },
        ),
      ],
    );
  }

  /// Calm-inspired Mindfulness Section
  Widget _buildCalmInspiredMindfulness(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.spa,
              size: FlutterFlowTheme.iconSizeM,
              color: theme.mindfulnessPrimary,
            ),
            const SizedBox(width: FlutterFlowTheme.spacingS),
            Text(
              'Mindfulness',
              style: theme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to mindfulness section
              },
              child: Text(
                'Explore',
                style: theme.bodyMedium.copyWith(
                  color: theme.mindfulnessPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Breathing Exercise Card
        FoCoCoBreathingWidget(
          duration: 300,
          inhaleTime: 4,
          holdTime: 4,
          exhaleTime: 4,
          onStart: () {
            // TODO: Track breathing session start
          },
          onStop: () {
            // TODO: Track breathing session stop
          },
          onComplete: () {
            // TODO: Track breathing session completion
          },
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        // Mindfulness Session Card
        FoCoCoMindfulnessCard(
          title: 'Pre-Round Calm',
          description: 'A 10-minute meditation to prepare your mind for golf',
          duration: '10 min',
          sessionType: 'meditation',
          progress: 0.0,
          onTap: () {
            // TODO: Navigate to meditation session
          },
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
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                theme,
                'Log Round',
                Icons.golf_course,
                theme.golfPrimary,
                () {
                  // TODO: Navigate to log round
                },
              ),
            ),
            const SizedBox(width: FlutterFlowTheme.spacingM),
            Expanded(
              child: _buildQuickActionCard(
                theme,
                'Training',
                Icons.fitness_center,
                theme.coachingPrimary,
                () {
                  // TODO: Navigate to training
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                theme,
                'AI Insights',
                Icons.psychology,
                theme.aiPrimary,
                () {
                  // TODO: Navigate to AI insights
                },
              ),
            ),
            const SizedBox(width: FlutterFlowTheme.spacingM),
            Expanded(
              child: _buildQuickActionCard(
                theme,
                'Progress',
                Icons.trending_up,
                theme.performanceGood,
                () {
                  // TODO: Navigate to progress
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        boxShadow: [theme.activityCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
          child: Padding(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: FlutterFlowTheme.iconSizeM,
                    color: color,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingS),
                Text(
                  title,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Enhanced Bottom Navigation
  Widget _buildEnhancedBottomNav(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlutterFlowTheme.spacingM,
            vertical: FlutterFlowTheme.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(theme, 'Home', Icons.home, true, () {}),
              _buildNavItem(theme, 'Training', Icons.fitness_center, false, () {}),
              _buildNavItem(theme, 'Progress', Icons.trending_up, false, () {}),
              _buildNavItem(theme, 'Profile', Icons.person, false, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    FlutterFlowTheme theme,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlutterFlowTheme.spacingM,
          vertical: FlutterFlowTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isActive ? theme.activityPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: FlutterFlowTheme.iconSizeM,
              color: isActive ? theme.activityPrimary : theme.secondaryText,
            ),
            const SizedBox(height: FlutterFlowTheme.spacingXS),
            Text(
              label,
              style: theme.bodySmall.copyWith(
                color: isActive ? theme.activityPrimary : theme.secondaryText,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
} 