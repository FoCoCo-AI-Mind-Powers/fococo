import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({Key? key}) : super(key: key);

  static const String routeName = 'dashboard';
  static const String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
    with TickerProviderStateMixin {
  late DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _chartController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());

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
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _chartController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _chartController.dispose();
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
        drawer: loggedIn
            ? StreamBuilder<UserRecord>(
                stream: UserRecord.getDocument(
                    FirebaseFirestore.instance.doc('user/${currentUserUid}')),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  return EnhancedFoCoCoDrawer(
                    currentUser: userData,
                    currentRoute: 'dashboard',
                    onNavigate: (route) => context.goNamed(route),
                  );
                },
              )
            : null,
        body: Stack(
          children: [
            // Main content
            Container(
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

                        // Main Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Mental Performance Overview
                                _buildMentalPerformanceSection(theme),

                                const SizedBox(height: 24),

                                // Golf Performance Metrics
                                _buildGolfPerformanceSection(theme),

                                const SizedBox(height: 24),

                                // Weekly Progress Chart
                                _buildWeeklyProgressSection(theme),

                                const SizedBox(height: 24),

                                // Recent Activities & Achievements
                                _buildActivitiesSection(theme),

                                const SizedBox(height: 24),

                                // AI Insights & Goals
                                _buildInsightsSection(theme),

                                const SizedBox(height: 100), // Space for navbar
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Voice Button
            const FloatingVoiceButton(),
          ],
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'dashboard',
          onTap: (route) {
            print('🔄 Dashboard page: Navigation requested to route: $route');
            context.goNamed(route);
          },
          currentUser: null, // Will be handled by the navbar internally
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: loggedIn
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/${currentUserUid}'))
          : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Menu button
              GestureDetector(
                onTap: () => scaffoldKey.currentState?.openDrawer(),
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
                    Icons.menu_rounded,
                    color: theme.primaryText,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Welcome text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName
                          : 'Golfer',
                      style: theme.headlineSmall.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification button
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
                  Icons.notifications_outlined,
                  color: theme.primaryText,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMentalPerformanceSection(FlutterFlowTheme theme) {
    return StreamBuilder<List<DashboardDataRecord>>(
      stream: FirebaseFirestore.instance
          .collection('dashboard_data')
          .where('userId', isEqualTo: currentUserUid)
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DashboardDataRecord.fromSnapshot(doc))
              .toList()),
      builder: (context, snapshot) {
        final dashboardData = snapshot.data?.firstOrNull;

        return GlassDashboardCard(
          title: 'Mental Performance Index',
          subtitle: 'Focus • Confidence • Control',
          children: [
            Column(
              children: [
                const SizedBox(height: 20),

                // Main MPI Circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final mpi = _calculateMPI(dashboardData);
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        child: CircularPercentIndicator(
                          radius: 90,
                          lineWidth: 12,
                          percent: mpi / 100,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${mpi.toInt()}',
                                style: theme.displaySmall.copyWith(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 48,
                                ),
                              ),
                              Text(
                                'MPI',
                                style: theme.labelMedium.copyWith(
                                  color: theme.secondaryText,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          progressColor: theme.primary,
                          backgroundColor:
                              theme.alternate.withValues(alpha: 0.3),
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animationDuration: 1500,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Individual metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricIndicator(
                      theme,
                      'Focus',
                      dashboardData?.mentalFocusScore ?? 75,
                      dashboardData?.mentalFocusTrend ?? 2.5,
                      theme.mentalFocus,
                    ),
                    _buildMetricIndicator(
                      theme,
                      'Confidence',
                      dashboardData?.confidenceScore ?? 82,
                      dashboardData?.confidenceTrend ?? -1.2,
                      theme.primary,
                    ),
                    _buildMetricIndicator(
                      theme,
                      'Control',
                      dashboardData?.controlScore ?? 88,
                      dashboardData?.controlTrend ?? 4.1,
                      theme.success,
                    ),
                  ],
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildGolfPerformanceSection(FlutterFlowTheme theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('golf_rounds')
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, roundsSnapshot) {
        final recentRounds = roundsSnapshot.data?.docs ?? [];

        return StreamBuilder<UserRecord>(
          stream: loggedIn
              ? UserRecord.getDocument(
                  FirebaseFirestore.instance.doc('user/${currentUserUid}'))
              : null,
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;

            return Column(
              children: [
                // Golf Stats Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Handicap',
                        user?.handicap != null
                            ? user!.handicap.toStringAsFixed(1)
                            : '--',
                        Icons.golf_course,
                        theme.golfPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Avg Score',
                        _calculateAverageScore(recentRounds).toStringAsFixed(1),
                        FontAwesomeIcons.golfBallTee,
                        theme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Rounds',
                        recentRounds.length.toString(),
                        Icons.calendar_month,
                        theme.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Best Round',
                        _getBestScore(recentRounds).toString(),
                        Icons.star,
                        theme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyProgressSection(FlutterFlowTheme theme) {
    return StreamBuilder<List<DashboardDataRecord>>(
      stream: FirebaseFirestore.instance
          .collection('dashboard_data')
          .where('userId', isEqualTo: currentUserUid)
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DashboardDataRecord.fromSnapshot(doc))
              .toList()),
      builder: (context, snapshot) {
        final dashboardData = snapshot.data?.firstOrNull;
        final weeklyProgress =
            dashboardData?.weeklyProgress ?? [65, 72, 68, 85, 78, 92, 88];

        return GlassDashboardCard(
          title: 'Weekly Progress',
          subtitle: 'Mental training consistency',
          children: [
            Column(
              children: [
                const SizedBox(height: 20),

                // Progress chart
                AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (context, child) {
                    return Container(
                      height: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyProgress.asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value;
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration:
                                    Duration(milliseconds: 500 + (index * 100)),
                                width: 24,
                                height:
                                    (value / 100) * 80 * _chartAnimation.value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      theme.primary.withValues(alpha: 0.8),
                                      theme.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                days[index],
                                style: theme.labelSmall.copyWith(
                                  color: theme.secondaryText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Streak info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStreakInfo(
                      theme,
                      'Current Streak',
                      '${dashboardData?.currentStreak ?? 7} days',
                      Icons.local_fire_department,
                      theme.warning,
                    ),
                    _buildStreakInfo(
                      theme,
                      'Best Streak',
                      '${dashboardData?.longestStreak ?? 15} days',
                      Icons.emoji_events,
                      theme.success,
                    ),
                  ],
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildActivitiesSection(FlutterFlowTheme theme) {
    return StreamBuilder<List<ActivityRecord>>(
      stream: FirebaseFirestore.instance
          .collection('activities')
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('activityDate', descending: true)
          .limit(3)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ActivityRecord.fromSnapshot(doc))
              .toList()),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];

        return GlassDashboardCard(
          title: 'Recent Activities',
          subtitle: 'Your latest sessions',
          children: [
            Column(
              children: activities.isEmpty
                  ? [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.psychology_outlined,
                        size: 48,
                        color: theme.secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activities yet',
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]
                  : activities
                      .map((activity) => _buildActivityItem(theme, activity))
                      .toList(),
            )
          ],
        );
      },
    );
  }

  Widget _buildInsightsSection(FlutterFlowTheme theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ai_insights')
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('generatedTime', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final insights = snapshot.data?.docs ?? [];
        final latestInsight = insights.isNotEmpty ? insights.first : null;

        return Column(
          children: [
            // AI Insight Card
            GlassDashboardCard(
              title: 'AI Insights',
              subtitle: 'Personalized recommendations',
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (latestInsight != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.aiPrimary.withValues(alpha: 0.1),
                              theme.aiSecondary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.aiPrimary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: theme.aiPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (latestInsight.data() as Map<String,
                                            dynamic>?)?['insightTitle'] ??
                                        'AI Insight',
                                    style: theme.titleSmall.copyWith(
                                      color: theme.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              () {
                                final content = (latestInsight.data() as Map<
                                        String, dynamic>?)?['insightContent'] ??
                                    'Your personalized AI insight will appear here.';
                                return content.length > 120
                                    ? '${content.substring(0, 120)}...'
                                    : content;
                              }(),
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 48,
                              color: theme.secondaryText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Complete a round to get AI insights',
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              ],
            ),

            const SizedBox(height: 16),

            // Goals Card
            StreamBuilder<List<DashboardDataRecord>>(
              stream: FirebaseFirestore.instance
                  .collection('dashboard_data')
                  .where('userId', isEqualTo: currentUserUid)
                  .limit(1)
                  .snapshots()
                  .map((snapshot) => snapshot.docs
                      .map((doc) => DashboardDataRecord.fromSnapshot(doc))
                      .toList()),
              builder: (context, snapshot) {
                final dashboardData = snapshot.data?.firstOrNull;
                final goals = dashboardData?.activeGoals ??
                    ['Improve putting', 'Mental focus training'];

                return GlassDashboardCard(
                  title: 'Active Goals',
                  subtitle: 'Your current objectives',
                  children: [
                    Column(
                      children: goals.isEmpty
                          ? [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.flag_outlined,
                                size: 48,
                                color:
                                    theme.secondaryText.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Set your first goal',
                                style: theme.bodyMedium.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ]
                          : goals
                              .map((goal) => _buildGoalItem(theme, goal))
                              .toList(),
                    )
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricIndicator(FlutterFlowTheme theme, String title,
      double value, double trend, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          child: CircularPercentIndicator(
            radius: 30,
            lineWidth: 6,
            percent: value / 100,
            center: Text(
              '${value.toInt()}',
              style: theme.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            progressColor: color,
            backgroundColor: theme.alternate.withValues(alpha: 0.3),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
            fontSize: 11,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              trend >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 12,
              color: trend >= 0 ? theme.success : theme.error,
            ),
            const SizedBox(width: 2),
            Text(
              '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}',
              style: theme.labelSmall.copyWith(
                color: trend >= 0 ? theme.success : theme.error,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(FlutterFlowTheme theme, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: theme.success,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.headlineSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: theme.labelMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakInfo(FlutterFlowTheme theme, String title, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          title,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(FlutterFlowTheme theme, ActivityRecord activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity.activityType == 'round'
                  ? FontAwesomeIcons.golfBallTee
                  : Icons.psychology,
              color: theme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity.subtitle,
                  style: theme.labelSmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (activity.isPersonalRecord)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildGoalItem(FlutterFlowTheme theme, String goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag,
            color: theme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              goal,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
              ),
            ),
          ),
          Container(
            width: 60,
            child: LinearPercentIndicator(
              lineHeight: 4,
              percent: math.Random().nextDouble() * 0.8 + 0.2,
              backgroundColor: theme.alternate.withValues(alpha: 0.3),
              progressColor: theme.primary,
              barRadius: const Radius.circular(2),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateMPI(DashboardDataRecord? data) {
    if (data == null) return 78.0;
    return (data.mentalFocusScore + data.confidenceScore + data.controlScore) /
        3;
  }

  double _calculateAverageScore(List<QueryDocumentSnapshot> rounds) {
    if (rounds.isEmpty) return 0.0;
    final total = rounds.fold<int>(0, (sum, round) {
      final data = round.data() as Map<String, dynamic>;
      return sum + (data['score'] as int? ?? 0);
    });
    return total / rounds.length;
  }

  int _getBestScore(List<QueryDocumentSnapshot> rounds) {
    if (rounds.isEmpty) return 0;
    return rounds.map((r) {
      final data = r.data() as Map<String, dynamic>;
      return data['score'] as int? ?? 0;
    }).reduce(math.min);
  }
}
