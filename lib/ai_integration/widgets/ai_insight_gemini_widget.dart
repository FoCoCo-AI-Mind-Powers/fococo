import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/services/focomap_gemini_voice_service.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Advanced AI Insight Widget with Real-time Gemini Voice Integration
/// Implements the 4-stage pipeline for natural conversational experience
class AIInsightGeminiWidget extends StatefulWidget {
  final String? activeRoundId;
  final VoiceContext initialContext;
  final Function(Map<String, dynamic>)? onInstructionGenerated;
  final Function(VoiceInsight)? onInsightReceived;
  final bool showVisualizations;
  final bool enableSpatialAnalysis;

  const AIInsightGeminiWidget({
    super.key,
    this.activeRoundId,
    this.initialContext = VoiceContext.offCourse,
    this.onInstructionGenerated,
    this.onInsightReceived,
    this.showVisualizations = true,
    this.enableSpatialAnalysis = true,
  });

  @override
  State<AIInsightGeminiWidget> createState() => _AIInsightGeminiWidgetState();
}

class _AIInsightGeminiWidgetState extends State<AIInsightGeminiWidget>
    with TickerProviderStateMixin {
  // Service
  final FoCoMapGeminiVoiceService _voiceService = FoCoMapGeminiVoiceService();

  // Stream subscriptions
  StreamSubscription<VoiceState>? _stateSubscription;
  StreamSubscription<String>? _transcriptionSubscription;
  StreamSubscription<VoiceInsight>? _insightSubscription;
  StreamSubscription<Map<String, dynamic>>? _instructionSubscription;

  // State
  VoiceState _currentState = VoiceState.uninitialized;
  String _currentTranscription = '';
  final List<ConversationItem> _conversationHistory = [];
  Map<String, dynamic>? _spatialVisualization;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Visual feedback
  final List<double> _audioLevels = List.filled(50, 0.0);
  Timer? _audioLevelTimer;
  double _currentAudioLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
  }

  void _initializeAnimations() {
    // Pulse animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Wave animation for audio visualization
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Slide animation for new messages
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initializeVoiceService() async {
    try {
      await _voiceService.initialize();

      // Subscribe to streams
      _stateSubscription = _voiceService.stateStream.listen(_handleStateChange);
      _transcriptionSubscription =
          _voiceService.transcriptionStream.listen(_handleTranscription);
      _insightSubscription = _voiceService.insightStream.listen(_handleInsight);
      _instructionSubscription =
          _voiceService.instructionStream.listen(_handleInstruction);

      setState(() {
        _currentState = VoiceState.initialized;
      });
    } catch (e) {
      debugPrint('Failed to initialize voice service: $e');
      _showError('Failed to initialize voice service');
    }
  }

  void _handleStateChange(VoiceState state) {
    setState(() {
      _currentState = state;
    });

    // Update animations based on state
    switch (state) {
      case VoiceState.listening:
      case VoiceState.voiceDetected:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        _startAudioLevelSimulation();
        break;
      case VoiceState.processing:
        _pulseController.stop();
        _waveController.stop();
        _stopAudioLevelSimulation();
        break;
      default:
        _pulseController.stop();
        _waveController.stop();
        _stopAudioLevelSimulation();
    }
  }

  void _handleTranscription(String transcription) {
    setState(() {
      _currentTranscription = transcription;
    });

    // Animate transcription update
    _fadeController.forward(from: 0);
  }

  void _handleInsight(VoiceInsight insight) {
    setState(() {
      _conversationHistory.add(ConversationItem(
        type: ConversationType.assistant,
        message: insight.message,
        suggestions: insight.suggestions,
        timestamp: DateTime.now(),
        spatialData: insight.spatialData,
      ));
    });

    // Animate new message
    _slideController.forward(from: 0);

    // Callback
    widget.onInsightReceived?.call(insight);

    // Update spatial visualization if available
    if (insight.spatialData != null && widget.showVisualizations) {
      _updateSpatialVisualization(insight.spatialData!);
    }
  }

  void _handleInstruction(Map<String, dynamic> instruction) {
    widget.onInstructionGenerated?.call(instruction);
  }

  void _updateSpatialVisualization(Map<String, dynamic> spatialData) {
    setState(() {
      _spatialVisualization = spatialData;
    });
  }

  Future<void> _toggleListening() async {
    if (_currentState == VoiceState.listening) {
      await _voiceService.stopListening();
    } else {
      // Add user's action to conversation
      _conversationHistory.add(ConversationItem(
        type: ConversationType.user,
        message: 'Started voice input...',
        timestamp: DateTime.now(),
      ));

      await _voiceService.startListening(
        context: widget.initialContext,
        roundId: widget.activeRoundId,
        metadata: {
          'enableSpatialAnalysis': widget.enableSpatialAnalysis,
        },
      );
    }
  }

  void _startAudioLevelSimulation() {
    _audioLevelTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        // Simulate audio levels with realistic patterns
        _currentAudioLevel = (_currentState == VoiceState.voiceDetected)
            ? 0.3 + math.Random().nextDouble() * 0.7
            : math.Random().nextDouble() * 0.3;

        _audioLevels.removeAt(0);
        _audioLevels.add(_currentAudioLevel);
      });
    });
  }

  void _stopAudioLevelSimulation() {
    _audioLevelTimer?.cancel();
    setState(() {
      _currentAudioLevel = 0.0;
      _audioLevels.fillRange(0, _audioLevels.length, 0.0);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            FlutterFlowTheme.of(context).primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header with status
          _buildHeader(),

          // Main content area
          Expanded(
            child: Stack(
              children: [
                // Conversation history
                _buildConversationHistory(),

                // Audio visualization overlay
                if (_currentState == VoiceState.listening ||
                    _currentState == VoiceState.voiceDetected)
                  _buildAudioVisualization(),

                // Spatial visualization
                if (_spatialVisualization != null && widget.showVisualizations)
                  _buildSpatialVisualization(),
              ],
            ),
          ),

          // Current transcription
          if (_currentTranscription.isNotEmpty) _buildTranscriptionDisplay(),

          // Control panel
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassDesignSystem.glassBackground(
        borderRadius: BorderRadius.circular(20),
        tintColor: _getStateColor(),
        opacity: 0.2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Status indicator
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _currentState == VoiceState.listening
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStateColor(),
                        boxShadow: [
                          BoxShadow(
                            color: _getStateColor().withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Status text
              Expanded(
                child: Text(
                  _getStateText(),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                ),
              ),

              // Context indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getContextText(),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversationHistory.length,
      itemBuilder: (context, index) {
        final item = _conversationHistory[index];
        return _buildConversationItem(
            item, index == _conversationHistory.length - 1);
      },
    );
  }

  Widget _buildConversationItem(ConversationItem item, bool isLatest) {
    final isUser = item.type == ConversationType.user;

    return FadeTransition(
      opacity: isLatest ? _fadeAnimation : const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: isLatest
            ? _slideAnimation
            : const AlwaysStoppedAnimation(Offset.zero),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                // AI Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        FlutterFlowTheme.of(context).primary,
                        FlutterFlowTheme.of(context).secondary,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Message bubble
              Flexible(
                child: GlassDesignSystem.glassBackground(
                  borderRadius: BorderRadius.circular(20),
                  tintColor: isUser ? Colors.blue : Colors.white,
                  opacity: isUser ? 0.3 : 0.1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.message,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                        ),

                        // Suggestions
                        if (item.suggestions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.suggestions.map((suggestion) {
                              return GestureDetector(
                                onTap: () => _handleSuggestionTap(suggestion),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          height: 1.0,
                                        ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Timestamp
                        const SizedBox(height: 8),
                        Text(
                          dateTimeFormat('Hm', item.timestamp),
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isUser) ...[
                const SizedBox(width: 12),
                // User Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade800,
                  ),
                  child: Center(
                    child: Text(
                      currentUser?.displayName?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioVisualization() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: AudioWavePainter(
              audioLevels: _audioLevels,
              wavePhase: _waveAnimation.value,
              color: _getStateColor().withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpatialVisualization() {
    return Positioned(
      top: 100,
      right: 16,
      child: GlassDesignSystem.glass3DCard(
        width: 200,
        height: 150,
        tintColor: Colors.purple,
        onTap: () {
          // Show detailed spatial view
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spatial Analysis',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
              ),
              const SizedBox(height: 8),
              // Mini visualization
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.insights,
                      color: Colors.white.withOpacity(0.5),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to view on map',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptionDisplay() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mic,
              color: _getStateColor(),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentTranscription,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main action button
          GestureDetector(
            onTap: _currentState == VoiceState.processing
                ? null
                : _toggleListening,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _currentState == VoiceState.listening
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getStateColor(),
                          _getStateColor().withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStateColor().withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStateIcon(),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    switch (_currentState) {
      case VoiceState.listening:
        return Colors.red;
      case VoiceState.voiceDetected:
        return Colors.orange;
      case VoiceState.processing:
        return Colors.blue;
      case VoiceState.error:
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  String _getStateText() {
    switch (_currentState) {
      case VoiceState.uninitialized:
        return 'Initializing AI...';
      case VoiceState.initialized:
        return 'Ready to listen';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.voiceDetected:
        return 'Processing your voice...';
      case VoiceState.processing:
        return 'Analyzing with Gemini AI...';
      case VoiceState.error:
        return 'Error occurred';
      default:
        return 'Tap to speak';
    }
  }

  IconData _getStateIcon() {
    switch (_currentState) {
      case VoiceState.listening:
      case VoiceState.voiceDetected:
        return Icons.stop;
      case VoiceState.processing:
        return Icons.psychology;
      default:
        return Icons.mic;
    }
  }

  String _getContextText() {
    switch (widget.initialContext) {
      case VoiceContext.preRound:
        return 'Pre-Round';
      case VoiceContext.activeRound:
        return 'Active Round';
      case VoiceContext.postRound:
        return 'Post-Round';
      case VoiceContext.practice:
        return 'Practice';
      case VoiceContext.offCourse:
        return 'Off Course';
    }
  }

  void _handleSuggestionTap(String suggestion) {
    // Add to conversation as user input
    _conversationHistory.add(ConversationItem(
      type: ConversationType.user,
      message: suggestion,
      timestamp: DateTime.now(),
    ));

    // Process as voice input
    setState(() {
      _currentTranscription = suggestion;
    });

    // You could trigger processing here
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _insightSubscription?.cancel();
    _instructionSubscription?.cancel();

    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    _audioLevelTimer?.cancel();
    _voiceService.dispose();

    super.dispose();
  }
}

// Custom painter for audio waves
class AudioWavePainter extends CustomPainter {
  final List<double> audioLevels;
  final double wavePhase;
  final Color color;

  AudioWavePainter({
    required this.audioLevels,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / audioLevels.length;

    for (int i = 0; i < audioLevels.length; i++) {
      final x = i * barWidth;
      final waveOffset = math.sin(wavePhase + i * 0.1) * 10;
      final height = audioLevels[i] * size.height * 0.8 + waveOffset;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, barWidth - 2, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AudioWavePainter oldDelegate) {
    return true;
  }
}

// Conversation item model
class ConversationItem {
  final ConversationType type;
  final String message;
  final List<String> suggestions;
  final DateTime timestamp;
  final Map<String, dynamic>? spatialData;

  ConversationItem({
    required this.type,
    required this.message,
    this.suggestions = const [],
    required this.timestamp,
    this.spatialData,
  });
}

enum ConversationType {
  user,
  assistant,
}
