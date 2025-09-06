import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/fococo_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'progress_model.dart';
export 'progress_model.dart';

class ProgressWidget extends StatefulWidget {
  const ProgressWidget({super.key});

  static String routeName = 'progress';
  static String routePath = '/progress';

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget> with TickerProviderStateMixin {
  late ProgressModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProgressModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _model.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).professionalPrimary,
        body: CustomScrollView(
          slivers: [
            // Enhanced SliverAppBar with Strava-inspired design
            SliverAppBar(
              expandedHeight: 320,
              floating: false,
              pinned: true,
              backgroundColor: FlutterFlowTheme.of(context).professionalPrimary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FlutterFlowTheme.of(context).professionalPrimary,
                        FlutterFlowTheme.of(context).aiPrimary,
                      ],
                      stops: const [0.0, 1.0],
                      begin: const AlignmentDirectional(-1.0, -1.0),
                      end: const AlignmentDirectional(1.0, 1.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 60, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress',
                                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                                    fontFamily: 'Montserrat',
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your Mental Game Journey',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Progress Stats with Strava-inspired design
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEnhancedStatCard('Rounds', '12', '+3 this week', Icons.golf_course),
                            _buildEnhancedStatCard('Avg Score', '78', '-2.3 improvement', Icons.trending_down),
                            _buildEnhancedStatCard('Best', '72', 'Personal best', Icons.emoji_events),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Overall Progress Score
                        WellnessScoreCard(
                          score: 78,
                          title: 'Mental Performance',
                          subtitle: 'Overall wellness score',
                          maxScore: 100,
                          date: DateTime.now(),
                          subScores: {
                            'focus': 82.0,
                            'calm': 76.0,
                            'energy': 85.0,
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Main Content
            SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Performance Analytics Section
                          _buildEnhancedSectionTitle('Performance Analytics', 'Track your improvement over time'),
                          const SizedBox(height: 16),
                          _buildProgressChart(),
                          
                          const SizedBox(height: 32),
                          
                          // Skills Development Section
                          _buildEnhancedSectionTitle('Skills Development', 'Master each aspect of your mental game'),
                          const SizedBox(height: 16),
                          _buildEnhancedSkillsProgress(),
                          
                          const SizedBox(height: 32),
                          
                          // Achievements & Badges Section
                          _buildEnhancedSectionTitle('Achievements & Badges', 'Celebrate your milestones'),
                          const SizedBox(height: 16),
                          _buildEnhancedAchievements(),
                          
                          const SizedBox(height: 32),
                          
                          // Progress Insights Section
                          _buildEnhancedSectionTitle('Progress Insights', 'AI-powered analysis of your journey'),
                          const SizedBox(height: 16),
                          _buildProgressInsights(),
                          
                          // Bottom padding for nav bar
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
        
        // Enhanced Bottom Navigation Bar
        bottomNavigationBar: FoCoCoAnimatedBottomNavBar(
          currentRoute: 'progress',
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(String label, String value, String change, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          Text(
            label,
            style: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'Inter',
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: FlutterFlowTheme.of(context).labelSmall.override(
              fontFamily: 'Inter',
              color: FlutterFlowTheme.of(context).statusActive,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Inter',
            color: Colors.white70,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    return FoCoCoCard(
      style: FoCoCoCardStyle.standard,
      child: Container(
        width: double.infinity,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: FlutterFlowTheme.of(context).aiPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Score Trend Chart',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive chart with your progress over time',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSkillsProgress() {
    final skills = [
      {'name': 'Mental Focus', 'progress': 0.85, 'icon': Icons.psychology_rounded, 'color': FlutterFlowTheme.of(context).mentalFocus},
      {'name': 'Confidence', 'progress': 0.72, 'icon': Icons.emoji_events, 'color': FlutterFlowTheme.of(context).aiPrimary},
      {'name': 'Consistency', 'progress': 0.68, 'icon': Icons.trending_up, 'color': FlutterFlowTheme.of(context).performanceGood},
      {'name': 'Pressure Handling', 'progress': 0.75, 'icon': Icons.compress, 'color': FlutterFlowTheme.of(context).aiPrimary},
    ];

    return Column(
      children: skills.map((skill) => _buildEnhancedSkillCard(skill)).toList(),
    );
  }

  Widget _buildEnhancedSkillCard(Map<String, dynamic> skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FoCoCoCard(
        style: FoCoCoCardStyle.standard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (skill['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    skill['icon'],
                    color: skill['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill['name'],
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level ${((skill['progress'] as double) * 10).toInt()}',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Inter',
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${((skill['progress'] as double) * 100).toInt()}%',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Montserrat',
                    color: skill['color'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CircularPercentIndicator(
              percent: skill['progress'] as double,
              radius: 60,
              lineWidth: 8,
              backgroundColor: FlutterFlowTheme.of(context).accent4,
              progressColor: skill['color'],
              center: Text(
                '${((skill['progress'] as double) * 100).toInt()}%',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAchievements() {
    return Column(
      children: [
        _buildEnhancedAchievementCard(
          'Consistency Master',
          'Played 5 rounds in a row',
          Icons.emoji_events,
          const Color(0xFFFFD700),
          'Gold',
          true,
        ),
        _buildEnhancedAchievementCard(
          'Focus Champion',
          'Maintained focus for 18 holes',
          Icons.psychology_rounded,
          const Color(0xFFC0C0C0),
          'Silver',
          true,
        ),
        _buildEnhancedAchievementCard(
          'Pressure Player',
          'Performed under pressure',
          Icons.compress,
          const Color(0xFFCD7F32),
          'Bronze',
          false,
        ),
      ],
    );
  }

  Widget _buildEnhancedAchievementCard(String title, String description, IconData icon, Color color, String tier, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FoCoCoCard(
        style: FoCoCoCardStyle.standard,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isUnlocked ? color : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isUnlocked ? color : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? FlutterFlowTheme.of(context).primaryText : Colors.grey,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tier,
                          style: FlutterFlowTheme.of(context).labelSmall.override(
                            fontFamily: 'Inter',
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: isUnlocked ? FlutterFlowTheme.of(context).secondaryText : Colors.grey,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              )
            else
              Icon(
                Icons.lock_outlined,
                color: Colors.grey,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInsights() {
    return Column(
      children: [
        AIInsightCard(
          title: 'Weekly Progress Analysis',
          content: 'Your mental game consistency has improved by 15% this week. Focus training is showing great results, especially your ability to maintain concentration during challenging situations.',
          insight: 'Your mental game consistency has improved by 15% this week. Focus training is showing great results, especially your ability to maintain concentration during challenging situations.',
          sentiment: 'positive',
          recommendations: [
            'Continue with daily visualization exercises',
            'Practice pressure scenarios during training',
            'Log your mental state after each round',
          ],
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          aiModel: 'Progress AI',
        ),
        const SizedBox(height: 16),
        FoCoCoCard(
          style: FoCoCoCardStyle.standard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Milestone',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: FlutterFlowTheme.of(context).aiPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achieve Mental Performance Score of 85',
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '7 points to go',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '92%',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Montserrat',
                      color: FlutterFlowTheme.of(context).aiPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.92,
                backgroundColor: FlutterFlowTheme.of(context).accent4,
                valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).aiPrimary),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, String page, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          context.goNamed(page);
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? FlutterFlowTheme.of(context).aiPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).aiPrimary,
                    FlutterFlowTheme.of(context).aiSecondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: FlutterFlowTheme.of(context).aiPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[400],
              size: isActive ? 22 : 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[400],
                fontSize: isActive ? 9 : 8,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 