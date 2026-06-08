import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../config/cartesia_config.dart';

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
/// Synthesis goes through the `synthesizeSpeech` Cloud Function so the
/// Cartesia API key (Secret Manager `CARTESIA_API`) never touches the client.
/// No screen should call Cartesia HTTP/WS endpoints directly.
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
  /// Keeps repeated reads of unchanging UI strings out of the billing path.
  static const int _maxCachedClips = 64;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Synthesize speech and return the audio bytes. Pass `cache: true` for
  /// static, unchanging strings so repeat reads are served from memory.
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
        _cache[key] = hit; // refresh LRU position
        return hit;
      }
    }

    final HttpsCallableResult result;
    try {
      final callable =
          _functions.httpsCallable(CartesiaConfig.synthesizeFunctionName);
      result = await callable.call<Map<String, dynamic>>({
        'transcript': text,
        'voice_id': vid,
        'model_id': mid,
        'language': language,
        'output_format': format.toJson(),
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
    final bytes = base64Decode(b64);

    if (key != null) {
      _cache[key] = bytes;
      while (_cache.length > _maxCachedClips) {
        _cache.remove(_cache.keys.first);
      }
    }
    return bytes;
  }

  /// Synthesize + play in one call. Returns once playback starts; await
  /// [_player.playerStateStream] / [isPlaying] to track completion.
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

/// just_audio source that plays an in-memory byte buffer.
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
