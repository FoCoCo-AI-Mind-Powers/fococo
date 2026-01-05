import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../services/livekit_cartesia_voice_service.dart' 
    show LiveKitCartesiaVoiceService, LiveKitConnectionState, VoiceModeState;
import 'just_talk_model.dart';
export 'just_talk_model.dart';

/// Just Talk Widget - Voice chat interface for AI coaching
class JustTalkWidget extends StatefulWidget {
  const JustTalkWidget({Key? key}) : super(key: key);

  static const String routeName = 'just_talk';
  static const String routePath = '/just_talk';

  @override
  State<JustTalkWidget> createState() => _JustTalkWidgetState();
}

class _JustTalkWidgetState extends State<JustTalkWidget>
    with TickerProviderStateMixin {
  late JustTalkModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;
  LiveKitConnectionState _connectionState = LiveKitConnectionState.disconnected;
  VoiceModeState _voiceState = VoiceModeState.assistant;
  bool _isMicrophoneEnabled = false;
  bool _isPaused = false;
  
  final LiveKitCartesiaVoiceService _livekitService = LiveKitCartesiaVoiceService();
  
  // Animated gradient controller
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    // #region agent log
    final logEntry = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'E',
      'location': 'just_talk_widget.dart:initState',
      'message': 'initState ENTRY',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(logEntry)}\n', mode: FileMode.append);
    // #endregion
    
    super.initState();
    _model = createModel(context, () => JustTalkModel());

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

    // Initialize gradient animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _gradientController.repeat();

    // #region agent log
    final logEntry2 = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'E',
      'location': 'just_talk_widget.dart:initState',
      'message': 'BEFORE stream listeners setup',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(logEntry2)}\n', mode: FileMode.append);
    // #endregion
    
    // Listen to LiveKit connection state with error handling
    _livekitService.connectionStateStream.listen(
      (state) {
        // #region agent log
        final logEntry3 = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'E',
          'location': 'just_talk_widget.dart:connectionStateStream',
          'message': 'connectionStateStream callback',
          'data': {'state': state.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(logEntry3)}\n', mode: FileMode.append);
        // #endregion
        _onConnectionStateChanged(state);
      },
      onError: (error) {
        // #region agent log
        final logEntry4 = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'E',
          'location': 'just_talk_widget.dart:connectionStateStream',
          'message': 'connectionStateStream ERROR',
          'data': {'error': error.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(logEntry4)}\n', mode: FileMode.append);
        // #endregion
        
        if (mounted) {
          if (kDebugMode) {
            print('❌ Connection state stream error: $error');
          }
          setState(() {
            _connectionState = LiveKitConnectionState.disconnected;
          });
        }
      },
    );
    
    // Listen to voice state with error handling
    _livekitService.voiceStateStream.listen(
      (state) {
        // #region agent log
        final logEntry5 = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'E',
          'location': 'just_talk_widget.dart:voiceStateStream',
          'message': 'voiceStateStream callback',
          'data': {'state': state.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(logEntry5)}\n', mode: FileMode.append);
        // #endregion
        _onVoiceStateChanged(state);
      },
      onError: (error) {
        // #region agent log
        final logEntry6 = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'E',
          'location': 'just_talk_widget.dart:voiceStateStream',
          'message': 'voiceStateStream ERROR',
          'data': {'error': error.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(logEntry6)}\n', mode: FileMode.append);
        // #endregion
        
        if (mounted) {
          if (kDebugMode) {
            print('❌ Voice state stream error: $error');
          }
          setState(() {
            _voiceState = VoiceModeState.assistant;
          });
        }
      },
    );
    
    // #region agent log
    final logEntry7 = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'E',
      'location': 'just_talk_widget.dart:initState',
      'message': 'initState EXIT',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(logEntry7)}\n', mode: FileMode.append);
    // #endregion
    
    // Don't auto-connect - let user initiate connection
    // Connection will happen when user taps the button
  }
  
  void _onVoiceStateChanged(VoiceModeState state) {
    if (mounted) {
      setState(() {
        _voiceState = state;
        _isPaused = state == VoiceModeState.paused;
      });
      
      // Adjust animations based on voice state
      switch (state) {
        case VoiceModeState.listening:
          _pulseController.repeat(reverse: true);
          _gradientController.repeat();
          break;
        case VoiceModeState.speaking:
          _pulseController.stop();
          _gradientController.repeat();
          break;
        case VoiceModeState.thinking:
          _pulseController.stop();
          _gradientController.repeat();
          break;
        case VoiceModeState.paused:
          _pulseController.stop();
          _gradientController.stop();
          break;
        case VoiceModeState.ready:
        case VoiceModeState.assistant:
          _pulseController.repeat(reverse: true);
          _gradientController.repeat();
          break;
      }
    }
  }
  
  Future<void> _connectToLiveKit() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _connectionState = LiveKitConnectionState.connecting;
      });
      
      await _livekitService.connect(
        roomName: 'fococo-voice-${DateTime.now().millisecondsSinceEpoch}',
        participantName: 'User',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionState = LiveKitConnectionState.disconnected;
        });
        
        // Show user-friendly error message
        final errorMessage = e.toString();
        final isTimeout = errorMessage.contains('timeout') || 
                         errorMessage.contains('Timeout');
        final isNetworkError = errorMessage.contains('SocketException') ||
                              errorMessage.contains('Network') ||
                              errorMessage.contains('Failed host lookup');
        
        String displayMessage;
        if (isTimeout) {
          displayMessage = 'Connection timed out. Please check your internet connection and try again.';
        } else if (isNetworkError) {
          displayMessage = 'Network error. Please check your internet connection.';
        } else {
          displayMessage = 'Connection failed. Please try again.\n\nError: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: FlutterFlowTheme.of(context).error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
  
  void _onConnectionStateChanged(LiveKitConnectionState state) {
    if (mounted) {
      setState(() {
        _connectionState = state;
      });
      
      // Adjust animations based on state
      switch (state) {
        case LiveKitConnectionState.connected:
          _pulseController.repeat(reverse: true);
          break;
        case LiveKitConnectionState.connecting:
        case LiveKitConnectionState.reconnecting:
          _pulseController.stop();
          break;
        case LiveKitConnectionState.disconnected:
          _pulseController.repeat(reverse: true);
          break;
      }
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _gradientController.dispose();
    
    // Safely disconnect from LiveKit
    try {
      _livekitService.disconnect();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error during disconnect: $e');
      }
    }
    
    super.dispose();
  }

  void _onButtonPressed() async {
    if (!mounted) return;
    
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Scale animation
      setState(() => _isPressed = true);
      await _scaleController.forward();
      await _scaleController.reverse();
      setState(() => _isPressed = false);

      // If not connected, try to connect first
      if (_connectionState != LiveKitConnectionState.connected) {
        await _connectToLiveKit();
        return;
      }

      // Toggle microphone based on current state
      if (_voiceState == VoiceModeState.assistant || _voiceState == VoiceModeState.ready) {
        // Start voice mode
        try {
          await _livekitService.setMicrophoneEnabled(true);
          if (mounted) {
            setState(() {
              _isMicrophoneEnabled = true;
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start voice mode: ${e.toString()}'),
                duration: const Duration(seconds: 3),
                backgroundColor: FlutterFlowTheme.of(context).error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }
  
  void _onPausePressed() async {
    if (!mounted) return;
    
    try {
      HapticFeedback.lightImpact();
      if (_isPaused) {
        await _livekitService.resume();
      } else {
        await _livekitService.pause();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isPaused ? 'resume' : 'pause'}: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }
  
  void _onStopPressed() async {
    if (!mounted) return;
    
    try {
      HapticFeedback.mediumImpact();
      await _livekitService.stop();
      if (mounted) {
        setState(() {
          _isMicrophoneEnabled = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }
  
  void _onRestartPressed() async {
    if (!mounted) return;
    
    try {
      HapticFeedback.lightImpact();
      await _livekitService.restart();
      if (mounted) {
        setState(() {
          _isMicrophoneEnabled = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.primaryText,
            size: 24,
          ),
          onPressed: () async {
            context.pop();
          },
        ),
        title: Text(
          'Just Talk',
          style: theme.titleLarge.copyWith(
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: _getAnimatedBackgroundGradient(theme),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main button with animated gradient
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseAnimation, 
                    _scaleAnimation, 
                    _gradientAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isPressed ? _scaleAnimation.value : 1.0,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getButtonColor(theme).withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: _isMicrophoneEnabled
                                  ? _pulseAnimation.value * 8
                                  : 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onButtonPressed,
                            borderRadius: BorderRadius.circular(60),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _getAnimatedButtonGradient(theme),
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
                ),
                const SizedBox(height: 32),
                // Status text
                Text(
                  _getStatusText(),
                  style: theme.bodyLarge.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Control buttons (only show in voice mode)
                if (_voiceState != VoiceModeState.assistant)
                  _buildControlButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(FlutterFlowTheme theme) {
    if (_connectionState != LiveKitConnectionState.connected) {
      return _buildConnectingIndicator(theme);
    }
    
    switch (_voiceState) {
      case VoiceModeState.listening:
        return _buildListeningIndicator(theme);
      case VoiceModeState.speaking:
        return _buildSpeakingIndicator(theme);
      case VoiceModeState.thinking:
        return _buildThinkingIndicator(theme);
      case VoiceModeState.paused:
        return _buildPausedIndicator(theme);
      case VoiceModeState.ready:
      case VoiceModeState.assistant:
        return _buildMicrophoneIcon(theme);
    }
  }
  
  Widget _buildPausedIndicator(FlutterFlowTheme theme) {
    return Icon(
      Icons.pause_circle_filled,
      size: 48,
      color: Colors.white,
    );
  }
  
  Widget _buildSpeakingIndicator(FlutterFlowTheme theme) {
    return Icon(
      FontAwesomeIcons.volumeHigh,
      size: 48,
      color: Colors.white,
    );
  }
  
  Widget _buildThinkingIndicator(FlutterFlowTheme theme) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
      ),
    );
  }
  
  Widget _buildConnectingIndicator(FlutterFlowTheme theme) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildMicrophoneIcon(FlutterFlowTheme theme) {
    return Icon(
      FontAwesomeIcons.microphone,
      size: 48,
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
            size: 48,
            color: Colors.white,
          ),
        );
      },
    );
  }


  Color _getButtonColor(FlutterFlowTheme theme) {
    if (_connectionState != LiveKitConnectionState.connected) {
      return theme.warning; // Orange for connecting
    }
    
    switch (_voiceState) {
      case VoiceModeState.listening:
        return theme.success; // Green for listening
      case VoiceModeState.speaking:
        return theme.info; // Blue for speaking
      case VoiceModeState.thinking:
        return theme.warning; // Orange for thinking
      case VoiceModeState.paused:
        return theme.secondaryText; // Gray for paused
      case VoiceModeState.ready:
      case VoiceModeState.assistant:
        return theme.primary; // Default FoCoCo primary color
    }
  }

  /// Get animated button gradient based on voice state and theme colors
  Gradient _getAnimatedButtonGradient(FlutterFlowTheme theme) {
    // Get theme colors for gradient animation
    final colors = _getGradientColorsForState(theme);
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(colors[0], colors[1], _gradientAnimation.value)!,
        Color.lerp(colors[1], colors[2], _gradientAnimation.value)!,
        Color.lerp(colors[2], colors[0], _gradientAnimation.value)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
  
  /// Get gradient colors based on voice state
  List<Color> _getGradientColorsForState(FlutterFlowTheme theme) {
    switch (_voiceState) {
      case VoiceModeState.listening:
        return [
          theme.success, // Green
          theme.tertiary, // Forest green
          theme.success.withValues(alpha: 0.8),
        ];
      case VoiceModeState.speaking:
        return [
          theme.info, // Blue
          theme.secondary, // Navy
          theme.info.withValues(alpha: 0.8),
        ];
      case VoiceModeState.thinking:
        return [
          theme.warning, // Orange
          theme.primary, // Brand orange
          theme.warning.withValues(alpha: 0.8),
        ];
      case VoiceModeState.paused:
        return [
          theme.secondaryText,
          theme.secondaryText.withValues(alpha: 0.7),
          theme.secondaryText.withValues(alpha: 0.5),
        ];
      case VoiceModeState.ready:
      case VoiceModeState.assistant:
        return [
          theme.primary, // Brand orange
          theme.secondary, // Navy
          theme.tertiary, // Green
        ];
    }
  }
  
  /// Get animated background gradient
  Gradient _getAnimatedBackgroundGradient(FlutterFlowTheme theme) {
    final colors = _getGradientColorsForState(theme);
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.primaryBackground,
        Color.lerp(
          colors[0].withValues(alpha: 0.1),
          colors[1].withValues(alpha: 0.1),
          _gradientAnimation.value,
        )!,
        theme.secondaryBackground,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
  
  /// Build control buttons (pause, stop, restart)
  Widget _buildControlButtons(FlutterFlowTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume button
        _buildControlButton(
          icon: _isPaused ? FontAwesomeIcons.play : FontAwesomeIcons.pause,
          label: _isPaused ? 'Resume' : 'Pause',
          onPressed: _onPausePressed,
          theme: theme,
        ),
        const SizedBox(width: 16),
        // Stop button
        _buildControlButton(
          icon: FontAwesomeIcons.stop,
          label: 'Stop',
          onPressed: _onStopPressed,
          theme: theme,
          isStop: true,
        ),
        const SizedBox(width: 16),
        // Restart button
        _buildControlButton(
          icon: FontAwesomeIcons.rotateRight,
          label: 'Restart',
          onPressed: _onRestartPressed,
          theme: theme,
        ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required FlutterFlowTheme theme,
    bool isStop = false,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isStop
                  ? [
                      theme.error,
                      theme.error.withValues(alpha: 0.8),
                    ]
                  : [
                      theme.primary.withValues(alpha: 0.8),
                      theme.secondary.withValues(alpha: 0.8),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isStop ? theme.error : theme.primary)
                    .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (_connectionState != LiveKitConnectionState.connected) {
      switch (_connectionState) {
        case LiveKitConnectionState.connecting:
          return 'Connecting to voice service...';
        case LiveKitConnectionState.reconnecting:
          return 'Reconnecting...';
        case LiveKitConnectionState.disconnected:
          return 'Tap to connect';
        case LiveKitConnectionState.connected:
          break;
      }
    }
    
    switch (_voiceState) {
      case VoiceModeState.assistant:
        return 'Tap to start talking with Carter, your AI Coach';
      case VoiceModeState.ready:
        return 'Ready to listen. Tap to start!';
      case VoiceModeState.listening:
        return 'Listening... Speak now!';
      case VoiceModeState.thinking:
        return 'Carter is thinking...';
      case VoiceModeState.speaking:
        return 'Carter is speaking...';
      case VoiceModeState.paused:
        return 'Paused. Tap resume to continue.';
    }
  }
}
