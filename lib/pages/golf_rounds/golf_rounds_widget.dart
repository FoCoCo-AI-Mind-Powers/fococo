import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GolfRoundsModel());
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
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B4D2C), Color(0xFF2E8B57)],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(-1.0, -1.0),
                    end: AlignmentDirectional(1.0, 1.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Golf Rounds',
                                style: FlutterFlowTheme.of(context).headlineMedium.override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                              onPressed: () {
                                // Navigate to add round screen
                                _showAddRoundBottomSheet(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Avg Score',
                              '78.5',
                              Icons.trending_down,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Best Round',
                              '72',
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total Rounds',
                              '24',
                              FontAwesomeIcons.golfBall,
                              Colors.blue,
                            ),
                          ),
                        ],
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
                          labelColor: const Color(0xFF0B4D2C),
                          unselectedLabelColor: Colors.white70,
                          labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                          tabs: const [
                            Tab(text: 'Recent'),
                            Tab(text: 'Stats'),
                            Tab(text: 'Progress'),
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
                    // Recent Rounds Tab
                    _buildRecentRoundsTab(),
                    
                    // Stats Tab
                    _buildStatsTab(),
                    
                    // Progress Tab
                    _buildProgressTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: Colors.white70,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoundsTab() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      child: ListView(
        children: [
          _buildRoundCard(
            courseName: 'Pebble Beach Golf Links',
            date: 'Today',
            score: 78,
            par: 72,
            handicap: 12,
            weather: 'Sunny, 72°F',
            mentalScore: 8.5,
          ),
          _buildRoundCard(
            courseName: 'Augusta National',
            date: '2 days ago',
            score: 82,
            par: 72,
            handicap: 12,
            weather: 'Windy, 68°F',
            mentalScore: 7.2,
          ),
          _buildRoundCard(
            courseName: 'St. Andrews Links',
            date: '1 week ago',
            score: 75,
            par: 72,
            handicap: 12,
            weather: 'Overcast, 65°F',
            mentalScore: 9.1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      child: ListView(
        children: [
          _buildStatSection('Scoring', [
            _buildStatRow('Average Score', '78.5', '+2.3 vs par'),
            _buildStatRow('Best Round', '72', 'Even par'),
            _buildStatRow('Worst Round', '89', '+17 vs par'),
            _buildStatRow('Under Par Rounds', '3', '12.5% of rounds'),
          ]),
          const SizedBox(height: 24),
          _buildStatSection('Mental Game', [
            _buildStatRow('Avg Mental Score', '8.2/10', '+0.5 this month'),
            _buildStatRow('Focus Rating', '8.7/10', 'Excellent'),
            _buildStatRow('Confidence', '7.8/10', 'Good'),
            _buildStatRow('Pressure Handling', '8.1/10', 'Very Good'),
          ]),
          const SizedBox(height: 24),
          _buildStatSection('Course Management', [
            _buildStatRow('Fairways Hit', '65%', '+5% this month'),
            _buildStatRow('Greens in Regulation', '58%', '+8% this month'),
            _buildStatRow('Putting Average', '1.87', '-0.13 this month'),
            _buildStatRow('Recovery Shots', '72%', '+12% this month'),
          ]),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      child: ListView(
        children: [
          // Progress Chart Placeholder
          Container(
            height: 200,
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Color(0xFF0B4D2C)),
                  SizedBox(height: 16),
                  Text(
                    'Score Progress Chart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B4D2C),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Visual progress tracking coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Achievements Section
          _buildAchievementsSection(),
        ],
      ),
    );
  }

  Widget _buildRoundCard({
    required String courseName,
    required String date,
    required int score,
    required int par,
    required int handicap,
    required String weather,
    required double mentalScore,
  }) {
    final scoreToPar = score - par;
    final scoreColor = scoreToPar <= 0 ? Colors.green : scoreToPar <= 5 ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'Inter',
                    color: scoreColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildRoundStat('To Par', '${scoreToPar > 0 ? '+' : ''}$scoreToPar'),
              ),
              Expanded(
                child: _buildRoundStat('Handicap', '$handicap'),
              ),
              Expanded(
                child: _buildRoundStat('Mental', '${mentalScore.toStringAsFixed(1)}/10'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.wb_sunny, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                weather,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
            fontFamily: 'Inter',
            color: Colors.grey[600],
            fontSize: 12,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String change) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      child: Row(
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
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              Text(
                change,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Achievements',
            style: FlutterFlowTheme.of(context).headlineSmall.override(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementItem(
            'Consistency Master',
            'Played 5 rounds within 3 strokes',
            Icons.emoji_events,
            Colors.amber,
          ),
          _buildAchievementItem(
            'Mental Warrior',
            'Maintained focus for entire round',
            Icons.psychology,
            Colors.purple,
          ),
          _buildAchievementItem(
            'Course Conqueror',
            'Played 3 different courses this month',
            FontAwesomeIcons.flag,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                    fontSize: 14,
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

  void _showAddRoundBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Round',
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Add Round Form Coming Soon',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 