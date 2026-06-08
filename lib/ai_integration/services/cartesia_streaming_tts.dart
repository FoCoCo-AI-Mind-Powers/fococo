import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/cartesia_config.dart';
import 'cartesia_pcm_audio.dart';

/// Low-latency Cartesia TTS over `wss://api.cartesia.ai/tts/websocket`.
///
/// Uses short-lived access tokens minted server-side (`mintCartesiaTtsAccessToken`)
/// so the API key never ships in the client. Sets `max_buffer_delay_ms: 0` so
/// Sonic starts generating immediately.
class CartesiaStreamingTts {
  CartesiaStreamingTts._({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  static CartesiaStreamingTts? _instance;
  static CartesiaStreamingTts get instance =>
      _instance ??= CartesiaStreamingTts._();

  @visibleForTesting
  static void debugReset({FirebaseFunctions? functions}) {
    unawaited(_instance?.dispose());
    _instance = CartesiaStreamingTts._(functions: functions);
  }

  final FirebaseFunctions _functions;
  WebSocketChannel? _channel;
  StreamController<dynamic>? _broadcast;
  StreamSubscription<dynamic>? _socketSub;
  StreamSubscription<dynamic>? _handlerSub;
  final Map<String, _PendingSynthesis> _pending = {};
  String? _accessToken;
  DateTime? _tokenExpiry;
  Completer<void>? _connectCompleter;
  Future<void> _operationTail = Future<void>.value();

  static const Duration _tokenSkew = Duration(seconds: 15);
  static const Duration _synthesisTimeout = Duration(seconds: 90);

  bool get _socketReady =>
      _channel != null &&
      _socketSub != null &&
      _handlerSub != null &&
      _broadcast != null &&
      !_broadcast!.isClosed;

  /// Pre-open the socket after auth so the first speak call skips connect latency.
  Future<void> warmConnection() async {
    try {
      await _ensureSocket();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Cartesia streaming TTS warm connect skipped: $e');
      }
    }
  }

  Future<Uint8List> synthesize({
    required String transcript,
    required String voiceId,
    String? modelId,
    Map<String, dynamic>? generationConfig,
    String? pronunciationDictId,
    String language = 'en',
    void Function(int bytesReceived)? onFirstChunk,
  }) {
    return _enqueue(() async {
      final trimmed = transcript.trim();
      if (trimmed.isEmpty) {
        return Uint8List(0);
      }

      await _ensureSocket();
      final channel = _channel;
      if (channel == null || !_socketReady) {
        throw StateError('Cartesia TTS WebSocket is not connected');
      }

      final contextId = const Uuid().v4();
      final pending = _PendingSynthesis(onFirstChunk: onFirstChunk);
      _pending[contextId] = pending;

      final payload = <String, dynamic>{
        'model_id': modelId ?? CartesiaConfig.ttsModel,
        'transcript': trimmed,
        'voice': {'mode': 'id', 'id': voiceId},
        'language': language,
        'context_id': contextId,
        'continue': false,
        'max_buffer_delay_ms': 0,
        'output_format': {
          'container': 'raw',
          'encoding': 'pcm_s16le',
          'sample_rate': kCartesiaStreamingSampleRate,
        },
        if (generationConfig != null && generationConfig.isNotEmpty)
          'generation_config': generationConfig,
        if (pronunciationDictId != null && pronunciationDictId.isNotEmpty)
          'pronunciation_dict_id': pronunciationDictId,
      };

      try {
        channel.sink.add(jsonEncode(payload));
        final pcm = await pending.completer.future.timeout(_synthesisTimeout);
        if (kDebugMode) {
          debugPrint(
            '✅ Cartesia streaming TTS: ${pcm.length} PCM bytes (context $contextId)',
          );
        }
        return pcm;
      } on StateError catch (e) {
        if (e.message.contains('already been listened')) {
          _tearDownSocket();
        }
        rethrow;
      } finally {
        _pending.remove(contextId);
      }
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final next = _operationTail.then((_) => action());
    _operationTail = next.then((_) {}, onError: (_) {});
    return next;
  }

  void _handleSocketMessage(dynamic message) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(message as String);
      if (decoded is! Map) return;
      json = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    final contextId = json['context_id']?.toString();
    if (contextId == null || contextId.isEmpty) {
      return;
    }

    final pending = _pending[contextId];
    if (pending == null) {
      return;
    }

    final type = json['type']?.toString();
    if (type == 'error') {
      pending.finishError(
        Exception(json['error'] ?? json['message'] ?? 'Cartesia TTS error'),
      );
      return;
    }

    if (type == 'chunk') {
      final data = json['data']?.toString();
      if (data != null && data.isNotEmpty) {
        pending.addChunk(base64Decode(data));
      }
      if (json['done'] == true) {
        pending.finishOk();
      }
      return;
    }

    if (type == 'done' || json['done'] == true) {
      pending.finishOk();
    }
  }

  Future<void> _ensureSocket() async {
    if (_socketReady) return;

    if (_connectCompleter != null) {
      await _connectCompleter!.future;
      if (_socketReady) return;
    }

    _connectCompleter = Completer<void>();
    try {
      await _openSocket();
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter!.complete();
      }
    } catch (e, stackTrace) {
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter!.completeError(e, stackTrace);
      }
      _tearDownSocket();
      rethrow;
    } finally {
      _connectCompleter = null;
    }
  }

