import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'ai_insights_model.dart';
export 'ai_insights_model.dart';

class AiInsightsWidget extends StatefulWidget {
  const AiInsightsWidget({super.key});

  static String routeName = 'ai_insights';
  static String routePath = '/ai_insights';

  @override
  State<AiInsightsWidget> createState() => _AiInsightsWidgetState();
}

class _AiInsightsWidgetState extends State<AiInsightsWidget> with TickerProviderStateMixin {
  late AiInsightsModel _model;
  late TabController _tabController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiInsightsModel());
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _model.dispose();
    _tabController.dispose();
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
        backgroundColor: Colors.grey[50],
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
                  stops: [0.0, 1.0],
                  begin: AlignmentDirectional(-1.0, -1.0),
                  end: AlignmentDirectional(1.0, 1.0),
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
                        Text(
                          'AI Insights',
                          style: FlutterFlowTheme.of(context).headlineMedium.override(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // AI Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Analysis Complete',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Based on your last 10 rounds',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '95%',
                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: const Color(0xFFFF6B35),
                        unselectedLabelColor: Colors.white70,
                        labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                        tabs: const [
                          Tab(text: 'Insights'),
                          Tab(text: 'Tips'),
                          Tab(text: 'Plan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Insights Tab
                  _buildInsightsTab(),
                  
                  // Tips Tab
                  _buildTipsTab(),
                  
                  // Plan Tab
                  _buildPlanTab(),
                ],
              ),
            ),
          ],
        ),
        
        // Creative Bottom Navigation Bar
        bottomNavigationBar: Container(
          height: 85,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B4D2C).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, Icons.home_rounded, 'Home', 'dashboard', false),
              _buildNavItem(context, FontAwesomeIcons.golfBall, 'Rounds', 'golf_rounds', false),
              _buildNavItem(context, Icons.psychology_rounded, 'Train', 'coaching_modules', false),
              _buildNavItem(context, Icons.trending_up_rounded, 'Progress', 'progress', false),
              _buildNavItem(context, Icons.insights_rounded, 'Insights', 'ai_insights', true),
              _buildNavItem(context, Icons.person_rounded, 'Profile', 'profile', false),
            ],
          ),
        ),
      ),
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
          color: isActive ? const Color(0xFF0B4D2C) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF0B4D2C), Color(0xFF2E8B57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0B4D2C).withOpacity(0.3),
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

  Widget _buildInsightsTab() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      child: ListView(
        children: [
          // Performance Overview
          _buildInsightCard(
            title: 'Performance Overview',
            icon: Icons.trending_up,
            color: const Color(0xFF10B981),
            child: Column(
              children: [
                _buildInsightRow('Current Handicap', '12.4', '+0.8 this month', Colors.green),
                const Divider(height: 20),
                _buildInsightRow('Avg Score', '78.5', '-2.3 vs last month', Colors.green),
                const Divider(height: 20),
                _buildInsightRow('Consistency', '85%', '+12% improvement', Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Strengths & Weaknesses
          _buildInsightCard(
            title: 'Strengths & Areas for Improvement',
            icon: Icons.psychology,
            color: const Color(0xFF6366F1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Strengths',
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStrengthItem('Putting', 'Excellent green reading', 92),
                _buildStrengthItem('Mental Game', 'Great under pressure', 88),
                const SizedBox(height: 16),
                Text(
                  'Areas for Improvement',
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWeaknessItem('Driving Accuracy', 'Focus on alignment', 65),
                _buildWeaknessItem('Course Management', 'Better club selection', 72),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // AI Predictions
          _buildInsightCard(
            title: 'AI Predictions',
            icon: Icons.auto_awesome,
            color: const Color(0xFF8B5CF6),
            child: Column(
              children: [
                _buildPredictionItem(
                  'Next Round Score',
                  '76-80',
                  'Based on recent improvement trend',
                  Icons.golf_course,
                ),
                const Divider(height: 20),
                _buildPredictionItem(
                  'Breakthrough Likelihood',
                  'High (78%)',
                  'You\'re close to breaking 75',
                  Icons.star,
                ),
                const Divider(height: 20),
                _buildPredictionItem(
                  'Optimal Practice Focus',
                  'Short Game',
                  'Biggest ROI for score improvement',
                  Icons.flag,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      child: ListView(
        children: [
          _buildTipCard(
            'Pre-Shot Routine Optimization',
            'Your data shows inconsistent pre-shot timing. Try this 15-second routine for better consistency.',
            Icons.access_time,
            Color(0xFF3B82F6),
            ['Take 3 deep breaths', 'Visualize the shot', 'One practice swing', 'Commit and execute'],
          ),
          _buildTipCard(
            'Mental Game Enhancement',
            'Focus on these mental strategies to improve your performance under pressure.',
            Icons.psychology,
            Color(0xFF8B5CF6),
            ['Use positive self-talk', 'Stay in the present', 'Accept bad shots quickly', 'Celebrate good shots'],
          ),
          _buildTipCard(
            'Course Management',
            'Smart decisions can save you 3-5 strokes per round. Follow these principles.',
            Icons.map,
            Color(0xFF10B981),
            ['Play to your strengths', 'Avoid big numbers', 'Take the safe route', 'Know your distances'],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      child: ListView(
        children: [
          // Weekly Plan
          _buildPlanCard(
            'This Week\'s Focus',
            'Personalized practice plan based on your weakest areas',
            [
              _buildPlanItem('Monday', 'Short Game Practice', '30 min', Icons.flag, false),
              _buildPlanItem('Wednesday', 'Mental Training Module', '15 min', Icons.psychology, true),
              _buildPlanItem('Friday', 'Driving Range Session', '45 min', FontAwesomeIcons.golfBall, false),
              _buildPlanItem('Saturday', 'Play a Round', '4 hours', Icons.golf_course, false),
            ],
          ),
          const SizedBox(height: 24),
          
          // Monthly Goals
          _buildGoalsCard(),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, String change, Color changeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.0,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            Text(
              change,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrengthItem(String skill, String description, int score) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                Text(
                  description,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score%',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessItem(String skill, String suggestion, int score) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                Text(
                  suggestion,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score%',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: const Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(String title, String prediction, String explanation, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
              Text(
                explanation,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Text(
          prediction,
          style: FlutterFlowTheme.of(context).bodyLarge.override(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B5CF6),
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(String title, String description, IconData icon, Color color, List<String> tips) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String description, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(String day, String activity, String duration, IconData icon, bool isCompleted) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF10B981) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF10B981) : Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 20,
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
                      day,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: const Color(0xFFFF6B35),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duration,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: Colors.grey[500],
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Goals',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            _buildGoalItem('Break 75', '2/5 rounds under 76', 0.4),
            _buildGoalItem('Mental Training', '12/15 sessions complete', 0.8),
            _buildGoalItem('Consistency', '85% target achieved', 0.85),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String goal, String progress, double percentage) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal,
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              Text(
                '${(percentage * 100).round()}%',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: const Color(0xFFFF6B35),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            progress,
            style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: Colors.grey[600],
              fontSize: 12, 
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
} 