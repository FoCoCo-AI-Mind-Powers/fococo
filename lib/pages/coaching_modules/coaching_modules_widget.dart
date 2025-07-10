import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/ai_integration/index.dart';
import '/backend/schema/index.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'coaching_modules_model.dart';
export 'coaching_modules_model.dart';

class CoachingModulesWidget extends StatefulWidget {
  const CoachingModulesWidget({super.key});

  static String routeName = 'coaching_modules';
  static String routePath = '/coaching_modules';

  @override
  State<CoachingModulesWidget> createState() => _CoachingModulesWidgetState();
}

class _CoachingModulesWidgetState extends State<CoachingModulesWidget> with TickerProviderStateMixin {
  late CoachingModulesModel _model;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CoachingModulesModel());
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
        backgroundColor: theme.calmBackground,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Enhanced App Bar with serene design
                _buildSliverAppBar(theme),
                
                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Learning Path Tab (Duolingo-inspired)
                      _buildLearningPathTab(theme),
                      
                      // Today's Sessions Tab (Headspace-inspired)
                      _buildTodaySessionsTab(theme),
                      
                      // Progress & Insights Tab
                      _buildProgressTab(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Enhanced Bottom Navigation
        bottomNavigationBar: _buildEnhancedBottomNav(theme),
      ),
    );
  }

  /// Enhanced SliverAppBar with Calm-inspired serene design
  Widget _buildSliverAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: theme.sereneGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${currentUserDisplayName.isNotEmpty ? currentUserDisplayName.split(' ').first : 'Golfer'}',
                              style: theme.headlineMedium.override(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to strengthen your mental game?',
                              style: theme.bodyMedium.override(
                                color: Colors.white.withOpacity(0.8),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Daily streak indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.fire,
                              color: theme.streakActive,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '7',
                              style: theme.titleMedium.override(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Today's motivation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Today\'s focus: Building confidence under pressure',
                            style: theme.bodyMedium.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: theme.coachingPrimary,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: theme.bodyMedium.override(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      tabs: const [
                        Tab(text: 'Learn'),
                        Tab(text: 'Today'),
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

  /// Learning Path Tab - Duolingo-inspired skill tree
  Widget _buildLearningPathTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Learning path header
          Text(
            'Your Learning Journey',
            style: theme.headlineSmall.override(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Master mental skills step by step',
            style: theme.bodyMedium.override(
              color: theme.secondaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Skill tree - Duolingo style
          _buildSkillTree(theme),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSkillTree(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Level 1 - Foundation
        _buildSkillLevel(
          theme,
          'Foundation',
          1,
          [
            _buildSkillNode(
              theme,
              'Breathing Basics',
              1,
              3,
              1.0,
              true,
              false,
              false,
              Icons.air_rounded,
            ),
            _buildSkillNode(
              theme,
              'Body Awareness',
              2,
              3,
              0.7,
              false,
              false,
              true,
              Icons.accessibility_rounded,
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Level 2 - Focus
        _buildSkillLevel(
          theme,
          'Focus Training',
          2,
          [
            _buildSkillNode(
              theme,
              'Concentration',
              1,
              4,
              0.5,
              false,
              false,
              false,
              Icons.center_focus_strong_rounded,
            ),
            _buildSkillNode(
              theme,
              'Visualization',
              0,
              4,
              0.0,
              false,
              true,
              false,
              Icons.visibility_rounded,
            ),
            _buildSkillNode(
              theme,
              'Mindful Practice',
              0,
              4,
              0.0,
              false,
              true,
              false,
              Icons.self_improvement_rounded,
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Level 3 - Performance
        _buildSkillLevel(
          theme,
          'Performance',
          3,
          [
            _buildSkillNode(
              theme,
              'Pressure Handling',
              0,
              5,
              0.0,
              false,
              true,
              false,
              Icons.trending_up_rounded,
            ),
            _buildSkillNode(
              theme,
              'Flow State',
              0,
              5,
              0.0,
              false,
              true,
              false,
              Icons.waves_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillLevel(
    FlutterFlowTheme theme,
    String title,
    int level,
    List<Widget> skills,
  ) {
    return Column(
      children: [
        // Level header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: theme.coachingPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Level $level',
                style: theme.bodySmall.override(
                  color: theme.coachingPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.titleMedium.override(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Skills grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: skills,
        ),
      ],
    );
  }

  Widget _buildSkillNode(
    FlutterFlowTheme theme,
    String title,
    int level,
    int maxLevel,
    double progress,
    bool isCompleted,
    bool isLocked,
    bool isActive,
    IconData icon,
  ) {
    return SkillProgressNode(
      title: title,
      level: level,
      maxLevel: maxLevel,
      progress: progress,
      isCompleted: isCompleted,
      isLocked: isLocked,
      isActive: isActive,
      onTap: isLocked ? null : () => _showSkillDetails(title, level, maxLevel),
    );
  }

  /// Today's Sessions Tab - Headspace-inspired
  Widget _buildTodaySessionsTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended for today
          Text(
            'Recommended for Today',
            style: theme.headlineSmall.override(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Based on your recent golf performance',
            style: theme.bodyMedium.override(
              color: theme.secondaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Featured session
          _buildFeaturedSession(theme),
          
          const SizedBox(height: 32),
          
          // Quick sessions
          Text(
            'Quick Sessions',
            style: theme.titleMedium.override(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildQuickSessionsList(theme),
          
          const SizedBox(height: 32),
          
          // Categories
          Text(
            'Browse by Category',
            style: theme.titleMedium.override(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildCategoryGrid(theme),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFeaturedSession(FlutterFlowTheme theme) {
    return FoCoCoCard(
      style: FoCoCoCardStyle.premium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.premiumGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FEATURED TODAY',
              style: theme.bodySmall.override(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Session details
          Row(
            children: [
              // Session icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.coachingPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: theme.coachingPrimary,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pressure-Free Putting',
                      style: theme.titleLarge.override(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn to stay calm and focused during crucial putts',
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: theme.coachingPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '12 minutes',
                          style: theme.bodySmall.override(
                            color: theme.coachingPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: theme.premiumGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Intermediate',
                          style: theme.bodySmall.override(
                            color: theme.secondaryText,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Start button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _startSession('Pressure-Free Putting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.coachingPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                'Start Session',
                style: theme.titleSmall.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSessionsList(FlutterFlowTheme theme) {
    return Column(
      children: [
        _buildQuickSessionItem(
          theme,
          'Pre-Round Confidence',
          '5 min',
          'Beginner',
          Icons.sports_golf_rounded,
          theme.golfPrimary,
        ),
        const SizedBox(height: 16),
        _buildQuickSessionItem(
          theme,
          'Post-Miss Recovery',
          '3 min',
          'Intermediate',
          Icons.refresh_rounded,
          theme.mindfulnessPrimary,
        ),
        const SizedBox(height: 16),
        _buildQuickSessionItem(
          theme,
          'Focus Reset',
          '4 min',
          'Beginner',
          Icons.center_focus_strong_rounded,
          theme.coachingPrimary,
        ),
      ],
    );
  }

  Widget _buildQuickSessionItem(
    FlutterFlowTheme theme,
    String title,
    String duration,
    String difficulty,
    IconData icon,
    Color color,
  ) {
    return FoCoCoCard(
      onTap: () => _startSession(title),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                  style: theme.titleSmall.override(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      duration,
                      style: theme.bodySmall.override(
                        color: color,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
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
          ),
          
          Icon(
            Icons.play_circle_filled_rounded,
            color: color,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(FlutterFlowTheme theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildCategoryCard(
          theme,
          'Breathing',
          Icons.air_rounded,
                     theme.mentalCalm,
          12,
        ),
        _buildCategoryCard(
          theme,
          'Confidence',
          Icons.emoji_emotions_rounded,
          theme.mindfulnessPrimary,
          8,
        ),
        _buildCategoryCard(
          theme,
          'Focus',
          Icons.center_focus_strong_rounded,
          theme.coachingPrimary,
          15,
        ),
        _buildCategoryCard(
          theme,
          'Pressure',
          Icons.trending_up_rounded,
          theme.golfPrimary,
          6,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    int sessionCount,
  ) {
    return FoCoCoCard(
      onTap: () => _showCategory(title),
      style: FoCoCoCardStyle.standard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: theme.titleSmall.override(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '$sessionCount sessions',
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Progress Tab
  Widget _buildProgressTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress
          Text(
            'Your Progress',
            style: theme.headlineSmall.override(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Progress overview cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              PerformanceMetricCard(
                title: 'Sessions',
                value: '24',
                unit: 'completed',
                percentage: 75.0,
                icon: Icons.self_improvement_rounded,
                primaryColor: theme.coachingPrimary,
                trend: '+3 this week',
              ),
              PerformanceMetricCard(
                title: 'Streak',
                value: '7',
                unit: 'days',
                percentage: 70.0,
                icon: FontAwesomeIcons.fire,
                primaryColor: theme.streakActive,
                trend: 'Best: 12 days',
              ),
              PerformanceMetricCard(
                title: 'Focus Score',
                value: '8.2',
                unit: '/10',
                percentage: 82.0,
                icon: Icons.center_focus_strong_rounded,
                primaryColor: theme.mentalFocus,
                trend: '+0.8 this month',
              ),
              PerformanceMetricCard(
                title: 'Confidence',
                value: '7.6',
                unit: '/10',
                percentage: 76.0,
                icon: Icons.emoji_emotions_rounded,
                primaryColor: theme.mindfulnessPrimary,
                trend: '+1.2 this month',
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Recent achievements
          Text(
            'Recent Achievements',
            style: theme.titleMedium.override(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  width: 160,
                  child: AchievementBadge(
                    title: 'Mindful Golfer',
                    description: 'Completed 20 mindfulness sessions',
                    icon: Icons.self_improvement_rounded,
                    tier: AchievementTier.gold,
                    isEarned: true,
                    earnedDate: DateTime.now().subtract(const Duration(days: 2)),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: AchievementBadge(
                    title: 'Consistency King',
                    description: 'Maintained 7-day streak',
                    icon: FontAwesomeIcons.fire,
                    tier: AchievementTier.silver,
                    isEarned: true,
                    earnedDate: DateTime.now().subtract(const Duration(days: 1)),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: AchievementBadge(
                    title: 'Focus Master',
                    description: 'Achieve 9+ focus score',
                    icon: Icons.center_focus_strong_rounded,
                    tier: AchievementTier.bronze,
                    isEarned: false,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // AI insights
          AIInsightCard(
            title: 'Mental Training Insights',
            insight: 'Your breathing exercises are improving your focus scores significantly. Continue the pre-round breathing routine for optimal results.',
            sentiment: 'positive',
            recommendations: [
              'Extend breathing sessions to 8 minutes',
              'Try advanced visualization techniques',
              'Practice pressure scenarios',
            ],
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
            aiModel: 'Mental Coach AI',
            onFeedback: () {
              // Handle feedback
            },
          ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Enhanced Bottom Navigation
  Widget _buildEnhancedBottomNav(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(theme, Icons.home_rounded, 'Home', 'dashboard', false),
              _buildNavItem(theme, FontAwesomeIcons.golfBall, 'Rounds', 'golf_rounds', false),
              _buildNavItem(theme, Icons.psychology_rounded, 'Train', 'coaching_modules', true),
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
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? theme.sereneGradient : null,
          borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 8),
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
  void _showSkillDetails(String title, int level, int maxLevel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Level $level of $maxLevel',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: FlutterFlowTheme.of(context).secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Continue Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(String sessionName) {
    // TODO: Implement session start
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Starting Session'),
        content: Text('$sessionName session will begin soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCategory(String category) {
    // TODO: Navigate to category page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category),
        content: Text('Browse $category sessions coming soon!'),
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