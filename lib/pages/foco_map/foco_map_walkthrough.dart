import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_design_system.dart';
import 'dart:math' as math;

class FoCoMapWalkthrough extends StatefulWidget {
  const FoCoMapWalkthrough({
    super.key,
    this.onComplete,
    this.onSkip,
  });

  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  @override
  State<FoCoMapWalkthrough> createState() => _FoCoMapWalkthroughState();
}

class _FoCoMapWalkthroughState extends State<FoCoMapWalkthrough>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  // Walkthrough steps
  final List<WalkthroughStep> _steps = [
    WalkthroughStep(
      title: 'Welcome to FoCoMap',
      description: 'Your visual golf performance analyzer that combines mental and technical data on an interactive map.',
      icon: Icons.map,
      primaryColor: Colors.blue,
      features: [
        'Track mental performance',
        'Analyze shot patterns',
        'Discover correlations',
      ],
    ),
    WalkthroughStep(
      title: 'Three Powerful Layers',
      description: 'Switch between different map views to gain unique insights into your game.',
      icon: Icons.layers,
      primaryColor: Colors.green,
      features: [
        'MindMap: Mental performance',
        'ShotMap: Technical analysis',
        'SyncMap: Combined insights',
      ],
    ),
    WalkthroughStep(
      title: 'MindMap Layer',
      description: 'Visualize your mental game with color-coded markers showing focus, confidence, and control.',
      icon: Icons.psychology,
      primaryColor: Colors.purple,
      features: [
        '🟢 Green: Strong mindset',
        '🟡 Yellow: Neutral state',
        '🔴 Red: Struggling round',
      ],
    ),
    WalkthroughStep(
      title: 'ShotMap Layer',
      description: 'See every shot with club-specific markers and performance patterns.',
      icon: Icons.golf_course,
      primaryColor: Colors.orange,
      features: [
        'Club-specific icons',
        'Shot outcome tracking',
        'Wind & conditions data',
      ],
    ),
    WalkthroughStep(
      title: 'SyncMap Layer',
      description: 'Discover how your mental state affects your technical performance.',
      icon: Icons.sync,
      primaryColor: Colors.teal,
      features: [
        'Mental-technical correlation',
        'Pattern identification',
        'AI-powered insights',
      ],
    ),
    WalkthroughStep(
      title: 'Voice Logging',
      description: 'Simply speak your thoughts and let AI categorize them automatically.',
      icon: Icons.mic,
      primaryColor: Colors.red,
      features: [
        'Natural language input',
        'Automatic categorization',
        'Real-time processing',
      ],
      showVoiceExample: true,
    ),
    WalkthroughStep(
      title: 'Live Mode',
      description: 'Track your round in real-time with instant map updates (Plus/Prime tiers).',
      icon: Icons.play_circle_filled,
      primaryColor: Colors.green,
      features: [
        'Real-time tracking',
        'Live voice input',
        'Instant insights',
      ],
    ),
    WalkthroughStep(
      title: 'Interactive Analysis',
      description: 'Tap any marker to see detailed information and AI-generated insights.',
      icon: Icons.touch_app,
      primaryColor: Colors.indigo,
      features: [
        'Detailed popup cards',
        'Historical comparisons',
        'Actionable recommendations',
      ],
    ),
    WalkthroughStep(
      title: 'Ready to Explore!',
      description: 'Start mapping your golf journey and unlock powerful insights about your game.',
      icon: Icons.rocket_launch,
      primaryColor: Colors.deepOrange,
      features: [
        'Tap the mic to log',
        'Switch between layers',
        'Discover your patterns',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start initial animations
    _startPageAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPageAnimations() {
    _fadeController.forward(from: 0);
    _slideController.forward(from: 0);
    _scaleController.forward(from: 0);
    if (_currentPage == 1) {
      _rotateController.repeat();
    } else {
      _rotateController.stop();
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWalkthrough();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipWalkthrough() {
    HapticFeedback.lightImpact();
    widget.onSkip?.call();
  }

  void _completeWalkthrough() {
    HapticFeedback.mediumImpact();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _skipWalkthrough,
                      child: Text(
                        'Skip',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.white70,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                      _startPageAnimations();
                    },
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return _buildStepContent(_steps[index]);
                    },
                  ),
                ),

                // Bottom navigation
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _steps[_currentPage].primaryColor.withValues(alpha: 0.3),
                Colors.black,
                _steps[_currentPage].primaryColor.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),

        // Animated particles
        ...List.generate(20, (index) {
          return _buildFloatingParticle(index);
        }),
      ],
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 4 + 2;
    final duration = random.nextInt(10) + 10;
    final delay = random.nextInt(5);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          child: _FloatingParticle(
            size: size,
            duration: Duration(seconds: duration),
            delay: Duration(seconds: delay),
            color: _steps[_currentPage].primaryColor.withValues(alpha: 0.3),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(WalkthroughStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: Listenable.merge([
              _scaleAnimation,
              _rotateAnimation,
              _pulseAnimation,
            ]),
            builder: (context, child) {
              Widget iconWidget = Icon(
                step.icon,
                size: 100,
                color: step.primaryColor,
              );

              if (_currentPage == 1) {
                // Rotate for layers
                iconWidget = Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: iconWidget,
                );
              } else if (_currentPage == 5 && step.showVoiceExample) {
                // Pulse for voice
                iconWidget = Transform.scale(
                  scale: _pulseAnimation.value,
                  child: iconWidget,
                );
              } else {
                // Scale for others
                iconWidget = Transform.scale(
                  scale: _scaleAnimation.value,
                  child: iconWidget,
                );
              }

              return iconWidget;
            },
          ),

          const SizedBox(height: 40),

          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                step.title,
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                step.description,
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                      color: Colors.white70,
                      letterSpacing: 0.0,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Features
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: step.features.map((feature) {
                final index = step.features.indexOf(feature);
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset((1 - value) * 50, 0),
                      child: Opacity(
                        opacity: value,
                        child: _buildFeatureItem(feature, step.primaryColor),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),

          // Voice example animation
          if (step.showVoiceExample) ...[
            const SizedBox(height: 32),
            _buildVoiceExample(),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  color: Colors.white,
                  letterSpacing: 0.0,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceExample() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Example Voice Input:',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: Colors.white70,
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '"Driver on 5, felt confident, crushed it 290 down the middle"',
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.0,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTag('Mental: Confident', Colors.green),
                  const SizedBox(width: 8),
                  _buildTag('Technical: Driver 290y', Colors.orange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: FlutterFlowTheme.of(context).bodySmall.override(
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 0.0,
            ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _steps[_currentPage].primaryColor
                      : Colors.white30,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              AnimatedOpacity(
                opacity: _currentPage > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FFButtonWidget(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  text: 'Previous',
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 18,
                  ),
                  options: FFButtonOptions(
                    width: 120,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.1),
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                    elevation: 0,
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),

              // Next/Complete button
              FFButtonWidget(
                onPressed: _nextPage,
                text: _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                icon: Icon(
                  _currentPage == _steps.length - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                  size: 18,
                ),
                options: FFButtonOptions(
                  width: 140,
                  height: 44,
                  color: _steps[_currentPage].primaryColor,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        letterSpacing: 0.0,
                      ),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Walkthrough step model
class WalkthroughStep {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final List<String> features;
  final bool showVoiceExample;

  WalkthroughStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.features,
    this.showVoiceExample = false,
  });
}

// Floating particle widget
class _FloatingParticle extends StatefulWidget {
  final double size;
  final Duration duration;
  final Duration delay;
  final Color color;

  const _FloatingParticle({
    required this.size,
    required this.duration,
    required this.delay,
    required this.color,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: MediaQuery.of(context).size.height,
      end: -50,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}