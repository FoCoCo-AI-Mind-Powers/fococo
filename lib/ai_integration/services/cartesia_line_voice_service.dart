import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

import '../config/cartesia_config.dart';
import 'audio_session_service.dart';
import 'cartesia_voice_runtime.dart';

/// Live speech-to-speech via Cartesia Line
/// (https://docs.cartesia.ai/line/integrations/websocket-api).
///
/// Gemini reasons inside the deployed Line agent; Cartesia handles STT + TTS.
/// The client never holds `CARTESIA_API` — only a short-lived access token from
/// [mintCartesiaAccessToken].
enum CartesiaLineVoiceState {
  idle,
  connecting,
  listening,
  speaking,
  processing,
  error,
}

class CartesiaLineVoiceSession {
  CartesiaLineVoiceSession({
    required this.surface,
    this.systemPrompt,
    this.introduction,
    this.metadata,
  });

  final String surface;
  final String? systemPrompt;
  final String? introduction;
  final Map<String, dynamic>? metadata;
}

class CartesiaLineVoiceService {
  CartesiaLineVoiceService._();

  static CartesiaLineVoiceService? _instance;
  static CartesiaLineVoiceService get instance =>
      _instance ??= CartesiaLineVoiceService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final StreamController<CartesiaLineVoiceState> _stateController =
      StreamController<CartesiaLineVoiceState>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  StreamSubscription<Uint8List>? _micSub;
  String? _streamId;
  String? _agentId;
  CartesiaLineVoiceState _state = CartesiaLineVoiceState.idle;
  bool _keepAlive = false;
  Timer? _pingTimer;
  final BytesBuilder _outputPcm = BytesBuilder(copy: false);
  static const int _inputSampleRate = 16000;

  Stream<CartesiaLineVoiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  CartesiaLineVoiceState get state => _state;

