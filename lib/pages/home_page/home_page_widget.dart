import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'home_page';
  static String routePath = '/home_page';

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
    final theme = FlutterFlowTheme.of(context);
    
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: FoCoCoAnimatedGradientBackground(
          gradientType: GradientType.primary,
          opacity: 0.05,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: theme.primaryBrandGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
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
                                  'Welcome to',
                                  style: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Use the new FoCoCoLogo component
                                FoCoCoLogo(
                                  size: LogoSize.large,
                                  showText: true,
                                  color: Colors.white,
                                  animated: false,
                                ),
                              ],
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => context.goNamed('login'),
                                icon: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
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
                        FontAwesomeIcons.golfBallTee,
                        theme.golfPrimary,
                        () {
                          context.goNamed('golf_rounds');
                        },
                      ),
                      
                      _buildFeatureCard(
                        'Mental Training',
                        'Access personalized mental coaching modules to improve focus, confidence, and performance.',
                        Icons.psychology_outlined,
                        theme.coachingPrimary,
                        () {
                          context.goNamed('coaching_modules');
                        },
                      ),
                      
                      _buildFeatureCard(
                        'AI Insights',
                        'Get AI-powered analysis of your game with personalized recommendations for improvement.',
                        Icons.auto_awesome,
                        theme.aiPrimary,
                        () {
                          context.goNamed('ai_insights');
                        },
                      ),
                      
                      _buildFeatureCard(
                        'Progress Analytics',
                        'View detailed analytics and track your improvement over time with comprehensive reports.',
                        Icons.trending_up_outlined,
                        theme.performanceExcellent,
                        () {
                          context.goNamed('progress');
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
                              color: const Color(0xFF0B4D2C).withValues(alpha: 0.3),
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
    final theme = FlutterFlowTheme.of(context);
    
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
            boxShadow: [
              theme.activityCardShadow,
            ],
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: FlutterFlowTheme.iconSizeXL + 8,
                height: FlutterFlowTheme.iconSizeXL + 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusXL),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: FlutterFlowTheme.iconSizeL,
                ),
              ),
              SizedBox(width: FlutterFlowTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium.override(
                        fontFamily: 'Montserrat',
                        color: theme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: FlutterFlowTheme.spacingS),
                    Text(
                      description,
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: theme.secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
