import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/services/biometric_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
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
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final BiometricAuthService _biometricService = BiometricAuthService();

  // Nature Animation Controllers
  AnimationController? _natureController;
  AnimationController? _particleController;
  AnimationController? _waveController;
  AnimationController? _breathingController;

  // Nature Animations
  Animation<double>? _natureAnimation;
  Animation<double>? _particleAnimation;
  Animation<double>? _waveAnimation;
  Animation<double>? _breathingAnimation;

  // Biometric state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricName = 'Biometric';
  bool _isCheckingBiometric = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    // Initialize Nature Animation Controllers
    _natureController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Initialize Animations
    _natureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _natureController!,
      curve: Curves.easeInOutSine,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController!,
      curve: Curves.linear,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController!,
      curve: Curves.easeInOutSine,
    ));

    _breathingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController!,
      curve: Curves.easeInOutSine,
    ));

    // Start animations
    _natureController?.repeat();
    _particleController?.repeat();
    _waveController?.repeat();
    _breathingController?.repeat(reverse: true);

    // Check biometric availability
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _natureController?.dispose();
    _particleController?.dispose();
    _waveController?.dispose();
    _breathingController?.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final status = await _biometricService.getBiometricStatus();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = status['isAvailable'] ?? false;
          _isBiometricEnabled = status['isEnabled'] ?? false;
          _biometricName = status['biometricName'] ?? 'Biometric';
        });
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isCheckingBiometric) return;

    setState(() {
      _isCheckingBiometric = true;
    });

    try {
      final String? email = await _biometricService.authenticateForLogin();

      if (email != null) {
        // Biometric authentication successful, sign in the user
        GoRouter.of(context).prepareAuthEvent();

        // For biometric login, we need to handle this differently since we don't have password
        // We'll assume the user is already authenticated via biometric and redirect
        context.goNamedAuth('dashboard', context.mounted);
      } else {
        _showErrorSnackBar(
            '${_biometricName} authentication failed or cancelled');
      }
    } catch (e) {
      _showErrorSnackBar(
          '${_biometricName} authentication error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingBiometric = false;
        });
      }
    }
  }

  Future<void> _showPasswordRecoveryDialog() async {
    final TextEditingController emailController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1B5E20).withValues(alpha: 0.2),
                              const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Color(0xFF1B5E20),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                            ),
                            Text(
                              'Enter your email to receive reset instructions',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF2E7D32),
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Email Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF2E7D32),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: const Color(0xFF1B5E20),
                            height: 1.4,
                          ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Inter',
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) {
                              _showErrorSnackBar(
                                  'Please enter your email address');
                              return;
                            }

                            Navigator.of(context).pop();

                            try {
                              await authManager.resetPassword(
                                email: email,
                                context: context,
                              );
                            } catch (e) {
                              _showErrorSnackBar(
                                  'Failed to send reset email. Please try again.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Send Reset Link',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: Container(
          width: screenWidth,
          height: screenHeight,
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
              // Animated Nature Background - Forest & Mountain Layers
              if (_natureAnimation != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _natureAnimation!,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: AnimatedNatureBackgroundPainter(
                          animation: _natureAnimation!.value,
                          theme: theme,
                        ),
                      );
                    },
                  ),
                ),

              // Animated Ocean Waves
              if (_waveAnimation != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveAnimation!,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: AnimatedOceanWavesPainter(
                          animation: _waveAnimation!.value,
                          theme: theme,
                        ),
                      );
                    },
                  ),
                ),

              // Floating Nature Particles
              if (_particleAnimation != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particleAnimation!,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: AnimatedNatureParticlesPainter(
                          animation: _particleAnimation!.value,
                          theme: theme,
                        ),
                      );
                    },
                  ),
                ),

              // Breathing Sky Gradient Overlay
              if (_breathingAnimation != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _breathingAnimation!,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.natureSky.withValues(
                                  alpha: 0.1 +
                                      (0.05 * _breathingAnimation!.value)),
                              Colors.transparent,
                              theme.natureForest.withValues(
                                  alpha: 0.05 +
                                      (0.03 * _breathingAnimation!.value)),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Enhanced Golf course pattern overlay with subtle animation
              if (_natureAnimation != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _natureAnimation!,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: EnhancedGolfCoursePatternPainter(
                          animation: _natureAnimation!.value,
                          theme: theme,
                        ),
                      );
                    },
                  ),
                ),

              // Navigation Back Button - Enhanced Glass Style
              Positioned(
                top: safeAreaTop + 16,
                left: 20,
                child: GlassDesignSystem.glass3DCard(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(0),
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      // Go to home page for unauthenticated users
                      context.goNamed('homePage');
                    }
                  },
                  tintColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Main Content - Scrollable to prevent overflow
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: safeAreaTop + 80,
                      bottom: safeAreaBottom + 20,
                    ),
                    child: Column(
                      children: [
                        // Logo Section - FoCoCo Logo Image
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: GlassDesignSystem.glass3DCard(
                                  width: 140,
                                  height: 140,
                                  padding: const EdgeInsets.all(16),
                                  tintColor:
                                      Colors.white.withValues(alpha: 0.15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.1),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/images/logo/FoCoCo - Logo with Title.png',
                                        width: 108,
                                        height: 108,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Tagline - Enhanced Typography
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: GlassDesignSystem.glass3DCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 16),
                                  tintColor:
                                      Colors.white.withValues(alpha: 0.12),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Master Your Mental Game',
                                        textAlign: TextAlign.center,
                                        style: theme.titleMedium.override(
                                          fontFamily: 'Inter',
                                          color: const Color(0xFFFFD54F),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lower Your Score • Elevate Your Mind',
                                        textAlign: TextAlign.center,
                                        style: theme.bodyMedium.override(
                                          fontFamily: 'Inter',
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Main Authentication Card - Enhanced Design
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: GlassDesignSystem.glass3DCard(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  tintColor:
                                      Colors.white.withValues(alpha: 0.95),
                                  child: Column(
                                    children: [
                                      // Header with Enhanced Golf Icon
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF1B5E20)
                                                      .withValues(alpha: 0.15),
                                                  const Color(0xFF2E7D32)
                                                      .withValues(alpha: 0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF1B5E20)
                                                    .withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.golf_course,
                                              color: const Color(0xFF1B5E20),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              'Welcome to the Course',
                                              style:
                                                  theme.headlineSmall.override(
                                                fontFamily: 'Inter',
                                                color: const Color(0xFF1B5E20),
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      Text(
                                        'Sign in to track your progress and lower your handicap',
                                        textAlign: TextAlign.center,
                                        style: theme.bodyMedium.override(
                                          fontFamily: 'Inter',
                                          color: const Color(0xFF2E7D32),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Google Sign In Button
                                      _buildAuthButton(
                                        onTap: () async {
                                          try {
                                            GoRouter.of(context)
                                                .prepareAuthEvent();
                                            final user = await authManager
                                                .signInWithGoogle(context);
                                            if (user == null) return;

                                            context.goNamedAuth(
                                                'dashboard', context.mounted);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Google Sign In failed. Please try again or use another method.'),
                                                backgroundColor:
                                                    Colors.red.shade400,
                                              ),
                                            );
                                          }
                                        },
                                        icon: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  'https://developers.google.com/identity/images/g-logo.png'),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        text: 'Continue with Google',
                                        backgroundColor: Colors.white,
                                        textColor: const Color(0xFF1F1F1F),
                                        theme: theme,
                                      ),

                                      const SizedBox(height: 12),

                                      // Apple Sign In (iOS only)
                                      if (Theme.of(context).platform ==
                                          TargetPlatform.iOS) ...[
                                        _buildAuthButton(
                                          onTap: () async {
                                            try {
                                              GoRouter.of(context)
                                                  .prepareAuthEvent();
                                              final user = await authManager
                                                  .signInWithApple(context);
                                              if (user == null) return;

                                              context.goNamedAuth(
                                                  'dashboard', context.mounted);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Apple Sign In failed. Please try again or use another method.'),
                                                  backgroundColor:
                                                      Colors.red.shade400,
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            FontAwesomeIcons.apple,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          text: 'Continue with Apple',
                                          backgroundColor: Colors.black,
                                          textColor: Colors.white,
                                          theme: theme,
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // Enhanced Divider
                                      _buildDivider(),

                                      const SizedBox(height: 12),

                                      // Biometric Authentication Button (if available and enabled)
                                      if (_isBiometricAvailable &&
                                          _isBiometricEnabled) ...[
                                        _buildAuthButton(
                                          onTap: _authenticateWithBiometric,
                                          icon: _isCheckingBiometric
                                              ? SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : Icon(
                                                  _getBiometricIcon(),
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                          text: _isCheckingBiometric
                                              ? 'Authenticating...'
                                              : 'Sign in with $_biometricName',
                                          backgroundColor:
                                              const Color(0xFF1B5E20),
                                          textColor: Colors.white,
                                          theme: theme,
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // VARK Quiz Button
                                      _buildAuthButton(
                                        onTap: () async {
                                          context.goNamed('vark_onboarding');
                                        },
                                        icon: Icon(
                                          Icons.quiz_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        text: 'Take Learning Style Quiz',
                                        backgroundColor:
                                            const Color(0xFF2E7D32),
                                        textColor: Colors.white,
                                        theme: theme,
                                      ),

                                      const SizedBox(height: 12),

                                      // Email Sign In Button
                                      _buildAuthButton(
                                        onTap: () async {
                                          context.goNamed('register');
                                        },
                                        icon: Icon(
                                          Icons.email_outlined,
                                          color: const Color(0xFF2E7D32),
                                          size: 18,
                                        ),
                                        text: 'Sign in with Email',
                                        backgroundColor: Colors.white,
                                        textColor: const Color(0xFF2E7D32),
                                        theme: theme,
                                      ),

                                      const SizedBox(height: 16),

                                      // Password Recovery Button
                                      InkWell(
                                        onTap: _showPasswordRecoveryDialog,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Text(
                                            'Forgot your password?',
                                            textAlign: TextAlign.center,
                                            style: theme.bodyMedium.override(
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF2E7D32),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Enhanced Terms and Privacy
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1400),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: GlassDesignSystem.glass3DCard(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                tintColor: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.flag,
                                        color: const Color(0xFFFFD54F),
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'By continuing, you agree to play by our Terms of Service and Privacy Policy',
                                        textAlign: TextAlign.center,
                                        style: theme.bodySmall.override(
                                          fontFamily: 'Inter',
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 10,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
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

  // Normal Auth Button Builder
  Widget _buildAuthButton({
    required VoidCallback onTap,
    required Widget icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required FlutterFlowTheme theme,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: backgroundColor.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: backgroundColor == Colors.white ||
                        backgroundColor.computeLuminance() > 0.5
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  text,
                  style: theme.titleMedium.override(
                    fontFamily: 'Inter',
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Divider
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.sports_golf,
              color: const Color(0xFF2E7D32),
              size: 10,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getBiometricIcon() {
    if (_biometricName.toLowerCase().contains('face')) {
      return FontAwesomeIcons.faceSmile;
    } else if (_biometricName.toLowerCase().contains('touch') ||
        _biometricName.toLowerCase().contains('fingerprint')) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }
}

// Enhanced Custom painter for sophisticated golf course pattern with animation
class EnhancedGolfCoursePatternPainter extends CustomPainter {
  final double animation;
  final FlutterFlowTheme theme;

  EnhancedGolfCoursePatternPainter({
    required this.animation,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Animated golf course fairway patterns using theme colors
    final fairwayPaint = Paint()
      ..color = theme.golfFairway.withValues(alpha: 0.08 + (0.02 * animation))
      ..style = PaintingStyle.fill;

    // Draw animated curved fairway patterns
    final animatedOffset = animation * 20;
    final path = Path();
    path.moveTo(0, size.height * 0.7 + animatedOffset);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.5 + (animatedOffset * 0.5),
      size.width * 0.6,
      size.height * 0.8 - animatedOffset,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.9 - (animatedOffset * 0.3),
      size.width,
      size.height * 0.6 + animatedOffset,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, fairwayPaint);

    // Animated green patterns using theme colors
    final greenPaint = Paint()
      ..color = theme.golfGreen.withValues(alpha: 0.06 + (0.02 * animation))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final animatedRadius = 80 + (i * 20) + (animation * 10);
      final center = Offset(
        size.width * (0.2 + i * 0.3) + (animation * 5),
        size.height * (0.3 + i * 0.2) + (animation * 3),
      );
      canvas.drawCircle(center, animatedRadius, greenPaint);
    }

    // Animated flag markers using theme sunset color
    final flagPaint = Paint()
      ..color = theme.natureSunset.withValues(alpha: 0.12 + (0.04 * animation))
      ..style = PaintingStyle.fill;

    // Draw animated flag positions
    final flagPositions = [
      Offset(size.width * 0.15 + (animation * 5), size.height * 0.25),
      Offset(size.width * 0.85 - (animation * 5), size.height * 0.75),
    ];

    for (final pos in flagPositions) {
      final flagPath = Path()
        ..moveTo(pos.dx, pos.dy)
        ..lineTo(pos.dx + 20 + (animation * 5), pos.dy - 10)
        ..lineTo(pos.dx + 20 + (animation * 5), pos.dy + 10)
        ..close();
      canvas.drawPath(flagPath, flagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Floating particles effect painter
class FloatingParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    final particles = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.15),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.85),
    ];

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final radius = 2.0 + (i % 3);
      canvas.drawCircle(particle, radius, particlePaint);
    }

    // Draw subtle connecting lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < particles.length - 1; i++) {
      if (i % 2 == 0) {
        canvas.drawLine(particles[i], particles[i + 1], linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Enhanced Custom painter for golf ball dimples
class GolfBallDimplesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw realistic dimple pattern
    final dimplePositions = [
      const Offset(0.25, 0.25),
      const Offset(0.75, 0.25),
      const Offset(0.5, 0.4),
      const Offset(0.25, 0.75),
      const Offset(0.75, 0.75),
      const Offset(0.4, 0.6),
      const Offset(0.6, 0.6),
    ];

    for (final pos in dimplePositions) {
      canvas.drawCircle(
        Offset(size.width * pos.dx, size.height * pos.dy),
        1.5,
        paint,
      );
    }

    // Add subtle highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated Nature Background Painter - Forest & Mountain Layers
class AnimatedNatureBackgroundPainter extends CustomPainter {
  final double animation;
  final FlutterFlowTheme theme;

  AnimatedNatureBackgroundPainter({
    required this.animation,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Animated Mountain Silhouettes
    final mountainPaint = Paint()
      ..color =
          theme.natureMountain.withValues(alpha: 0.15 + (0.05 * animation))
      ..style = PaintingStyle.fill;

    // Draw animated mountain layers
    final mountainPath1 = Path();
    mountainPath1.moveTo(0, size.height * 0.6);
    mountainPath1.quadraticBezierTo(
      size.width * 0.2 + (animation * 10),
      size.height * 0.4 - (animation * 5),
      size.width * 0.4,
      size.height * 0.5,
    );
    mountainPath1.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.3 + (animation * 8),
      size.width * 0.8 - (animation * 5),
      size.height * 0.45,
    );
    mountainPath1.lineTo(size.width, size.height * 0.5);
    mountainPath1.lineTo(size.width, size.height);
    mountainPath1.lineTo(0, size.height);
    mountainPath1.close();
    canvas.drawPath(mountainPath1, mountainPaint);

    // Animated Forest Layers
    final forestPaint = Paint()
      ..color = theme.natureForest.withValues(alpha: 0.12 + (0.03 * animation))
      ..style = PaintingStyle.fill;

    // Draw animated forest silhouettes
    for (int i = 0; i < 8; i++) {
      final treeX = (size.width / 8) * i + (animation * 15);
      final treeHeight = 40 + (i % 3) * 20 + (animation * 10);
      final treeWidth = 8 + (i % 2) * 4;

      final treePath = Path();
      treePath.moveTo(treeX, size.height * 0.8);
      treePath.lineTo(treeX - treeWidth, size.height * 0.8 - treeHeight);
      treePath.lineTo(treeX + treeWidth, size.height * 0.8 - treeHeight);
      treePath.close();

      canvas.drawPath(treePath, forestPaint);
    }

    // Animated Sunset Glow
    final sunsetPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 0.8,
        colors: [
          theme.natureSunset.withValues(alpha: 0.2 + (0.1 * animation)),
          theme.natureSunset.withValues(alpha: 0.1 + (0.05 * animation)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.6),
      sunsetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animated Ocean Waves Painter
class AnimatedOceanWavesPainter extends CustomPainter {
  final double animation;
  final FlutterFlowTheme theme;

  AnimatedOceanWavesPainter({
    required this.animation,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Animated Ocean Waves
    final wavePaint = Paint()
      ..color = theme.natureOcean.withValues(alpha: 0.08 + (0.04 * animation))
      ..style = PaintingStyle.fill;

    // Draw multiple animated wave layers
    for (int layer = 0; layer < 3; layer++) {
      final waveHeight = 20 + (layer * 10);
      final waveSpeed = 1.0 + (layer * 0.5);
      final animatedPhase = (animation * waveSpeed) * 2 * math.pi;

      final wavePath = Path();
      wavePath.moveTo(0, size.height * 0.85 + (layer * 5));

      for (double x = 0; x <= size.width; x += 5) {
        final waveY = size.height * 0.85 +
            (layer * 5) +
            (waveHeight * 0.5 * (1 + math.sin((x / 50) + animatedPhase)));

        if (x == 0) {
          wavePath.moveTo(x, waveY);
        } else {
          wavePath.lineTo(x, waveY);
        }
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.lineTo(0, size.height);
      wavePath.close();

      canvas.drawPath(wavePath, wavePaint);
    }

    // Animated Water Reflections
    final reflectionPaint = Paint()
      ..color = theme.natureSky.withValues(alpha: 0.05 + (0.02 * animation))
      ..style = PaintingStyle.fill;

    final reflectionPath = Path();
    reflectionPath.moveTo(0, size.height * 0.9);
    reflectionPath.quadraticBezierTo(
      size.width * 0.3 + (animation * 20),
      size.height * 0.85 + (animation * 5),
      size.width * 0.7 - (animation * 15),
      size.height * 0.9,
    );
    reflectionPath.lineTo(size.width, size.height);
    reflectionPath.lineTo(0, size.height);
    reflectionPath.close();

    canvas.drawPath(reflectionPath, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animated Nature Particles Painter
class AnimatedNatureParticlesPainter extends CustomPainter {
  final double animation;
  final FlutterFlowTheme theme;

  AnimatedNatureParticlesPainter({
    required this.animation,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Floating Leaf Particles
    final leafPaint = Paint()
      ..color = theme.natureSecondary.withValues(alpha: 0.3 + (0.2 * animation))
      ..style = PaintingStyle.fill;

    final leafParticles = [
      {'x': 0.1, 'y': 0.2, 'size': 3.0, 'speed': 1.0},
      {'x': 0.3, 'y': 0.15, 'size': 2.5, 'speed': 1.2},
      {'x': 0.7, 'y': 0.3, 'size': 4.0, 'speed': 0.8},
      {'x': 0.9, 'y': 0.25, 'size': 3.5, 'speed': 1.1},
      {'x': 0.2, 'y': 0.8, 'size': 2.0, 'speed': 1.3},
      {'x': 0.8, 'y': 0.85, 'size': 3.0, 'speed': 0.9},
    ];

    for (final particle in leafParticles) {
      final x = size.width * (particle['x'] as double) +
          (animation * (particle['speed'] as double) * 30);
      final y = size.height * (particle['y'] as double) +
          (animation * (particle['speed'] as double) * 20);
      final particleSize = particle['size'] as double;

      // Draw leaf-like shape
      final leafPath = Path();
      leafPath.moveTo(x, y);
      leafPath.quadraticBezierTo(
          x + particleSize, y - particleSize, x + particleSize * 2, y);
      leafPath.quadraticBezierTo(x + particleSize, y + particleSize, x, y);
      leafPath.close();

      canvas.drawPath(leafPath, leafPaint);
    }

    // Floating Pollen Particles
    final pollenPaint = Paint()
      ..color = theme.natureSunset.withValues(alpha: 0.4 + (0.3 * animation))
      ..style = PaintingStyle.fill;

    final pollenParticles = [
      {'x': 0.15, 'y': 0.4, 'size': 1.5, 'speed': 0.7},
      {'x': 0.45, 'y': 0.35, 'size': 1.0, 'speed': 1.0},
      {'x': 0.65, 'y': 0.5, 'size': 2.0, 'speed': 0.6},
      {'x': 0.85, 'y': 0.45, 'size': 1.2, 'speed': 0.9},
      {'x': 0.25, 'y': 0.7, 'size': 1.8, 'speed': 0.8},
      {'x': 0.75, 'y': 0.65, 'size': 1.3, 'speed': 1.1},
    ];

    for (final particle in pollenParticles) {
      final x = size.width * (particle['x'] as double) +
          (animation * (particle['speed'] as double) * 25);
      final y = size.height * (particle['y'] as double) +
          (math.sin(animation * math.pi * 2 * (particle['speed'] as double)) *
              10);
      final particleSize = particle['size'] as double;

      canvas.drawCircle(Offset(x, y), particleSize, pollenPaint);
    }

    // Connecting Nature Lines
    final connectionPaint = Paint()
      ..color = theme.naturePrimary.withValues(alpha: 0.1 + (0.05 * animation))
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw subtle connecting lines between particles
    for (int i = 0; i < leafParticles.length - 1; i++) {
      if (i % 2 == 0) {
        final start = Offset(
          size.width * (leafParticles[i]['x'] as double),
          size.height * (leafParticles[i]['y'] as double),
        );
        final end = Offset(
          size.width * (leafParticles[i + 1]['x'] as double),
          size.height * (leafParticles[i + 1]['y'] as double),
        );

        canvas.drawLine(start, end, connectionPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
