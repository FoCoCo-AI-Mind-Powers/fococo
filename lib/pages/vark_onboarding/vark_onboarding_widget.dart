import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '/services/store_subscription_service.dart';
import '/services/subscription_state_provider.dart';
import '/services/auth_flow_service.dart';
import 'vark_onboarding_model.dart';
export 'vark_onboarding_model.dart';

class VarkOnboardingWidget extends StatefulWidget {
  const VarkOnboardingWidget({super.key});

  static String routeName = 'vark_onboarding';
  static String routePath = '/vark_onboarding';

  @override
  State<VarkOnboardingWidget> createState() => _VarkOnboardingWidgetState();
}

class _VarkOnboardingWidgetState extends State<VarkOnboardingWidget>
    with TickerProviderStateMixin {
  late VarkOnboardingModel _model;
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _slideController;
  late AnimationController _staggerController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Loading and error states
  bool _isSaving = false;
  bool _isProcessingSubscription = false;

  // Store Subscription Service
  final StoreSubscriptionService _storeService = StoreSubscriptionService();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VarkOnboardingModel());

    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController.forward();
    _loadSavedProgress();
    _initializeInAppPurchase();

    // Start animations for first slide
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _model.currentSlide < 4) {
        _slideController.forward();
        _staggerController.forward();
      }
    });

    // Auto-advance intro slides (0-3) after delay
    _startAutoAdvance();
  }

  void _initializeInAppPurchase() {
    // Initialize store subscription service
    _storeService.initialize();
  }

  Future<void> _handleSubscriptionPurchase(FlutterFlowTheme theme) async {
    if (_model.selectedMembershipPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a membership plan'),
          backgroundColor: theme.error,
        ),
      );
      return;
    }

    // Prevent multiple simultaneous purchase attempts
    if (_isProcessingSubscription) {
      debugPrint('⚠️ Purchase already in progress');
      return;
    }

    try {
      final isMonthly = _model.selectedBillingPeriod == 'monthly';

      setState(() {
        _isProcessingSubscription = true;
      });

      debugPrint(
          '🛒 Starting purchase flow for: ${isMonthly ? "monthly" : "yearly"}');

      // Use store subscription service
      final success = await _storeService.purchaseSubscription(
        isMonthly: isMonthly,
        onSuccess: (purchaseDetails) async {
          debugPrint('✅ Purchase success callback received');
          // Refresh subscription state provider after successful purchase
          try {
            await SubscriptionStateProvider().refreshSubscriptionState();
            debugPrint('✅ Subscription state refreshed after purchase');
          } catch (e) {
            debugPrint('⚠️ Failed to refresh subscription state: $e');
          }

          if (mounted) {
            setState(() {
              _isProcessingSubscription = false;
            });
            _nextSlide();
          }
        },
        onError: (error) {
          debugPrint('❌ Purchase error callback: $error');
          if (mounted) {
            setState(() {
              _isProcessingSubscription = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Purchase failed: $error'),
                backgroundColor: theme.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
      );

      if (!success) {
        debugPrint('❌ Purchase initiation failed');
        if (mounted) {
          setState(() {
            _isProcessingSubscription = false;
          });
        }
      } else {
        debugPrint(
            '✅ Purchase initiated successfully, waiting for store response...');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Purchase error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isProcessingSubscription = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: theme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startAutoAdvance() {
    // Auto-advance intro slides (slides 0-3) after 4 seconds each
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _model.currentSlide < 4) {
        _nextSlide();
        if (_model.currentSlide < 4) {
          _startAutoAdvance();
        }
      }
    });
  }

  @override
  void dispose() {
    _storeService.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_model.currentSlide < _model.totalSlides - 1) {
      _autoSaveProgress();
      // Reset animations for next slide
      _slideController.reset();
      _staggerController.reset();
      setState(() {
        _model.currentSlide++;
      });
      _pageController
          .nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      )
          .then((_) {
        // Start animations for new slide
        if (_model.currentSlide < 4) {
          _slideController.forward();
          _staggerController.forward();
        }
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousSlide() {
    if (_model.currentSlide > 0) {
      setState(() {
        _model.currentSlide--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_model.currentSlide == 17) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _saveUserProfile();
        await _clearLocalStorage();

        if (mounted) {
          final decision =
              await AuthFlowService.instance.resolvePostAuthDecision();
          if (!mounted) return;
          GoRouter.of(context).clearRedirectLocation();
          context.goNamed(decision.routeName, extra: decision.extra);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _saveUserProfile() async {
    if (!loggedIn || currentUserUid.isEmpty) {
      throw Exception('User not logged in');
    }

    // Calculate VARK scores
    _model.varkScores = _model.calculateVARKScores();
    _model.dominantLearningStyle = _model.getDominantStyle();

    final Map<String, dynamic> userData = {
      'dateOfBirth': _model.dateOfBirth?.toIso8601String(),
      'age': _model.getAge(),
      'termsAccepted': _model.termsAccepted,
      'hasParentalPermission': _model.hasParentalPermission,
      'varkScores': _model.varkScores,
      'dominantLearningStyle': _model.dominantLearningStyle,
      'selectedGoal': _model.selectedGoal,
      'selectedMembershipPlan': _model.selectedMembershipPlan,
      'selectedBillingPeriod': _model.selectedBillingPeriod,
      'varkPreferences': VarkPreferencesStruct(
        visual: _model.dominantLearningStyle == 'visual',
        aural: _model.dominantLearningStyle == 'aural',
        readWrite: _model.dominantLearningStyle == 'readWrite',
        kinesthetic: _model.dominantLearningStyle == 'kinesthetic',
      ).toMap(),
      'onboardingCompleted': true,
      'assessmentDate': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUserUid)
        .update(userData);
  }

  Future<void> _autoSaveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('onboarding_current_slide', _model.currentSlide);
      await prefs.setString(
          'onboarding_dob', _model.dateOfBirth?.toIso8601String() ?? '');
      await prefs.setBool('onboarding_terms', _model.termsAccepted);
      await prefs.setBool('onboarding_parental', _model.hasParentalPermission);
      await prefs.setString('onboarding_vark_answers',
          _model.varkAnswers.map((a) => a.toString()).join(','));
      await prefs.setString('onboarding_goal', _model.selectedGoal);
      await prefs.setString(
          'onboarding_membership', _model.selectedMembershipPlan);
      await prefs.setString('onboarding_billing', _model.selectedBillingPeriod);
    } catch (e) {
      print('Auto-save failed: $e');
    }
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('onboarding_current_slide')) {
        setState(() {
          _model.currentSlide = prefs.getInt('onboarding_current_slide') ?? 0;
          final dobStr = prefs.getString('onboarding_dob');
          if (dobStr != null && dobStr.isNotEmpty) {
            _model.dateOfBirth = DateTime.parse(dobStr);
          }
          _model.termsAccepted = prefs.getBool('onboarding_terms') ?? false;
          _model.hasParentalPermission =
              prefs.getBool('onboarding_parental') ?? false;
          final answersStr = prefs.getString('onboarding_vark_answers');
          if (answersStr != null && answersStr.isNotEmpty) {
            _model.varkAnswers = answersStr
                .split(',')
                .where((s) => s.isNotEmpty)
                .map((s) => int.tryParse(s) ?? 0)
                .toList();
          }
          _model.selectedGoal = prefs.getString('onboarding_goal') ?? '';
          _model.selectedMembershipPlan =
              prefs.getString('onboarding_membership') ?? '';
          _model.selectedBillingPeriod =
              prefs.getString('onboarding_billing') ?? 'monthly';
        });
        _pageController.jumpToPage(_model.currentSlide);
      }
    } catch (e) {
      print('Error loading saved progress: $e');
    }
  }

  Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith('onboarding_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing local storage: $e');
    }
  }

  // Helper method to build glass card
  Widget _buildGlassCard(FlutterFlowTheme theme, Widget child,
      {EdgeInsets? outerPadding, EdgeInsets? innerPadding}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: outerPadding ?? const EdgeInsets.all(32),
          child: GlassDesignSystem.glassBackground(
            child: Padding(
              padding: innerPadding ?? const EdgeInsets.all(32),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  // Build shooting stars animation (reused from splash screen)
  Widget _buildWindParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 4.0;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;

    // Determine particle color based on theme brightness
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Use opposite color based on theme brightness
    final particleColor = isLight
        ? Colors.black.withValues(alpha: 0.15 + random.nextDouble() * 0.25)
        : Colors.white.withValues(alpha: 0.3 + random.nextDouble() * 0.4);

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + (index * 0.1)) % 1.0;
        final top = MediaQuery.of(context).size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: particleColor,
            ),
          ),
        );
      },
    );
  }

  // Helper: Build persistent FoCoCo logo at top
  Widget _buildPersistentLogo(FlutterFlowTheme theme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/logo/Logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Helper: Build bottom progress indicator content (without Positioned wrapper)
  Widget _buildBottomProgressContent(
      FlutterFlowTheme theme, int currentSlide, int totalSlides) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: GlassDesignSystem.glassBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Slide ${currentSlide + 1} of $totalSlides',
                    style: theme.bodySmall.override(
                      fontFamily: 'Inter',
                      color: theme.secondaryText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  Text(
                    '${((currentSlide + 1) / totalSlides * 100).round()}%',
                    style: theme.bodySmall.override(
                      fontFamily: 'Inter',
                      color: theme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (currentSlide + 1) / totalSlides,
                backgroundColor: theme.secondaryText.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                minHeight: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Build bottom progress indicator (with Positioned wrapper for Stack)
  Widget _buildBottomProgress(
      FlutterFlowTheme theme, int currentSlide, int totalSlides) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 60,
      left: 0,
      right: 0,
      child: SafeArea(
        child: _buildBottomProgressContent(theme, currentSlide, totalSlides),
      ),
    );
  }

  // Slide builders
  Widget _buildSlide1(FlutterFlowTheme theme) {
    // Title animation
    final titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // Tagline animation
    final taglineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        // Main content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  return _buildGlassCard(
                    theme,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title with slide up
                        Transform.translate(
                          offset: Offset(0, 30 * (1 - titleAnimation.value)),
                          child: Opacity(
                            opacity: titleAnimation.value,
                            child: Text(
                              'FoCoCo',
                              style: theme.displaySmall.override(
                                fontFamily: 'Montserrat',
                                color: theme.primaryText,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Tagline with slide up
                        Transform.translate(
                          offset: Offset(0, 20 * (1 - taglineAnimation.value)),
                          child: Opacity(
                            opacity: taglineAnimation.value,
                            child: Text(
                              'Your Mind Powers the Game',
                              textAlign: TextAlign.center,
                              style: theme.headlineMedium.override(
                                fontFamily: 'Montserrat',
                                color: theme.secondaryText,
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    innerPadding: const EdgeInsets.all(48),
                  );
                },
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 0, _model.totalSlides),
      ],
    );
  }

  Widget _buildSlide2(FlutterFlowTheme theme) {
    // Staggered animations for each line
    final line1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    final line2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOut),
      ),
    );
    final line3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );
    final line4Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        // Main content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  return _buildGlassCard(
                    theme,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // "Where Mind"
                        Transform.translate(
                          offset: Offset(0, 30 * (1 - line1Animation.value)),
                          child: Opacity(
                            opacity: line1Animation.value,
                            child: Text(
                              'Where Mind',
                              textAlign: TextAlign.center,
                              style: theme.displaySmall.override(
                                fontFamily: 'Montserrat',
                                color: theme.primaryText,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "and"
                        Transform.translate(
                          offset: Offset(0, 20 * (1 - line2Animation.value)),
                          child: Opacity(
                            opacity: line2Animation.value,
                            child: Text(
                              'and',
                              textAlign: TextAlign.center,
                              style: theme.headlineMedium.override(
                                fontFamily: 'Montserrat',
                                color: theme.secondaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "Performance"
                        Transform.translate(
                          offset: Offset(0, 30 * (1 - line3Animation.value)),
                          child: Opacity(
                            opacity: line3Animation.value,
                            child: Text(
                              'Performance',
                              textAlign: TextAlign.center,
                              style: theme.titleLarge.override(
                                fontFamily: 'Montserrat',
                                color: theme.primaryText,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "Meet."
                        Transform.translate(
                          offset: Offset(0, 20 * (1 - line4Animation.value)),
                          child: Opacity(
                            opacity: line4Animation.value,
                            child: Text(
                              'Meet.',
                              textAlign: TextAlign.center,
                              style: theme.displaySmall.override(
                                fontFamily: 'Montserrat',
                                color: theme.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    innerPadding: const EdgeInsets.all(48),
                  );
                },
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 1, _model.totalSlides),
      ],
    );
  }

  Widget _buildSlide3(FlutterFlowTheme theme) {
    // Staggered animations for each feature
    final feature1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOutCubic),
      ),
    );
    final feature2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.25, 0.58, curve: Curves.easeOutCubic),
      ),
    );
    final feature3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.5, 0.83, curve: Curves.easeOutCubic),
      ),
    );

    return Stack(
      children: [
        // Main content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  return _buildGlassCard(
                    theme,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureItem(
                          theme,
                          'Personalized Routines',
                          Icons.person_outline,
                          feature1Animation,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          theme,
                          'Performance Tracking',
                          Icons.trending_up_outlined,
                          feature2Animation,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          theme,
                          'Real Progress',
                          Icons.check_circle_outline,
                          feature3Animation,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 2, _model.totalSlides),
      ],
    );
  }

  Widget _buildFeatureItem(
    FlutterFlowTheme theme,
    String text,
    IconData icon,
    Animation<double> animation,
  ) {
    return Transform.translate(
      offset: Offset(0, 30 * (1 - animation.value)),
      child: Opacity(
        opacity: animation.value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.secondaryBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.glassBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container with Apple-style design - smaller
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Text with proper constraints - smaller
              Expanded(
                child: Text(
                  text,
                  style: theme.headlineMedium.override(
                    fontFamily: 'Montserrat',
                    color: theme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide4(FlutterFlowTheme theme) {
    // Title animation
    final titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        // Main content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  return _buildGlassCard(
                    theme,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title with scale and fade
                        Transform.scale(
                          scale: 0.8 + (titleAnimation.value * 0.2),
                          child: Opacity(
                            opacity: titleAnimation.value,
                            child: Text(
                              'Ready to Unlock Your Game?',
                              textAlign: TextAlign.center,
                              style: theme.displaySmall.override(
                                fontFamily: 'Montserrat',
                                color: theme.primaryText,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    innerPadding: const EdgeInsets.all(48),
                  );
                },
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 3, _model.totalSlides),
      ],
    );
  }

  Widget _buildSlide5(FlutterFlowTheme theme) {
    final age = _model.getAge();

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 20,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo in column with content
                  SafeArea(
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo/Logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Main Card Container
                  GlassDesignSystem.glassBackground(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title - smaller
                          Text(
                            'Let\'s Personalize Your Experience',
                            textAlign: TextAlign.center,
                            style: theme.headlineMedium.override(
                              fontFamily: 'Montserrat',
                              color: theme.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date of Birth Input - Full Width
                          _buildEnhancedDatePicker(theme),

                          // Visual Age Indicator - Full Width
                          if (_model.dateOfBirth != null) ...[
                            const SizedBox(height: 12),
                            _buildAgeIndicator(theme, age),
                          ],

                          const SizedBox(height: 16),

                          // Terms Checkbox - Full Width
                          _buildEnhancedTermsCheckbox(theme),

                          // Age-specific content
                          if (_model.dateOfBirth != null &&
                              _model.termsAccepted) ...[
                            const SizedBox(height: 20),
                            if (age != null && age < 16)
                              _buildUnderMinimumAgeMessage(theme),
                            if (age != null && age >= 16 && age < 18)
                              _buildTeenageConsent(theme),
                            // Removed continue button - navigation arrows handle this
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bottom progress indicator
        _buildBottomProgress(theme, 4, _model.totalSlides),
      ],
    );
  }

  Widget _buildEnhancedDatePicker(FlutterFlowTheme theme) {
    final hasDate = _model.dateOfBirth != null;

    return GestureDetector(
      onTap: () => _showDatePicker(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.glassBackground.withValues(alpha: 0.4),
                  theme.glassTint.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasDate
                    ? theme.primary.withValues(alpha: 0.4)
                    : theme.glassBorder.withValues(alpha: 0.3),
                width: hasDate ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon Container - Smaller
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primary.withValues(alpha: 0.2),
                        theme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: theme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Date Content - Full Width
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
                        style: theme.bodySmall.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasDate
                            ? DateFormat('MMMM dd, yyyy')
                                .format(_model.dateOfBirth!)
                            : 'Tap to select your date of birth',
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: hasDate
                              ? theme.primaryText
                              : theme.secondaryText.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight:
                              hasDate ? FontWeight.w600 : FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.secondaryText.withValues(alpha: 0.4),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTermsCheckbox(FlutterFlowTheme theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _model.termsAccepted = !_model.termsAccepted;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.glassBackground.withValues(alpha: 0.3),
                  theme.glassTint.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _model.termsAccepted
                    ? theme.primary.withValues(alpha: 0.4)
                    : theme.glassBorder.withValues(alpha: 0.3),
                width: _model.termsAccepted ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Checkbox Container - Smaller
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: _model.termsAccepted
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primary,
                              theme.primary.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: _model.termsAccepted ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: theme.primary,
                      width: 2,
                    ),
                    boxShadow: _model.termsAccepted
                        ? [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: _model.termsAccepted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Terms Text - Full Width, Smaller Font
                Expanded(
                  child: Text(
                    'I accept the Terms and Privacy Policy',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      height: 1.5,
                      fontSize: 13,
                      fontWeight: _model.termsAccepted
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: -0.1,
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

  Widget _buildAgeIndicator(FlutterFlowTheme theme, int? age) {
    if (age == null) return const SizedBox.shrink();

    Color ageColor;
    String ageLabel;
    IconData ageIcon;
    Color backgroundColor;

    if (age < 16) {
      ageColor = theme.error;
      ageLabel = 'Under 16';
      ageIcon = Icons.block_rounded;
      backgroundColor = theme.error.withValues(alpha: 0.15);
    } else if (age >= 16 && age < 18) {
      ageColor = theme.warning;
      ageLabel = 'Teen (16-17)';
      ageIcon = Icons.child_care_rounded;
      backgroundColor = theme.warning.withValues(alpha: 0.15);
    } else {
      ageColor = theme.success;
      ageLabel = 'Adult (18+)';
      ageIcon = Icons.check_circle_rounded;
      backgroundColor = theme.success.withValues(alpha: 0.15);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ageColor.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon Container - Smaller
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ageColor.withValues(alpha: 0.25),
                      ageColor.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ageColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ageColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  ageIcon,
                  color: ageColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Age Content - Full Width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age: $age years',
                      style: theme.bodyLarge.override(
                        fontFamily: 'Montserrat',
                        color: theme.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ageColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ageLabel,
                        style: theme.bodySmall.override(
                          fontFamily: 'Inter',
                          color: ageColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          letterSpacing: 0.2,
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

  Widget _buildUnderMinimumAgeMessage(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.error.withValues(alpha: 0.2),
                theme.error.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.error.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Icon - Smaller
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.error.withValues(alpha: 0.3),
                      theme.error.withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.error.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.block_rounded,
                  color: theme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'App is for 16+',
                textAlign: TextAlign.center,
                style: theme.bodyLarge.override(
                  fontFamily: 'Montserrat',
                  color: theme.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'To use, a parent/legal guardian must create the account.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  fontFamily: 'Inter',
                  color: theme.primaryText,
                  fontSize: 14,
                  height: 1.5,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.error,
                        theme.error.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.error.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        exit(0);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'EXIT APP',
                          textAlign: TextAlign.center,
                          style: theme.titleMedium.override(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
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

  Widget _buildTeenageConsent(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.glassBackground.withValues(alpha: 0.4),
                    theme.glassTint.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title with icon - Smaller
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.warning.withValues(alpha: 0.2),
                              theme.warning.withValues(alpha: 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.warning.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: theme.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Parental Permission Required',
                          textAlign: TextAlign.center,
                          style: theme.bodyLarge.override(
                            fontFamily: 'Montserrat',
                            color: theme.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Permission Checkbox - Full Width
                  _buildPermissionCheckbox(
                    theme,
                    'I have permission from my parent or guardian to use this app.',
                    _model.hasParentalPermission,
                    theme.primary,
                    () {
                      setState(() {
                        _model.hasParentalPermission = true;
                        _model.noParentalPermission = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // No Permission Checkbox - Full Width
                  _buildPermissionCheckbox(
                    theme,
                    'I do not have permission from my parent or guardian to use this app.',
                    _model.noParentalPermission,
                    theme.error,
                    () {
                      setState(() {
                        _model.noParentalPermission = true;
                        _model.hasParentalPermission = false;
                      });
                    },
                    isNegative: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Removed continue button - navigation arrows handle this
        if (_model.noParentalPermission) ...[
          const SizedBox(height: 16),
          FFButtonWidget(
            onPressed: () {
              exit(0);
            },
            text: 'EXIT APP',
            options: FFButtonOptions(
              width: double.infinity,
              height: 50,
              color: theme.error,
              textStyle: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              borderRadius: BorderRadius.circular(14),
              elevation: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionCheckbox(
    FlutterFlowTheme theme,
    String text,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap, {
    bool isNegative = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        accentColor.withValues(alpha: 0.15),
                        accentColor.withValues(alpha: 0.05),
                      ]
                    : [
                        theme.glassBackground.withValues(alpha: 0.3),
                        theme.glassTint.withValues(alpha: 0.15),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : theme.glassBorder.withValues(alpha: 0.3),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      height: 1.5,
                      letterSpacing: -0.1,
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

  Widget _buildContinueButton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary,
              theme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _nextSlide,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: theme.titleMedium.override(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canProceedToNextSlide() {
    // Check validation based on current slide
    if (_model.currentSlide == 4) {
      // Age verification slide
      return _model.canProceedFromAgeVerification();
    } else if (_model.currentSlide >= 7 && _model.currentSlide <= 13) {
      // VARK questions (slides 7-13 are Q1-Q7)
      final questionIndex = _model.currentSlide - 7;
      // Check if current question is answered
      if (questionIndex < _model.varkAnswers.length) {
        return _model.varkAnswers[questionIndex] >= 0;
      }
      return false;
    } else if (_model.currentSlide == 15) {
      // Goals selection slide
      return _model.selectedGoal.isNotEmpty;
    } else if (_model.currentSlide == 16) {
      // Membership selection slide
      return _model.selectedMembershipPlan.isNotEmpty &&
          !_isProcessingSubscription;
    }
    // Other slides can proceed
    return true;
  }

  Future<void> _showDatePicker() async {
    final theme = FlutterFlowTheme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _model.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.primary,
              onPrimary: Colors.white,
              surface: theme.primaryBackground,
              onSurface: theme.primaryText,
              secondary: theme.secondary,
              onSecondary: Colors.white,
              error: theme.error,
              onError: Colors.white,
            ),
            dialogBackgroundColor: theme.primaryBackground,
            cardColor: theme.secondaryBackground,
            scaffoldBackgroundColor: theme.primaryBackground,
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: theme.primaryText,
                  displayColor: theme.primaryText,
                ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: theme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                borderSide: BorderSide(
                  color: theme.glassBorder,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                borderSide: BorderSide(
                  color: theme.glassBorder,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
                borderSide: BorderSide(
                  color: theme.primary,
                  width: 2,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      FlutterFlowTheme.borderRadiusButton),
                ),
                elevation: FlutterFlowTheme.elevationM,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _model.dateOfBirth = picked;
      });
    }
  }

  Widget _buildSlide6(FlutterFlowTheme theme) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildGlassCard(
                  theme,
                  innerPadding: const EdgeInsets.all(48),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'We all Learn Differently.',
                        textAlign: TextAlign.center,
                        style: theme.displaySmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'FoCoCo adapts to you!',
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'So your experience is personal, focused, and built to match how you learn best.',
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 5, _model.totalSlides),
      ],
    );
  }

  Widget _buildSlide7(FlutterFlowTheme theme) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildGlassCard(
                  theme,
                  innerPadding: const EdgeInsets.all(48),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Let\'s get started.',
                        textAlign: TextAlign.center,
                        style: theme.headlineLarge.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '7 quick questions to discover how you learn best.',
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'There are no right or wrong answers.',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      FFButtonWidget(
                        onPressed: () {
                          setState(() {
                            _model.currentQuestionIndex = 0;
                          });
                          _nextSlide();
                        },
                        text: 'Begin',
                        options: FFButtonOptions(
                          width: 200,
                          height: 56,
                          color: theme.primary,
                          textStyle: theme.titleMedium.override(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 6, _model.totalSlides),
      ],
    );
  }

  Widget _buildVarkQuestionSlide(int questionIndex, FlutterFlowTheme theme) {
    if (questionIndex >= _model.varkQuestions.length) {
      return const SizedBox();
    }

    final question = _model.varkQuestions[questionIndex];
    final selectedAnswer = questionIndex < _model.varkAnswers.length
        ? _model.varkAnswers[questionIndex]
        : -1;

    return Stack(
      children: [
        // Main content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom +
                  100, // Space for bottom controls
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassDesignSystem.glassBackground(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Question - smaller, more compact
                      Text(
                        question['question'],
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Options - more compact spacing
                      ...List.generate(
                        question['options'].length,
                        (index) => _buildVarkOption(
                          question['options'][index],
                          index,
                          questionIndex,
                          selectedAnswer == index,
                          theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Persistent logo at top
        _buildPersistentLogo(theme),

        // Progress indicator - positioned at bottom
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 60,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: GlassDesignSystem.glassBackground(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${questionIndex + 1} of ${_model.varkQuestions.length}',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.secondaryText,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            '${((questionIndex + 1) / _model.varkQuestions.length * 100).round()}%',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value:
                            (questionIndex + 1) / _model.varkQuestions.length,
                        backgroundColor:
                            theme.secondaryText.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                        minHeight: 2.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVarkOption(
    Map<String, dynamic> option,
    int optionIndex,
    int questionIndex,
    bool isSelected,
    FlutterFlowTheme theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_model.varkAnswers.length > questionIndex) {
              _model.varkAnswers[questionIndex] = optionIndex;
            } else {
              while (_model.varkAnswers.length <= questionIndex) {
                _model.varkAnswers.add(-1);
              }
              _model.varkAnswers[questionIndex] = optionIndex;
            }
          });
          // Removed auto-advance - user must use navigation arrows
        },
        child: GlassDesignSystem.glassBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.primary : Colors.transparent,
                    border: Border.all(
                      color: theme.primary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option['text'],
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      height: 1.4,
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

  Widget _buildSlide15(FlutterFlowTheme theme) {
    _model.varkScores = _model.calculateVARKScores();
    _model.dominantLearningStyle = _model.getDominantStyle();
    final displayName =
        _model.getLearningStyleDisplayName(_model.dominantLearningStyle);

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildGlassCard(
                  theme,
                  innerPadding: const EdgeInsets.all(48),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'You\'re a',
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.secondaryText,
                          fontSize: 20,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$displayName',
                        textAlign: TextAlign.center,
                        style: theme.displaySmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learner',
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.secondaryText,
                          fontSize: 20,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Persistent logo at top
        _buildPersistentLogo(theme),
        // Bottom progress indicator
        _buildBottomProgress(theme, 14, _model.totalSlides),
      ],
    );
  }

  Widget _buildSlide16(FlutterFlowTheme theme) {
    final goals = [
      'Improve consistency',
      'Build confidence under pressure',
      'Stay calm and focused',
      'Play to my full potential',
      'Something else (add later in notes)',
    ];

    return Stack(
      children: [
        // Main content
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              bottom: MediaQuery.of(context).padding.bottom +
                  100, // Space for bottom controls
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassDesignSystem.glassBackground(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Question - smaller, more compact
                      Text(
                        'What\'s Your Main Goal?',
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Options - more compact spacing
                      ...goals.map((goal) => _buildGoalOption(goal, theme)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Persistent logo at top
        _buildPersistentLogo(theme),

        // Progress indicator - positioned at bottom
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 60,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: GlassDesignSystem.glassBackground(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Slide ${15 + 1} of ${_model.totalSlides}',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.secondaryText,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            '${((15 + 1) / _model.totalSlides * 100).round()}%',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (15 + 1) / _model.totalSlides,
                        backgroundColor:
                            theme.secondaryText.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                        minHeight: 2.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalOption(String goal, FlutterFlowTheme theme) {
    final isSelected = _model.selectedGoal == goal;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _model.selectedGoal = goal;
          });
          // Removed auto-advance - user must use navigation arrows
        },
        child: GlassDesignSystem.glassBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.primary : Colors.transparent,
                    border: Border.all(
                      color: theme.primary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal,
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      height: 1.4,
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

  Widget _buildSlide17(FlutterFlowTheme theme) {
    // Auto-select Prime plan if not already selected
    if (_model.selectedMembershipPlan.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _model.selectedMembershipPlan = 'prime';
          });
        }
      });
    }

    return Column(
      children: [
        // Logo at top
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo/Logo.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Flexible space between logo and content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: GlassDesignSystem.glassBackground(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Choose Your Membership',
                          style: theme.headlineMedium.override(
                            fontFamily: 'Montserrat',
                            color: theme.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Get coaching that supports your game, on and off the course.',
                          style: theme.bodyMedium.override(
                            fontFamily: 'Inter',
                            color: theme.secondaryText,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Billing Period Toggle
                        GlassDesignSystem.glassBackground(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _model.selectedBillingPeriod =
                                            'monthly';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _model.selectedBillingPeriod ==
                                                'monthly'
                                            ? theme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Monthly',
                                        textAlign: TextAlign.center,
                                        style: theme.bodyMedium.override(
                                          fontFamily: 'Inter',
                                          color: _model.selectedBillingPeriod ==
                                                  'monthly'
                                              ? Colors.white
                                              : theme.primaryText,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _model.selectedBillingPeriod = 'yearly';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _model.selectedBillingPeriod ==
                                                'yearly'
                                            ? theme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Yearly',
                                        textAlign: TextAlign.center,
                                        style: theme.bodyMedium.override(
                                          fontFamily: 'Inter',
                                          color: _model.selectedBillingPeriod ==
                                                  'yearly'
                                              ? Colors.white
                                              : theme.primaryText,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PRIME Plan Only
                        _buildMembershipPlan(
                          'PRIME',
                          _model.selectedBillingPeriod == 'monthly'
                              ? '\$17.99'
                              : '\$139.99',
                          _model.selectedBillingPeriod == 'monthly'
                              ? '/month'
                              : '/year',
                          null,
                          [
                            'Personalized learning with VARK profile',
                            'Advanced AI Mind Coaching',
                            'Full FoCoMap suite: MindMap, ShotMap, SyncMap',
                            'Hands-free golf shot logging ("Just Talk!")',
                            'Premium Mind & Game analysis, linked together',
                            'Golf round logging & journaling',
                            'Mind Power Index (MPI) with progress history',
                          ],
                          'prime',
                          false,
                          theme,
                        ),

                        if (_model.selectedMembershipPlan.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          FFButtonWidget(
                            onPressed: _isProcessingSubscription
                                ? null
                                : () => _handleSubscriptionPurchase(theme),
                            text: _isProcessingSubscription
                                ? 'Processing...'
                                : Platform.isIOS
                                    ? 'Subscribe with App Store'
                                    : Platform.isAndroid
                                        ? 'Subscribe with Google Play'
                                        : 'Choose Plan and Start',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 56,
                              color: _isProcessingSubscription
                                  ? theme.secondaryText
                                  : theme.primary,
                              textStyle: theme.bodyLarge.override(
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              elevation: _isProcessingSubscription ? 0 : 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Platform.isIOS
                                ? 'Subscriptions are managed by Apple. Cancel anytime in Settings.'
                                : Platform.isAndroid
                                    ? 'Subscriptions are managed by Google. Cancel anytime in Play Store.'
                                    : 'Subscriptions are managed by your platform store.',
                            textAlign: TextAlign.center,
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.secondaryText,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipPlan(
    String planName,
    String price,
    String period,
    String? savings,
    List<String> features,
    String planId,
    bool isMostPopular,
    FlutterFlowTheme theme,
  ) {
    final isSelected = _model.selectedMembershipPlan == planId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _model.selectedMembershipPlan = planId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.glassBackground
                        .withValues(alpha: isSelected ? 0.3 : 0.15),
                    theme.glassTint.withValues(alpha: isSelected ? 0.25 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : theme.glassBorder.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        planName,
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      if (isMostPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Most Popular',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          period,
                          style: theme.bodyMedium.override(
                            fontFamily: 'Inter',
                            color: theme.secondaryText,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (savings != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            savings,
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (planId == 'prime' &&
                      _model.selectedBillingPeriod == 'monthly') ...[
                    const SizedBox(height: 8),
                    Text(
                      '7-day Free Trial, cancel anytime',
                      style: theme.bodySmall.override(
                        fontFamily: 'Inter',
                        color: theme.secondaryText,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ...features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.bodySmall.override(
                                fontFamily: 'Inter',
                                color: theme.primaryText,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide18(FlutterFlowTheme theme) {
    final displayName =
        _model.getLearningStyleDisplayName(_model.dominantLearningStyle);

    return Column(
      children: [
        // Logo at top
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo/Logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Flexible space between logo and content
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: _buildGlassCard(
                    theme,
                    innerPadding: const EdgeInsets.all(48),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Let\'s Get Started.',
                          textAlign: TextAlign.center,
                          style: theme.displaySmall.override(
                            fontFamily: 'Montserrat',
                            color: theme.primaryText,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Thank you for joining FoCoCo.',
                          textAlign: TextAlign.center,
                          style: theme.bodyLarge.override(
                            fontFamily: 'Inter',
                            color: theme.secondaryText,
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your experience is tailored based on:\n• Your $displayName learning style\n• Your primary goal: ${_model.selectedGoal}',
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium.override(
                            fontFamily: 'Inter',
                            color: theme.primaryText,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'We\'ll help you build routines, track performance, and unlock your potential one round at a time.',
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium.override(
                            fontFamily: 'Inter',
                            color: theme.secondaryText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        FFButtonWidget(
                          onPressed: _isSaving ? null : _completeOnboarding,
                          text: _isSaving ? 'Saving...' : 'Begin My Journey',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56,
                            color:
                                _isSaving ? theme.secondaryText : theme.primary,
                            textStyle: theme.titleMedium.override(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            elevation: _isSaving ? 0 : 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bottom progress indicator (anchored at bottom, no SafeArea)
        Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: _buildBottomProgressContent(theme, 17, _model.totalSlides),
        ),
      ],
    );
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
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.primaryBackground, // Use theme background (light/dark)
          ),
          child: Stack(
            children: [
              // Animated particles background
              ...List.generate(20, (index) => _buildWindParticle(index)),

              // Main content
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _model.currentSlide = index;
                  });
                  // Reset and start animations for new slide
                  if (index < 4) {
                    _slideController.reset();
                    _staggerController.reset();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _slideController.forward();
                        _staggerController.forward();
                      }
                    });
                  }
                },
                children: [
                  _buildSlide1(theme), // Slide 0: Brand Intro
                  _buildSlide2(theme), // Slide 1: Positioning
                  _buildSlide3(theme), // Slide 2: Value Prop
                  _buildSlide4(theme), // Slide 3: CTA
                  _buildSlide5(theme), // Slide 4: Age Verification
                  _buildSlide6(theme), // Slide 5: VARK Intro
                  _buildSlide7(theme), // Slide 6: VARK Instructions
                  _buildVarkQuestionSlide(0, theme), // Slide 7: Q1
                  _buildVarkQuestionSlide(1, theme), // Slide 8: Q2
                  _buildVarkQuestionSlide(2, theme), // Slide 9: Q3
                  _buildVarkQuestionSlide(3, theme), // Slide 10: Q4
                  _buildVarkQuestionSlide(4, theme), // Slide 11: Q5
                  _buildVarkQuestionSlide(5, theme), // Slide 12: Q6
                  _buildVarkQuestionSlide(6, theme), // Slide 13: Q7
                  _buildSlide15(theme), // Slide 14: VARK Result
                  _buildSlide16(theme), // Slide 15: Goals
                  _buildSlide17(theme), // Slide 16: Membership
                  _buildSlide18(theme), // Slide 17: Welcome
                ],
              ),

              // Navigation controls - Smaller, more bottom-aligned
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: _model.currentSlide > 0
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _previousSlide,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.secondaryBackground
                                          .withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.glassBorder
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: theme.primaryText,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(width: 40),
                      ),

                      // Next button (hidden on last slide)
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _model.currentSlide < _model.totalSlides - 1
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _canProceedToNextSlide()
                                      ? () {
                                          // Check if can proceed based on current slide
                                          if (_model.currentSlide == 4) {
                                            // Age verification
                                            if (_model
                                                .canProceedFromAgeVerification()) {
                                              _nextSlide();
                                            }
                                          } else if (_model.currentSlide >= 7 &&
                                              _model.currentSlide <= 13) {
                                            // VARK questions - check if answered
                                            final questionIndex =
                                                _model.currentSlide - 7;
                                            if (questionIndex <
                                                    _model.varkAnswers.length &&
                                                _model.varkAnswers[
                                                        questionIndex] >=
                                                    0) {
                                              _nextSlide();
                                            }
                                          } else if (_model.currentSlide ==
                                              15) {
                                            // Goals selection
                                            if (_model
                                                .selectedGoal.isNotEmpty) {
                                              _nextSlide();
                                            }
                                          } else if (_model.currentSlide ==
                                              16) {
                                            // Membership selection
                                            if (_model.selectedMembershipPlan
                                                .isNotEmpty) {
                                              _nextSlide();
                                            }
                                          } else {
                                            _nextSlide();
                                          }
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _canProceedToNextSlide()
                                          ? theme.primary.withValues(alpha: 0.9)
                                          : theme.secondaryText
                                              .withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: _canProceedToNextSlide()
                                          ? Colors.white
                                          : theme.secondaryText
                                              .withValues(alpha: 0.4),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(width: 40),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
