import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/utils/friendly_error_mapper.dart';
import '../services/cartesia_line_voice_service.dart';

/// Full-screen live coach using Cartesia Line (Gemini + Cartesia voice).
///
/// Returns `true` when the user ends a connected session, `false` when connect
/// fails (caller may fall back to legacy voice), or `null` if dismissed early.
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

  static Future<bool?> show(
    BuildContext context, {
    required String surface,
    String? systemPrompt,
    String? introduction,
    Map<String, dynamic>? metadata,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
  bool _connected = false;
  bool _connectFailed = false;
  bool _popped = false;

  void _popSheet(bool? result) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(result);
  }

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
      if (mounted) {
        setState(() => _connected = true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectFailed = true;
        _error = FriendlyErrorMapper.message(
          e,
          fallback: 'Live voice is unavailable right now.',
        );
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        _popSheet(false);
      }
    }
  }

  Future<void> _end() async {
    await _line.disconnect();
    _popSheet(_connected);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    unawaited(_line.disconnect());
    super.dispose();
  }

  String get _statusLabel {
    if (_error != null) return _error!;
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
        return 'Unavailable';
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
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    _statusLabel,
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                    textAlign: TextAlign.center,
                    maxLines: _connectFailed ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Iconify(
              Carbon.phone_voice,
              size: 56,
              color: _state == CartesiaLineVoiceState.speaking
                  ? theme.secondary
                  : theme.primaryText.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _connected || _connectFailed ? _end : null,
                child: Text(_connectFailed ? 'Close' : 'End conversation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