  Future<void> _openSocket() async {
    _tearDownSocket();

    final token = await _getAccessToken();
    final uri = Uri.parse(
      '${CartesiaConfig.ttsWebSocketUrl}'
      '?cartesia_version=${Uri.encodeComponent(CartesiaConfig.version)}'
      '&access_token=${Uri.encodeComponent(token)}',
    );

    final channel = WebSocketChannel.connect(uri);
    final broadcast = StreamController<dynamic>.broadcast();

    _channel = channel;
    _broadcast = broadcast;
    _socketSub = channel.stream.listen(
      broadcast.add,
      onError: (Object error) {
        if (!broadcast.isClosed) {
          broadcast.addError(error);
        }
        _handleSocketFailure(error);
      },
      onDone: () {
        if (!broadcast.isClosed) {
          broadcast.close();
        }
        _handleSocketFailure(
          StateError('Cartesia TTS socket closed before synthesis finished'),
        );
      },
      cancelOnError: false,
    );
    _handlerSub = broadcast.stream.listen(
      _handleSocketMessage,
      onError: (Object error) => _failPending(error),
    );

    if (kDebugMode) {
      debugPrint('🔌 Cartesia TTS WebSocket connected');
    }
  }

  void _handleSocketFailure(Object error) {
    if (kDebugMode) {
      debugPrint('⚠️ Cartesia TTS WebSocket error: $error');
    }
    _failPending(error);
    _tearDownSocket();
  }

  void _failPending(Object error) {
    for (final pending in _pending.values) {
      pending.finishError(error);
    }
    _pending.clear();
  }

  Future<String> _getAccessToken() async {
    final now = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(now.add(_tokenSkew))) {
      return _accessToken!;
    }

    final callable = _functions.httpsCallable(
      CartesiaConfig.mintTtsAccessTokenFunctionName,
    );
    final result = await callable.call<Map<String, dynamic>>();
    final data = Map<String, dynamic>.from(result.data as Map);
    final token = (data['access_token'] ?? data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw StateError('mintCartesiaTtsAccessToken returned no token');
    }
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 300;
    _accessToken = token;
    _tokenExpiry = now.add(Duration(seconds: expiresIn));
    return token;
  }

  void _tearDownSocket() {
    _handlerSub?.cancel();
    _handlerSub = null;
    _socketSub?.cancel();
    _socketSub = null;
    try {
      _channel?.sink.close();
    } catch (_) {
      // Socket may already be closed.
    }
    if (_broadcast != null && !_broadcast!.isClosed) {
      _broadcast!.close();
    }
    _broadcast = null;
    _channel = null;
  }

  Future<void> dispose() async {
    _failPending(StateError('Cartesia TTS disposed'));
    _tearDownSocket();
    _accessToken = null;
    _tokenExpiry = null;
    _operationTail = Future<void>.value();
  }
}

class _PendingSynthesis {
  _PendingSynthesis({this.onFirstChunk});

  final BytesBuilder _buffer = BytesBuilder(copy: false);
  final Completer<Uint8List> completer = Completer<Uint8List>();
  final void Function(int bytesReceived)? onFirstChunk;
  bool _gotFirstChunk = false;
  bool _finished = false;

  void addChunk(List<int> bytes) {
    if (_finished) return;
    _buffer.add(bytes);
    if (!_gotFirstChunk) {
      _gotFirstChunk = true;
      onFirstChunk?.call(_buffer.length);
    }
  }

  void finishOk() {
    if (_finished || completer.isCompleted) return;
    _finished = true;
    completer.complete(Uint8List.fromList(_buffer.toBytes()));
  }

  void finishError(Object error) {
    if (_finished || completer.isCompleted) return;
    _finished = true;
    completer.completeError(error);
  }
}
