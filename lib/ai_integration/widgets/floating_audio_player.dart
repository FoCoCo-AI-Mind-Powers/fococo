import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../services/cartesia_tts_service.dart';

/// Compact floating audio player for navbar
/// Shows when audio is playing, centered above navigation items
class FloatingAudioPlayer extends StatefulWidget {
  const FloatingAudioPlayer({Key? key}) : super(key: key);

  @override
  State<FloatingAudioPlayer> createState() => _FloatingAudioPlayerState();
}

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer>
    with TickerProviderStateMixin {
  final CartesiaTTSService _ttsService = CartesiaTTSService.instance;
  
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _setupAnimations();
    _setupAudioListeners();
  }

  void _setupAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupAudioListeners() {
    _ttsService.playerStateStream.listen((state) {
      if (mounted) {
        final wasPlaying = _isPlaying;
        setState(() {
          _isPlaying = state.playing;
          _isPaused = !state.playing &&
              state.processingState != ProcessingState.completed;
        });

        // Control animations
        if (_isPlaying && !wasPlaying) {
          _waveAnimationController.repeat();
          _slideController.forward();
        } else if (!_isPlaying && wasPlaying) {
          _waveAnimationController.stop();
          _waveAnimationController.reset();
          // Hide after a delay when stopped
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isPlaying && !_isPaused) {
              _slideController.reverse();
            }
          });
        }
      }
    });

    // Listen to position changes
    Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentPosition = _ttsService.currentPosition;
          _totalDuration = _ttsService.duration ?? Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.lightImpact();
    
    if (_isPlaying) {
      await _ttsService.pausePlayback();
    } else if (_isPaused) {
      await _ttsService.resumePlayback();
    }
  }

  Future<void> _stopPlayback() async {
    HapticFeedback.mediumImpact();
    await _ttsService.stopSpeaking();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    // Only show if audio is playing or paused
    if (!_isPlaying && !_isPaused) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary.withValues(alpha: 0.95),
              theme.primary.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Pause button
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Wave animation or progress
            if (_isPlaying) ...[
              SizedBox(
                width: 40,
                height: 20,
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final animationValue = (_waveAnimation.value + delay) % 1.0;
                        final height = 4 + (animationValue * 8);

                        return Container(
                          width: 2.5,
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ] else ...[
              Icon(
                FontAwesomeIcons.pause,
                color: Colors.white.withValues(alpha: 0.7),
                size: 12,
              ),
            ],
            
            const SizedBox(width: 12),
            
            // Time display
            if (_totalDuration.inSeconds > 0) ...[
              Text(
                _formatDuration(_currentPosition),
                style: theme.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ${_formatDuration(_totalDuration)}',
                style: theme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
            
            const SizedBox(width: 8),
            
            // Stop button
            GestureDetector(
              onTap: _stopPlayback,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.stop,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Close / dismiss
            GestureDetector(
              onTap: _closePlayer,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closePlayer() async {
    HapticFeedback.lightImpact();
    await _ttsService.stopSpeaking();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
      _slideController.reverse();
    }
  }
}

