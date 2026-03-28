import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '/ai_integration/config/cartesia_mcp_config.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import 'fococo_insight_service.dart';

class FoCoCoTabWidget extends StatefulWidget {
  const FoCoCoTabWidget({super.key});

  static const String routeName = 'fococo';
  static const String routePath = '/fococo';

  @override
  State<FoCoCoTabWidget> createState() => _FoCoCoTabWidgetState();
}

// ── Speaker state ────────────────────────────────────────────────────────────

enum _SpeakerState { idle, playing, failed }

class _FoCoCoTabWidgetState extends State<FoCoCoTabWidget>
    with TickerProviderStateMixin {
  // ── Insight ─────────────────────────────────────────────────────────────
  String? _insightText;
  bool _insightLoading = true;

  // ── Speaker / TTS ────────────────────────────────────────────────────────
  _SpeakerState _speakerState = _SpeakerState.idle;
  AudioPlayer? _audioPlayer;
  bool _ttsReady = false; // audio file is cached for today
  bool _showSpeakerLoader = false; // only shown after 2s delay

  // ── Wave animation ────────────────────────────────────────────────────────
  late AnimationController _waveController;

  // ── Speaker pulse animation ───────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── Speaker loader shimmer ────────────────────────────────────────────────
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Wave: slow looping background
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Pulse: for "playing" state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer: for "loading >2s" speaker state
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _audioPlayer = AudioPlayer();
    _audioPlayer!.playerStateStream.listen(_onPlayerState);

    _loadInsight();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ── Insight loading ──────────────────────────────────────────────────────

  Future<void> _loadInsight() async {
    setState(() => _insightLoading = true);
    try {
      final text = await FoCoCoInsightService.instance
          .getTodayInsight(currentUserUid);
      if (!mounted) return;
      setState(() {
        _insightText = text;
        _insightLoading = false;
      });
      // Fire TTS in parallel — do not await
      _prepareTTS(text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _insightLoading = false);
    }
  }

  // ── TTS preparation ──────────────────────────────────────────────────────

  Future<void> _prepareTTS(String text) async {
    try {
      // Check if today's audio is already cached
      final audioFile = await _todayAudioFile();
      if (await audioFile.exists()) {
        if (!mounted) return;
        setState(() => _ttsReady = true);
        return;
      }

      // Show loader after 2s if still not ready
      final loaderTimer = Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_ttsReady) {
          setState(() => _showSpeakerLoader = true);
        }
      });

      // Generate audio from Cartesia
      final audioBytes = await _generateCartesiaAudio(text);
      await loaderTimer; // ensure timer runs

      if (!mounted) return;
      await audioFile.writeAsBytes(audioBytes);
      setState(() {
        _ttsReady = true;
        _showSpeakerLoader = false;
      });
    } catch (e) {
      if (kDebugMode) print('⚠️ FoCoCoTab TTS failed: $e');
      if (mounted) {
        setState(() {
          _speakerState = _SpeakerState.failed;
          _showSpeakerLoader = false;
        });
      }
    }
  }

  Future<Uint8List> _generateCartesiaAudio(String text) async {
    const voiceId = '7442d6b8-ff51-4477-bd30-0c0d16df84eb';
    final response = await http.post(
      Uri.parse('${CartesiaMCPConfig.baseUrl}/tts/bytes'),
      headers: {
        'X-API-Key': CartesiaMCPConfig.apiKey,
        'Cartesia-Version': CartesiaMCPConfig.apiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model_id': 'sonic-2',
        'transcript': text,
        'voice': {'mode': 'id', 'id': voiceId},
        'output_format': {
          'container': 'mp3',
          'encoding': 'mp3',
          'sample_rate': 44100,
        },
        'language': 'en',
        'speed': 'slow',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Cartesia ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  Future<File> _todayAudioFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return File('${dir.path}/tts_audio_$key.mp3');
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  Future<void> _togglePlayback() async {
    if (_speakerState == _SpeakerState.playing) {
      await _audioPlayer?.stop();
      if (mounted) setState(() => _speakerState = _SpeakerState.idle);
      return;
    }

    if (!_ttsReady) return; // speaker icon is hidden/shimmer

    try {
      final file = await _todayAudioFile();
      if (!await file.exists()) return;
      await _audioPlayer?.setFilePath(file.path);
      await _audioPlayer?.play();
      if (mounted) setState(() => _speakerState = _SpeakerState.playing);
    } catch (e) {
      if (kDebugMode) print('⚠️ FoCoCoTab playback error: $e');
    }
  }

  void _onPlayerState(PlayerState state) {
    if (!mounted) return;
    if (state.processingState == ProcessingState.completed) {
      setState(() => _speakerState = _SpeakerState.idle);
    }
  }

  // ── Route change: stop audio ──────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If routed away, stop playback
    final location = GoRouterState.of(context).uri.toString();
    if (!location.contains('fococo') && _speakerState == _SpeakerState.playing) {
      _audioPlayer?.stop();
      setState(() => _speakerState = _SpeakerState.idle);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return StreamBuilder<UserRecord>(
      stream: loggedIn
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/$currentUserUid'))
          : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return FoCoCoAdaptiveScaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          title: 'FoCoCo',
          currentRoute: 'fococo',
          onTap: (route) => context.goNamed(route),
          showBottomNav: false, // Shell provides the nav bar
          enableVoiceButton: false,
          drawer: user != null
              ? FoCoCoDrawer(
                  currentUser: user,
                  currentRoute: 'fococo',
                  onNavigate: (route) => context.goNamed(route),
                )
              : null,
          body: Container(
            color: const Color(0xFF0A0A0A),
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Background wave
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, _) => CustomPaint(
                        painter: _WavePainter(_waveController.value),
                      ),
                    ),
                  ),
                  // Insight content
                  Positioned.fill(
                    child: _buildContent(theme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(FlutterFlowTheme theme) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom +
            kFoCoCoBottomNavStripAndTabsHeight +
            8,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInsightText(),
              const SizedBox(height: 24),
              _buildSpeakerIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightText() {
    if (_insightLoading) {
      return _buildShimmerText();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _insightText ?? '',
        key: ValueKey(_insightText),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.65,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmer = _shimmerController.value;
        return Column(
          children: List.generate(3, (i) {
            final width = i == 2 ? 0.6 : (i == 0 ? 1.0 : 0.85);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                height: 16,
                width: MediaQuery.sizeOf(context).width * 0.7 * width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [
                      (shimmer - 0.3).clamp(0.0, 1.0),
                      shimmer.clamp(0.0, 1.0),
                      (shimmer + 0.3).clamp(0.0, 1.0),
                    ],
                    colors: const [
                      Color(0xFF1A1A1A),
                      Color(0xFF2E2E2E),
                      Color(0xFF1A1A1A),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSpeakerIcon() {
    // Failed → hide entirely per spec
    if (_speakerState == _SpeakerState.failed) {
      return const SizedBox.shrink();
    }

    // Still loading and >2s have elapsed → shimmer
    if (!_ttsReady && _showSpeakerLoader) {
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) => Opacity(
          opacity: 0.3 +
              0.5 * math.sin(_shimmerController.value * math.pi * 2).abs(),
          child: const Icon(
            Icons.volume_up_rounded,
            color: Color(0xFF888888),
            size: 22,
          ),
        ),
      );
    }

    // Not ready yet (and <2s) → show nothing
    if (!_ttsReady) return const SizedBox(height: 22);

    // Playing → gold pulse
    if (_speakerState == _SpeakerState.playing) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) => Opacity(
          opacity: _pulseAnim.value,
          child: GestureDetector(
            onTap: _togglePlayback,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFFC9A84C), // Gold
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Idle → grey, tappable
    return GestureDetector(
      onTap: _togglePlayback,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            Icons.volume_up_rounded,
            color: Color(0xFF888888),
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Wave background painter ──────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  const _WavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var w = 0; w < 3; w++) {
      final phase = progress * 2 * math.pi + w * (math.pi * 2 / 3);
      final amplitude = size.height * 0.045;
      final yCenter = size.height * (0.35 + w * 0.12);

      final path = Path();
      for (var x = 0.0; x <= size.width; x++) {
        final y = yCenter +
            amplitude * math.sin(x / size.width * 2 * math.pi * 2 + phase);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}
