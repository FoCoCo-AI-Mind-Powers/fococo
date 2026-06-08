import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../services/cartesia_line_voice_service.dart';

/// Full-screen live coach using Cartesia Line (Gemini + Cartesia voice).
class FoCoCoLineVoiceSheet extends StatefulWidget {
  const FoCoCoLineVoiceSheet({
    super.key,
    required this.surface,
    this.systemPrompt,
    this.introduction,
    this.metadata,
  });

  final String surface;
  final String? systemPrompt;
  final String? introduction;
  final Map<String, dynamic>? metadata;

  static Future<void> show(
    BuildContext context, {
    required String surface,
    String? systemPrompt,
    String? introduction,
    Map<String, dynamic>? metadata,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoCoCoLineVoiceSheet(
        surface: surface,
        systemPrompt: systemPrompt,
        introduction: introduction,
        metadata: metadata,
      ),
    );
  }

  @override
  State<FoCoCoLineVoiceSheet> createState() => _FoCoCoLineVoiceSheetState();
}

class _FoCoCoLineVoiceSheetState extends State<FoCoCoLineVoiceSheet> {
  final CartesiaLineVoiceService _line = CartesiaLineVoiceService.instance;
  StreamSubscription<CartesiaLineVoiceState>? _stateSub;
  CartesiaLineVoiceState _state = CartesiaLineVoiceState.idle;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stateSub = _line.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _line.connect(
        CartesiaLineVoiceSession(
          surface: widget.surface,
          systemPrompt: widget.systemPrompt,
          introduction: widget.introduction,
          metadata: widget.metadata,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _end() async {
    await _line.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    unawaited(_line.disconnect());
    super.dispose();
  }

  String get _statusLabel {
    if (_error != null) return 'Unavailable';
    switch (_state) {
      case CartesiaLineVoiceState.connecting:
        return 'Connecting…';
      case CartesiaLineVoiceState.listening:
        return 'Listening';
      case CartesiaLineVoiceState.speaking:
        return 'Speaking';
      case CartesiaLineVoiceState.processing:
        return 'Thinking…';
      case CartesiaLineVoiceState.error:
        return 'Error';
      case CartesiaLineVoiceState.idle:
        return 'Starting…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.42,
      margin: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.secondaryText.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'FoCoCo Voice',
              style: theme.titleMedium.copyWith(color: theme.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? _statusLabel,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Iconify(
              Carbon.microphone,
              size: 56,
              color: _state == CartesiaLineVoiceState.speaking
                  ? theme.secondary
                  : theme.primaryText.withValues(alpha: 0.85),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _end,
                child: const Text('End conversation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
