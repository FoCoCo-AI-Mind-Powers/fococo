import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  late DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
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
          child: SingleChildScrollView(
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 40, 24, 32),
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
                                  'Welcome back,',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 16,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUserDisplayName.isNotEmpty 
                                    ? currentUserDisplayName 
                                    : 'Champion',
                                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () => context.goNamed('profile'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Current Streak Card
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
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Streak',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '7',
                                          style: FlutterFlowTheme.of(context).displaySmall.override(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'days',
                                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                                            fontFamily: 'Inter',
                                            color: Colors.white70,
                                            fontSize: 16,
                                            height: 1.0,
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
                    ),
                  ),
                ),
                
                // Quick Actions
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Inter',
                          color: const Color(0xFF0B4D2C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              icon: FontAwesomeIcons.golfBall,
                              title: 'Track Round',
                              subtitle: 'Log your game',
                              color: const Color(0xFF2E8B57),
                              onTap: () => context.goNamed('golf_rounds'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              icon: Icons.psychology_outlined,
                              title: 'Mental Training',
                              subtitle: 'Practice focus',
                              color: const Color(0xFF6B46C1),
                              onTap: () => context.goNamed('coaching_modules'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              icon: Icons.insights_outlined,
                              title: 'AI Insights',
                              subtitle: 'Get analysis',
                              color: const Color(0xFFFF6B35),
                              onTap: () => context.goNamed('ai_insights'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              icon: Icons.trending_up_outlined,
                              title: 'Progress',
                              subtitle: 'View stats',
                              color: const Color(0xFF059669),
                              onTap: () => context.goNamed('progress'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Recent Activity
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                              fontFamily: 'Inter',
                              color: const Color(0xFF0B4D2C),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.goNamed('progress'),
                            child: Text(
                              'View All',
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: const Color(0xFF2E8B57),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Activity List
                      _buildActivityItem(
                        context,
                        icon: FontAwesomeIcons.golfBall,
                        title: 'Round at Pebble Beach',
                        subtitle: 'Score: 78 • 2 hours ago',
                        iconColor: const Color(0xFF2E8B57),
                      ),
                      _buildActivityItem(
                        context,
                        icon: Icons.psychology_outlined,
                        title: 'Visualization Training',
                        subtitle: 'Completed • Yesterday',
                        iconColor: const Color(0xFF6B46C1),
                      ),
                      _buildActivityItem(
                        context,
                        icon: Icons.emoji_events_outlined,
                        title: 'Achievement Unlocked',
                        subtitle: 'Consistency Master • 2 days ago',
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
                
                // Bottom padding
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        
        // Bottom Navigation Bar
        bottomNavigationBar: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, Icons.home, 'Home', true, () {}),
              _buildNavItem(context, FontAwesomeIcons.golfBall, 'Rounds', false, () => context.goNamed('golf_rounds')),
              _buildNavItem(context, Icons.psychology_outlined, 'Train', false, () => context.goNamed('coaching_modules')),
              _buildNavItem(context, Icons.insights_outlined, 'Insights', false, () => context.goNamed('ai_insights')),
              _buildNavItem(context, Icons.person_outline, 'Profile', false, () => context.goNamed('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 20),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
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
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF0B4D2C) : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: isActive ? const Color(0xFF0B4D2C) : Colors.grey[400],
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 