import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:just_audio/just_audio.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/backend.dart';
import '/backend/schema/mental_sessions_record.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'virtual_training_experience_painter.dart';
import 'virtual_training_experience_model.dart';
export 'virtual_training_experience_model.dart';

/// Premium Virtual Training Experience Widget
/// Pure code implementation using Custom Painters - matches quality of Calm and Strava
class VirtualTrainingExperienceWidget extends StatefulWidget {
  const VirtualTrainingExperienceWidget({
    super.key,
    this.moduleTitle,
    this.moduleId,
    this.description,
    this.estimatedDuration,
  });

  final String? moduleTitle;
  final String? moduleId;
  final String? description;
  final int? estimatedDuration;

  static const String routeName = 'virtual_training_experience';
  static const String routePath = '/virtual_training_experience';

  @override
  State<VirtualTrainingExperienceWidget> createState() =>
      _VirtualTrainingExperienceWidgetState();
}

class _VirtualTrainingExperienceWidgetState
    extends State<VirtualTrainingExperienceWidget>
    with TickerProviderStateMixin {
  late VirtualTrainingExperienceModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation Controllers
  late AnimationController _breathController;
  late AnimationController _focusMeterController;
  late AnimationController _ambientController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Session State
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;
  bool _isCompleted = false;
  double _focusScore = 0.0; // 0.0 - 1.0 for focus level tracking
  double _calmLevel = 0.5; // 0.0 - 1.0 for calm level tracking

  // Breathing Technique (4-7-8)
  static const int _inhaleSeconds = 4;
  static const int _holdSeconds = 7;
  static const int _exhaleSeconds = 8;
  static const int _cycleSeconds = _inhaleSeconds + _holdSeconds + _exhaleSeconds;

  // Audio
  AudioPlayer? _ambientAudioPlayer;
  bool _audioEnabled = true;

  // Custom Painter Data
  final List<Particle> _particles = [];
  final List<Wave> _waves = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VirtualTrainingExperienceModel());

    // Initialize animations
    _breathController = AnimationController(
      duration: const Duration(seconds: _cycleSeconds),
      vsync: this,
    );

    _focusMeterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _ambientController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Start animations
    _fadeController.forward();

    // Initialize visual elements
    _initializeParticles();
    _initializeWaves();

    // Initialize audio
    _initializeAudio();

    // Start session
    _startSession();
  }

  /// Initialize audio for ambient sounds
  Future<void> _initializeAudio() async {
    try {
      _ambientAudioPlayer = AudioPlayer();
      // Note: Replace with actual audio asset when available
      // await _ambientAudioPlayer!.setAsset('assets/audios/ambient_calm.mp3');
      // await _ambientAudioPlayer!.setLoopMode(LoopMode.one);
      // if (_audioEnabled) {
      //   await _ambientAudioPlayer!.play();
      // }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error initializing audio: $e');
      }
    }
  }

  /// Initialize particles for ambient effects
  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 80; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2 + random.nextDouble() * 4,
        opacity: 0.2 + random.nextDouble() * 0.5,
        speedX: (random.nextDouble() - 0.5) * 0.003,
        speedY: (random.nextDouble() - 0.5) * 0.003,
        colorIndex: random.nextInt(3),
      ));
    }
  }

  /// Initialize waves for ambient effects
  void _initializeWaves() {
    for (int i = 0; i < 5; i++) {
      _waves.add(Wave(
        phase: i * 0.5,
        amplitude: 0.3 + i * 0.1,
        speed: 0.01 + i * 0.005,
        colorIndex: i % 3,
      ));
    }
  }

  /// Start the training session
  void _startSession() {
    _startTime = DateTime.now();
    // _currentPhase = SessionPhase.breathing; // Will be used for phase transitions
    _startBreathingCycle();
    _startTimer();
    _updateFocusScore();
  }

  /// Start breathing cycle with smooth animations
  void _startBreathingCycle() {
    if (_isPaused || _isCompleted) return;

    _breathController.forward(from: 0.0);
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathController.reverse();
        _breathController.addStatusListener((reverseStatus) {
          if (reverseStatus == AnimationStatus.dismissed) {
            if (!_isPaused && !_isCompleted) {
              _startBreathingCycle();
            }
          }
        });
      }
    });
  }

  /// Update focus score over time (simulating improvement)
  void _updateFocusScore() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() {
          _focusScore = (_focusScore + 0.02).clamp(0.0, 1.0);
          _calmLevel = (_calmLevel + 0.015).clamp(0.0, 1.0);
        });
        _updateFocusScore();
      }
    });
  }

  /// Timer for session tracking
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _startTime != null && !_isPaused && !_isCompleted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
          _updateParticles();
          _updateWaves();
        });
        _startTimer();
      }
    });
  }

  /// Update particles for animation
  void _updateParticles() {
    for (var particle in _particles) {
      particle.x = (particle.x + particle.speedX) % 1.0;
      particle.y = (particle.y + particle.speedY) % 1.0;
      particle.opacity = 0.2 +
          math.sin(_elapsedTime.inMilliseconds / 2000.0 + particle.x * 10) * 0.4;
    }
  }

  /// Update waves for animation
  void _updateWaves() {
    for (var wave in _waves) {
      wave.phase += wave.speed;
      if (wave.phase > math.pi * 2) {
        wave.phase -= math.pi * 2;
      }
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Pause/Resume session
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _breathController.stop();
        _ambientAudioPlayer?.pause();
      } else {
        _startBreathingCycle();
        _ambientAudioPlayer?.play();
      }
    });
  }

  /// Complete session
  Future<void> _completeSession() async {
    if (_isCompleted) return;

    setState(() {
      _isCompleted = true;
      _breathController.stop();
      // _currentPhase = SessionPhase.complete; // Will be used for phase transitions
    });

    // Save session to Firestore
    await _saveSession();

    if (mounted) {
      HapticFeedback.mediumImpact();
      
      // Show completion dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildCompletionDialog(),
      );
    }
  }

  /// Save session to Firestore
  Future<void> _saveSession() async {
    if (currentUser == null || widget.moduleId == null) return;

    try {
      await MentalSessionsRecord.collection.add({
        'userId': currentUserUid,
        'moduleTitle': widget.moduleTitle ?? 'Training Session',
        'moduleId': widget.moduleId,
        'sessionType': 'virtual_training',
        'dateStarted': _startTime,
        'dateCompleted': FieldValue.serverTimestamp(),
        'isCompleted': true,
        'duration': _elapsedTime.inSeconds,
        'progressPercentage': 100,
        'focusScore': _focusScore,
        'calmLevel': _calmLevel,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving session: $e');
      }
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _focusMeterController.dispose();
    _ambientController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _ambientAudioPlayer?.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.mentalFocus.withValues(alpha: 0.6),
              theme.mentalCalm.withValues(alpha: 0.4),
              theme.primaryBackground,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Background with Custom Painter
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return CustomPaint(
                  painter: PremiumAmbientPainter(
                    time: _ambientController.value,
                    particles: _particles,
                    waves: _waves,
                    theme: theme,
                    focusScore: _focusScore,
                    calmLevel: _calmLevel,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),

            // Main Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
          child: Column(
            children: [
                    // Premium Header
                    _buildPremiumHeader(theme),

                    // Main Visualization Area
                    Expanded(
                      child: _buildMainVisualization(theme),
                    ),

                    // Control Panel
                    _buildControlPanel(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fade animation getter
  Animation<double> get _fadeAnimation => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ));

  /// Build premium header matching Calm/Strava quality
  Widget _buildPremiumHeader(FlutterFlowTheme theme) {
    return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
          // Back button with glassmorphic style
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.safePop(),
                    ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.moduleTitle ?? 'Training Session',
                            style: theme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              style: theme.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

          const SizedBox(width: 12),

          // Time Display
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                            ),
                          ),
                          child: Text(
                            _formatDuration(_elapsedTime),
                  style: theme.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
            ),
                        ),
                      ],
                    ),
    );
  }

  /// Build main visualization area with Custom Painters
  Widget _buildMainVisualization(FlutterFlowTheme theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Breathing Ring (Custom Painter)
            _buildBreathingRing(theme),

            const SizedBox(height: 40),

            // Focus Meter (Custom Painter)
            _buildFocusMeter(theme),

            const SizedBox(height: 40),

            // Calm Level Indicator
            _buildCalmIndicator(theme),
          ],
        ),
      ),
    );
  }

  /// Build breathing ring with Custom Painter animation
  Widget _buildBreathingRing(FlutterFlowTheme theme) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final breathProgress = _breathController.value;
        final cycleProgress = (breathProgress * _cycleSeconds) % _cycleSeconds;
        
        bool isInhaling = cycleProgress < _inhaleSeconds;
        bool isHolding = cycleProgress >= _inhaleSeconds && 
                        cycleProgress < _inhaleSeconds + _holdSeconds;

        // Calculate ring scale (0.4 to 1.0)
        double scale;
        String phaseText;
        Color phaseColor;

        if (isInhaling) {
          scale = 0.4 + (cycleProgress / _inhaleSeconds) * 0.6;
          phaseText = 'Breathe In';
          phaseColor = theme.mentalFocus;
        } else if (isHolding) {
          scale = 1.0;
          phaseText = 'Hold';
          phaseColor = theme.mentalCalm;
        } else {
          scale = 1.0 - ((cycleProgress - _inhaleSeconds - _holdSeconds) / _exhaleSeconds) * 0.6;
          phaseText = 'Breathe Out';
          phaseColor = theme.mentalStrength;
        }

        return Column(
          children: [
            // Premium Custom Painter implementation
            SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: BreathingRingPainter(
                  scale: scale,
                  color: phaseColor,
                  theme: theme,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Phase Text
            Text(
              phaseText,
              style: theme.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Breathing Instructions
            Text(
              isInhaling
                  ? 'Inhale for $_inhaleSeconds seconds'
                  : isHolding
                      ? 'Hold for $_holdSeconds seconds'
                      : 'Exhale for $_exhaleSeconds seconds',
              style: theme.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build focus meter with Custom Painter
  Widget _buildFocusMeter(FlutterFlowTheme theme) {
    return Column(
      children: [
        Text(
          'Focus Level',
          style: theme.titleMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Premium Custom Painter implementation
        SizedBox(
          width: 250,
          height: 60,
          child: CustomPaint(
            painter: FocusMeterPainter(
              progress: _focusScore,
              theme: theme,
            ),
          ),
        ),

        const SizedBox(height: 12),
        
                              Text(
          '${(_focusScore * 100).toInt()}%',
          style: theme.titleLarge.copyWith(
            color: theme.mentalFocus,
                                  fontWeight: FontWeight.w700,
                                ),
        ),
      ],
    );
  }

  /// Build calm level indicator
  Widget _buildCalmIndicator(FlutterFlowTheme theme) {
    return Column(
      children: [
                                Text(
          'Calm Level',
          style: theme.titleMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          width: 250,
          height: 12,
          child: CustomPaint(
            painter: CalmLevelPainter(
              progress: _calmLevel,
              theme: theme,
            ),
          ),
        ),

        const SizedBox(height: 12),
        
        Text(
          '${(_calmLevel * 100).toInt()}%',
          style: theme.titleLarge.copyWith(
            color: theme.mentalCalm,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Build control panel
  Widget _buildControlPanel(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Pause/Resume and Complete buttons
          Row(
            children: [
              Expanded(
                child: _buildGlassButton(
                  theme: theme,
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  label: _isPaused ? 'Resume' : 'Pause',
                  onPressed: _togglePause,
                  color: theme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassButton(
                  theme: theme,
                  icon: Icons.check_circle,
                  label: 'Complete',
                  onPressed: _isCompleted ? null : _completeSession,
                  color: theme.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Audio Toggle
          _buildGlassButton(
            theme: theme,
            icon: _audioEnabled ? Icons.volume_up : Icons.volume_off,
            label: _audioEnabled ? 'Sound On' : 'Sound Off',
            onPressed: () {
              setState(() {
                _audioEnabled = !_audioEnabled;
              });
              if (_audioEnabled) {
                _ambientAudioPlayer?.play();
              } else {
                _ambientAudioPlayer?.pause();
              }
            },
            color: theme.secondaryText,
            isOutlined: true,
                                ),
                            ],
                          ),
    );
  }

  /// Build glassmorphic button
  Widget _buildGlassButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isOutlined = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isOutlined
                    ? Colors.transparent
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOutlined
                      ? Colors.white.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  /// Build completion dialog
  Widget _buildCompletionDialog() {
    final theme = FlutterFlowTheme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground.withValues(alpha: 0.9),
                  theme.glassBackground.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.success,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Session Complete!',
                  style: theme.headlineSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Great work! You\'ve completed ${widget.moduleTitle ?? "your training session"}',
                  style: theme.bodyLarge.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.safePop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

/// Session phases
enum SessionPhase {
  preparation,
  breathing,
  focus,
  complete,
}
