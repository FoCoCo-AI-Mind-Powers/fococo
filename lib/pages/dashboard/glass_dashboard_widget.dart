/// FoCoCo Glass Dashboard
/// Modern glassmorphism design with enhanced AI integration

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/services/app_tutorial_service.dart';

/// Enhanced Glass Dashboard Widget with AI Integration
class GlassDashboardWidget extends StatefulWidget {
  const GlassDashboardWidget({super.key});

  static String routeName = 'glass_dashboard';
  static String routePath = '/glass_dashboard';

  @override
  State<GlassDashboardWidget> createState() => _GlassDashboardWidgetState();
}

class _GlassDashboardWidgetState extends State<GlassDashboardWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AppTutorialService _tutorialService = AppTutorialService();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tutorial target keys
  final GlobalKey _pillarCardsKey = GlobalKey();
  final GlobalKey _quickActionsKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _aiCoachKey = GlobalKey();
  final GlobalKey _recentActivityKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Check and show tutorial
    _checkAndShowTutorial();
  }

  Future<void> _checkAndShowTutorial() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    _tutorialService.startDashboardTutorial(
      context,
      pillarCardsKey: _pillarCardsKey,
      quickActionsKey: _quickActionsKey,
      statsKey: _statsKey,
      aiCoachKey: _aiCoachKey,
      recentActivityKey: _recentActivityKey,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryBackground,
                theme.secondaryBackground.withValues(alpha: 0.8),
                theme.primaryBackground.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // Glass App Bar
                    _buildGlassAppBar(theme),

                    // Dashboard Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Section with AI Badge
                            _buildWelcomeSection(theme),

                            const SizedBox(height: 24),

                            // Quick Stats Row
                            _buildQuickStatsRow(theme),

                            const SizedBox(height: 24),

                            // AI Insights Section
                            _buildAIInsightsSection(theme),

                            const SizedBox(height: 24),

                            // Performance Overview
                            _buildPerformanceOverview(theme),

                            const SizedBox(height: 24),

                            // Recent Activity
                            _buildRecentActivity(theme),

                            const SizedBox(height: 24),

                            // Quick Actions
                            _buildQuickActions(theme),

                            const SizedBox(
                                height: 100), // Bottom padding for nav
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
        bottomNavigationBar: FoCoCoAnimatedBottomNavBar(
          currentRoute: 'dashboard',
        ),
      ),
    );
  }

  /// Glass App Bar with User Info
  Widget _buildGlassAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryBackground.withValues(alpha: 0.95),
                theme.primaryBackground.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: theme.primaryBrandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: theme.glass3DShadows,
                          ),
                          child: FoCoCoLogo(
                            size: LogoSize.small,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_getTimeOfDayGreeting()}',
                                style: theme.bodyMedium.override(
                                  color: theme.secondaryText,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUserDisplayName.isNotEmpty
                                    ? currentUserDisplayName
                                    : 'Golfer',
                                style: theme.headlineSmall.override(
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notifications
                        GlassDesignSystem.glass3DCard(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(12),
                          onTap: () {
                            // Handle notifications
                          },
                          child: Icon(
                            FontAwesomeIcons.bell,
                            color: theme.primaryText,
                            size: 20,
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
      ),
    );
  }

  /// Welcome Section with AI Badge
  Widget _buildWelcomeSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Your Mental Game Today',
      subtitle: 'AI-powered insights to enhance your performance',
      showAIBadge: true,
      aiInsight:
          'Your focus score has improved 15% this week. Try the new pre-shot routine to maintain consistency.',
      icon: Icon(
        FontAwesomeIcons.brain,
        color: Colors.white,
        size: 24,
      ),
      onTap: () {
        context.pushNamed('ai_insights');
      },
    );
  }

  /// Quick Stats Row
  Widget _buildQuickStatsRow(FlutterFlowTheme theme) {
    return Row(
      key: _pillarCardsKey,
      children: [
        Expanded(
          child: GlassPerformanceCard(
            title: 'Mental Score',
            value: '8.2',
            change: '+1.3',
            icon: FontAwesomeIcons.brain,
            color: theme.aiPrimary,
            isPositive: true,
            onTap: () {
              context.pushNamed('progress');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassPerformanceCard(
            title: 'Focus Level',
            value: '85%',
            change: '+5%',
            icon: FontAwesomeIcons.bullseye,
            color: theme.mentalFocus,
            isPositive: true,
            onTap: () {
              context.pushNamed('mind_coach');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassPerformanceCard(
            title: 'Streak',
            value: '7',
            change: 'days',
            icon: FontAwesomeIcons.fire,
            color: theme.streakActive,
            isPositive: true,
            onTap: () {
              context.pushNamed('achievements');
            },
          ),
        ),
      ],
    );
  }

  /// AI Insights Section
  Widget _buildAIInsightsSection(FlutterFlowTheme theme) {
    return Column(
      key: _aiCoachKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              FontAwesomeIcons.star,
              color: theme.aiPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'AI Insights',
              style: theme.titleLarge.override(
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                context.pushNamed('ai_insights');
              },
              child: Text(
                'View All',
                style: theme.bodyMedium.override(
                  color: theme.aiPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassDesignSystem.glass3DCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: theme.aiGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      FontAwesomeIcons.chartLine,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Trend Analysis',
                          style: theme.titleMedium.override(
                            color: theme.primaryText,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your mental game shows consistent improvement over the last 2 weeks.',
                          style: theme.bodySmall.override(
                            color: theme.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassMetricBadge(
                      label: 'Confidence',
                      value: '+12%',
                      color: theme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassMetricBadge(
                      label: 'Focus',
                      value: '+8%',
                      color: theme.aiPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassMetricBadge(
                      label: 'Control',
                      value: '+15%',
                      color: theme.mentalBalance,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Performance Overview
  Widget _buildPerformanceOverview(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: theme.titleLarge.override(
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        GlassDesignSystem.glass3DCard(
          child: Row(
            children: [
              // Progress Ring
              GlassProgressRing(
                progress: 0.75,
                size: 80,
                color: theme.primary,
                centerText: '75%',
              ),

              const SizedBox(width: 20),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mental Performance Index',
                      style: theme.titleMedium.override(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your recent rounds and training sessions',
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.arrowTrendUp,
                          color: theme.success,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Improving steadily',
                          style: theme.bodySmall.override(
                            color: theme.success,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Recent Activity
  Widget _buildRecentActivity(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: theme.titleLarge.override(
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                context.pushNamed('golf_sync');
              },
              child: Text(
                'View All',
                style: theme.bodyMedium.override(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassActivityItem(
          title: 'Morning Practice Round',
          subtitle: 'Worked on focus and pre-shot routine',
          timestamp: '2 hours ago',
          leading: Icon(
            FontAwesomeIcons.golfBallTee,
            color: Colors.white,
            size: 20,
          ),
          metrics: [
            GlassMetricBadge(
              label: 'Score',
              value: '78',
              color: theme.success,
            ),
            GlassMetricBadge(
              label: 'Focus',
              value: '8.5',
              color: theme.aiPrimary,
            ),
          ],
          onTap: () {
            context.pushNamed('golf_rounds');
          },
        ),
        const SizedBox(height: 12),
        GlassActivityItem(
          title: 'Mindfulness Session',
          subtitle: 'Completed breathing exercises',
          timestamp: 'Yesterday',
          leading: Icon(
            FontAwesomeIcons.leaf,
            color: Colors.white,
            size: 20,
          ),
          metrics: [
            GlassMetricBadge(
              label: 'Duration',
              value: '15min',
              color: theme.calmPrimary,
            ),
            GlassMetricBadge(
              label: 'Rating',
              value: '9/10',
              color: theme.mentalCalm,
            ),
          ],
          onTap: () {
            context.pushNamed('mind_coach');
          },
        ),
      ],
    );
  }

  /// Quick Actions
  Widget _buildQuickActions(FlutterFlowTheme theme) {
    return Column(
      key: _quickActionsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.titleLarge.override(
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GlassDesignSystem.glassButton(
                text: 'Log Round',
                icon: FontAwesomeIcons.plus,
                onPressed: () {
                  context.pushNamed('golf_sync');
                },
                color: theme.golfPrimary,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassDesignSystem.glassButton(
                text: 'Train Mind',
                icon: FontAwesomeIcons.brain,
                onPressed: () {
                  context.pushNamed('mind_coach');
                },
                color: theme.aiPrimary,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassDesignSystem.glassButton(
                text: 'AI Insights',
                icon: FontAwesomeIcons.star,
                onPressed: () {
                  context.pushNamed('ai_insights');
                },
                color: theme.insightPositive,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassDesignSystem.glassButton(
                text: 'Progress',
                icon: FontAwesomeIcons.chartLine,
                onPressed: () {
                  context.pushNamed('progress');
                },
                color: theme.performanceGood,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
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
