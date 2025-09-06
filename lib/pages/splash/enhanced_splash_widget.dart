import 'package:flutter/material.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'dart:math' as math;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/foundation.dart';

class EnhancedSplashWidget extends StatefulWidget {
  const EnhancedSplashWidget({super.key});

  @override
  State<EnhancedSplashWidget> createState() => _EnhancedSplashWidgetState();
}

class _EnhancedSplashWidgetState extends State<EnhancedSplashWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create animations
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start fade in
    _fadeController.forward();

    // Wait a bit then start scale
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    // Start continuous rotation (wind power effect)
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Custom splash screen body with your existing animations
  Widget _buildCustomSplashBody() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary,
            theme.secondary,
            theme.tertiary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated background particles (wind effect)
          ...List.generate(20, (index) => _buildWindParticle(index)),

          // Main logo container
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _scaleAnimation,
                _rotationAnimation,
              ]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rotating logo container
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo/FoCoCo Logo Wihtout Title.png',
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                      ),
                                      child: const Icon(
                                        Icons.golf_course,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // App tagline
                        Text(
                          'Focus. Confidence. Control.',
                          style: theme.headlineMedium.override(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Master Your Mental Game',
                          style: theme.bodyLarge.override(
                            fontFamily: 'Inter',
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Loading indicator
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 4.0;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final progress = (_rotationController.value + (index * 0.1)) % 1.0;
        final top = MediaQuery.of(context).size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white
                  .withValues(alpha: 0.3 + random.nextDouble() * 0.4),
            ),
          ),
        );
      },
    );
  }

  // Navigation logic to determine next screen
  Future<void> _handleNavigation() async {
    try {
      // Check authentication state
      final user = currentUser;

      if (kDebugMode) {
        print('🔄 Enhanced Splash: Checking user authentication...');
      }

      // Wait a minimum time to show the beautiful animation
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      if (user != null && user.loggedIn) {
        if (kDebugMode) {
          print('✅ Enhanced Splash: User logged in, navigating to dashboard');
        }
        context.go('/dashboard');
      } else {
        if (kDebugMode) {
          print('✅ Enhanced Splash: User not logged in, navigating to home');
        }
        context.go('/home');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Enhanced Splash: Error during navigation: $e');
      }
      // Fallback navigation
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen(
      // Duration must be null when using asyncNavigationCallback
      duration: null,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      splashScreenBody: _buildCustomSplashBody(),
      asyncNavigationCallback: _handleNavigation,
      onInit: () {
        if (kDebugMode) {
          print('🚀 Enhanced Splash Screen initialized');
        }
      },
      onEnd: () {
        if (kDebugMode) {
          print('🏁 Enhanced Splash Screen ended');
        }
      },
    );
  }
}
