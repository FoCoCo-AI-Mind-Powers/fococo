import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../config/cartesia_config.dart';
import 'cartesia_api_service.dart';
import 'cartesia_pcm_audio.dart';
import 'cartesia_streaming_tts.dart';

/// Output format the audio pipeline expects.
///
/// Default is WAV @ 44.1kHz (§9.2 open item). Switch encoding/sample rate if
/// the playback pipeline needs it — every voice path must agree on one value.
class CartesiaAudioFormat {
  final String container; // 'raw' | 'wav' | 'mp3'
  final String encoding; // 'pcm_f32le' | 'pcm_s16le' | 'mulaw'
  final int sampleRate;

  const CartesiaAudioFormat({
    required this.container,
    required this.encoding,
    required this.sampleRate,
  });

  static const wav44k = CartesiaAudioFormat(
    container: 'wav',
    encoding: 'pcm_s16le',
    sampleRate: 44100,
  );

  Map<String, dynamic> toJson() => {
        'container': container,
        'encoding': encoding,
        'sample_rate': sampleRate,
      };
}

/// Single Cartesia TTS surface for the whole app (§3 of the migration guide).
///
/// Prefers the warmed WebSocket path (`max_buffer_delay_ms: 0`) for instant
/// generation; falls back to `synthesizeSpeech` when the socket is unavailable.
class CartesiaTts {
  CartesiaTts._({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  static CartesiaTts? _instance;
  static CartesiaTts get instance => _instance ??= CartesiaTts._();

  @visibleForTesting
  static void debugReset({FirebaseFunctions? functions}) {
    _instance?.dispose();
    _instance = CartesiaTts._(functions: functions);
  }

  final FirebaseFunctions _functions;
  final AudioPlayer _player = AudioPlayer();

  /// LRU cache for static-string audio (key = text + voice + model + format).
  static const int _maxCachedClips = 64;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;

  Future<Uint8List> synthesize({
    required String text,
    String? voiceId,
    String? modelId,
    CartesiaAudioFormat format = CartesiaAudioFormat.wav44k,
    String language = 'en',
    bool cache = false,
  }) async {
    final vid = voiceId ?? CartesiaConfig.voiceId;
    final mid = modelId ?? CartesiaConfig.ttsModel;
    final key = cache ? _cacheKey(text, vid, mid, format) : null;

    if (key != null) {
      final hit = _cache.remove(key);
      if (hit != null) {
        _cache[key] = hit;
        return hit;
      }
    }

    await CartesiaAPIService.instance.initialize();

    Uint8List bytes;
    if (format == CartesiaAudioFormat.wav44k) {
      try {
        final pcm = await CartesiaStreamingTts.instance.synthesize(
          transcript: text.trim(),
          voiceId: vid,
          modelId: mid,
          language: language,
        );
        if (pcm.isNotEmpty) {
          bytes = pcm16MonoToWav(pcm, sampleRate: kCartesiaStreamingSampleRate);
        } else {
          bytes = await _synthesizeViaCallable(
            text: text,
            voiceId: vid,
            modelId: mid,
            format: format,
            language: language,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ CartesiaTts websocket fallback: $e');
        }
        bytes = await _synthesizeViaCallable(
          text: text,
          voiceId: vid,
          modelId: mid,
          format: format,
          language: language,
        );
      }
    } else {
      bytes = await _synthesizeViaCallable(
        text: text,
        voiceId: vid,
        modelId: mid,
        format: format,
        language: language,
      );
    }

    if (key != null) {
      _cache[key] = bytes;
      while (_cache.length > _maxCachedClips) {
        _cache.remove(_cache.keys.first);
      }
    }
    return bytes;
  }

  Future<Uint8List> _synthesizeViaCallable({
    required String text,
    required String voiceId,
    required String modelId,
    required CartesiaAudioFormat format,
    required String language,
  }) async {
    final HttpsCallableResult result;
    try {
      final callable =
          _functions.httpsCallable(CartesiaConfig.synthesizeFunctionName);
      result = await callable.call<Map<String, dynamic>>({
        'transcript': text,
        'voice_id': voiceId,
        'model_id': modelId,
        'language': language,
        'output_format': format.toJson(),
        'max_buffer_delay_ms': 0,
      });
    } on FirebaseFunctionsException catch (e) {
      throw CartesiaTtsException(
        'synthesizeSpeech failed: ${e.code} ${e.message}',
        code: e.code,
      );
    }

    final data = Map<String, dynamic>.from(result.data as Map);
    final b64 = data['audio_base64'] as String?;
    if (b64 == null || b64.isEmpty) {
      throw CartesiaTtsException('synthesizeSpeech returned no audio');
    }
    return base64Decode(b64);
  }

  Future<void> speak(
    String text, {
    String? voiceId,
    String? modelId,
    bool cache = false,
  }) async {
    final bytes = await synthesize(
      text: text,
      voiceId: voiceId,
      modelId: modelId,
      cache: cache,
    );
    await _player.setAudioSource(_BytesAudioSource(bytes));
    await _player.play();
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
    _cache.clear();
  }

  String _cacheKey(
    String text,
    String voice,
    String model,
    CartesiaAudioFormat fmt,
  ) {
    final h = sha1.convert(utf8.encode(
        '$model|$voice|${fmt.encoding}|${fmt.sampleRate}|$text'));
    return h.toString();
  }
}

class CartesiaTtsException implements Exception {
  final String message;
  final String? code;
  CartesiaTtsException(this.message, {this.code});
  @override
  String toString() => 'CartesiaTtsException($message)';
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
