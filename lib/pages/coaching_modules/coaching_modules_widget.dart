import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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

class _CoachingModulesWidgetState extends State<CoachingModulesWidget> {
  late CoachingModulesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CoachingModulesModel());
  }

  @override
  void dispose() {
    _model.dispose();
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
                    colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(-1.0, -1.0),
                    end: AlignmentDirectional(1.0, 1.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 32),
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
                                'Mental Training',
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
                            child: const Icon(
                              Icons.psychology_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Overview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Progress',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  '65% Complete',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: 0.65,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildProgressStat('Modules\nCompleted', '13/20'),
                                _buildProgressStat('Current\nStreak', '5 days'),
                                _buildProgressStat('Avg Score\nImprovement', '+2.3'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content Section
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's Recommended Module
                        Text(
                          'Today\'s Focus',
                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'Inter',
                            color: const Color(0xFF0B4D2C),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFeaturedModule(
                          title: 'Pre-Shot Routine Mastery',
                          description: 'Develop a consistent mental routine for every shot',
                          duration: '12 min',
                          difficulty: 'Intermediate',
                          progress: 0.4,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 32),
                        
                        // Module Categories
                        Text(
                          'Training Categories',
                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'Inter',
                            color: const Color(0xFF0B4D2C),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Category Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildCategoryCard(
                              'Focus & Concentration',
                              '8 modules',
                              Icons.center_focus_strong,
                              const Color(0xFF3B82F6),
                            ),
                            _buildCategoryCard(
                              'Pressure Management',
                              '6 modules',
                              Icons.compress,
                              const Color(0xFFEF4444),
                            ),
                            _buildCategoryCard(
                              'Visualization',
                              '5 modules',
                              Icons.visibility,
                              const Color(0xFF8B5CF6),
                            ),
                            _buildCategoryCard(
                              'Confidence Building',
                              '7 modules',
                              Icons.trending_up,
                              const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Recent Modules
                        Text(
                          'Continue Learning',
                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'Inter',
                            color: const Color(0xFF0B4D2C),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildModuleCard(
                          title: 'Breathing Techniques',
                          description: 'Master your breath for better focus',
                          duration: '8 min',
                          difficulty: 'Beginner',
                          progress: 0.8,
                          isCompleted: false,
                        ),
                        _buildModuleCard(
                          title: 'Mental Rehearsal',
                          description: 'Practice shots in your mind',
                          duration: '15 min',
                          difficulty: 'Advanced',
                          progress: 1.0,
                          isCompleted: true,
                        ),
                        _buildModuleCard(
                          title: 'Dealing with Bad Shots',
                          description: 'Bounce back stronger from mistakes',
                          duration: '10 min',
                          difficulty: 'Intermediate',
                          progress: 0.3,
                          isCompleted: false,
                        ),
                      ],
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

  Widget _buildProgressStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).bodySmall.override(
            fontFamily: 'Inter',
            color: Colors.white70,
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedModule({
    required String title,
    required String description,
    required String duration,
    required String difficulty,
    required double progress,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          stops: const [0.0, 1.0],
          begin: const AlignmentDirectional(-1.0, -1.0),
          end: const AlignmentDirectional(1.0, 1.0),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: color.withOpacity(0.3),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: Colors.white70,
                fontSize: 14,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildModuleInfo(Icons.access_time, duration),
                const SizedBox(width: 16),
                _buildModuleInfo(Icons.trending_up, difficulty),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}% Complete',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: Colors.white70,
                fontSize: 12,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: FlutterFlowTheme.of(context).bodySmall.override(
            fontFamily: 'Inter',
            color: Colors.white70,
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Navigate to category details
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                  fontSize: 12, 
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String description,
    required String duration,
    required String difficulty,
    required double progress,
    required bool isCompleted,
  }) {
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted 
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFF6B46C1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF6B46C1),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[500], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: Colors.grey[500],
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.trending_up, color: Colors.grey[500], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        difficulty,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: Colors.grey[500],
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                      minHeight: 4,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 