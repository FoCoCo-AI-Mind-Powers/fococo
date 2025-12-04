import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/glass_design_system.dart';
import '../ai_integration/services/fococo_voice_service.dart';
import '../ai_integration/widgets/voice_chat_modal.dart';

class FloatingVoiceButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final double? bottom;

  const FloatingVoiceButton({
    Key? key,
    this.onPressed,
    this.bottom = -60.0, // Positioned above navbar (110px height)
  }) : super(key: key);

  @override
  State<FloatingVoiceButton> createState() => _FloatingVoiceButtonState();
}

class _FloatingVoiceButtonState extends State<FloatingVoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _tooltipController;
  late AnimationController _tooltipPulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tooltipFadeAnimation;
  late Animation<double> _tooltipScaleAnimation;
  late Animation<double> _tooltipPulseAnimation;
  VoiceServiceState _voiceState = VoiceServiceState.uninitialized;
  bool _showTooltip = false;
  bool _hasSeenTooltip = false;

  static const String _tooltipSeenKey = 'has_seen_voice_tooltip';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _tooltipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _tooltipFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tooltipController,
      curve: Curves.easeOut,
    ));
    _tooltipScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tooltipController,
      curve: Curves.easeOutBack,
    ));

    _tooltipPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _tooltipPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _tooltipPulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Initialize voice service listener
    FoCoCoVoiceService().stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _voiceState = state;
        });
      }
    });

    // Check if user has seen tooltip and show if new user
    _checkAndShowTooltip();
  }

  Future<void> _checkAndShowTooltip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenTooltip = prefs.getBool(_tooltipSeenKey) ?? false;

      if (!_hasSeenTooltip && mounted) {
        // Wait a bit before showing tooltip
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          setState(() {
            _showTooltip = true;
          });
          _tooltipController.forward();
          _tooltipPulseController.repeat(reverse: true);

          // Auto-hide after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _showTooltip) {
              _hideTooltip();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking tooltip preference: $e');
    }
  }

  Future<void> _hideTooltip() async {
    if (!_showTooltip) return;

    await _tooltipController.reverse();
    _tooltipPulseController.stop();

    if (mounted) {
      setState(() {
        _showTooltip = false;
      });

      // Mark as seen
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_tooltipSeenKey, true);
        _hasSeenTooltip = true;
      } catch (e) {
        debugPrint('Error saving tooltip preference: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tooltipController.dispose();
    _tooltipPulseController.dispose();
    super.dispose();
  }

  Color _getVoiceButtonColor(FlutterFlowTheme theme) {
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
        return const Color(0xFF9C27B0); // Purple
      default:
        return theme.primary;
    }
  }

  IconData _getVoiceIcon() {
    switch (_voiceState) {
      case VoiceServiceState.listening:
        return Icons.mic;
      case VoiceServiceState.thinking:
      case VoiceServiceState.connecting:
        return Icons.more_horiz;
      case VoiceServiceState.speaking:
        return Icons.volume_up;
      case VoiceServiceState.error:
        return Icons.error_outline;
      default:
        return Icons.mic_rounded;
    }
  }

  void _onPressed() async {
    HapticFeedback.mediumImpact();

    // Hide tooltip when button is pressed
    if (_showTooltip) {
      _hideTooltip();
    }

    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    // Default behavior: Show voice chat modal with voice mode enabled
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        enableDrag: true,
        isDismissible: true,
        builder: (context) => const FoCoCoVoiceChatModal(
          initialVoiceMode:
              true, // Start in voice mode when opened from floating button
        ),
      );
    }
  }

  Widget _buildTooltip(FlutterFlowTheme theme) {
    if (!_showTooltip) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final navbarHeight = 110.0;
    final buttonBottom = navbarHeight + 10.0 + bottomPadding;
    final tooltipBottom = buttonBottom + 80; // 80px above the button

    return Positioned(
      bottom: tooltipBottom,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _tooltipFadeAnimation,
          child: ScaleTransition(
            scale: _tooltipScaleAnimation,
            child: AnimatedBuilder(
              animation: _tooltipPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _tooltipPulseAnimation.value,
                  child: GestureDetector(
                    onTap: _hideTooltip,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.glassBackground.withValues(
                                alpha: GlassDesignSystem.glassOpacity + 0.2),
                            theme.glassTint.withValues(
                                alpha: GlassDesignSystem.glassOpacity + 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.glassBorder.withValues(
                              alpha:
                                  GlassDesignSystem.glassBorderOpacity + 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'JustTalk',
                            style: theme.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Featuring Carter, your AI Coach',
                            style: theme.titleMedium.copyWith(
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ready to help strengthen your mind and game.',
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final navbarHeight = 0.0; // Navbar height
    // Position button 10px above navbar, accounting for safe area
    final buttonBottom = navbarHeight + 10.0 + bottomPadding;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit
          .expand, // Make Stack fill available space for proper positioning
      children: [
        Positioned(
          bottom: buttonBottom,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: GestureDetector(
                    onLongPress: () {
                      if (!_hasSeenTooltip) {
                        setState(() {
                          _showTooltip = true;
                        });
                        _tooltipController.forward();
                        _tooltipPulseController.repeat(reverse: true);
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getVoiceButtonColor(theme),
                            _getVoiceButtonColor(theme).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: _getVoiceButtonColor(theme)
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: _onPressed,
                          child: Center(
                            child: Icon(
                              _getVoiceIcon(),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _buildTooltip(theme),
      ],
    );
  }
}

