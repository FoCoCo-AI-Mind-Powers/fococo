import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    // Pulse animation for circular indicators
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
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
        body: StreamBuilder<List<DashboardDataRecord>>(
          stream: queryDashboardDataRecord(
            queryBuilder: (dashboardDataRecord) => dashboardDataRecord
                .where('userId', isEqualTo: currentUserUid)
                .limit(1),
          ),
          builder: (context, snapshot) {
            // Get dashboard data
            DashboardDataRecord? dashboardData = snapshot.data?.firstOrNull;
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    // Enhanced Glassmorphic App Bar
                    _buildGlassmorphicAppBar(theme, dashboardData),
                    
                    // Main Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Circular Progress Indicators Row
                            _buildCircularProgressRow(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // Glassmorphic Streak Card
                            _buildGlassmorphicStreakCard(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // Weekly Progress Chart
                            _buildWeeklyProgressChart(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // Performance Metrics Grid
                            _buildPerformanceMetricsGrid(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // Recent Activities with Glassmorphism
                            _buildRecentActivities(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // Mindfulness Section
                            _buildEnhancedMindfulness(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // AI Insights Card
                            _buildAIInsightsCard(theme, dashboardData),
                            
                            const SizedBox(height: 24),
                            
                            // Quick Actions Grid
                            _buildEnhancedQuickActions(theme),
                            
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: FoCoCoNavBar(
          currentRoute: 'dashboard',
          enableVoiceButton: true,
          onTap: (route) => context.goNamed(route),
        ),
      ),
    );
  }

  /// Glassmorphic App Bar
  Widget _buildGlassmorphicAppBar(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.activityPrimary.withValues(alpha: 0.8),
                theme.activitySecondary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // Glassmorphic Avatar
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
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
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Welcome Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_getTimeOfDayGreeting()}',
                                  style: theme.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUserDisplayName.isNotEmpty 
                                      ? currentUserDisplayName 
                                      : 'Golfer',
                                  style: theme.headlineMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data?.dailyInsight ?? 'Ready for today\'s training?',
                                  style: theme.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Glassmorphic Notification Bell
                          _buildGlassmorphicButton(
                            icon: Icons.notifications_outlined,
                            onTap: () {
                              // Navigate to notifications
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Progress Indicators Row
  Widget _buildCircularProgressRow(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: _buildCircularProgressCard(
              theme: theme,
              title: 'Mental Focus',
              value: data?.mentalFocusScore ?? 85,
              trend: data?.mentalFocusTrend ?? 5.2,
              color: theme.aiPrimary,
              icon: FontAwesomeIcons.brain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCircularProgressCard(
              theme: theme,
              title: 'Confidence',
              value: data?.confidenceScore ?? 78,
              trend: data?.confidenceTrend ?? -2.1,
              color: theme.coachingPrimary,
              icon: Icons.psychology,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCircularProgressCard(
              theme: theme,
              title: 'Control',
              value: data?.controlScore ?? 92,
              trend: data?.controlTrend ?? 8.5,
              color: theme.performanceExcellent,
              icon: Icons.speed,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Circular Progress Card
  Widget _buildCircularProgressCard({
    required FlutterFlowTheme theme,
    required String title,
    required double value,
    required double trend,
    required Color color,
    required IconData icon,
  }) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 40,
                    lineWidth: 8,
                    animation: true,
                    percent: value / 100,
                    backgroundColor: color.withValues(alpha: 0.1),
                    progressColor: color,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${value.toInt()}%',
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  trend > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trend > 0 ? theme.performanceExcellent : theme.performancePoor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Glassmorphic Streak Card
  Widget _buildGlassmorphicStreakCard(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
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
          child: Row(
            children: [
              // Streak Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.warning.withValues(alpha: 0.8),
                      theme.warning.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.fire,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Streak Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data?.currentStreak ?? 7} Day ${data?.streakType ?? 'Training'} Streak!',
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Longest: ${data?.longestStreak ?? 15} days',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Streak Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (data?.isStreakActive ?? true) 
                      ? theme.performanceExcellent.withValues(alpha: 0.2)
                      : theme.performancePoor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (data?.isStreakActive ?? true) ? 'Active' : 'Inactive',
                  style: theme.bodySmall.copyWith(
                    color: (data?.isStreakActive ?? true) 
                        ? theme.performanceExcellent
                        : theme.performancePoor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Weekly Progress Chart
  Widget _buildWeeklyProgressChart(FlutterFlowTheme theme, DashboardDataRecord? data) {
    final weeklyData = data?.weeklyProgress ?? [65, 70, 68, 75, 72, 78, 82];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryBackground,
            theme.secondaryBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.activityPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${((weeklyData.last - weeklyData.first) / weeklyData.first * 100).toStringAsFixed(1)}%',
                  style: theme.bodySmall.copyWith(
                    color: theme.activityPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          days[value.toInt()],
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        gradient: LinearGradient(
                          colors: [
                            theme.activityPrimary,
                            theme.activitySecondary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.grayIcon.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Performance Metrics Grid
  Widget _buildPerformanceMetricsGrid(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          theme: theme,
          title: 'Avg Score',
          value: data?.averageScore.toStringAsFixed(1) ?? '78.5',
          icon: FontAwesomeIcons.golfBallTee,
          color: theme.golfPrimary,
          subtitle: 'Last 10 rounds',
        ),
        _buildMetricCard(
          theme: theme,
          title: 'Handicap',
          value: data?.handicap.toStringAsFixed(1) ?? '12.3',
          icon: Icons.trending_down,
          color: theme.performanceGood,
          subtitle: 'Improving',
        ),
        _buildMetricCard(
          theme: theme,
          title: 'Mindful Minutes',
          value: '${data?.totalMindfulMinutes ?? 245}',
          icon: Icons.spa,
          color: theme.mindfulnessPrimary,
          subtitle: 'This month',
        ),
        _buildMetricCard(
          theme: theme,
          title: 'Rounds',
          value: '${data?.roundsThisMonth ?? 12}',
          icon: Icons.golf_course,
          color: theme.secondary,
          subtitle: 'This month',
        ),
      ],
    );
  }

  /// Individual Metric Card
  Widget _buildMetricCard({
    required FlutterFlowTheme theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                title,
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                ),
              ),
              Text(
                subtitle,
                style: theme.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Recent Activities Section
  Widget _buildRecentActivities(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('golf_rounds'),
              child: Text(
                'View All',
                style: theme.bodyMedium.copyWith(
                  color: theme.activityPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Stream of recent activities
        StreamBuilder<List<ActivityRecord>>(
          stream: queryActivityRecord(
            queryBuilder: (activityRecord) => activityRecord
                .where('userId', isEqualTo: currentUserUid)
                .orderBy('activityDate', descending: true)
                .limit(3),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyActivities(theme);
            }
            
            final activities = snapshot.data!;
            return Column(
              children: activities.map((activity) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildActivityCard(theme, activity),
                ),
              ).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Activity Card with Glassmorphism
  Widget _buildActivityCard(FlutterFlowTheme theme, ActivityRecord activity) {
    return InkWell(
      onTap: () {
        // Navigate to activity details
      },
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Activity Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activity.activityType == 'round' 
                        ? theme.golfPrimary.withValues(alpha: 0.2)
                        : theme.coachingPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.activityType == 'round' 
                        ? FontAwesomeIcons.golfBallTee
                        : Icons.psychology,
                    color: activity.activityType == 'round' 
                        ? theme.golfPrimary
                        : theme.coachingPrimary,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Activity Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.subtitle,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                      if (activity.stats.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: activity.stats.entries.take(3).map((stat) => 
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat.value.toString(),
                                    style: theme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                  Text(
                                    stat.key,
                                    style: theme.labelSmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Score/Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activity.score,
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatActivityDate(activity.activityDate),
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                    if (activity.isPersonalRecord) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PR',
                          style: theme.labelSmall.copyWith(
                            color: theme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty Activities State
  Widget _buildEmptyActivities(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.grayIcon.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.golf_course_outlined,
            size: 48,
            color: theme.grayIcon,
          ),
          const SizedBox(height: 16),
          Text(
            'No activities yet',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first round or training session',
            style: theme.bodySmall.copyWith(
              color: theme.grayIcon,
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced Mindfulness Section
  Widget _buildEnhancedMindfulness(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.mindfulnessPrimary.withValues(alpha: 0.1),
            theme.mindfulnessPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.mindfulnessPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mindfulness',
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.mindfulnessPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data?.weeklyMindfulSessions ?? 3}/7 sessions',
                  style: theme.bodySmall.copyWith(
                    color: theme.mindfulnessPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Breathing Exercise Button
          InkWell(
            onTap: () {
              // Start breathing exercise
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.mindfulnessPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.air,
                      color: theme.mindfulnessPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Breathing Exercise',
                          style: theme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        Text(
                          '5 minutes • Reduce stress',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_filled,
                    color: theme.mindfulnessPrimary,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data?.currentMindfulnessGoal ?? 'Daily meditation goal',
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: (data?.weeklyMindfulSessions ?? 3) / 7,
                backgroundColor: theme.mindfulnessPrimary.withValues(alpha: 0.1),
                progressColor: theme.mindfulnessPrimary,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// AI Insights Card
  Widget _buildAIInsightsCard(FlutterFlowTheme theme, DashboardDataRecord? data) {
    return InkWell(
      onTap: () => context.goNamed('ai_insights'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.aiPrimary,
              theme.aiSecondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.aiPrimary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.brain,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insights',
                    style: theme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data?.weeklyChallenge ?? 'Complete 5 mindfulness sessions this week',
                    style: theme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced Quick Actions
  Widget _buildEnhancedQuickActions(FlutterFlowTheme theme) {
    final actions = [
      QuickAction(
        title: 'Log Round',
        icon: FontAwesomeIcons.golfBallTee,
        color: theme.golfPrimary,
        route: 'golf_rounds',
      ),
      QuickAction(
        title: 'Training',
        icon: Icons.fitness_center,
        color: theme.coachingPrimary,
        route: 'coaching_modules',
      ),
      QuickAction(
        title: 'AI Coach',
        icon: Icons.psychology,
        color: theme.aiPrimary,
        route: 'ai_insights',
      ),
      QuickAction(
        title: 'Progress',
        icon: Icons.trending_up,
        color: theme.performanceGood,
        route: 'progress',
      ),
    ];
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: actions.map((action) => 
        _buildQuickActionCard(theme, action),
      ).toList(),
    );
  }

  Widget _buildQuickActionCard(FlutterFlowTheme theme, QuickAction action) {
    return InkWell(
      onTap: () => context.goNamed(action.route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              action.color.withValues(alpha: 0.1),
              action.color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: action.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                size: 20,
                color: action.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.title,
                style: theme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glassmorphic Button Helper
  Widget _buildGlassmorphicButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Format activity date
  String _formatActivityDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
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

// Quick Action Model
class QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}