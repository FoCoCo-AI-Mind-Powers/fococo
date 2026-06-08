import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';

/// Runs [work] behind a pillar-colored prep overlay for every MindCoach start
/// path (catalog session, favorite replay, resume, builder, play-again).
Future<T?> runMindCoachSessionPrep<T>({
  required BuildContext context,
  required Color accentColor,
  required Future<T> Function() work,
  String? sessionTitle,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) => _MindCoachSessionPrepDialog<T>(
      accentColor: accentColor,
      sessionTitle: sessionTitle,
      work: work,
    ),
  );
}

class _MindCoachSessionPrepDialog<T> extends StatefulWidget {
  const _MindCoachSessionPrepDialog({
    required this.accentColor,
    required this.work,
    this.sessionTitle,
  });

  final Color accentColor;
  final Future<T> Function() work;
  final String? sessionTitle;

  @override
  State<_MindCoachSessionPrepDialog<T>> createState() =>
      _MindCoachSessionPrepDialogState<T>();
}

class _MindCoachSessionPrepDialogState<T>
    extends State<_MindCoachSessionPrepDialog<T>>
    with SingleTickerProviderStateMixin {
  _PrepPhase _phase = _PrepPhase.preparing;
  String? _errorMessage;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final result = await widget.work();
      if (!mounted) return;
      setState(() => _phase = _PrepPhase.ready);
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PrepPhase.failed;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final title = widget.sessionTitle?.trim();
    final headline = switch (_phase) {
      _PrepPhase.preparing => 'Preparing your session',
      _PrepPhase.ready => 'Session ready',
      _PrepPhase.failed => 'Could not prepare session',
    };
    final subtitle = switch (_phase) {
      _PrepPhase.preparing =>
        'Personalizing coaching for your round and learning style.',
      _PrepPhase.ready => 'Opening your MindCoach experience now.',
      _PrepPhase.failed =>
        _errorMessage ?? 'Something went wrong. Please try again.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: MindCoachV2Visuals.baseBackground.withValues(alpha: 0.92),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 36,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final pulse = 0.88 + (_pulseController.value * 0.12);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_phase == _PrepPhase.preparing)
                                  SizedBox(
                                    width: 88 * pulse,
                                    height: 88 * pulse,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: accent.withValues(alpha: 0.9),
                                    ),
                                  ),
                                if (_phase == _PrepPhase.ready)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 64,
                                    color: accent,
                                  ),
                                if (_phase == _PrepPhase.failed)
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 58,
                                    color: Colors.redAccent.withValues(alpha: 0.9),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (title != null && title.isNotEmpty) ...[
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            headline,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  height: 1.45,
                                ),
                          ),
                          if (_phase == _PrepPhase.preparing) ...[
                            const SizedBox(height: 22),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.08),
                                color: accent,
                              ),
                            ),
                          ],
                          if (_phase == _PrepPhase.failed) ...[
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PrepPhase { preparing, ready, failed }
