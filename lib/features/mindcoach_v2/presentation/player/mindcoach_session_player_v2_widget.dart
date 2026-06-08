import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_tts_service.dart';
import '/features/mindcoach_v2/services/mindcoach_replay_cache.dart';

const int kMindCoachFavoriteLimitPerPillar = 5;

enum MindCoachV2PlayerNextAction {
  none,
  playAgain,
  backToSessions,
}

class MindCoachV2PlayerResult {
  MindCoachV2PlayerResult({
    required this.completed,
    required this.completionStatus,
    required this.favoriteSaved,
    required this.nextAction,
    this.helpfulnessRating,
    this.runId,
  });

  final bool completed;
  final MindCoachV2CompletionStatus completionStatus;
  final bool favoriteSaved;
  final MindCoachV2PlayerNextAction nextAction;
  final int? helpfulnessRating;
  final String? runId;
}

class MindCoachSessionPlayerV2Widget extends StatefulWidget {
  const MindCoachSessionPlayerV2Widget({
    super.key,
    required this.generateResponse,
  });

  final MindCoachV2GenerateResponse generateResponse;

  @override
  State<MindCoachSessionPlayerV2Widget> createState() =>
      _MindCoachSessionPlayerV2WidgetState();
}

class _MindCoachSessionPlayerV2WidgetState
    extends State<MindCoachSessionPlayerV2Widget> {
  static const String _tag = 'PLAYER';

  final MindCoachV2Repository _repository = MindCoachV2Repository.instance;
  final MindCoachV2DebugLogger _logger = MindCoachV2DebugLogger.instance;

  late final MindCoachV2TTSService _ttsService;
  late final List<String> _lines;
  late final List<MindCoachV2SpeechLine> _speechLines;
  late final List<int> _revealStartMs;
  final Stopwatch _playbackClock = Stopwatch();
  List<MindCoachV2TimedLine>? _timedLines;

  late final int _totalDurationMs;

  StreamSubscription<MindCoachV2TTSLineEvent>? _lineEventsSub;
  StreamSubscription<MindCoachV2TTSState>? _ttsStateSub;
  Timer? _progressTicker;
  Timer? _fallbackTimer;

  DateTime? _activeLineStartAt;
  int? _activeLineIndex;
  int _lastCompletedIndex = -1;
  DateTime? _fallbackStartedAt;
  int _fallbackBaseElapsedMs = 0;

  int _elapsedMs = 0;
  int _visibleLineCount = 0;
  int _spokenDurationMs = 0;
  bool _showCompletion = false;
  bool _playbackFinished = false;
  bool _submitting = false;
  bool _degradedMode = false;
  bool _saveFavorite = false;
  bool _favoriteSaved = false;
  String? _runId;
  bool _ttsMuted = false;

  bool get _isLiveMinimal =>
      widget.generateResponse.uiMode == MindCoachV2UiMode.liveMinimal;

  MindCoachV2Session get _session => widget.generateResponse.session;
  MindCoachV2Pillar get _pillar => _session.pillar;
  Color get _accent => MindCoachV2Visuals.accentForPillar(_pillar);
  late final MindCoachSessionVisualStyle _visualStyle;

  @override
  void initState() {
    super.initState();
    _visualStyle = MindCoachV2Visuals.visualStyleFor(
      session: _session,
      uiMode: widget.generateResponse.uiMode,
    );
    _syncSessionChrome();
    _runId = widget.generateResponse.runId;

    _timedLines = (_session.lines != null && _session.lines!.isNotEmpty)
        ? _session.lines
        : null;

    if (_timedLines != null) {
      _lines = _timedLines!.map((line) => line.text).toList(growable: false);
    } else {
      _lines = _tokenizeLines(_session.coachingText);
    }

    _speechLines = List<MindCoachV2SpeechLine>.generate(
      _lines.length,
      (index) => MindCoachV2SpeechLine(
        lineIndex: index,
        text: _lines[index],
        durationHintMs: _durationHintFor(index, _session.deliveryLength),
      ),
      growable: false,
    );

    _revealStartMs = _buildRevealStartMs();
    final hintedTotal = _speechLines.fold<int>(
      0,
      (sum, line) => sum + (line.durationHintMs ?? 2500),
    );

    if ((_session.totalDurationSec ?? 0) > 0) {
      _totalDurationMs =
          math.max(_session.totalDurationSec! * 1000, hintedTotal);
    } else {
      _totalDurationMs = math.max(hintedTotal, 1);
    }

    _ttsService = MindCoachV2TTSService();
    _lineEventsSub = _ttsService.lineEvents.listen(_onLineEvent);
    _ttsStateSub = _ttsService.stateStream.listen((state) {
      if (!mounted) {
        return;
      }
      if (state == MindCoachV2TTSState.degraded && !_degradedMode) {
        setState(() => _degradedMode = true);
      }
    });

    _logger.log(_tag, 'initState', {
      'sessionId': widget.generateResponse.sessionId,
      'sessionKey': _session.sessionKey,
      'uiMode': widget.generateResponse.uiMode.wireValue,
      'templateId': _session.templateId,
      'lineCount': _lines.length,
      'hasTimedLines': (_timedLines != null).toString(),
      'totalDurationMs': _totalDurationMs,
    });

    _startProgressTicker();
    unawaited(_startPlayback());
  }

  void _syncSessionChrome() {
    setFoCoCoNavBarBackgroundOverride(
      MindCoachV2Visuals.shellBackgroundForPillar(_pillar),
    );
    setFoCoCoNavSelectedColorOverride('mind_coach', _accent);
  }

  @override
  void dispose() {
    _lineEventsSub?.cancel();
    _ttsStateSub?.cancel();
    _progressTicker?.cancel();
    _fallbackTimer?.cancel();
    _ttsService.dispose();
    _logger.log(_tag, 'disposed');
    super.dispose();
  }

  List<String> _tokenizeLines(String text) {
    final split = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (split.isEmpty) {
      return const <String>['Take one breath.', 'Focus on the next target.'];
    }
    return split;
  }

  int _durationHintFor(int index, String deliveryLength) {
    if (_timedLines != null && index < _timedLines!.length) {
      return _timedLines![index].durationMs;
    }

    final text = _lines[index];
    final chars = text.length;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final base = 1200 + math.max(chars * 18, words * 240);
    final normalized = deliveryLength.toLowerCase();

    if (normalized.contains('micro')) {
      return base.clamp(1600, 3200).toInt();
    }
    if (normalized.contains('deep')) {
      return (base + 1200).clamp(3200, 7600).toInt();
    }
    return (base + 700).clamp(2200, 5200).toInt();
  }

  List<int> _buildRevealStartMs() {
    final revealStarts = <int>[];
    var cursor = 0;
    for (final line in _speechLines) {
      revealStarts.add(cursor);
      cursor += line.durationHintMs ?? 2500;
    }
    return revealStarts;
  }

  Future<void> _startPlayback() async {
    if (_speechLines.isEmpty) {
      _finishPlayback();
      return;
    }

    try {
      await _ttsService.init(
        deliveryLength: _session.deliveryLength,
        voiceProfileKey: 'mentor_calm',
      );

      if (_ttsMuted) {
        _startFallbackPlayback(reason: 'muted_start');
        return;
      }

      _playbackClock
        ..reset()
        ..start();
      await _ttsService.playLines(_speechLines);
    } catch (error, stackTrace) {
      _logger.error(
        _tag,
        'Cartesia playback init failed; switching to timed fallback',
        null,
        error,
        stackTrace,
      );
      _startFallbackPlayback(reason: 'tts_init_failure');
    }
  }

  void _startProgressTicker() {
    _progressTicker?.cancel();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || _playbackFinished || _fallbackTimer != null) {
        return;
      }

      final activeElapsed = _activeLineStartAt == null
          ? 0
          : DateTime.now().difference(_activeLineStartAt!).inMilliseconds;
      final nextElapsed = (_spokenDurationMs + activeElapsed)
          .clamp(0, _totalDurationMs)
          .toInt();
      if (nextElapsed != _elapsedMs) {
        setState(() => _elapsedMs = nextElapsed);
      }
    });
  }

  void _onLineEvent(MindCoachV2TTSLineEvent event) {
    if (!mounted || _playbackFinished) {
      return;
    }

    switch (event.type) {
      case MindCoachV2TTSLineEventType.lineStarted:
        final index = event.lineIndex ?? 0;
        _activeLineIndex = index;
        _activeLineStartAt = DateTime.now();
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
        setState(() {
          _visibleLineCount = math.max(_visibleLineCount, index + 1);
        });
        break;
      case MindCoachV2TTSLineEventType.lineCompleted:
      case MindCoachV2TTSLineEventType.lineTimeout:
      case MindCoachV2TTSLineEventType.lineError:
        final lineIndex = event.lineIndex ?? _activeLineIndex ?? 0;
        final durationMs = event.durationMs ??
            _speechLines[math.min(lineIndex, _speechLines.length - 1)]
                .durationHintMs ??
            2500;

        _spokenDurationMs =
            (_spokenDurationMs + durationMs).clamp(0, _totalDurationMs).toInt();
        _activeLineIndex = null;
        _activeLineStartAt = null;
        _lastCompletedIndex = math.max(_lastCompletedIndex, lineIndex);

        if (event.type == MindCoachV2TTSLineEventType.lineTimeout ||
            event.type == MindCoachV2TTSLineEventType.lineError) {
          _startFallbackPlayback(
            reason: event.type == MindCoachV2TTSLineEventType.lineTimeout
                ? 'line_timeout'
                : 'line_error',
            continueFromCurrent: true,
          );
        }

        setState(() {
          _elapsedMs = _spokenDurationMs.clamp(0, _totalDurationMs).toInt();
          _visibleLineCount = math.max(_visibleLineCount, lineIndex + 1);
          if (event.type != MindCoachV2TTSLineEventType.lineCompleted) {
            _degradedMode = true;
          }
        });
        break;
      case MindCoachV2TTSLineEventType.queueCompleted:
        _finishPlayback();
        break;
      case MindCoachV2TTSLineEventType.queueCancelled:
        break;
    }
  }

  void _startFallbackPlayback({
    required String reason,
    bool continueFromCurrent = false,
  }) {
    if (_playbackFinished) {
      return;
    }

    _fallbackTimer?.cancel();
    _fallbackStartedAt = DateTime.now();
    _fallbackBaseElapsedMs = continueFromCurrent ? _elapsedMs : 0;
    _degradedMode = true;
    _logger.warn(_tag, 'starting timed fallback playback', {
      'reason': reason,
      'continueFromCurrent': continueFromCurrent.toString(),
    });
    unawaited(_ttsService.stop(clearQueue: true));

    if (!continueFromCurrent) {
      _visibleLineCount = _lines.isEmpty ? 0 : 1;
      _elapsedMs = 0;
      _spokenDurationMs = 0;
      _lastCompletedIndex = -1;
      _activeLineIndex = 0;
    }

    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted || _playbackFinished) {
        timer.cancel();
        return;
      }

      final elapsedSinceFallback =
          DateTime.now().difference(_fallbackStartedAt!).inMilliseconds;
      final totalElapsed = (_fallbackBaseElapsedMs + elapsedSinceFallback)
          .clamp(0, _totalDurationMs)
          .toInt();

      int visible = 0;
      for (final revealStartMs in _revealStartMs) {
        if (revealStartMs <= totalElapsed) {
          visible += 1;
        }
      }
      visible = visible.clamp(0, _lines.length);
      final activeIndex =
          visible <= 0 ? 0 : math.min(visible - 1, _lines.length - 1);

      setState(() {
        _elapsedMs = totalElapsed;
        _visibleLineCount = math.max(_visibleLineCount, visible);
        _activeLineIndex = activeIndex;
      });

      if (totalElapsed >= _totalDurationMs) {
        timer.cancel();
        _finishPlayback();
      }
    });
  }

  void _finishPlayback() {
    if (_playbackFinished) {
      return;
    }

    _playbackFinished = true;
    _playbackClock.stop();
    _fallbackTimer?.cancel();

    _logger.log(_tag, 'playback complete', {
      'elapsedMs': _playbackClock.elapsedMilliseconds,
      'degradedMode': _degradedMode.toString(),
    });

    setState(() {
      _visibleLineCount = _lines.length;
      _elapsedMs = _totalDurationMs;
      _showCompletion = true;
      _activeLineIndex = null;
    });

    if (_isLiveMinimal) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) {
          return;
        }
        _completeAndExit(
          status: MindCoachV2CompletionStatus.autoDismissed,
          nextAction: MindCoachV2PlayerNextAction.backToSessions,
        );
      });
    }
  }

  List<int> _windowIndices() {
    if (_lines.isEmpty) {
      return const <int>[];
    }
    final center =
        (_activeLineIndex ?? _lastCompletedIndex).clamp(0, _lines.length - 1);
    final indices = <int>[];
    for (var index = center - 1; index <= center + 1; index += 1) {
      if (index >= 0 && index < _lines.length) {
        indices.add(index);
      }
    }
    if (indices.isEmpty) {
      indices.add(0);
    }
    return indices;
  }

  Future<void> _handleBack() async {
    if (_submitting) {
      return;
    }
    await _ttsService.stop();
    await _completeAndExit(
      status: MindCoachV2CompletionStatus.abandoned,
      nextAction: MindCoachV2PlayerNextAction.backToSessions,
    );
  }

  Future<bool> _maybeSaveFavorite() async {
    if (!_saveFavorite || _favoriteSaved) {
      return _favoriteSaved;
    }

    final initialResult = await _repository.saveFavorite(session: _session);
    if (initialResult.saved) {
      return true;
    }
    if (!initialResult.needsReplacement || !mounted) {
      return false;
    }

    final replacement = await showDialog<MindCoachV2Favorite>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _FavoriteReplaceDialog(
          color: _accent,
          favorites: initialResult.currentFavorites,
        );
      },
    );

    if (replacement == null) {
      return false;
    }

    final replaced = await _repository.saveFavorite(
      session: _session,
      replaceFavoriteId: replacement.favoriteId,
    );
    return replaced.saved;
  }

  Future<void> _completeAndExit({
    required MindCoachV2CompletionStatus status,
    required MindCoachV2PlayerNextAction nextAction,
  }) async {
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);
    _fallbackTimer?.cancel();
    await _ttsService.stop();

    String? completedRunId = _runId;
    var favoriteSaved = _favoriteSaved;

    try {
      if (status == MindCoachV2CompletionStatus.completed && _saveFavorite) {
        favoriteSaved = await _maybeSaveFavorite();
        if (_saveFavorite && !favoriteSaved && mounted) {
          setState(() => _submitting = false);
          return;
        }
        _favoriteSaved = favoriteSaved;
      }

      final response = await _repository.completeRun(
        MindCoachV2CompleteRequest(
          sessionId: widget.generateResponse.sessionId,
          runId: _runId,
          completionStatus: status,
        ),
      );
      completedRunId = response.runId;
    } catch (error, stackTrace) {
      _logger.error(
        _tag,
        'completeRun failed (continuing exit)',
        null,
        error,
        stackTrace,
      );
    }

    if (status == MindCoachV2CompletionStatus.completed) {
      unawaited(
        MindCoachReplayCache.saveFromResponse(widget.generateResponse),
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      MindCoachV2PlayerResult(
        completed: status == MindCoachV2CompletionStatus.completed ||
            status == MindCoachV2CompletionStatus.autoDismissed,
        completionStatus: status,
        favoriteSaved: favoriteSaved,
        nextAction: nextAction,
        helpfulnessRating: null,
        runId: completedRunId,
      ),
    );
  }

  void _toggleMute() {
    setState(() => _ttsMuted = !_ttsMuted);
    _ttsService.setMuted(_ttsMuted);

    if (_ttsMuted && !_playbackFinished) {
      _startFallbackPlayback(
        reason: 'user_muted',
        continueFromCurrent: true,
      );
    }
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = _totalDurationMs <= 0
        ? 0.0
        : (_elapsedMs / _totalDurationMs).clamp(0.0, 1.0);
    final remainingSec =
        math.max(0, ((_totalDurationMs - _elapsedMs) / 1000).ceil());

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: _accent.withValues(alpha: _visualStyle.progressAccentAlpha),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$remainingSec sec',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildLineCopy(BuildContext context, int centerIndex) {
    final activeLine = _lines[centerIndex];
    final subtitleIndex = centerIndex + 1;
    final hasSubtitle =
        subtitleIndex < _lines.length && _visualStyle.showLiveHeader;

    if (_visualStyle.showLiveHeader) {
      return Column(
        key: ValueKey<String>('live_line_$centerIndex'),
        children: [
          Text(
            activeLine.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  height: 1.25,
                ),
          ),
          if (hasSubtitle) ...[
            const SizedBox(height: 10),
            Text(
              _lines[subtitleIndex],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      );
    }

    final lineWindow = _windowIndices();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Column(
        key: ValueKey<String>('guided_line_${centerIndex}_$_visibleLineCount'),
        children: [
          for (final index in lineWindow)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _lines[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white.withValues(
                        alpha: index == centerIndex
                            ? 0.98
                            : index < centerIndex
                                ? 0.36
                                : 0.3,
                      ),
                      fontWeight: index == centerIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                      height: 1.35,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybackBody(BuildContext context) {
    final centerIndex =
        _activeLineIndex ?? _lastCompletedIndex.clamp(0, _lines.length - 1);
    final headerTitle = _visualStyle.showLiveHeader
        ? 'LIVE MIND COACH SESSION'
        : _session.topBarTitle;

    return Column(
      children: [
        if (!_visualStyle.showLiveHeader)
          Row(
            children: [
              IconButton(
                onPressed: _handleBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  headerTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _ttsMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        if (_visualStyle.showLiveHeader)
          Row(
            children: [
              IconButton(
                onPressed: _handleBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  headerTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _ttsMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        _buildProgressBar(context),
        const SizedBox(height: 28),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MindCoachSessionPulseOrb(
                color: _accent,
                active: !_ttsMuted && !_playbackFinished,
                diameter: _visualStyle.orbDiameter,
                pulseDuration:
                    Duration(milliseconds: _visualStyle.pulseDurationMs),
                glowStrength: _visualStyle.glowStrength,
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildLineCopy(context, centerIndex),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionBody(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 28),
        Text(
          _pillar.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
        ),
        const SizedBox(height: 8),
        MindCoachGlowLine(color: _accent, width: 172),
        const Spacer(),
        Text(
          'You are ready.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        MindCoachGlowLine(color: _accent, width: 172),
        const Spacer(),
        _ActionButton(
          label: 'Play Again',
          accent: _accent,
          primary: true,
          onTap: _submitting
              ? null
              : () => _completeAndExit(
                    status: MindCoachV2CompletionStatus.completed,
                    nextAction: MindCoachV2PlayerNextAction.playAgain,
                  ),
        ),
        const SizedBox(height: 14),
        _ActionButton(
          label: 'Back to Sessions',
          accent: Colors.white.withValues(alpha: 0.42),
          primary: false,
          onTap: _submitting
              ? null
              : () => _completeAndExit(
                    status: MindCoachV2CompletionStatus.completed,
                    nextAction: MindCoachV2PlayerNextAction.backToSessions,
                  ),
        ),
        const SizedBox(height: 18),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _submitting
              ? null
              : () => setState(() => _saveFavorite = !_saveFavorite),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _saveFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: _saveFavorite
                      ? _accent
                      : Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _favoriteSaved ? 'Saved to Favorites' : 'Add to Favorites',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: MindCoachV2Visuals.shellBackgroundForPillar(_pillar),
        body: MindCoachV2Backdrop(
          pillar: _pillar,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: _showCompletion && !_isLiveMinimal
                  ? _buildCompletionBody(context)
                  : _buildPlaybackBody(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.accent,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: primary
              ? accent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: accent.withValues(alpha: primary ? 0.9 : 0.35),
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color:
                    Colors.white.withValues(alpha: onTap == null ? 0.45 : 0.96),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _FavoriteReplaceDialog extends StatelessWidget {
  const _FavoriteReplaceDialog({
    required this.color,
    required this.favorites,
  });

  final Color color;
  final List<MindCoachV2Favorite> favorites;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF131523),
          border: Border.all(color: color.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve saved $kMindCoachFavoriteLimitPerPillar favorites.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose one to replace.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
            ),
            const SizedBox(height: 18),
            for (final favorite in favorites) ...[
              InkWell(
                onTap: () => Navigator.of(context).pop(favorite),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              favorite.sessionName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(
                            favorite.contextMode.displayLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.56),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MindCoachGlowLine(color: color, width: double.infinity),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

