import 'dart:async';
import 'dart:collection';

import '/ai_integration/config/cartesia_mcp_config.dart';
import '/ai_integration/services/cartesia_api_service.dart';
import '/services/ai_voice_preference_service.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';

enum MindCoachV2TTSState { idle, speaking, degraded, error }

enum MindCoachV2TTSLineEventType {
  lineStarted,
  lineCompleted,
  lineTimeout,
  lineError,
  queueCompleted,
  queueCancelled,
}

class MindCoachV2SpeechLine {
  const MindCoachV2SpeechLine({
    required this.lineIndex,
    required this.text,
    this.durationHintMs,
  });

  final int lineIndex;
  final String text;
  final int? durationHintMs;
}

class MindCoachV2TTSLineEvent {
  const MindCoachV2TTSLineEvent({
    required this.type,
    this.lineIndex,
    this.durationMs,
    this.error,
  });

  final MindCoachV2TTSLineEventType type;
  final int? lineIndex;
  final int? durationMs;
  final Object? error;
}

class MindCoachV2TTSService {
  MindCoachV2TTSService();

  static const String _tag = 'TTS';

  final CartesiaAPIService _cartesia = CartesiaAPIService.instance;
  final MindCoachV2DebugLogger _logger = MindCoachV2DebugLogger.instance;

  final Queue<MindCoachV2SpeechLine> _queue = Queue<MindCoachV2SpeechLine>();
  final StreamController<MindCoachV2TTSState> _stateController =
      StreamController<MindCoachV2TTSState>.broadcast();
  final StreamController<MindCoachV2TTSLineEvent> _lineEventController =
      StreamController<MindCoachV2TTSLineEvent>.broadcast();

  MindCoachV2TTSState _state = MindCoachV2TTSState.idle;
  bool _initialized = false;
  bool _processing = false;
  bool _disposed = false;
  bool _muted = false;
  bool _cancelRequested = false;
  String _voiceProfileKey = 'mentor_calm';
  String? _voiceId;

  Stream<MindCoachV2TTSState> get stateStream => _stateController.stream;
  Stream<MindCoachV2TTSLineEvent> get lineEvents => _lineEventController.stream;

  MindCoachV2TTSState get currentState => _state;
  bool get isMuted => _muted;
  bool get isSpeaking => _state == MindCoachV2TTSState.speaking;

