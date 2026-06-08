import 'dart:async';

import 'package:flutter/material.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'dart:math' as math;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/app_session_prefs_service.dart';
import '/services/boot_phase_logger.dart';
import '/services/startup_auth_service.dart';
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
      duration: const Duration(seconds: 6), // Doubled for 2 rotations
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
      end: 4 * math.pi, // Two full rotations
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
    if (!mounted) return;
    _scaleController.forward();

    // Start rotation animation (2 full rotations)
    _rotationController.forward();
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
      decoration: const BoxDecoration(
        color: Colors.black,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rotating logo container
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(12),
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
                                    'assets/images/logo/Logo.png',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                        child: const Icon(
                                          Icons.golf_course,
                                          size: 56,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // App tagline
                        Text(
                          'FoCoCo',
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
                          'Your Mind Powers the Game',
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
    unawaited(BootPhaseLogger.record('splash_navigation_started'));
    try {
      if (kDebugMode) {
        print('🔄 Enhanced Splash: Checking user authentication...');
      }

      final authBootstrapFuture = StartupAuthService.instance.bootstrap();

      // Wait a minimum time to show the beautiful animation
      await Future.delayed(const Duration(milliseconds: 2500));
      await authBootstrapFuture.timeout(const Duration(seconds: 2),
          onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Enhanced Splash: auth bootstrap wait timed out');
        }
      });

      if (!mounted) return;

      // Always read auth state after the animation + bootstrap wait.
      final user = currentUser;

      if (user != null && user.loggedIn) {
        if (kDebugMode) {
          print(
              '✅ Enhanced Splash: User logged in, routing to default tab (deferred paywall check)');
        }
        // CRITICAL: do NOT call AuthFlowService.resolvePostAuthDecision() here.
        // That method reads + writes the user doc in Firestore, which on iOS
        // during the launch window triggers the native gRPC
        // `std::__libcpp_condvar_wait` crash. Instead, route to the default
        // tab immediately. The paywall / onboarding gate can be evaluated
        // from the destination screen after the app is fully warmed up.
        unawaited(
            BootPhaseLogger.record('splash_routing_to_authed_landing'));
        AppStateNotifier.instance.stopShowingSplashImage();
        final tab = await AppSessionPrefsService.postLoginTab();
        if (!mounted) return;
        context.goNamed(tab);
      } else {
        if (kDebugMode) {
          print('✅ Enhanced Splash: User not logged in, navigating to login');
        }
        unawaited(BootPhaseLogger.record('splash_routing_to_login'));
        AppStateNotifier.instance.stopShowingSplashImage();
        context.go('/login');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Enhanced Splash: Error during navigation: $e');
      }
      // Capture splash navigation failures explicitly — these were previously
      // swallowed and silently rerouted to /login, hiding the real cause of
      // TestFlight launch crashes.
      unawaited(BootPhaseLogger.record('splash_navigation_failed'));
      try {
        await BootPhaseLogger.setCustomKey(
            'splash_navigation_error', e.toString());
      } catch (_) {}
      // Surface to PlatformDispatcher.onError so it lands in Crashlytics with
      // a stack — runZonedGuarded in main.dart will catch it.
      Future<void>.error(e, stack);
      if (mounted) {
        AppStateNotifier.instance.stopShowingSplashImage();
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen(
      // Duration must be null when using asyncNavigationCallback
      duration: null,
      backgroundColor: Colors.black,
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
