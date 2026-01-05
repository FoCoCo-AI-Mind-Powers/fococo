import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'visualize_tool_painter.dart';
import 'visualize_tool_model.dart';
export 'visualize_tool_model.dart';

class VisualizeToolWidget extends StatefulWidget {
  const VisualizeToolWidget({Key? key}) : super(key: key);

  static const String routeName = 'visualize_tool';
  static const String routePath = '/visualize_tool';

  @override
  State<VisualizeToolWidget> createState() => _VisualizeToolWidgetState();
}

class _VisualizeToolWidgetState extends State<VisualizeToolWidget>
    with TickerProviderStateMixin {
  late VisualizeToolModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _particleController;
  late AnimationController _fadeController;
  
  List<Particle> _particles = [];
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VisualizeToolModel());

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _initializeParticles();
    _startTime = DateTime.now();
    _startTimer();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(30, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 3 + random.nextDouble() * 5,
        opacity: 0.3 + random.nextDouble() * 0.7,
        speedX: (random.nextDouble() - 0.5) * 0.01,
        speedY: (random.nextDouble() - 0.5) * 0.01,
      );
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
          _updateParticles();
        });
        _startTimer();
      }
    });
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.x = (particle.x + particle.speedX) % 1.0;
      particle.y = (particle.y + particle.speedY) % 1.0;
      particle.opacity = 0.3 + math.sin(_elapsedTime.inMilliseconds / 1000.0 + particle.x) * 0.4;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _particleController.dispose();
    _fadeController.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.mentalFocus.withValues(alpha: 0.4),
              theme.mentalFocus.withValues(alpha: 0.2),
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
                            'Visualization',
                            style: theme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Mental Imagery Exercise',
                            style: theme.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
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

              // Visualization area
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Stack(
                    children: [
                      // Particle visualization
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: VisualizationParticlePainter(
                              time: _particleController.value,
                              color: theme.mentalFocus,
                              particles: _particles,
                            ),
                            size: MediaQuery.of(context).size,
                          );
                        },
                      ),
                      
                      // Content overlay
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Picture Your Success',
                                style: theme.displaySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Visualize your perfect shot, the ball\'s flight path, and your ideal outcome',
                                style: theme.bodyLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
    );
  }
}


