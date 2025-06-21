import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
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
        backgroundColor: const Color(0xFF0B4D2C), // Golf green primary
        body: SafeArea(
          top: true,
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B4D2C), Color(0xFF2E8B57)], // Dark to medium green
                stops: [0.0, 1.0],
                begin: AlignmentDirectional(0.0, -1.0),
                end: AlignmentDirectional(0.0, 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Logo and Brand Section
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 20,
                                color: Colors.black26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            FontAwesomeIcons.golfBall,
                            color: Color(0xFF0B4D2C),
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // App Name
                        Text(
                          'FoCoCo',
                          style: FlutterFlowTheme.of(context).displayLarge.override(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 48,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Tagline
                        Text(
                          'Focus • Confidence • Control',
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          'Master Your Mental Game',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: Colors.white60,
                            fontSize: 14,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Authentication Section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(32, 48, 32, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Welcome Text
                          Text(
                            'Welcome Back',
                            style: FlutterFlowTheme.of(context).headlineMedium.override(
                              fontFamily: 'Inter',
                              color: const Color(0xFF0B4D2C),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Text(
                            'Sign in to continue your mental game journey',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: Colors.grey[600],
                              fontSize: 16,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Google Sign In Button
                          FFButtonWidget(
                            onPressed: () async {
                              GoRouter.of(context).prepareAuthEvent();
                              final user = await authManager.signInWithGoogle(context);
                              if (user == null) return;
                              
                              context.goNamedAuth('dashboard', context.mounted);
                            },
                            text: 'Continue with Google',
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              color: Colors.white,
                              size: 20,
                            ),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 56,
                              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                              color: const Color(0xFFDB4437),
                              textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                              elevation: 3,
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Apple Sign In Button
                          if (Theme.of(context).platform == TargetPlatform.iOS)
                            FFButtonWidget(
                              onPressed: () async {
                                GoRouter.of(context).prepareAuthEvent();
                                final user = await authManager.signInWithApple(context);
                                if (user == null) return;
                                
                                context.goNamedAuth('dashboard', context.mounted);
                              },
                              text: 'Continue with Apple',
                              icon: const FaIcon(
                                FontAwesomeIcons.apple,
                                color: Colors.white,
                                size: 20,
                              ),
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 56,
                                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                                color: Colors.black,
                                textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                                elevation: 3,
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          
                          if (Theme.of(context).platform == TargetPlatform.iOS)
                            const SizedBox(height: 16),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey[300],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                                child: Text(
                                  'OR',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Sign In Button
                          FFButtonWidget(
                            onPressed: () async {
                              context.goNamed('register');
                            },
                            text: 'Sign in with Email',
                            icon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF0B4D2C),
                              size: 20,
                            ),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 56,
                              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                              color: Colors.transparent,
                              textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Inter',
                                color: const Color(0xFF0B4D2C),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                              elevation: 0,
                              borderSide: const BorderSide(
                                color: Color(0xFF0B4D2C),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Terms and Privacy
                          Text(
                            'By continuing, you agree to our Terms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: Colors.grey[500],
                              fontSize: 12,
                              height: 1.0,
                            ),
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
      ),
    );
  }
}
