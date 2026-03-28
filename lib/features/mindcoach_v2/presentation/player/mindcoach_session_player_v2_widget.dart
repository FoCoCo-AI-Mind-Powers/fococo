import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/adaptive_ui/adaptive_ui.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_tts_service.dart';

class MindCoachV2PlayerResult {
  MindCoachV2PlayerResult({
    required this.completed,
    required this.completionStatus,
    required this.favoriteSaved,
    this.helpfulnessRating,
    this.runId,
  });

  final bool completed;
  final MindCoachV2CompletionStatus completionStatus;
  final bool favoriteSaved;
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
  List<MindCoachV2TimedLine>? _timedLines;

  late final int _totalDurationMs;

  StreamSubscription<MindCoachV2TTSLineEvent>? _lineEventsSub;
  StreamSubscription<MindCoachV2TTSState>? _ttsStateSub;
  Timer? _progressTicker;
  Timer? _fallbackTimer;

  DateTime? _activeLineStartAt;
  int? _activeLineIndex;
  DateTime? _fallbackStartedAt;
  int _fallbackBaseElapsedMs = 0;

  int _elapsedMs = 0;
  int _visibleLineCount = 0;
  int _spokenDurationMs = 0;
  bool _showCompletion = false;
  bool _playbackFinished = false;
  bool _submitting = false;
  bool _degradedMode = false;
  int _rating = 4;
  bool _saveFavorite = false;
  String? _runId;
  bool _ttsMuted = false;

  bool get _isLiveMinimal =>
      widget.generateResponse.uiMode == MindCoachV2UiMode.liveMinimal;

