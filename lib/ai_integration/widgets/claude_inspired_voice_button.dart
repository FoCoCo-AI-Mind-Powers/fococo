import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/fococo_voice_service.dart';
import 'claude_inspired_voice_modal.dart';

/// Claude AI-inspired floating voice button with sophisticated animations
/// Features thinking mode toggle and production-ready voice integration
class ClaudeInspiredVoiceButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final double size;
  final EdgeInsets margin;

  const ClaudeInspiredVoiceButton({
    Key? key,
    this.onPressed,
    this.enabled = true,
    this.size = 64.0,
    this.margin = const EdgeInsets.only(bottom: 24),
  }) : super(key: key);

  @override
  State<ClaudeInspiredVoiceButton> createState() =>
      _ClaudeInspiredVoiceButtonState();
}

class _ClaudeInspiredVoiceButtonState extends State<ClaudeInspiredVoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  late AnimationController _thinkingController;
  late AnimationController _pressController;

  late Animation<double> _breathingAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _thinkingAnimation;
  late Animation<double> _pressAnimation;

  final FoCoCoVoiceService _voiceService = FoCoCoVoiceService();
  VoiceServiceState _voiceState = VoiceServiceState.uninitialized;
  bool _isThinkingMode = false;
  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVoiceListeners();
    _initializeVoiceService();
    _showInitialTooltip();
  }

  void _initializeAnimations() {
    // Breathing animation - subtle pulsing
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Ripple animation - for interactions
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Thinking animation - complex rotation for deep thinking mode
    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _thinkingAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _thinkingController, curve: Curves.linear),
    );

    // Press animation - tactile feedback
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // Start breathing animation
    _breathingController.repeat(reverse: true);
  }

  void _setupVoiceListeners() {
    _voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _voiceState = state;
        });
        _updateAnimationsForState(state);
      }
    });

    _voiceService.thinkingModeStream.listen((isThinking) {
      if (mounted) {
        setState(() {
          _isThinkingMode = isThinking;
        });
        _updateThinkingAnimation();
      }
    });
  }

  void _updateAnimationsForState(VoiceServiceState state) {
    switch (state) {
      case VoiceServiceState.listening:
        _rippleController.repeat();
        break;
      case VoiceServiceState.thinking:
        _rippleController.stop();
        break;
      case VoiceServiceState.speaking:
        _rippleController.stop();
        break;
      case VoiceServiceState.ready:
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.connecting:
      case VoiceServiceState.error:
        _rippleController.stop();
        break;
    }
  }

  void _updateThinkingAnimation() {
    if (_isThinkingMode) {
      _thinkingController.repeat();
    } else {
      _thinkingController.stop();
      _thinkingController.reset();
    }
  }

  Future<void> _initializeVoiceService() async {
    try {
      await _voiceService.initialize();
    } catch (e) {
      debugPrint('❌ Failed to initialize voice service: $e');
    }
  }

  void _showInitialTooltip() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showTooltip = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showTooltip = false);
        });
      }
    });
  }

  Future<void> _onButtonPressed() async {
    if (!widget.enabled) return;

    // Tactile feedback
    HapticFeedback.mediumImpact();

    // Press animation
    await _pressController.forward();
    await _pressController.reverse();

    // Ripple effect
    _rippleController.forward(from: 0.0);

    // Show voice chat modal
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        enableDrag: true,
        isDismissible: true,
        useSafeArea: true,
        builder: (context) => ClaudeInspiredVoiceModal(
          voiceService: _voiceService,
        ),
      );
    }

    widget.onPressed?.call();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    _thinkingController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Positioned(
      bottom: widget.margin.bottom,
      left: 0,
      right: 0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer ripple effect
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Container(
                  width: widget.size * (1 + _rippleAnimation.value * 1.2),
                  height: widget.size * (1 + _rippleAnimation.value * 1.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStateColor(theme).withValues(
                        alpha: 0.3 * (1 - _rippleAnimation.value),
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

            // Thinking mode indicator ring
            if (_isThinkingMode)
              AnimatedBuilder(
                animation: _thinkingAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _thinkingAnimation.value * math.pi,
                    child: Container(
                      width: widget.size + 16,
                      height: widget.size + 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.aiPrimary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: ThinkingRingPainter(
                          color: theme.aiPrimary,
                          progress: _thinkingAnimation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Main button
            AnimatedBuilder(
              animation: Listenable.merge([
                _breathingAnimation,
                _pressAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value * _pressAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStateColor(theme).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius:
                              _voiceState == VoiceServiceState.listening
                                  ? 8
                                  : 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _getButtonGradient(theme),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.enabled ? _onButtonPressed : null,
                              borderRadius:
                                  BorderRadius.circular(widget.size / 2),
                              child: Center(
                                child: _buildButtonContent(theme),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Thinking mode toggle (top-right)
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _voiceService.toggleThinkingMode();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isThinkingMode
                        ? theme.aiPrimary
                        : theme.secondaryBackground,
                    border: Border.all(
                      color: _isThinkingMode
                          ? Colors.white.withValues(alpha: 0.3)
                          : theme.secondaryText.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isThinkingMode
                        ? FontAwesomeIcons.brain
                        : FontAwesomeIcons.bolt,
                    size: 12,
                    color: _isThinkingMode ? Colors.white : theme.secondaryText,
                  ),
                ),
              ),
            ),

            // Tooltip
            if (_showTooltip)
              Positioned(
                bottom: widget.size + 20,
                child: AnimatedOpacity(
                  opacity: _showTooltip ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI Mental Coach',
                          style: theme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.bolt,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quick Chat',
                              style: theme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              FontAwesomeIcons.brain,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Deep Think',
                              style: theme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
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
    );
  }

  Widget _buildButtonContent(FlutterFlowTheme theme) {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return _buildListeningIndicator(theme);
      case VoiceServiceState.thinking:
        return _buildThinkingIndicator(theme);
      case VoiceServiceState.speaking:
        return _buildSpeakingIndicator(theme);
      case VoiceServiceState.error:
        return _buildErrorIndicator(theme);
      case VoiceServiceState.connecting:
        return _buildConnectingIndicator(theme);
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.ready:
        return _buildMicrophoneIcon(theme);
    }
  }

  Widget _buildMicrophoneIcon(FlutterFlowTheme theme) {
    return Icon(
      FontAwesomeIcons.microphone,
      size: widget.size * 0.35,
      color: Colors.white,
    );
  }

  Widget _buildListeningIndicator(FlutterFlowTheme theme) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_breathingAnimation.value - 1.0) * 2,
          child: Icon(
            FontAwesomeIcons.microphoneLines,
            size: widget.size * 0.35,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildThinkingIndicator(FlutterFlowTheme theme) {
    return SizedBox(
      width: widget.size * 0.4,
      height: widget.size * 0.4,
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildSpeakingIndicator(FlutterFlowTheme theme) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_breathingAnimation.value - 1.0) * 1.5,
          child: Icon(
            FontAwesomeIcons.volumeHigh,
            size: widget.size * 0.35,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildConnectingIndicator(FlutterFlowTheme theme) {
    return SizedBox(
      width: widget.size * 0.3,
      height: widget.size * 0.3,
      child: CircularProgressIndicator(
        valueColor:
            AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorIndicator(FlutterFlowTheme theme) {
    return Icon(
      Icons.error_outline,
      size: widget.size * 0.35,
      color: Colors.red[300],
    );
  }

  Color _getStateColor(FlutterFlowTheme theme) {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return const Color(0xFF4CAF50); // Green
      case VoiceServiceState.thinking:
        return const Color(0xFFFF9800); // Orange
      case VoiceServiceState.speaking:
        return const Color(0xFF2196F3); // Blue
      case VoiceServiceState.error:
        return const Color(0xFFF44336); // Red
      case VoiceServiceState.connecting:
        return theme.secondary;
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.ready:
        return _isThinkingMode ? theme.aiPrimary : theme.primary;
    }
  }

  Gradient _getButtonGradient(FlutterFlowTheme theme) {
    final color = _getStateColor(theme);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withValues(alpha: 0.8),
      ],
      stops: const [0.0, 1.0],
    );
  }
}

/// Custom painter for thinking mode ring
class ThinkingRingPainter extends CustomPainter {
  final Color color;
  final double progress;

  ThinkingRingPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw animated arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );

    // Draw small dots at intervals
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotCenter, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(ThinkingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
