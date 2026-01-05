import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'breathing_tool_painter.dart';
import 'breathing_tool_model.dart';
export 'breathing_tool_model.dart';

class BreathingToolWidget extends StatefulWidget {
  const BreathingToolWidget({Key? key}) : super(key: key);

  static const String routeName = 'breathing_tool';
  static const String routePath = '/breathing_tool';

  @override
  State<BreathingToolWidget> createState() => _BreathingToolWidgetState();
}

class _BreathingToolWidgetState extends State<BreathingToolWidget>
    with TickerProviderStateMixin {
  late BreathingToolModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _breathController;
  late AnimationController _fadeController;
  late Animation<double> _breathAnimation;

  // Breathing state
  bool _isInhale = true;
  int _breathCycle = 0;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;
  bool _isPaused = false;

  // Breathing technique: 4-7-8 (inhale 4s, hold 7s, exhale 8s)
  static const int _inhaleSeconds = 4;
  static const int _holdSeconds = 7;
  static const int _exhaleSeconds = 8;
  static const int _cycleSeconds = _inhaleSeconds + _holdSeconds + _exhaleSeconds;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BreathingToolModel());

    // Initialize breath animation controller
    _breathController = AnimationController(
      duration: const Duration(seconds: _cycleSeconds),
      vsync: this,
    )..repeat();

    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _breathController.addListener(_updateBreathState);

    // Initialize fade controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _startTime = DateTime.now();
    _startTimer();
  }

  void _updateBreathState() {
    if (!mounted) return;
    
    final progress = _breathAnimation.value;
    final cycleProgress = (progress * _cycleSeconds) % _cycleSeconds;
    final newCycle = (progress * _cycleSeconds).floor();
    
    setState(() {
      if (cycleProgress < _inhaleSeconds) {
        _isInhale = true;
      } else if (cycleProgress < _inhaleSeconds + _holdSeconds) {
        _isInhale = true; // Still showing circle during hold
      } else {
        _isInhale = false;
      }
      
      if (newCycle != _breathCycle && newCycle > 0) {
        _breathCycle = newCycle;
      }
    });
  }

  void _startTimer() {
    if (_startTime == null) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isPaused && _startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
        _startTimer();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _breathController.stop();
      } else {
        _breathController.repeat();
      }
    });
  }

  String _getBreathInstruction() {
    final progress = _breathAnimation.value;
    final cycleProgress = (progress * _cycleSeconds) % _cycleSeconds;
    
    if (cycleProgress < _inhaleSeconds) {
      return 'Breathe In';
    } else if (cycleProgress < _inhaleSeconds + _holdSeconds) {
      return 'Hold';
    } else {
      return 'Breathe Out';
    }
  }

  double _getBreathProgress() {
    final progress = _breathAnimation.value;
    final cycleProgress = (progress * _cycleSeconds) % _cycleSeconds;
    
    if (cycleProgress < _inhaleSeconds) {
      return cycleProgress / _inhaleSeconds;
    } else if (cycleProgress < _inhaleSeconds + _holdSeconds) {
      return 1.0; // Full during hold
    } else {
      return 1.0 - ((cycleProgress - _inhaleSeconds - _holdSeconds) / _exhaleSeconds);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _breathController.dispose();
    _fadeController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.breathingActive.withValues(alpha: 0.3),
              theme.breathingActive.withValues(alpha: 0.1),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.safePop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breathing Exercise',
                            style: theme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '4-7-8 Technique',
                            style: theme.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _formatDuration(_elapsedTime),
                        style: theme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main breathing visualization
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Breathing circle animation
                        AnimatedBuilder(
                          animation: _breathAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size(300, 300),
                              painter: BreathingCirclePainter(
                                breathProgress: _getBreathProgress(),
                                color: theme.breathingActive,
                                isInhale: _isInhale,
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Instruction text
                        AnimatedBuilder(
                          animation: _breathAnimation,
                          builder: (context, child) {
                            return Text(
                              _getBreathInstruction(),
                              style: theme.displayMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 48,
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Cycle counter
                        Text(
                          'Cycle $_breathCycle',
                          style: theme.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Guide text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Inhale for 4 seconds, hold for 7 seconds, exhale for 8 seconds',
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause/Resume button
                    GestureDetector(
                      onTap: _togglePause,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 32,
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

