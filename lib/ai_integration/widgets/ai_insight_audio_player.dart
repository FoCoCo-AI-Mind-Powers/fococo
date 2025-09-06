import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import 'package:just_audio/just_audio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '/flutter_flow/flutter_flow_theme.dart';

import '../models/ai_models.dart';
import '../services/cartesia_tts_service.dart';

/// Audio player widget for AI insights with Cartesia TTS integration
class AIInsightAudioPlayer extends StatefulWidget {
  final AIInsightWithAudioResponse? insightWithAudio;
  final String? fallbackText;
  final VarkPreferencesStruct? varkPreferences;
  final String contentType;
  final bool autoPlay;
  final VoidCallback? onPlayComplete;
  final Color? primaryColor;
  final Color? backgroundColor;

  const AIInsightAudioPlayer({
    super.key,
    this.insightWithAudio,
    this.fallbackText,
    this.varkPreferences,
    this.contentType = 'coaching',
    this.autoPlay = false,
    this.onPlayComplete,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<AIInsightAudioPlayer> createState() => _AIInsightAudioPlayerState();
}

class _AIInsightAudioPlayerState extends State<AIInsightAudioPlayer>
    with TickerProviderStateMixin {
  final CartesiaTTSService _ttsService = CartesiaTTSService.instance;

  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAudioListeners();

    // Auto-play if requested and audio is available
    if (widget.autoPlay && widget.insightWithAudio?.hasAudio == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playExistingAudio();
      });
    }
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
  }

  void _setupAudioListeners() {
    _ttsService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isPaused = !state.playing &&
              state.processingState != ProcessingState.completed;

          if (state.processingState == ProcessingState.completed) {
            _onPlaybackComplete();
          }
        });

        // Control wave animation based on playback state
        if (_isPlaying) {
          _waveAnimationController.repeat();
        } else {
          _waveAnimationController.stop();
        }
      }
    });

    // Listen to position changes
    Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentPosition = _ttsService.currentPosition ?? Duration.zero;
          _totalDuration = _ttsService.duration ?? Duration.zero;
        });
      }
    });
  }

  void _onPlaybackComplete() {
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentPosition = Duration.zero;
    });

    _waveAnimationController.stop();
    _waveAnimationController.reset();

    widget.onPlayComplete?.call();
  }

  Future<void> _playExistingAudio() async {
    if (widget.insightWithAudio?.hasAudio != true) return;

    final audioPath = widget.insightWithAudio!.audioPath;
    if (audioPath == null || !File(audioPath).existsSync()) {
      if (kDebugMode) {
        print('⚠️ Audio file not found: $audioPath');
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await _ttsService.playAudioData(
        await File(audioPath).readAsBytes(),
        onComplete: _onPlaybackComplete,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing existing audio: $e');
      }
      _showErrorSnackBar('Failed to play audio');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateAndPlayAudio() async {
    final textToSpeak = widget.insightWithAudio?.summary ??
        widget.fallbackText ??
        'No text available for audio playback.';

    try {
      setState(() {
        _isLoading = true;
      });

      await _ttsService.speakText(
        text: textToSpeak,
        varkPreferences: widget.varkPreferences ??
            VarkPreferencesStruct(
              visual: false,
              aural: true,
              readWrite: false,
              kinesthetic: false,
            ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating and playing audio: $e');
      }
      _showErrorSnackBar(
          'Failed to generate audio. Please check your Cartesia API key.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _ttsService.pausePlayback();
    } else if (_isPaused) {
      await _ttsService.resumePlayback();
    } else {
      // Start new playback
      if (widget.insightWithAudio?.hasAudio == true) {
        await _playExistingAudio();
      } else {
        await _generateAndPlayAudio();
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _ttsService.stopSpeaking();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentPosition = Duration.zero;
    });
    _waveAnimationController.stop();
    _waveAnimationController.reset();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primary;
    final backgroundColor = widget.backgroundColor ?? theme.secondaryBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with audio indicator
          Row(
            children: [
              Icon(
                FontAwesomeIcons.volumeHigh,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Insight Audio',
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
              ),
              if (widget.insightWithAudio?.hasAudio == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'High Quality',
                    style: theme.bodySmall.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Audio controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryBackground,
                            ),
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? FontAwesomeIcons.pause
                              : FontAwesomeIcons.play,
                          color: theme.primaryBackground,
                          size: 20,
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Stop button
              if (_isPlaying || _isPaused)
                GestureDetector(
                  onTap: _stopPlayback,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.secondaryText.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FontAwesomeIcons.stop,
                      color: theme.secondaryText,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar and time
          if (_totalDuration.inSeconds > 0) ...[
            Row(
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(
                      value: _totalDuration.inSeconds > 0
                          ? _currentPosition.inSeconds /
                              _totalDuration.inSeconds
                          : 0.0,
                      backgroundColor: theme.alternate,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Wave animation when playing
          if (_isPlaying)
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final delay = index * 0.2;
                    final animationValue = (_waveAnimation.value + delay) % 1.0;
                    final height = 4 + (animationValue * 12);

                    return Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),

          // Audio info
          if (widget.insightWithAudio?.hasAudio == true) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.microphone,
                  size: 12,
                  color: theme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Powered by Cartesia',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }
}
