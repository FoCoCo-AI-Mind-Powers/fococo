import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/gemini_voice_service.dart';
import 'voice_chat_modal.dart';

/// Floating voice chat button that sits in the center of the bottom navigation
class VoiceChatButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final double size;

  const VoiceChatButton({
    Key? key,
    this.onPressed,
    this.enabled = true,
    this.size = 60.0,
  }) : super(key: key);

  @override
  State<VoiceChatButton> createState() => _VoiceChatButtonState();
}

class _VoiceChatButtonState extends State<VoiceChatButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;
  VoiceServiceState _voiceState = VoiceServiceState.uninitialized;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Listen to voice service state
    GeminiVoiceService().stateStream.listen(_onVoiceStateChanged);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged(VoiceServiceState state) {
    if (mounted) {
      setState(() {
        _voiceState = state;
      });

      // Adjust animations based on state
      switch (state) {
        case VoiceServiceState.listening:
          _pulseController.repeat(reverse: true);
          break;
        case VoiceServiceState.thinking:
        case VoiceServiceState.speaking:
          _pulseController.stop();
          break;
        case VoiceServiceState.ready:
        case VoiceServiceState.uninitialized:
        case VoiceServiceState.error:
          _pulseController.repeat(reverse: true);
          break;
      }
    }
  }

  void _onButtonPressed() async {
    if (!widget.enabled) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Scale animation
    setState(() => _isPressed = true);
    await _scaleController.forward();
    await _scaleController.reverse();
    setState(() => _isPressed = false);

    // Show voice chat modal
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => const FoCoCoVoiceChatModal(),
      );
    }

    // Execute custom callback if provided
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getButtonColor(theme).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: _voiceState == VoiceServiceState.listening
                      ? _pulseAnimation.value * 8
                      : 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? _onButtonPressed : null,
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getButtonGradient(theme),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _buildButtonContent(theme),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.ready:
        return _buildMicrophoneIcon(theme);
    }
  }

  Widget _buildMicrophoneIcon(FlutterFlowTheme theme) {
    return Icon(
      FontAwesomeIcons.microphone,
      size: widget.size * 0.4,
      color: Colors.white,
    );
  }

  Widget _buildListeningIndicator(FlutterFlowTheme theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Icon(
            FontAwesomeIcons.microphoneLines,
            size: widget.size * 0.4,
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
    return Icon(
      FontAwesomeIcons.volumeHigh,
      size: widget.size * 0.4,
      color: Colors.white,
    );
  }

  Widget _buildErrorIndicator(FlutterFlowTheme theme) {
    return Icon(
      Icons.error_outline,
      size: widget.size * 0.4,
      color: Colors.red[300],
    );
  }

  Color _getButtonColor(FlutterFlowTheme theme) {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return const Color(0xFF4CAF50); // Green for active listening
      case VoiceServiceState.thinking:
        return const Color(0xFFFF9800); // Orange for thinking
      case VoiceServiceState.speaking:
        return const Color(0xFF2196F3); // Blue for speaking
      case VoiceServiceState.error:
        return const Color(0xFFF44336); // Red for error
      case VoiceServiceState.uninitialized:
      case VoiceServiceState.ready:
        return theme.primary; // Default FoCoCo primary color
    }
  }

  Gradient _getButtonGradient(FlutterFlowTheme theme) {
    final color = _getButtonColor(theme);

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

/// Enhanced floating voice button with more sophisticated animations
class EnhancedVoiceChatButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final double size;
  final EdgeInsets margin;

  const EnhancedVoiceChatButton({
    Key? key,
    this.onPressed,
    this.enabled = true,
    this.size = 60.0,
    this.margin = const EdgeInsets.only(bottom: 20),
  }) : super(key: key);

  @override
  State<EnhancedVoiceChatButton> createState() =>
      _EnhancedVoiceChatButtonState();
}

class _EnhancedVoiceChatButtonState extends State<EnhancedVoiceChatButton>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;

  VoiceServiceState _voiceState = VoiceServiceState.uninitialized;
  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start breathing animation
    _breathingController.repeat(reverse: true);

    // Listen to voice service state
    GeminiVoiceService().stateStream.listen(_onVoiceStateChanged);

    // Show tooltip after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showTooltip = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showTooltip = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged(VoiceServiceState state) {
    if (mounted) {
      setState(() {
        _voiceState = state;
      });

      switch (state) {
        case VoiceServiceState.listening:
          _rippleController.repeat();
          _rotationController.stop();
          break;
        case VoiceServiceState.thinking:
          _rippleController.stop();
          _rotationController.repeat();
          break;
        case VoiceServiceState.speaking:
          _rippleController.stop();
          _rotationController.stop();
          break;
        case VoiceServiceState.ready:
        case VoiceServiceState.uninitialized:
        case VoiceServiceState.error:
          _rippleController.stop();
          _rotationController.stop();
          break;
      }
    }
  }

  void _onButtonPressed() async {
    if (!widget.enabled) return;

    HapticFeedback.lightImpact();

    // Trigger ripple effect
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
        builder: (context) => const FoCoCoVoiceChatModal(),
      );
    }

    widget.onPressed?.call();
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
          children: [
            // Ripple effect
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Container(
                  width: widget.size * (1 + _rippleAnimation.value * 0.8),
                  height: widget.size * (1 + _rippleAnimation.value * 0.8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primary.withValues(
                        alpha: 0.3 * (1 - _rippleAnimation.value),
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

            // Main button with breathing animation
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value,
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 3.14159,
                        child: VoiceChatButton(
                          onPressed: _onButtonPressed,
                          enabled: widget.enabled,
                          size: widget.size,
                        ),
                      );
                    },
                  ),
                );
              },
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
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Tap to chat with your AI Coach',
                      style: theme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
