import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
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
                                  'Welcome to',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 16,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'FoCoCo',
                                  style: FlutterFlowTheme.of(context).displayMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  'Focus • Confidence • Control',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                FontAwesomeIcons.golfBall,
                                color: Color(0xFF0B4D2C),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Welcome Message
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
                              Text(
                                'Master Your Mental Game',
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
                                'Transform your golf performance with AI-powered mental coaching, personalized insights, and proven techniques.',
                                textAlign: TextAlign.center,
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
                      ],
                    ),
                  ),
                ),
                
                // Main Features
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Started',
                        style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Inter',
                          color: const Color(0xFF0B4D2C),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Feature Cards
                      _buildFeatureCard(
                        'Track Your Rounds',
                        'Log your golf rounds and track your progress with detailed statistics and insights.',
                        FontAwesomeIcons.golfBall,
                        const Color(0xFF2E8B57),
                        () {
                          // Navigate to golf rounds (when auth system is set up)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Golf rounds tracking coming soon!')),
                          );
                        },
                      ),
                      
                      _buildFeatureCard(
                        'Mental Training',
                        'Access personalized mental coaching modules to improve focus, confidence, and performance.',
                        Icons.psychology_outlined,
                        const Color(0xFF6B46C1),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mental training modules coming soon!')),
                          );
                        },
                      ),
                      
                      _buildFeatureCard(
                        'AI Insights',
                        'Get AI-powered analysis of your game with personalized recommendations for improvement.',
                        Icons.auto_awesome,
                        const Color(0xFFFF6B35),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI insights coming soon!')),
                          );
                        },
                      ),
                      
                      _buildFeatureCard(
                        'Progress Analytics',
                        'View detailed analytics and track your improvement over time with comprehensive reports.',
                        Icons.trending_up_outlined,
                        const Color(0xFF059669),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Progress analytics coming soon!')),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Auth Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B4D2C), Color(0xFF2E8B57)],
                            stops: [0.0, 1.0],
                            begin: AlignmentDirectional(-1.0, 0.0),
                            end: AlignmentDirectional(1.0, 0.0),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: const Color(0xFF0B4D2C).withOpacity(0.3),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Ready to Transform Your Game?',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context).headlineMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Join thousands of golfers who have improved their mental game with FoCoCo.',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: FFButtonWidget(
                                    onPressed: () => context.goNamed('login'),
                                    text: 'Sign In',
                                    options: FFButtonOptions(
                                      height: 48,
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                      color: Colors.white,
                                      textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                        fontFamily: 'Inter',
                                        color: const Color(0xFF0B4D2C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                      ),
                                      elevation: 0,
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FFButtonWidget(
                                    onPressed: () => context.goNamed('login'),
                                    text: 'Get Started',
                                    options: FFButtonOptions(
                                      height: 48,
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                      color: Colors.transparent,
                                      textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                      ),
                                      elevation: 0,
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
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
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
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
      ),
    );
  }
}
