import 'package:flutter/material.dart';
import 'dart:async';
import '/flutter_flow/flutter_flow_theme.dart';
import '/ai_integration/services/gemini_live_agent_service.dart';
import '/ai_integration/services/mind_coach_session_service.dart';
import '/ai_integration/models/mind_coach_models.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Voice-First MindCoach Session Widget
/// Minimal UI for voice-first coaching sessions during active rounds
/// Implements the UX spec from mindCoachUX.md
class MindCoachVoiceSessionWidget extends StatefulWidget {
  const MindCoachVoiceSessionWidget({
    super.key,
    required this.templateId,
    required this.templateName,
    required this.coachingText,
    this.durationEstimate = 60,
    this.config,
  });

  final String templateId;
  final String templateName;
  final String coachingText;
  final int durationEstimate; // seconds
  final MindCoachAgentConfig? config;

  @override
  State<MindCoachVoiceSessionWidget> createState() =>
      _MindCoachVoiceSessionWidgetState();
}

class _MindCoachVoiceSessionWidgetState
    extends State<MindCoachVoiceSessionWidget>
    with TickerProviderStateMixin {
  final GeminiLiveAgentService _agentService = GeminiLiveAgentService();
  final MindCoachSessionService _sessionService =
      MindCoachSessionService.instance;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _lineController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  // State
  List<String> _coachingLines = [];
  int _currentLineIndex = -1;
  bool _isComplete = false;
  bool _isMicActive = false;
  String? _sessionId;
  DateTime? _sessionStartTime;

  // Stream subscriptions
  StreamSubscription<LiveKitAgentState>? _stateSubscription;
  StreamSubscription<String>? _responseTextSubscription;

  @override
  void initState() {
    super.initState();

    // Parse coaching text into lines
    _coachingLines = widget.coachingText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationEstimate),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Start animations
    _fadeController.forward();
    _startSession();
  }

  Future<void> _startSession() async {
    _sessionStartTime = DateTime.now();

    // Create session in background
    final userId = currentUserUid;
    if (userId.isNotEmpty) {
      final session = MindCoachSession(
        sessionId: '',
        userId: userId,
        timestamp: DateTime.now(),
        templateId: widget.templateId,
        contentId: null,
        scenarioTag: null,
        varkMode: widget.config?.varkMode ?? 'Aural',
        level: widget.config?.level ?? 'Foundation',
        length: widget.config?.length ?? 'standard',
        cueUsed: widget.templateName,
        routineType: 'Voice-First MindCoach',
        mindsetBefore: 3, // Default for voice sessions
        context: widget.config?.context ?? {},
        coachingTextDelivered: widget.coachingText,
        followUpQuestion: null,
        successSignals: {
          'session_completed': false,
          'mindset_improved': false,
        },
        sessionType: 'coaching',
      );

      _sessionId = await _sessionService.createSession(session);
    }

    // Connect to LiveKit if config provided
    if (widget.config != null) {
      try {
        final roomName = 'mindcoach_${DateTime.now().millisecondsSinceEpoch}';
        await _agentService.connect(
          roomName: roomName,
          config: widget.config!,
        );

        // Listen to state changes
        _stateSubscription = _agentService.stateStream.listen((state) {
          setState(() {
            _isMicActive = state == LiveKitAgentState.listening ||
                state == LiveKitAgentState.ready;
          });
        });

        // Listen to response text for line-by-line display
        _responseTextSubscription =
            _agentService.responseTextStream.listen((text) {
          // If agent sends text, we can update lines dynamically
          // For now, we use the pre-loaded coaching text
        });
      } catch (e) {
        debugPrint('Error connecting to LiveKit: $e');
      }
    }

    // Start displaying lines
    _startLineDisplay();
    _progressController.forward();
  }

  void _startLineDisplay() {
    if (_coachingLines.isEmpty) {
      _completeSession();
      return;
    }

    // Display first line immediately
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentLineIndex = 0;
        });
        _displayNextLine();
      }
    });
  }

  void _displayNextLine() {
    if (_currentLineIndex >= _coachingLines.length - 1) {
      // All lines displayed, wait then complete
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _completeSession();
        }
      });
      return;
    }

    // Display next line with delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _currentLineIndex < _coachingLines.length - 1) {
        setState(() {
          _currentLineIndex++;
        });
        _displayNextLine();
      }
    });
  }

  Future<void> _completeSession() async {
    if (_isComplete) return;

    setState(() {
      _isComplete = true;
    });

    // Update session in background
    if (_sessionId != null) {
      final duration = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : widget.durationEstimate;

      await _sessionService.updateSession(_sessionId!, {
        'successSignalFlags': {
          'session_completed': true,
          'mindset_improved': false,
        },
        'validator_status': 'PASS',
        'duration': duration,
      });
    }

    // Disconnect from LiveKit
    await _agentService.disconnect();

    // Fade out and return
    await _fadeController.reverse();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lineController.dispose();
    _progressController.dispose();
    _stateSubscription?.cancel();
    _responseTextSubscription?.cancel();
    _agentService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryBackground,
              theme.primaryBackground.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Template name • Duration estimate
              _buildTopBar(theme),
              
              // Center: Large text, line-by-line display
              Expanded(
                child: _buildCenterContent(theme),
              ),
              
              // Bottom: Mic icon + Progress ring
              _buildBottomIndicators(theme),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '${widget.templateName} • ~${widget.durationEstimate} seconds',
        style: theme.bodySmall.copyWith(
          color: theme.secondaryText,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCenterContent(FlutterFlowTheme theme) {
    if (_isComplete) {
      return Center(
        child: Text(
          'Session complete.',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_currentLineIndex < 0) {
      return const SizedBox.shrink();
    }

    // Display current line and previous lines
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show all lines up to current index
            for (int i = 0; i <= _currentLineIndex && i < _coachingLines.length; i++)
              _buildLine(theme, _coachingLines[i], i == _currentLineIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(FlutterFlowTheme theme, String text, bool isCurrent) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isCurrent ? 1.0 : 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              text,
              style: theme.headlineMedium.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
                height: 1.4,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomIndicators(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isMicActive
                  ? theme.aiPrimary.withValues(alpha: 0.2)
                  : theme.glassBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isMicActive
                    ? theme.aiPrimary
                    : theme.glassBorder.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.mic,
              color: _isMicActive ? theme.aiPrimary : theme.secondaryText,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Progress ring
          SizedBox(
            width: 48,
            height: 48,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: 3,
                  backgroundColor: theme.glassBorder.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