  @override
  void initState() {
    super.initState();
    _runId = widget.generateResponse.runId;

    final session = widget.generateResponse.session;
    _timedLines = (session.lines != null && session.lines!.isNotEmpty)
        ? session.lines
        : null;

    if (_timedLines != null) {
      _lines = _timedLines!.map((line) => line.text).toList(growable: false);
    } else {
      _lines = _tokenizeLines(session.coachingText);
    }

    _speechLines = List<MindCoachV2SpeechLine>.generate(
      _lines.length,
      (index) => MindCoachV2SpeechLine(
        lineIndex: index,
        text: _lines[index],
        durationHintMs: _durationHintFor(index, session.deliveryLength),
      ),
      growable: false,
    );

    _revealStartMs = _buildRevealStartMs();
    final hintedTotal = _speechLines.fold<int>(
      0,
      (sum, line) => sum + (line.durationHintMs ?? 2500),
    );

    if ((session.totalDurationSec ?? 0) > 0) {
      _totalDurationMs =
          math.max(session.totalDurationSec! * 1000, hintedTotal);
    } else {
      _totalDurationMs = math.max(hintedTotal, 1);
    }

    _logger.log(_tag, 'initState', {
      'sessionId': widget.generateResponse.sessionId,
      'uiMode': widget.generateResponse.uiMode.wireValue,
      'templateId': session.templateId,
      'routineType': session.routineType,
      'deliveryLength': session.deliveryLength,
      'lineCount': _lines.length,
      'hasTimedLines': (_timedLines != null).toString(),
      'totalDurationMs': _totalDurationMs,
    });

    _ttsService = MindCoachV2TTSService();
    _lineEventsSub = _ttsService.lineEvents.listen(_onLineEvent);
    _ttsStateSub = _ttsService.stateStream.listen((state) {
      if (!mounted) return;
      if (state == MindCoachV2TTSState.degraded && !_degradedMode) {
        setState(() => _degradedMode = true);
      }
    });

    _startProgressTicker();
    unawaited(_startPlayback());
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
        .toList();
    if (split.isEmpty) {
      return <String>['Take one breath.', 'Focus on the next target.'];
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
    final base = 1000 + math.max(chars * 17, words * 210);
    final normalized = deliveryLength.toLowerCase();

    if (normalized.contains('micro')) {
      return base.clamp(1200, 2600).toInt();
    }
    if (normalized.contains('deep')) {
      return (base + 900).clamp(2200, 6200).toInt();
    }
    return (base + 350).clamp(1600, 3800).toInt();
  }

  List<int> _buildRevealStartMs() {
    final revealStarts = <int>[];
    var cursor = 0;
    for (int i = 0; i < _speechLines.length; i += 1) {
      revealStarts.add(cursor);
      cursor += _speechLines[i].durationHintMs ?? 2500;
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
        deliveryLength: widget.generateResponse.session.deliveryLength,
        voiceProfileKey: 'mentor_calm',
      );

      if (_ttsMuted) {
        _startFallbackPlayback(reason: 'muted_start');
        return;
      }

      _logger.log(_tag, 'starting Cartesia line queue', {
        'lineCount': _speechLines.length,
      });

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
      if (!mounted || _playbackFinished) {
        return;
      }

      if (_fallbackTimer != null) {
        return;
      }

      final activeElapsed = (_activeLineStartAt == null)
          ? 0
          : DateTime.now().difference(_activeLineStartAt!).inMilliseconds;
      final nextElapsed = (_spokenDurationMs + activeElapsed)
          .clamp(0, _totalDurationMs)
          .toInt();

      if (nextElapsed != _elapsedMs) {
        setState(() {
          _elapsedMs = nextElapsed;
        });
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
          if (lineIndex + 1 > _visibleLineCount) {
            _visibleLineCount = lineIndex + 1;
          }
          if (event.type != MindCoachV2TTSLineEventType.lineCompleted) {
            _degradedMode = true;
          }
        });
        break;
      case MindCoachV2TTSLineEventType.queueCompleted:
        _finishPlayback();
        break;
      case MindCoachV2TTSLineEventType.queueCancelled:
        // Expected when user exits, mutes, or we switch to fallback mode.
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

    _logger.warn(_tag, 'starting timed fallback playback', {
      'reason': reason,
      'continueFromCurrent': continueFromCurrent,
      'baseElapsedMs': _fallbackBaseElapsedMs,
    });

    unawaited(_ttsService.stop(clearQueue: true));

    _degradedMode = true;

    if (!continueFromCurrent) {
      _visibleLineCount = _lines.isEmpty ? 0 : 1;
      _elapsedMs = 0;
      _spokenDurationMs = 0;
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

      setState(() {
        _elapsedMs = totalElapsed;
        _visibleLineCount = math.max(_visibleLineCount, visible);
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
    _fallbackTimer?.cancel();

    _logger.log(_tag, 'playback complete', {
      'degradedMode': _degradedMode.toString(),
      'visibleLines': _visibleLineCount,
    });

    setState(() {
      _visibleLineCount = _lines.length;
      _elapsedMs = _totalDurationMs;
      _showCompletion = true;
    });

    if (_isLiveMinimal) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) {
          return;
        }
        _completeAndExit(
          status: MindCoachV2CompletionStatus.autoDismissed,
          saveFavorite: false,
          rating: null,
        );
      });
    }
  }

  Future<void> _handleBack() async {
    if (_submitting) {
      return;
    }

    _logger.log(_tag, 'user abandoned playback');
    await _ttsService.stop();
    await _completeAndExit(
      status: MindCoachV2CompletionStatus.abandoned,
      saveFavorite: false,
      rating: null,
    );
  }

  Future<void> _completeAndExit({
    required MindCoachV2CompletionStatus status,
    required bool saveFavorite,
    required int? rating,
  }) async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    _fallbackTimer?.cancel();
    await _ttsService.stop();

    String? completedRunId = _runId;
    bool favoriteSaved = false;

    try {
      final response = await _repository.completeRun(
        MindCoachV2CompleteRequest(
          sessionId: widget.generateResponse.sessionId,
          runId: _runId,
          completionStatus: status,
          helpfulnessRating: rating,
          saveFavorite: saveFavorite,
        ),
      );
      completedRunId = response.runId;
      favoriteSaved = response.favoriteSaved;
    } catch (error, stackTrace) {
      _logger.error(_tag, 'completeRun failed (continuing exit)', null, error,
          stackTrace);
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
        helpfulnessRating: rating,
        runId: completedRunId,
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _ttsMuted = !_ttsMuted;
    });

    _ttsService.setMuted(_ttsMuted);

    if (_ttsMuted && !_playbackFinished) {
      _startFallbackPlayback(
        reason: 'user_muted',
        continueFromCurrent: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _totalDurationMs > 0
        ? (_elapsedMs / _totalDurationMs).clamp(0.0, 1.0)
        : (_lines.isEmpty ? 1.0 : (_visibleLineCount / _lines.length));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: buildFoCoCoAppBar(
          context,
          backgroundColor: Colors.black,
          title: Text(
            '${widget.generateResponse.session.routineType} • ~${(_totalDurationMs / 1000).round()}s',
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70),
          ),
          actions: [
            if (!_isLiveMinimal)
              IconButton(
                icon: Icon(
                  _ttsMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white70,
                ),
                onPressed: _toggleMute,
                tooltip: _ttsMuted ? 'Unmute' : 'Mute',
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0;
                          i < _visibleLineCount && i < _lines.length;
                          i++)
                        Padding(
                          key: ValueKey('line_$i'),
                          padding: const EdgeInsets.only(bottom: 18),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('fade_$i'),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(opacity: value, child: child);
                            },
                            child: Text(
                              _lines[i],
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_ttsMuted && !_showCompletion)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.lightBlueAccent,
                          size: 18,
                        ),
                      ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.lightBlueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_degradedMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Playback recovered with timing fallback.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_showCompletion)
                  Text(
                    'Session complete.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 12),
                if (_showCompletion && !_isLiveMinimal)
                  Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Helpfulness',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            dropdownColor: Colors.black87,
                            value: _rating,
                            style: const TextStyle(color: Colors.white),
                            items: const [1, 2, 3, 4, 5]
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text('$v'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _rating = value;
                              });
                            },
                          ),
                        ],
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Save to favorites',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: FoCoCoAdaptiveSwitch(
                          value: _saveFavorite,
                          onChanged: (value) {
                            setState(() {
                              _saveFavorite = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FoCoCoAdaptiveButton(
                          onPressed: _submitting
                              ? null
                              : () {
                                  _completeAndExit(
                                    status:
                                        MindCoachV2CompletionStatus.completed,
                                    saveFavorite: _saveFavorite,
                                    rating: _rating,
                                  );
                                },
                          label: _submitting ? 'Saving...' : 'Done',
                          enabled: !_submitting,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