  void _setState(CartesiaLineVoiceState next) {
    if (_state == next) return;
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  Future<bool> connect(CartesiaLineVoiceSession session) async {
    if (_state != CartesiaLineVoiceState.idle &&
        _state != CartesiaLineVoiceState.error) {
      return false;
    }

    _setState(CartesiaLineVoiceState.connecting);
    _keepAlive = true;

    try {
      final runtime = await CartesiaVoiceRuntime.load();
      if (!runtime.hasLineAgent) {
        throw StateError(
          'Cartesia Line agent is not configured. Set CARTESIA_LINE_AGENT_ID '
          'and deploy cartesia_line_agent.',
        );
      }
      _agentId = runtime.lineAgentId;

      final tokenResult = await _functions
          .httpsCallable(CartesiaConfig.mintAccessTokenFunctionName)
          .call<Map<String, dynamic>>({
        'agent_id': _agentId,
        'expires_in': 300,
      });
      final tokenData = Map<String, dynamic>.from(tokenResult.data as Map);
      final accessToken = (tokenData['access_token'] ?? '').toString();
      if (accessToken.isEmpty) {
        throw StateError('mintCartesiaAccessToken returned no token');
      }

      await AudioSessionService.activateVoiceChat();

      final uri = Uri.parse(
        '${CartesiaConfig.lineWebSocketBase}/agents/stream/$_agentId',
      );

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Cartesia-Version': runtime.cartesiaVersion,
        },
      );
      socket.pingInterval = const Duration(seconds: 60);

      _channel = IOWebSocketChannel(socket);
      _socketSub = _channel!.stream.listen(
        _onSocketMessage,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );

      final ttsConfig = <String, dynamic>{
        'voice_id': CartesiaConfig.voiceId,
        'model': CartesiaConfig.ttsModel,
        'language': 'en',
        if (runtime.pronunciationDictId.isNotEmpty)
          'pronunciation_dict_id': runtime.pronunciationDictId,
      };

      final startPayload = <String, dynamic>{
        'event': 'start',
        'config': {
          'input_format': 'pcm_16000',
          'voice_id': CartesiaConfig.voiceId,
          'tts': ttsConfig,
        },
        if (session.metadata != null && session.metadata!.isNotEmpty)
          'metadata': {
            'surface': session.surface,
            ...session.metadata!,
          }
        else
          'metadata': {'surface': session.surface},
      };

      final agentOverrides = <String, dynamic>{};
      if (session.systemPrompt != null && session.systemPrompt!.isNotEmpty) {
        agentOverrides['system_prompt'] = session.systemPrompt;
      }
      if (session.introduction != null && session.introduction!.isNotEmpty) {
        agentOverrides['introduction'] = session.introduction;
      }
      if (agentOverrides.isNotEmpty) {
        startPayload['agent'] = agentOverrides;
      }

      _channel!.sink.add(jsonEncode(startPayload));

      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission denied');
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _inputSampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _micSub = stream.listen(_sendMicChunk);
      _setState(CartesiaLineVoiceState.listening);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cartesia Line connect failed: $e');
      }
      _setState(CartesiaLineVoiceState.error);
      await disconnect();
      rethrow;
    }
  }

  void _sendMicChunk(Uint8List pcm) {
    if (!_keepAlive || _streamId == null || _channel == null) return;
    if (_state != CartesiaLineVoiceState.listening &&
        _state != CartesiaLineVoiceState.speaking) {
      return;
    }

    final payload = jsonEncode({
      'event': 'media_input',
      'stream_id': _streamId,
      'media': {'payload': base64Encode(pcm)},
    });
    _channel!.sink.add(payload);
  }

  Future<void> _onSocketMessage(dynamic raw) async {
    if (raw is! String) return;
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return;
    }

    final event = (data['event'] ?? '').toString();

    switch (event) {
      case 'ack':
        _streamId = (data['stream_id'] ?? '').toString();
        break;
      case 'media_output':
        final media = data['media'];
        if (media is! Map) break;
        final b64 = (media['payload'] ?? '').toString();
        if (b64.isEmpty) break;
        try {
          final bytes = base64Decode(b64);
          _outputPcm.add(bytes);
          _setState(CartesiaLineVoiceState.speaking);
          await _flushOutputAudio();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Line media_output decode failed: $e');
          }
        }
        break;
      case 'clear':
        await _interruptPlayback();
        _setState(CartesiaLineVoiceState.listening);
        break;
      case 'transfer_call':
        if (kDebugMode) {
          debugPrint('ℹ️ Line transfer_call: ${data['transfer']}');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _interruptPlayback() async {
    _outputPcm.clear();
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> _flushOutputAudio() async {
    if (_outputPcm.isEmpty) return;
    try {
      final pcm = _outputPcm.takeBytes();
      final wav = _pcmToWav(pcm, sampleRate: 24000);
      await _player.setAudioSource(_LinePcmSource(wav));
      if (!_player.playing) {
        await _player.play();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Line playback failed: $e');
      }
    }
  }

  void _onSocketError(Object error) {
    if (kDebugMode) {
      debugPrint('❌ Cartesia Line socket error: $error');
    }
    if (_keepAlive) {
      _setState(CartesiaLineVoiceState.error);
    }
  }

  void _onSocketDone() {
    if (_keepAlive && kDebugMode) {
      debugPrint('ℹ️ Cartesia Line socket closed');
    }
    if (_keepAlive) {
      unawaited(disconnect());
    }
  }

  Future<void> disconnect() async {
    _keepAlive = false;
    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      await _micSub?.cancel();
    } catch (_) {}
    _micSub = null;

    try {
      await _recorder.stop();
    } catch (_) {}

    try {
      await _socketSub?.cancel();
    } catch (_) {}
    _socketSub = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _streamId = null;

    await _interruptPlayback();
    await AudioSessionService.deactivateVoiceChat();
    _setState(CartesiaLineVoiceState.idle);
  }

  Uint8List _pcmToWav(Uint8List pcm, {required int sampleRate}) {
    final byteData = ByteData(44 + pcm.length);
    byteData.setUint32(0, 0x52494646, Endian.big);
    byteData.setUint32(4, 36 + pcm.length, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big);
    byteData.setUint32(12, 0x666D7420, Endian.big);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint32(36, 0x64617461, Endian.big);
    byteData.setUint32(40, pcm.length, Endian.little);
    final wav = byteData.buffer.asUint8List();
    wav.setRange(44, 44 + pcm.length, pcm);
    return wav;
  }

  void dispose() {
    unawaited(disconnect());
    _stateController.close();
    _transcriptController.close();
    _player.dispose();
  }
}

class _LinePcmSource extends StreamAudioSource {
  _LinePcmSource(this._wav);

  final Uint8List _wav;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _wav.length;
    return StreamAudioResponse(
      sourceLength: _wav.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_wav.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