  void _setState(MindCoachV2TTSState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  void _emit(MindCoachV2TTSLineEvent event) {
    if (!_lineEventController.isClosed) {
      _lineEventController.add(event);
    }
  }

  Future<void> init({
    String deliveryLength = 'standard',
    String voiceProfileKey = 'mentor_calm',
  }) async {
    if (_initialized || _disposed) {
      return;
    }

    _voiceProfileKey = voiceProfileKey;
    _voiceId = _resolveVoiceId(voiceProfileKey) ?? kFoCoCoDefaultCartesiaVoiceId;

    _logger.log(_tag, 'Initializing Cartesia TTS', {
      'deliveryLength': deliveryLength,
      'voiceProfileKey': voiceProfileKey,
      'hasVoiceId': (_voiceId != null).toString(),
    });

    try {
      await _cartesia.initialize();
      _cartesia.setVoiceId(_voiceId!);
      // Label the background / lock-screen media controls for this session.
      _cartesia.setPlaybackTitle('MindCoach Session');
      _initialized = true;
      _setState(MindCoachV2TTSState.idle);
      _logger.log(_tag, 'Cartesia TTS initialized successfully');
    } catch (error, stackTrace) {
      _setState(MindCoachV2TTSState.error);
      _logger.error(_tag, 'Cartesia TTS init failed', null, error, stackTrace);
      rethrow;
    }
  }

  String? _resolveVoiceId(String profileKey) {
    final profile = CartesiaMCPConfig.getVoiceProfile(profileKey);
    if (profile == null) {
      return null;
    }
    final rawId = profile['voice_id'];
    if (rawId == null) {
      return null;
    }
    final normalized = rawId.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> playLines(
    List<MindCoachV2SpeechLine> lines, {
    bool replaceQueue = true,
  }) async {
    if (_disposed) {
      return;
    }
    if (!await AiVoicePreferenceService.isEnabled()) {
      return;
    }
    if (!_initialized) {
      await init(voiceProfileKey: _voiceProfileKey);
    }

    if (replaceQueue) {
      _queue.clear();
    }

    for (final line in lines) {
      if (line.text.trim().isEmpty) {
        continue;
      }
      _queue.add(line);
    }

    _cancelRequested = false;
    unawaited(_drainQueue());
  }

  int _timeoutFor(MindCoachV2SpeechLine line) {
    final hint = line.durationHintMs ?? 0;
    if (hint <= 0) {
      return 9000;
    }
    return (hint + 4000).clamp(4000, 14000);
  }

  Future<void> _drainQueue() async {
    if (_processing || _disposed) {
      return;
    }
    if (_queue.isEmpty) {
      _emit(const MindCoachV2TTSLineEvent(
        type: MindCoachV2TTSLineEventType.queueCompleted,
      ));
      _setState(MindCoachV2TTSState.idle);
      return;
    }

    _processing = true;

    try {
      while (_queue.isNotEmpty && !_cancelRequested && !_muted && !_disposed) {
        final line = _queue.removeFirst();
        _setState(MindCoachV2TTSState.speaking);
        _emit(MindCoachV2TTSLineEvent(
          type: MindCoachV2TTSLineEventType.lineStarted,
          lineIndex: line.lineIndex,
        ));

        final stopwatch = Stopwatch()..start();
        try {
          final timeoutMs = _timeoutFor(line);
          await Future.any<void>([
            _cartesia.speakTextAndWait(
              text: line.text,
              voiceId: _voiceId,
              voiceProfileKey: _voiceProfileKey,
              contentType: 'coaching',
            ),
            Future<void>.delayed(
              Duration(milliseconds: timeoutMs),
              () => throw _MindCoachTTSLineTimeout(),
            ),
          ]);
          stopwatch.stop();

          _emit(MindCoachV2TTSLineEvent(
            type: MindCoachV2TTSLineEventType.lineCompleted,
            lineIndex: line.lineIndex,
            durationMs: stopwatch.elapsedMilliseconds,
          ));
        } on _MindCoachTTSLineTimeout catch (error) {
          stopwatch.stop();
          _setState(MindCoachV2TTSState.degraded);
          await _cartesia.stopSpeaking();
          _logger.warn(_tag, 'Line timed out, continuing in degraded mode', {
            'lineIndex': line.lineIndex,
            'timeoutMs': _timeoutFor(line),
          });
          _emit(MindCoachV2TTSLineEvent(
            type: MindCoachV2TTSLineEventType.lineTimeout,
            lineIndex: line.lineIndex,
            durationMs: stopwatch.elapsedMilliseconds,
            error: error,
          ));
        } catch (error, stackTrace) {
          stopwatch.stop();
          _setState(MindCoachV2TTSState.error);
          _logger.error(
              _tag,
              'Line failed while speaking',
              {
                'lineIndex': line.lineIndex,
              },
              error,
              stackTrace);
          _emit(MindCoachV2TTSLineEvent(
            type: MindCoachV2TTSLineEventType.lineError,
            lineIndex: line.lineIndex,
            error: error,
          ));
        }
      }

      if (_cancelRequested || _muted) {
        _emit(const MindCoachV2TTSLineEvent(
          type: MindCoachV2TTSLineEventType.queueCancelled,
        ));
      } else {
        _emit(const MindCoachV2TTSLineEvent(
          type: MindCoachV2TTSLineEventType.queueCompleted,
        ));
      }
    } finally {
      _processing = false;
      _setState(_state == MindCoachV2TTSState.error
          ? MindCoachV2TTSState.error
          : MindCoachV2TTSState.idle);
    }
  }

  Future<void> stop({bool clearQueue = true}) async {
    if (_disposed) {
      return;
    }

    _cancelRequested = true;
    if (clearQueue) {
      _queue.clear();
    }

    try {
      await _cartesia.stopSpeaking();
    } catch (_) {
      // Non-fatal stop failure.
    }

    _setState(MindCoachV2TTSState.idle);
    _emit(const MindCoachV2TTSLineEvent(
      type: MindCoachV2TTSLineEventType.queueCancelled,
    ));
  }

  void setMuted(bool muted) {
    _muted = muted;
    _logger.log(_tag, 'Mute toggled', {'muted': muted.toString()});
    if (muted) {
      unawaited(stop(clearQueue: true));
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _cancelRequested = true;
    _queue.clear();
    unawaited(_cartesia.stopSpeaking());
    _stateController.close();
    _lineEventController.close();
  }
}

class _MindCoachTTSLineTimeout implements Exception {}
