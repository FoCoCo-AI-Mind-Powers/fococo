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
        body: FoCoCoAnimatedGradientBackground(
          gradientType: GradientType.primary,
          opacity: 0.3,
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            decoration: BoxDecoration(
              gradient: theme.primaryBrandGradient,
            ),
            child: SafeArea(
              top: true,
              bottom: false, // Let container go to bottom
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
                          // App Logo - Updated with new FoCoCoLogo component
                          Flexible(
                            child: FoCoCoLogo(
                              size: LogoSize.large, // Reduced from extraLarge
                              showText: true,
                              animated: true,
                              color: Colors.white,
                            ),
                          ),
                          
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Responsive spacing
                          
                          // Tagline
                          Flexible(
                            child: Text(
                              'Focus • Confidence • Control',
                              style: theme.bodyLarge.override(
                                fontFamily: 'Inter',
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                letterSpacing: 1.2,
                                height: 1.0,
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.01), // Responsive spacing
                          
                          Flexible(
                            child: Text(
                              'Master Your Mental Game',
                              style: theme.bodyMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.0,
                              ),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
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
                              child: Column(
                                children: [
                                  // Handle bar
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Title
                                  Text(
                                    _isExpanded ? 'Welcome Back' : 'Sign In',
                                    style: theme.headlineMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF0B4D2C),
                                      fontSize: _isExpanded ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                  
                                  if (!_isExpanded) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to continue',
                                      style: theme.bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Icon(
                                      Icons.keyboard_arrow_up,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                  ],
                                  
                                  if (_isExpanded) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Sign in to continue your mental game journey',
                                            textAlign: TextAlign.center,
                                            style: theme.bodyMedium.override(
                                              fontFamily: 'Inter',
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
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
                                      // Sign in description
                                      Text(
                                        'Sign in to continue your mental game journey',
                                        textAlign: TextAlign.center,
                                        style: theme.bodyMedium.override(
                                          fontFamily: 'Inter',
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      
                                      // Google Sign In Button
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withValues(alpha: 0.1),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
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
                                                // Handle Google Sign In errors gracefully
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
                                                // Google Logo
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
                                                    color: Colors.grey.shade700,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
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
                                              // Handle Apple Sign In errors gracefully
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
                                              style: theme.bodyMedium.override(
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
                                          textStyle: theme.titleMedium.override(
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
                                      
                                      const SizedBox(height: 40),
                                      
                                      // Terms and Privacy
                                      Text(
                                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                                        textAlign: TextAlign.center,
                                        style: theme.bodySmall.override(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
