import 'dart:async';
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

enum _SpeakerState { idle, playing, failed }

class _FoCoCoTabWidgetState extends State<FoCoCoTabWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  FoCoCoDailyInsight? _insight;
  String? _insightText;
  bool _insightLoading = true;
  bool _hasBootstrapped = false;

  _SpeakerState _speakerState = _SpeakerState.idle;
  AudioPlayer? _audioPlayer;
  bool _ttsReady = false;
  bool _showSpeakerLoader = false;
  bool _speakerTimedOut = false;
  bool _audioPreloaded = false;

  Timer? _speakerLoaderTimer;
  Timer? _speakerHideTimer;
  DateTime? _screenVisibleSince;
  bool _isCurrentRouteVisible = true;

  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _audioPlayer = AudioPlayer();
    _audioPlayer!.playerStateStream.listen(_onPlayerState);

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_flushScreenTime());
    _cancelSpeakerTimers();
    _waveController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isCurrentRouteVisible) {
        _resumeScreenTimer();
      }
      return;
    }

    unawaited(_flushScreenTime());
    if (_speakerState == _SpeakerState.playing) {
      unawaited(_audioPlayer?.stop());
      if (mounted) {
        setState(() => _speakerState = _SpeakerState.idle);
      }
    }
  }

  Future<void> _loadInsight() async {
    setState(() => _insightLoading = true);
    try {
      final insight = await FoCoCoInsightService.instance.getTodayInsight();
      if (!mounted) return;

      setState(() {
        _insight = insight;
        _insightText = insight.insightText;
        _insightLoading = false;
      });

      unawaited(FoCoCoInsightService.instance.markOpened(insight));
      _resumeScreenTimer();
      unawaited(_prepareTTS(insight.insightText));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo tab insight load failed: $error');
      }
      if (!mounted) return;
      setState(() => _insightLoading = false);
    }
  }

  Future<void> _preloadCachedAudio() async {
    try {
      final audioFile = await _todayAudioFile();
      if (!await audioFile.exists()) return;

      await _preloadAudioFile(audioFile);
      if (!mounted) return;
      setState(() {
        _ttsReady = true;
        _speakerState = _speakerState == _SpeakerState.failed
            ? _SpeakerState.failed
            : _SpeakerState.idle;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCoTab cached audio preload failed: $error');
      }
    }
  }

  Future<void> _prepareTTS(String text) async {
    try {
      final audioFile = await _todayAudioFile();
      if (await audioFile.exists()) {
        await _preloadAudioFile(audioFile);
        if (!mounted) return;
        setState(() {
          _ttsReady = true;
          _showSpeakerLoader = false;
          _speakerTimedOut = false;
          if (_speakerState != _SpeakerState.failed) {
            _speakerState = _SpeakerState.idle;
          }
        });
        return;
      }

      _cancelSpeakerTimers();
      if (mounted) {
        setState(() {
          _ttsReady = false;
          _audioPreloaded = false;
          _showSpeakerLoader = false;
          _speakerTimedOut = false;
          _speakerState = _SpeakerState.idle;
        });
      }

      _speakerLoaderTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || _ttsReady || _speakerTimedOut) return;
        setState(() => _showSpeakerLoader = true);
      });

      _speakerHideTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || _ttsReady) return;
        setState(() {
          _speakerTimedOut = true;
          _showSpeakerLoader = false;
          _speakerState = _SpeakerState.failed;
        });
      });

      final audioBytes = await _generateAudioWithRetry(text);
      if (audioBytes == null) {
        if (!mounted) return;
        if (_speakerTimedOut) {
          setState(() {
            _showSpeakerLoader = false;
            _speakerState = _SpeakerState.failed;
          });
        }
        return;
      }

      await audioFile.writeAsBytes(audioBytes);
      await _preloadAudioFile(audioFile);
      if (!mounted) return;

      setState(() {
        _ttsReady = true;
        _showSpeakerLoader = false;
        if (!_speakerTimedOut) {
          _speakerState = _SpeakerState.idle;
        }
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCoTab TTS preparation failed: $error');
      }
      if (!mounted) return;
      setState(() {
        _showSpeakerLoader = false;
        _speakerState = _SpeakerState.failed;
      });
    }
  }

  Future<Uint8List?> _generateAudioWithRetry(String text) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _generateCartesiaAudio(text);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ FoCoCoTab TTS attempt ${attempt + 1} failed: $error',
          );
        }
      }
    }
    return null;
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

  Future<void> _preloadAudioFile(File audioFile) async {
    await _audioPlayer?.setFilePath(audioFile.path);
    _audioPreloaded = true;
  }

  Future<File> _todayAudioFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return File('${dir.path}/tts_audio_$key.mp3');
  }

  Future<void> _togglePlayback() async {
    if (_speakerState == _SpeakerState.playing) {
      await _audioPlayer?.stop();
      if (mounted) setState(() => _speakerState = _SpeakerState.idle);
      return;
    }

    if (!_ttsReady || _speakerState == _SpeakerState.failed) {
      return;
    }

    try {
      final file = await _todayAudioFile();
      if (!await file.exists()) return;

      if (!_audioPreloaded) {
        await _preloadAudioFile(file);
      } else {
        await _audioPlayer?.seek(Duration.zero);
      }

      await _audioPlayer?.play();
      if (!mounted) return;

      setState(() => _speakerState = _SpeakerState.playing);
      unawaited(FoCoCoInsightService.instance.markAudioPlayed(_insight));
      if (_insight != null) {
        _insight = _insight!.copyWith(playedAudio: true);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCoTab playback error: $error');
      }
    }
  }

  void _onPlayerState(PlayerState state) {
    if (!mounted) return;
    if (state.processingState == ProcessingState.completed) {
      setState(() => _speakerState = _SpeakerState.idle);
    }
  }

  void _resumeScreenTimer() {
    if (!_isCurrentRouteVisible ||
        _insight == null ||
        !_insight!.hasRemoteRecord) {
      return;
    }
    _screenVisibleSince ??= DateTime.now();
  }

  Future<void> _flushScreenTime() async {
    final visibleSince = _screenVisibleSince;
    _screenVisibleSince = null;
    if (visibleSince == null || _insight == null) return;

    final elapsed = DateTime.now().difference(visibleSince);
    if (elapsed.inMilliseconds < 250) return;

    try {
      await FoCoCoInsightService.instance.addTimeOnScreen(_insight, elapsed);
      _insight = _insight!.copyWith(
        timeOnScreenSec:
            _insight!.timeOnScreenSec + (elapsed.inMilliseconds / 1000),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCoTab screen-time flush failed: $error');
      }
    }
  }

  void _syncRouteVisibility() {
    final isVisible =
        GoRouterState.of(context).uri.toString().contains('fococo');
    if (isVisible == _isCurrentRouteVisible) {
      return;
    }

    _isCurrentRouteVisible = isVisible;
    if (_isCurrentRouteVisible) {
      _resumeScreenTimer();
      return;
    }

    unawaited(_flushScreenTime());
    if (_speakerState == _SpeakerState.playing) {
      unawaited(_audioPlayer?.stop());
      _speakerState = _SpeakerState.idle;
    }
  }

  void _cancelSpeakerTimers() {
    _speakerLoaderTimer?.cancel();
    _speakerHideTimer?.cancel();
    _speakerLoaderTimer = null;
    _speakerHideTimer = null;
  }

  void _bootstrapIfVisible() {
    final isVisible =
        GoRouterState.of(context).uri.toString().contains(FoCoCoTabWidget.routePath);
    if (!isVisible || _hasBootstrapped) {
      return;
    }

    _hasBootstrapped = true;
    unawaited(_preloadCachedAudio());
    unawaited(_loadInsight());
  }

  @override
  Widget build(BuildContext context) {
    _syncRouteVisibility();
    _bootstrapIfVisible();
    final theme = FlutterFlowTheme.of(context);
    final isVisible =
        GoRouterState.of(context).uri.toString().contains(FoCoCoTabWidget.routePath);

    return StreamBuilder<UserRecord>(
      stream: isVisible && loggedIn
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
          showBottomNav: false,
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
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, _) => CustomPaint(
                        painter: _WavePainter(_waveController.value),
                      ),
                    ),
                  ),
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
          children: List.generate(3, (index) {
            final width = index == 2 ? 0.6 : (index == 0 ? 1.0 : 0.85);
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
    if (_speakerState == _SpeakerState.failed) {
      return const SizedBox.shrink();
    }

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

    if (!_ttsReady) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            Icons.volume_up_rounded,
            color: Color(0xFF888888),
            size: 22,
          ),
        ),
      );
    }

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
                  color: Color(0xFFC9A84C),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

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

class _WavePainter extends CustomPainter {
  const _WavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var wave = 0; wave < 3; wave++) {
      final phase = progress * 2 * math.pi + wave * (math.pi * 2 / 3);
      final amplitude = size.height * 0.045;
      final yCenter = size.height * (0.35 + wave * 0.12);

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
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
