import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/ai_integration/widgets/navbar_widget.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'ai_insights_model.dart';
export 'ai_insights_model.dart';

class AiInsightsWidget extends StatefulWidget {
  const AiInsightsWidget({super.key});

  static String routeName = 'ai_insights';
  static String routePath = '/ai_insights';

  @override
  State<AiInsightsWidget> createState() => _AiInsightsWidgetState();
}

class _AiInsightsWidgetState extends State<AiInsightsWidget>
    with TickerProviderStateMixin {
  late AiInsightsModel _model;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  // final AICoachingService _aiService = AICoachingService.instance; // TODO: Use when AI service is ready

  // Chat state
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiInsightsModel());
    _tabController = TabController(length: 3, vsync: this);

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    // Pulse animation for AI elements
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

    // Glow animation for AI brain
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);

    // Initialize with welcome message
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            "Hi! I'm your AI mental golf coach. I can help you analyze your performance, provide personalized tips, and guide you through mental exercises. What would you like to work on today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
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
                // Glassmorphic App Bar with AI Brain
                _buildGlassmorphicAIAppBar(theme),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // AI Chat Tab
                      _buildAIChatTab(theme),

                      // AI Insights Tab
                      _buildAIInsightsTab(theme),

                      // AI Recommendations Tab
                      _buildAIRecommendationsTab(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Navigation
        bottomNavigationBar: FoCoCoNavBar(
          currentRoute: 'ai_insights',
          enableVoiceButton: true,
          onTap: (route) => context.goNamed(route),
        ),
      ),
    );
  }

  /// Glassmorphic AI App Bar
  Widget _buildGlassmorphicAIAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.aiPrimary.withValues(alpha: 0.9),
                theme.aiSecondary.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // AI Brain Animation
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(
                                        alpha: 0.3 * _glowAnimation.value),
                                    Colors.white.withValues(
                                        alpha: 0.1 * _glowAnimation.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.aiPrimary.withValues(
                                        alpha: 0.4 * _glowAnimation.value),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.brain,
                                color: Colors.white,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AI Mental Coach',
                        style: theme.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Powered by Advanced AI',
                        style: theme.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildGlassmorphicTabs(theme),
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

  /// Glassmorphic Tab Bar
  Widget _buildGlassmorphicTabs(FlutterFlowTheme theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: theme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Chat'),
          Tab(text: 'Insights'),
          Tab(text: 'Recommend'),
        ],
      ),
    );
  }

  /// AI Chat Tab
  Widget _buildAIChatTab(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Chat Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildChatMessage(theme, message);
            },
          ),
        ),

        // Input Area
        _buildChatInputArea(theme),
      ],
    );
  }

  /// Chat Message Bubble
  Widget _buildChatMessage(FlutterFlowTheme theme, ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.aiPrimary, theme.aiSecondary],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.brain,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          theme.primary.withValues(alpha: 0.8),
                          theme.secondary.withValues(alpha: 0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: !isUser
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                message.text,
                style: theme.bodyMedium.copyWith(
                  color: isUser ? Colors.white : theme.primaryText,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.secondaryBackground,
              child: Text(
                currentUserDisplayName.isNotEmpty
                    ? currentUserDisplayName[0].toUpperCase()
                    : 'U',
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Chat Input Area
  Widget _buildChatInputArea(FlutterFlowTheme theme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.secondaryBackground.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: theme.secondaryText.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: theme.bodyMedium.copyWith(color: theme.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach...',
                      hintStyle: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.aiPrimary, theme.aiSecondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _sendMessage(_messageController.text),
                    borderRadius: BorderRadius.circular(24),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AI Insights Tab
  Widget _buildAIInsightsTab(FlutterFlowTheme theme) {
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Mental Performance Overview
              _buildMentalPerformanceOverview(theme, dashboardData),

              const SizedBox(height: 20),

              // AI-Generated Insights Cards
              _buildInsightCard(
                theme: theme,
                title: 'Focus Analysis',
                content:
                    'Your focus tends to drop after the 12th hole. Try implementing a mid-round reset routine.',
                icon: Icons.center_focus_strong,
                color: theme.aiPrimary,
              ),

              const SizedBox(height: 16),

              _buildInsightCard(
                theme: theme,
                title: 'Confidence Pattern',
                content:
                    'You perform 15% better when playing with familiar partners. Use visualization before solo rounds.',
                icon: Icons.trending_up,
                color: theme.performanceExcellent,
              ),

              const SizedBox(height: 16),

              _buildInsightCard(
                theme: theme,
                title: 'Control Recommendation',
                content:
                    'Your breathing pattern affects putting accuracy. Practice box breathing before crucial putts.',
                icon: Icons.air,
                color: theme.mindfulnessPrimary,
              ),

              const SizedBox(height: 20),

              // Weekly Mental Score Trend
              _buildWeeklyMentalScoreTrend(theme, dashboardData),
            ],
          ),
        );
      },
    );
  }

  /// Mental Performance Overview
  Widget _buildMentalPerformanceOverview(
      FlutterFlowTheme theme, DashboardDataRecord? data) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Text(
            'Mental Performance Score',
            style: theme.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMentalMetric(
                theme: theme,
                label: 'Focus',
                value: data?.mentalFocusScore ?? 85,
                color: theme.aiPrimary,
                icon: FontAwesomeIcons.bullseye,
              ),
              _buildMentalMetric(
                theme: theme,
                label: 'Confidence',
                value: data?.confidenceScore ?? 78,
                color: theme.coachingPrimary,
                icon: FontAwesomeIcons.medal,
              ),
              _buildMentalMetric(
                theme: theme,
                label: 'Control',
                value: data?.controlScore ?? 92,
                color: theme.performanceExcellent,
                icon: FontAwesomeIcons.scaleBalanced,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.aiPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.aiPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.aiPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your overall mental game is strong. Focus on maintaining consistency in high-pressure situations.',
                    style: theme.bodySmall.copyWith(
                      color: theme.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mental Metric Widget
  Widget _buildMentalMetric({
    required FlutterFlowTheme theme,
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 40,
                  lineWidth: 6,
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
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toInt()}%',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          label,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
      ],
    );
  }

  /// Insight Card
  Widget _buildInsightCard({
    required FlutterFlowTheme theme,
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Weekly Mental Score Trend
  Widget _buildWeeklyMentalScoreTrend(
      FlutterFlowTheme theme, DashboardDataRecord? data) {
    final weeklyData = data?.weeklyProgress ?? [75, 78, 82, 80, 85, 88, 90];

    return Container(
      height: 250,
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
                'Mental Score Trend',
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.aiPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${((weeklyData.last - weeklyData.first) / weeklyData.first * 100).toStringAsFixed(1)}%',
                  style: theme.bodySmall.copyWith(
                    color: theme.aiPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        theme.aiPrimary,
                        theme.aiSecondary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: theme.aiPrimary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.aiPrimary.withValues(alpha: 0.3),
                          theme.aiPrimary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI Recommendations Tab
  Widget _buildAIRecommendationsTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalized Training Plan
          _buildTrainingPlanSection(theme),

          const SizedBox(height: 24),

          // Recommended Modules
          _buildRecommendedModulesSection(theme),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActionsSection(theme),
        ],
      ),
    );
  }

  /// Training Plan Section
  Widget _buildTrainingPlanSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Personalized Plan',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.aiPrimary.withValues(alpha: 0.1),
                theme.aiSecondary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.aiPrimary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildPlanItem(
                theme: theme,
                time: 'Morning',
                activity: '5-min Visualization',
                icon: Icons.visibility,
              ),
              const SizedBox(height: 12),
              _buildPlanItem(
                theme: theme,
                time: 'Pre-Round',
                activity: 'Breathing Exercise',
                icon: Icons.air,
              ),
              const SizedBox(height: 12),
              _buildPlanItem(
                theme: theme,
                time: 'Evening',
                activity: 'Reflection Journal',
                icon: Icons.book,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Plan Item
  Widget _buildPlanItem({
    required FlutterFlowTheme theme,
    required String time,
    required String activity,
    required IconData icon,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.aiPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.aiPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
                Text(
                  activity,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          FFButtonWidget(
            onPressed: () {},
            text: 'Start',
            options: FFButtonOptions(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.aiPrimary,
              textStyle: theme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  /// Recommended Modules Section
  Widget _buildRecommendedModulesSection(FlutterFlowTheme theme) {
    final modules = [
      {
        'title': 'Pre-Shot Routine Mastery',
        'duration': '15 min',
        'type': 'Focus',
        'color': theme.aiPrimary,
      },
      {
        'title': 'Confidence Under Pressure',
        'duration': '20 min',
        'type': 'Mental',
        'color': theme.coachingPrimary,
      },
      {
        'title': 'Emotional Control Techniques',
        'duration': '10 min',
        'type': 'Control',
        'color': theme.performanceExcellent,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended for You',
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed('coaching_modules'),
              child: Text(
                'See All',
                style: theme.bodyMedium.copyWith(
                  color: theme.aiPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...modules
            .map((module) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildModuleCard(
                    theme: theme,
                    title: module['title'] as String,
                    duration: module['duration'] as String,
                    type: module['type'] as String,
                    color: module['color'] as Color,
                  ),
                ))
            .toList(),
      ],
    );
  }

  /// Module Card
  Widget _buildModuleCard({
    required FlutterFlowTheme theme,
    required String title,
    required String duration,
    required String type,
    required Color color,
  }) {
    return InkWell(
      onTap: () => context.goNamed('coaching_modules'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: theme.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Actions Section
  Widget _buildQuickActionsSection(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.warning.withValues(alpha: 0.1),
            theme.warning.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flash_on,
            color: theme.warning,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Quick Mental Reset',
            style: theme.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feeling stressed? Try a 2-minute reset',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          FFButtonWidget(
            onPressed: () {},
            text: 'Start Reset',
            options: FFButtonOptions(
              width: double.infinity,
              height: 48,
              color: theme.warning,
              textStyle: theme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Call AI service - use the appropriate method based on your AI service
      // For now, using a placeholder response
      final response =
          "I'm analyzing your query: '$text'. Based on your recent performance, I recommend focusing on your mental game during the back nine.";

      // TODO: Replace with actual AI service call
      // final response = await _aiService.generateInsight(
      //   prompt: text,
      //   context: _buildChatContext(),
      // );

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

  String _buildChatContext() {
    // Build context from recent messages
    final recentMessages = _messages
        .take(10)
        .map((m) => '${m.isUser ? "User" : "AI"}: ${m.text}')
        .join('\n');

    return recentMessages;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
