import 'dart:async';

import 'package:flutter/material.dart';

import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

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
  final MindCoachV2Repository _repository = MindCoachV2Repository.instance;

  late final List<String> _lines;
  Timer? _timer;
  int _visibleLineCount = 1;
  bool _showCompletion = false;
  bool _submitting = false;
  int _rating = 4;
  bool _saveFavorite = false;
  String? _runId;

  bool get _isLiveMinimal =>
      widget.generateResponse.uiMode == MindCoachV2UiMode.liveMinimal;

  @override
  void initState() {
    super.initState();
    _runId = widget.generateResponse.runId;
    _lines = _tokenizeLines(widget.generateResponse.session.coachingText);
    _startPlayback();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> _tokenizeLines(String text) {
    final split = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (split.isEmpty) {
      return <String>['Take one breath. Focus on the next target.'];
    }
    return split;
  }

  void _startPlayback() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visibleLineCount < _lines.length) {
        setState(() {
          _visibleLineCount += 1;
        });
        return;
      }

      timer.cancel();
      setState(() {
        _showCompletion = true;
      });

      if (_isLiveMinimal) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) {
          return;
        }
        await _completeAndExit(
          status: MindCoachV2CompletionStatus.autoDismissed,
          saveFavorite: false,
          rating: null,
        );
      }
    });
  }

  Future<void> _handleBack() async {
    if (_submitting) {
      return;
    }
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
    } catch (_) {
      // Keep UX responsive even when completion write fails.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _lines.isEmpty ? 1.0 : _visibleLineCount / _lines.length;

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
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            '${widget.generateResponse.session.routineType} • ${widget.generateResponse.session.deliveryLength}',
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70),
          ),
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
                          padding: const EdgeInsets.only(bottom: 18),
                          child: AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 280),
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
                LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.lightBlueAccent),
                ),
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
                      SwitchListTile.adaptive(
                        value: _saveFavorite,
                        activeThumbColor: Colors.lightBlueAccent,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Save to favorites',
                          style: TextStyle(color: Colors.white70),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _saveFavorite = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                          child: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Done'),
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
