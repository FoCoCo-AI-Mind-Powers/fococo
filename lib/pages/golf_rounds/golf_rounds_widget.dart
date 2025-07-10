import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/ai_integration/index.dart';
import '/backend/schema/index.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'golf_rounds_model.dart';
export 'golf_rounds_model.dart';

class GolfRoundsWidget extends StatefulWidget {
  const GolfRoundsWidget({super.key});

  static String routeName = 'golf_rounds';
  static String routePath = '/golf_rounds';

  @override
  State<GolfRoundsWidget> createState() => _GolfRoundsWidgetState();
}

class _GolfRoundsWidgetState extends State<GolfRoundsWidget> with TickerProviderStateMixin {
  late GolfRoundsModel _model;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GolfRoundsModel());
    _tabController = TabController(length: 3, vsync: this);
    
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _model.dispose();
    _tabController.dispose();
    _animationController.dispose();
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
          child: CustomScrollView(
            slivers: [
              // Enhanced App Bar with Strava-inspired header
              _buildSliverAppBar(theme),
              
              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Recent Rounds Tab (Strava-inspired activity feed)
                    _buildRecentRoundsTab(theme),
                    
                    // Performance Analytics Tab
                    _buildPerformanceAnalyticsTab(theme),
                    
                    // Progress & Insights Tab
                    _buildProgressInsightsTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Floating Action Button for new round
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddRoundBottomSheet(context),
          backgroundColor: theme.golfPrimary,
          icon: Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Log Round',
            style: theme.titleSmall.override(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        
        // Enhanced Bottom Navigation
        bottomNavigationBar: _buildEnhancedBottomNav(theme),
      ),
    );
  }

  /// Enhanced SliverAppBar with Strava-inspired header
  Widget _buildSliverAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      expandedHeight: 280,
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
                children: [
                  // Header with title and profile
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Golf Rounds',
                              style: theme.headlineMedium.override(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: FlutterFlowTheme.spacingXS),
                            Text(
                              'Track your journey to lower scores',
                              style: theme.bodyMedium.override(
                                color: Colors.white.withOpacity(0.8),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => context.goNamed('profile'),
                          icon: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: FlutterFlowTheme.spacingL),
                  
                  // Performance metrics cards (Strava-inspired)
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStatCard(
                          theme,
                          'Avg Score',
                          '78.5',
                          '-2.3 from last month',
                          Icons.trending_down_rounded,
                          theme.success,
                        ),
                      ),
                      const SizedBox(width: FlutterFlowTheme.spacingM),
                      Expanded(
                        child: _buildHeaderStatCard(
                          theme,
                          'Best Round',
                          '72',
                          'Personal best!',
                          Icons.emoji_events_rounded,
                          theme.premiumGold,
                        ),
                      ),
                      const SizedBox(width: FlutterFlowTheme.spacingM),
                      Expanded(
                        child: _buildHeaderStatCard(
                          theme,
                          'Rounds',
                          '24',
                          'This year',
                          FontAwesomeIcons.golfBall,
                          theme.golfPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: FlutterFlowTheme.spacingL),
                  
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: theme.golfPrimary,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: theme.bodyMedium.override(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      tabs: const [
                        Tab(text: 'Recent'),
                        Tab(text: 'Analytics'),
                        Tab(text: 'Progress'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatCard(
    FlutterFlowTheme theme,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: FlutterFlowTheme.spacingS),
          Text(
            value,
            style: theme.headlineSmall.override(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: FlutterFlowTheme.spacingXS),
          Text(
            title,
            style: theme.bodySmall.override(
              color: Colors.white.withOpacity(0.8),
              height: 1.2,
            ),
          ),
          const SizedBox(height: FlutterFlowTheme.spacingXS),
          Text(
            subtitle,
            style: theme.bodySmall.override(
              color: color,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Recent Rounds Tab - Strava-inspired activity feed
  Widget _buildRecentRoundsTab(FlutterFlowTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      children: [
        // Filter and sort options
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Rounds',
                style: theme.headlineSmall.override(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FlutterFlowTheme.spacingM,
                vertical: FlutterFlowTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: theme.secondaryText,
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingS),
                  Text(
                    'Filter',
                    style: theme.bodyMedium.override(
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingL),
        
        // Round cards with Strava-inspired design
        _buildRoundCard(
          theme,
          'Pebble Beach Golf Links',
          DateTime.now().subtract(const Duration(days: 2)),
          82,
          'Challenging conditions with strong winds. Great mental focus on back 9.',
          {
            'Fairways': 71,
            'Greens': 67,
            'Putts': 32,
          },
          true, // has AI analysis
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        _buildRoundCard(
          theme,
          'Torrey Pines Golf Course',
          DateTime.now().subtract(const Duration(days: 5)),
          78,
          'Best round of the month! Putting was on point.',
          {
            'Fairways': 79,
            'Greens': 72,
            'Putts': 28,
          },
          true,
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        _buildRoundCard(
          theme,
          'Spyglass Hill Golf Course',
          DateTime.now().subtract(const Duration(days: 8)),
          85,
          'Tough day on the course. Need to work on short game.',
          {
            'Fairways': 64,
            'Greens': 61,
            'Putts': 36,
          },
          false,
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingXXL),
      ],
    );
  }

  Widget _buildRoundCard(
    FlutterFlowTheme theme,
    String courseName,
    DateTime date,
    int score,
    String notes,
    Map<String, int> stats,
    bool hasAIAnalysis,
  ) {
    return FoCoCoCard(
      style: FoCoCoCardStyle.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with course and date
          Row(
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
                      courseName,
                      style: theme.titleMedium.override(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: FlutterFlowTheme.spacingXS),
                    Text(
                      dateTimeFormat('MMM d, yyyy', date),
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlutterFlowTheme.spacingM,
                  vertical: FlutterFlowTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(theme, score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
                ),
                child: Text(
                  score.toString(),
                  style: theme.titleLarge.override(
                    color: _getScoreColor(theme, score),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Performance metrics
          Row(
            children: stats.entries.map((entry) => Expanded(
              child: Column(
                children: [
                  Text(
                    '${entry.value}%',
                                         style: theme.titleSmall.override(
                       fontWeight: FontWeight.w600,
                       color: theme.getPerformanceColor(entry.value / 100),
                       height: 1.2,
                     ),
                  ),
                  const SizedBox(height: FlutterFlowTheme.spacingXS),
                  Text(
                    entry.key,
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingM),
          
          // Notes
          if (notes.isNotEmpty) ...[
            Text(
              notes,
              style: theme.bodyMedium.override(
                color: theme.primaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: FlutterFlowTheme.spacingM),
          ],
          
          // Action buttons
          Row(
            children: [
              if (hasAIAnalysis)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAIAnalysis(courseName, score),
                    icon: Icon(
                      Icons.psychology_rounded,
                      size: 16,
                      color: theme.aiPrimary,
                    ),
                    label: Text(
                      'AI Analysis',
                      style: theme.bodySmall.override(
                        color: theme.aiPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.aiPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                      ),
                    ),
                  ),
                ),
              
              if (hasAIAnalysis) const SizedBox(width: FlutterFlowTheme.spacingM),
              
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRoundDetails(courseName, score),
                  icon: Icon(
                    Icons.bar_chart_rounded,
                    size: 16,
                    color: theme.golfPrimary,
                  ),
                  label: Text(
                    'View Details',
                    style: theme.bodySmall.override(
                      color: theme.golfPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.golfPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Performance Analytics Tab
  Widget _buildPerformanceAnalyticsTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance overview
          Text(
            'Performance Analytics',
            style: theme.headlineSmall.override(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Performance metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: FlutterFlowTheme.spacingM,
            crossAxisSpacing: FlutterFlowTheme.spacingM,
            children: [
              PerformanceMetricCard(
                title: 'Driving',
                value: '72',
                unit: '% accuracy',
                percentage: 72.0,
                icon: Icons.sports_golf_rounded,
                trend: '+5.2',
                primaryColor: theme.golfPrimary,
              ),
              PerformanceMetricCard(
                title: 'Approach',
                value: '68',
                unit: '% on green',
                percentage: 68.0,
                icon: Icons.flag_rounded,
                trend: '+2.8',
                primaryColor: theme.golfSecondary,
              ),
              PerformanceMetricCard(
                title: 'Short Game',
                value: '78',
                unit: '% up & down',
                percentage: 78.0,
                icon: Icons.golf_course_rounded,
                trend: '-1.2',
                primaryColor: theme.performanceAverage,
              ),
              PerformanceMetricCard(
                title: 'Putting',
                value: '1.82',
                unit: 'avg putts',
                percentage: 65.0,
                icon: Icons.circle_outlined,
                trend: '+0.08',
                primaryColor: theme.performancePoor,
              ),
            ],
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Score trend chart placeholder
          FoCoCoCard(
            style: FoCoCoCardStyle.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Trend',
                  style: theme.titleMedium.override(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingS),
                Text(
                  'Last 12 rounds',
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingL),
                
                // Placeholder for chart
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: theme.secondaryText,
                          size: 48,
                        ),
                        const SizedBox(height: FlutterFlowTheme.spacingS),
                        Text(
                          'Score Trend Chart',
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                            height: 1.2,
                          ),
                        ),
                      ],
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

  /// Progress & AI Insights Tab
  Widget _buildProgressInsightsTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress overview
          Text(
            'Progress & Insights',
            style: theme.headlineSmall.override(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // AI-powered insights
          AIInsightCard(
            title: 'Performance Analysis',
            insight: 'Your driving accuracy has improved by 5.2% over the last month. Focus on maintaining this consistency while working on approach shots to greens.',
            sentiment: 'positive',
            recommendations: [
              'Practice approach shots from 100-150 yards',
              'Work on green reading for better putting',
              'Maintain current driving routine',
            ],
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
            aiModel: 'Golf AI Pro',
            onFeedback: () {
              // Handle feedback
            },
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Goals and achievements
          FoCoCoCard(
            style: FoCoCoCardStyle.wellness,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Goals',
                  style: theme.titleMedium.override(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingM),
                
                _buildGoalItem(
                  theme,
                  'Break 80 consistently',
                  'Shoot under 80 in 3 of next 5 rounds',
                  0.6,
                  Icons.emoji_events_rounded,
                ),
                
                const SizedBox(height: FlutterFlowTheme.spacingM),
                
                _buildGoalItem(
                  theme,
                  'Improve putting average',
                  'Get under 1.8 putts per green',
                  0.3,
                  Icons.circle_outlined,
                ),
                
                const SizedBox(height: FlutterFlowTheme.spacingM),
                
                _buildGoalItem(
                  theme,
                  'Fairway accuracy',
                  'Hit 75% of fairways',
                  0.8,
                  Icons.sports_golf_rounded,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: FlutterFlowTheme.spacingL),
          
          // Recent achievements
          Text(
            'Recent Achievements',
            style: theme.titleMedium.override(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
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
                    title: 'Fairway Finder',
                    description: 'Hit 80% fairways in a round',
                    icon: Icons.sports_golf_rounded,
                    tier: AchievementTier.gold,
                    isEarned: true,
                    earnedDate: DateTime.now().subtract(const Duration(days: 3)),
                  ),
                ),
                const SizedBox(width: FlutterFlowTheme.spacingM),
                SizedBox(
                  width: 160,
                  child: AchievementBadge(
                    title: 'Sub-80 Club',
                    description: 'Shot under 80 for first time',
                    icon: Icons.emoji_events_rounded,
                    tier: AchievementTier.silver,
                    isEarned: true,
                    earnedDate: DateTime.now().subtract(const Duration(days: 7)),
                  ),
                ),
                const SizedBox(width: FlutterFlowTheme.spacingM),
                SizedBox(
                  width: 160,
                  child: AchievementBadge(
                    title: 'Putting Master',
                    description: 'Average under 1.8 putts/green',
                    icon: Icons.circle_outlined,
                    tier: AchievementTier.bronze,
                    isEarned: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(
    FlutterFlowTheme theme,
    String title,
    String description,
    double progress,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.golfPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.golfPrimary,
            size: 20,
          ),
        ),
        
        const SizedBox(width: FlutterFlowTheme.spacingM),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.titleSmall.override(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: FlutterFlowTheme.spacingXS),
              Text(
                description,
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: FlutterFlowTheme.spacingS),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.alternate,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.golfPrimary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: FlutterFlowTheme.spacingM),
        
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.bodySmall.override(
            color: theme.golfPrimary,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
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
              _buildNavItem(theme, Icons.home_rounded, 'Home', 'dashboard', false),
              _buildNavItem(theme, FontAwesomeIcons.golfBall, 'Rounds', 'golf_rounds', true),
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

  // Helper methods
  Color _getScoreColor(FlutterFlowTheme theme, int score) {
    if (score <= 75) return theme.performanceGood;
    if (score <= 85) return theme.performanceAverage;
    return theme.performancePoor;
  }

  void _showAddRoundBottomSheet(BuildContext context) {
    // TODO: Implement add round bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Round',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: FlutterFlowTheme.spacingL),
            Text(
              'Coming soon - Track your rounds with detailed statistics and AI-powered insights.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: FlutterFlowTheme.of(context).secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FlutterFlowTheme.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIAnalysis(String courseName, int score) {
    // TODO: Show AI analysis modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Analysis'),
        content: Text('Detailed AI analysis for $courseName (Score: $score) coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRoundDetails(String courseName, int score) {
    // TODO: Show round details modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Round Details'),
        content: Text('Detailed statistics for $courseName (Score: $score) coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
} 