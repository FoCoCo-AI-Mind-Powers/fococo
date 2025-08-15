import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';
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

class _LoginWidgetState extends State<LoginWidget>
    with TickerProviderStateMixin {
  late LoginModel _model;
  late AnimationController _animationController;
  bool _isExpanded = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _toggleContainer() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
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
        body: Container(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1B5E20), // Deep forest green
                const Color(0xFF2E7D32), // Golf course green
                const Color(0xFF388E3C), // Lighter golf green
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
          ),
          child: Stack(
            children: [
              // Golf course pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: GolfCoursePatternPainter(),
                ),
              ),
              SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    // Logo and Brand Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Golf ball icon above logo
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.sports_golf,
                                    color: Color(0xFF1B5E20),
                                    size: 32,
                                  ),
                                  // Golf ball dimples effect
                                  CustomPaint(
                                    size: const Size(50, 50),
                                    painter: GolfBallDimplesPainter(),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                            
                            // App Logo
                            Flexible(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 120,
                                width: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                            
                            SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                            
                            // Golf-focused tagline
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Master Your Mental Game',
                                    style: theme.headlineSmall.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFFFFD54F), // Gold accent
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      height: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lower Your Score • Elevate Your Mind',
                                    style: theme.bodyLarge.override(
                                      fontFamily: 'Inter',
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 13,
                                      letterSpacing: 0.8,
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
                    
                    // Dynamic Authentication Section
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isExpanded 
                        ? MediaQuery.of(context).size.height * 0.75 
                        : MediaQuery.of(context).size.height * 0.3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: Column(
                          children: [
                            // Handle bar and tap area
                            GestureDetector(
                              onTap: _toggleContainer,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      const Color(0xFFF5F5F5),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Handle bar
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Title with golf icon
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.golf_course,
                                          color: const Color(0xFF1B5E20),
                                          size: 28,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isExpanded ? 'Welcome to the Course' : 'Tee Off',
                                          style: theme.headlineMedium.override(
                                            fontFamily: 'Inter',
                                            color: const Color(0xFF1B5E20),
                                            fontSize: _isExpanded ? 26 : 24,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (!_isExpanded) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ready to improve your game?',
                                        style: theme.bodyMedium.override(
                                          fontFamily: 'Inter',
                                          color: const Color(0xFF388E3C),
                                          fontSize: 14,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Icon(
                                        Icons.keyboard_arrow_up,
                                        color: const Color(0xFF2E7D32),
                                        size: 24,
                                      ),
                                    ],
                                    
                                    if (_isExpanded) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Sign in to track your progress and lower your handicap',
                                              textAlign: TextAlign.center,
                                              style: theme.bodyMedium.override(
                                                fontFamily: 'Inter',
                                                color: const Color(0xFF388E3C),
                                                fontSize: 15,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF2E7D32)),
                                            onPressed: _toggleContainer,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            
                            // Expanded content
                            if (_isExpanded)
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(32, 0, 32, 48),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 30),
                                        
                                        // Google Sign In Button
                                        Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFF2E7D32),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () async {
                                                try {
                                                  GoRouter.of(context).prepareAuthEvent();
                                                  final user = await authManager.signInWithGoogle(context);
                                                  if (user == null) return;
                                                  
                                                  context.goNamedAuth('dashboard', context.mounted);
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Google Sign In failed. Please try again or use another method.'),
                                                      backgroundColor: Colors.red.shade400,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: const BoxDecoration(
                                                      image: DecorationImage(
                                                        image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Continue with Google',
                                                    style: theme.titleMedium.override(
                                                      fontFamily: 'Inter',
                                                      color: const Color(0xFF1B5E20),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Apple Sign In Button
                                        if (Theme.of(context).platform == TargetPlatform.iOS)
                                          FFButtonWidget(
                                            onPressed: () async {
                                              try {
                                                GoRouter.of(context).prepareAuthEvent();
                                                final user = await authManager.signInWithApple(context);
                                                if (user == null) return;
                                                
                                                context.goNamedAuth('dashboard', context.mounted);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Apple Sign In failed. Please try again or use another method.'),
                                                    backgroundColor: Colors.red.shade400,
                                                  ),
                                                );
                                              }
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
                                              textStyle: theme.titleMedium.override(
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
                                        
                                        // Divider with golf ball
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                thickness: 1,
                                                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.sports_golf,
                                                  color: Color(0xFF2E7D32),
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                thickness: 1,
                                                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Email Sign In Button
                                        FFButtonWidget(
                                          onPressed: () async {
                                            context.goNamed('vark_onboarding');
                                          },
                                          text: 'Take Learning Style Quiz',
                                          icon: const Icon(
                                            Icons.quiz_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 56,
                                            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                            iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                                            color: const Color(0xFF2E7D32),
                                            textStyle: theme.titleMedium.override(
                                              fontFamily: 'Inter',
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              height: 1.0,
                                            ),
                                            elevation: 2,
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            hoverColor: const Color(0xFF1B5E20),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Email Sign In Button (Alternative)
                                        FFButtonWidget(
                                          onPressed: () async {
                                            context.goNamed('register');
                                          },
                                          text: 'Sign in with Email',
                                          icon: const Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFF2E7D32),
                                            size: 20,
                                          ),
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 56,
                                            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                            iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                                            color: Colors.white,
                                            textStyle: theme.titleMedium.override(
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF2E7D32),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              height: 1.0,
                                            ),
                                            elevation: 1,
                                            borderSide: const BorderSide(
                                              color: Color(0xFF2E7D32),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            hoverColor: const Color(0xFFF5F5F5),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 40),
                                        
                                        // Terms and Privacy with golf theme
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.flag,
                                              color: const Color(0xFFFFD54F),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'By continuing, you agree to play by our Terms of Service and Privacy Policy',
                                                textAlign: TextAlign.center,
                                                style: theme.bodySmall.override(
                                                  fontFamily: 'Inter',
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for golf course pattern
class GolfCoursePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    // Draw subtle golf course patterns
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        size.width * 0.8 + (i * 40),
        size.height * 0.2 + (i * 30),
      );
      canvas.drawCircle(offset, 60, paint);
    }
    
    // Draw flag patterns
    final flagPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.3)
        ..lineTo(size.width * 0.15, size.height * 0.25)
        ..lineTo(size.width * 0.15, size.height * 0.35)
        ..close(),
      flagPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for golf ball dimples
class GolfBallDimplesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    // Draw small dimples on the golf ball
    final dimplePositions = [
      const Offset(0.3, 0.3),
      const Offset(0.7, 0.3),
      const Offset(0.5, 0.5),
      const Offset(0.3, 0.7),
      const Offset(0.7, 0.7),
    ];
    
    for (final pos in dimplePositions) {
      canvas.drawCircle(
        Offset(size.width * pos.dx, size.height * pos.dy),
        2,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
