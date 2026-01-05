import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/mindcoach_sessions_record.dart';
import '/backend/schema/training_plans_record.dart';
import '/backend/schema/ai_insights_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/widgets/floating_voice_button.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'dart:math' show Random;

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

  // Tagline system
  String _currentTagline = '';

  // Tagline lists from PDF
  static const List<String> _focusTaglines = [
    'Lock in. One shot at a time.',
    'You don\'t need more time, just more attention.',
    'Everything else can wait. Right now matters most.',
    'Quiet the noise. Trust the target.',
  ];

  static const List<String> _confidenceTaglines = [
    'Confidence isn\'t a feeling, it\'s your preparation showing up.',
    'Back yourself. You\'ve earned the right.',
    'No hype. Just trust.',
    'Let your routine do the talking.',
  ];

  static const List<String> _controlTaglines = [
    'Control isn\'t not feeling, it\'s responding with clarity.',
    'Whatever happens next, you\'ve got a plan.',
    'Reset. Rebuild. Respond.',
    'Composure wins more than talent.',
  ];

  String _getRandomTagline() {
    final allTaglines = [
      ..._focusTaglines,
      ..._confidenceTaglines,
      ..._controlTaglines
    ];
    return allTaglines[Random().nextInt(allTaglines.length)];
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());

    // Initialize random tagline
    _currentTagline = _getRandomTagline();

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
        endDrawer: loggedIn ? _buildNotificationsDrawer(theme) : null,
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
                                // TODAY Header with colored tab
                                _buildTodayHeaderSection(theme),

                                const SizedBox(height: 24),

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

                                const SizedBox(height: 24),

                                // Focus Areas
                                _buildFocusAreasSection(theme),

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
        final displayName = user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'Golfer';

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

              // Welcome message with full name
              Expanded(
                child: Text(
                  'Welcome back, $displayName',
                  style: theme.titleLarge.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                ),
              ),

              const SizedBox(width: 16),

              // Notification button
              GestureDetector(
                onTap: () {
                  scaffoldKey.currentState?.openEndDrawer();
                },
                child: StreamBuilder<int>(
                  stream: NotificationsRecord.collection
                      .where('userId', isEqualTo: currentUserUid)
                      .where('isRead', isEqualTo: false)
                      .snapshots()
                      .map((snapshot) => snapshot.docs.length),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return Container(
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
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              color: theme.primaryText,
                              size: 24,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayHeaderSection(FlutterFlowTheme theme) {
    // Ensure tagline is initialized
    if (_currentTagline.isEmpty) {
      _currentTagline = _getRandomTagline();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colored "Today" tab
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary.withValues(alpha: 0.8),
                theme.primary.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.today_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'TODAY',
                style: theme.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Today content card
        GlassDashboardCard(
          title: 'Momentum Overview',
          subtitle:
              'Momentum overview. It\'s where your mind and game meet ... today!',
          children: [
            const SizedBox(height: 8),
            // Today's advice/tagline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.1),
                    theme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentTagline,
                      style: theme.bodyMedium.copyWith(
                        color: theme.primaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
          title: 'Mind Power Index (MPI)',
          subtitle:
              'Your current mental game, based on the 3 core pillars for peak performance',
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

            return GlassDashboardCard(
              title: 'Golf Performance',
              subtitle:
                  'The physical result of mental routines done right (MPI)',
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),

                    // Handicap wrapped in container (Section 2)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.glassBackground.withValues(alpha: 0.2),
                            theme.glassTint.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.glassBorder.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.golfPrimary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      theme.golfPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.golf_course,
                                  color: theme.golfPrimary,
                                  size: 22,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.trending_up,
                                color: theme.success,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.handicap != null
                                ? user!.handicap.toStringAsFixed(1)
                                : '--',
                            style: theme.headlineMedium.copyWith(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Handicap',
                            style: theme.titleMedium.copyWith(
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Other Golf Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'Avg Score',
                            _calculateAverageScore(recentRounds)
                                .toStringAsFixed(1),
                            FontAwesomeIcons.golfBallTee,
                            theme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'Rounds',
                            recentRounds.length.toString(),
                            Icons.calendar_month,
                            theme.success,
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
                            'Best Round',
                            _getBestScore(recentRounds).toString(),
                            Icons.star,
                            theme.warning,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(), // Empty space for alignment
                        ),
                      ],
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
          title: 'Progress Streaks',
          subtitle: 'This is how Focus, Confidence, and Control are built',
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
    return StreamBuilder<List<MindcoachSessionsRecord>>(
      stream: MindcoachSessionsRecord.collection
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MindcoachSessionsRecord.fromSnapshot(doc))
              .toList()),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        return GlassDashboardCard(
          title: 'Recent Sessions',
          subtitle: 'The routines that shape your results',
          children: [
            Column(
              children: sessions.isEmpty
                  ? [
                      const SizedBox(height: 24),
                      Text(
                        'No sessions completed yet',
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FFButtonWidget(
                        onPressed: () => context.goNamed('mind_coach'),
                        text: 'Start Your First Session',
                        options: FFButtonOptions(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: theme.primary,
                          textStyle: theme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]
                  : sessions
                      .map((session) => _buildMindcoachSessionItem(theme, session))
                      .toList(),
            )
          ],
        );
      },
    );
  }

  Widget _buildInsightsSection(FlutterFlowTheme theme) {
    // Get today's date at start of day
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<List<AiInsightsRecord>>(
      stream: AiInsightsRecord.collection
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('createdTime', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AiInsightsRecord.fromSnapshot(doc))
              .toList()),
      builder: (context, snapshot) {
        final allInsights = snapshot.data ?? [];
        // Check if there's an insight for today
        AiInsightsRecord? todayInsight;
        for (final insight in allInsights) {
          final generatedTime = insight.generatedTime ?? insight.createdTime;
          if (generatedTime != null &&
              generatedTime.isAfter(todayStart) &&
              generatedTime.isBefore(todayEnd)) {
            todayInsight = insight;
            break;
          }
        }
        // Only show insight if it's from today
        final hasTodayInsight = todayInsight != null;

        return Column(
          children: [
            // AI Insight Card
            GlassDashboardCard(
              title: 'AI Insights',
              subtitle: 'Understand what\'s working, and why',
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (hasTodayInsight) ...[
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
                                    todayInsight.insightTitle.isNotEmpty
                                        ? todayInsight.insightTitle
                                        : 'AI Insight',
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
                              todayInsight.insightContent.isNotEmpty
                                  ? (todayInsight.insightContent.length > 120
                                      ? '${todayInsight.insightContent.substring(0, 120)}...'
                                      : todayInsight.insightContent)
                                  : 'Your personalized AI insight will appear here.',
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'No insights available for today',
                            style: theme.bodyMedium.copyWith(
                              color: theme.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FFButtonWidget(
                            onPressed: () => context.goNamed('ai_insights'),
                            text: 'Generate Insights',
                            options: FFButtonOptions(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: theme.primary,
                              textStyle: theme.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ],
                  ],
                )
              ],
            ),

            const SizedBox(height: 16),

            // Goals Card
            StreamBuilder<List<TrainingPlansRecord>>(
              stream: TrainingPlansRecord.collection
                  .where('userId', isEqualTo: currentUserUid)
                  .where('isActive', isEqualTo: true)
                  .snapshots()
                  .map((snapshot) => snapshot.docs
                      .map((doc) => TrainingPlansRecord.fromSnapshot(doc))
                      .toList()),
              builder: (context, snapshot) {
                final activePlans = snapshot.data ?? [];
                final goals = activePlans
                    .map((plan) => plan.title.isNotEmpty ? plan.title : 'Training Plan')
                    .toList();

                return GlassDashboardCard(
                  title: 'Active Goals',
                  subtitle: 'Your current objectives',
                  children: [
                    Column(
                      children: goals.isEmpty
                          ? [
                              const SizedBox(height: 24),
                              Text(
                                'No active goals set yet',
                                style: theme.bodyMedium.copyWith(
                                  color: theme.secondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FFButtonWidget(
                                onPressed: () => context.goNamed('mind_coach'),
                                text: 'Set Your Goals',
                                options: FFButtonOptions(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  color: theme.primary,
                                  textStyle: theme.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 24),
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


  Widget _buildMindcoachSessionItem(FlutterFlowTheme theme, MindcoachSessionsRecord session) {
    final timestamp = session.timestamp ?? session.createdTime;
    final routineType = session.routineType.isNotEmpty ? session.routineType : 'Mind Coach Session';
    final deliveryLength = session.deliveryLength.isNotEmpty ? session.deliveryLength : '';
    
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
              Icons.psychology,
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
                  routineType,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (deliveryLength.isNotEmpty) ...[
                      Text(
                        deliveryLength,
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                    if (timestamp != null) ...[
                      if (deliveryLength.isNotEmpty) const SizedBox(width: 8),
                      Text(
                        _formatSessionDate(timestamp),
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: theme.success,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildNotificationsDrawer(FlutterFlowTheme theme) {
    return Drawer(
      backgroundColor: theme.primaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.1),
                    theme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: theme.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: StreamBuilder<List<NotificationsRecord>>(
                stream: NotificationsRecord.collection
                    .where('userId', isEqualTo: currentUserUid)
                    .snapshots()
                    .map((snapshot) {
                      final notifications = snapshot.docs
                          .map((doc) => NotificationsRecord.fromSnapshot(doc))
                          .toList();
                      // Sort by createdTime descending
                      notifications.sort((a, b) {
                        final aTime = a.createdTime ?? DateTime(1970);
                        final bTime = b.createdTime ?? DateTime(1970);
                        return bTime.compareTo(aTime);
                      });
                      return notifications.take(50).toList();
                    }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: theme.secondaryText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: theme.bodyLarge.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(theme, notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(FlutterFlowTheme theme, NotificationsRecord notification) {
    final isUnread = !notification.isRead;
    
    return InkWell(
      onTap: () async {
        // Mark as read
        if (!notification.isRead) {
          await notification.reference.update({
            'isRead': true,
            'readTime': FieldValue.serverTimestamp(),
          });
        }
        
        // Handle action if available
        if (notification.actionUrl.isNotEmpty) {
          // Navigate or handle action
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? theme.primary.withValues(alpha: 0.05)
              : theme.glassBackground.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? theme.primary.withValues(alpha: 0.2)
                : theme.glassBorder.withValues(alpha: 0.1),
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(theme, notification.type)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(theme, notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.bodyMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (notification.createdTime != null)
                    Text(
                      _formatNotificationDate(notification.createdTime!),
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(FlutterFlowTheme theme, String type) {
    switch (type.toLowerCase()) {
      case 'achievement':
        return theme.success;
      case 'insight':
        return theme.aiPrimary;
      case 'reminder':
        return theme.warning;
      case 'progress':
        return theme.primary;
      default:
        return theme.primary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'achievement':
        return Icons.emoji_events;
      case 'insight':
        return Icons.psychology;
      case 'reminder':
        return Icons.notifications;
      case 'progress':
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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

  Widget _buildFocusAreasSection(FlutterFlowTheme theme) {
    return StreamBuilder<List<TrainingPlansRecord>>(
      stream: TrainingPlansRecord.collection
          .where('userId', isEqualTo: currentUserUid)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TrainingPlansRecord.fromSnapshot(doc))
              .toList()),
      builder: (context, snapshot) {
        final activePlans = snapshot.data ?? [];
        final focusAreas = activePlans
            .map((plan) => plan.title.isNotEmpty ? plan.title : 'Training Plan')
            .toList();

        return GlassDashboardCard(
          title: 'Focus Areas',
          subtitle: 'Currently working on ...',
          children: [
            Column(
              children: focusAreas.isEmpty
                  ? [
                      const SizedBox(height: 24),
                      Text(
                        'No focus areas set yet',
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FFButtonWidget(
                        onPressed: () => context.goNamed('mind_coach'),
                        text: 'Set Focus Areas',
                        options: FFButtonOptions(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: theme.primary,
                          textStyle: theme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]
                  : focusAreas
                      .map((area) => _buildFocusAreaItem(theme, area))
                      .toList(),
            )
          ],
        );
      },
    );
  }

  Widget _buildFocusAreaItem(FlutterFlowTheme theme, String area) {
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
            Icons.center_focus_strong,
            color: theme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              area,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
              ),
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
