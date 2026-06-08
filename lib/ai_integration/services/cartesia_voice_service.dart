import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../backend/schema/structs/vark_preferences_struct.dart';
import 'cartesia_api_service.dart';

/// High-level state of a Cartesia voice interaction.
enum CartesiaVoiceState {
  idle,
  listening,
  transcribing,
  thinking,
  speaking,
  error,
}

/// Unified voice facade — Cartesia is the single provider for every voice
/// input and output in the app.
///
/// Recording (microphone) -> Cartesia STT -> caller-supplied text responder ->
/// Cartesia TTS playback. Recording uses the `record` package; transcription
/// and speech delegate to [CartesiaAPIService].
///
/// This service owns its own recorder, so it must not be used concurrently
/// with another recorder on the same screen.
class CartesiaVoiceService {
  CartesiaVoiceService._();

  static CartesiaVoiceService? _instance;
  static CartesiaVoiceService get instance =>
      _instance ??= CartesiaVoiceService._();

  /// The existing instance, or `null` if voice has not been used yet. Lets
  /// callers (e.g. lifecycle handlers) avoid eagerly creating a recorder.
  static CartesiaVoiceService? get maybeInstance => _instance;

  final CartesiaAPIService _cartesia = CartesiaAPIService.instance;
  final AudioRecorder _recorder = AudioRecorder();

  final StreamController<CartesiaVoiceState> _stateController =
      StreamController<CartesiaVoiceState>.broadcast();

  CartesiaVoiceState _state = CartesiaVoiceState.idle;
  String? _activeRecordingPath;
  bool _disposed = false;

  /// Last sample rate / encoding used for a recording — handed to STT so the
  /// transcription request matches the captured audio exactly.
  static const int _recordSampleRate = 16000;

  Stream<CartesiaVoiceState> get stateStream => _stateController.stream;
  CartesiaVoiceState get state => _state;
  bool get isListening => _state == CartesiaVoiceState.listening;
  bool get isSpeaking => _state == CartesiaVoiceState.speaking;

  /// Underlying TTS engine, exposed for callers that only need playback.
  CartesiaAPIService get tts => _cartesia;

  void _setState(CartesiaVoiceState next) {
    if (_disposed || _state == next) return;
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  /// Whether the microphone permission has been granted.
  Future<bool> hasMicrophonePermission() => _recorder.hasPermission();

  /// Begin capturing microphone audio. Returns false if permission is denied
  /// or recording could not start.
  Future<bool> startListening() async {
    if (_disposed) return false;
    if (_state == CartesiaVoiceState.listening) return true;

    try {
      if (!await _recorder.hasPermission()) {
        return false;
      }

      // Stop any in-progress playback before opening the mic.
      await _cartesia.stopSpeaking();

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/cartesia_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: _recordSampleRate,
          numChannels: 1,
        ),
        path: path,
      );

      _activeRecordingPath = path;
      _setState(CartesiaVoiceState.listening);
      return true;
    } catch (e) {
      if (kDebugMode) print('⚠️ Cartesia voice startListening failed: $e');
      _setState(CartesiaVoiceState.error);
      return false;
    }
  }

  /// Stop capturing and transcribe the captured audio via Cartesia STT.
  /// Returns `null` if nothing usable was captured.
  Future<CartesiaTranscript?> stopListeningAndTranscribe({
    String? language,
  }) async {
    if (_disposed) return null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      if (kDebugMode) print('⚠️ Cartesia voice stop failed: $e');
    }
    path ??= _activeRecordingPath;
    _activeRecordingPath = null;

    if (path == null) {
      _setState(CartesiaVoiceState.idle);
      return null;
    }

    final file = File(path);
    if (!file.existsSync()) {
      _setState(CartesiaVoiceState.idle);
      return null;
    }

    try {
      _setState(CartesiaVoiceState.transcribing);
      final bytes = await file.readAsBytes();
      final transcript = await _cartesia.transcribeAudio(
        audioBytes: bytes,
        fileName: 'voice-input.wav',
        contentType: MediaType('audio', 'wav'),
        encoding: 'pcm_s16le',
        sampleRate: _recordSampleRate,
        language: language,
      );
      _setState(CartesiaVoiceState.idle);
      return transcript;
    } catch (e) {
      if (kDebugMode) print('⚠️ Cartesia voice transcription failed: $e');
      _setState(CartesiaVoiceState.error);
      return null;
    } finally {
      // Best-effort cleanup of the temp recording.
      try {
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  /// Cancel an in-progress recording without transcribing it.
  Future<void> cancelListening() async {
    if (_disposed) return;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    final path = _activeRecordingPath;
    _activeRecordingPath = null;
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
    _setState(CartesiaVoiceState.idle);
  }

  /// Speak [text] with the FoCoCo Cartesia voice. Returns when playback ends.
  Future<void> speak(
    String text, {
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
  }) async {
    if (_disposed || text.trim().isEmpty) return;
    try {
      _setState(CartesiaVoiceState.speaking);
      await _cartesia.speakTextAndWait(
        text: text,
        voiceId: voiceId,
        voiceProfileKey: voiceProfileKey,
        contentType: contentType,
        varkPreferences: varkPreferences,
        speedMultiplier: speedMultiplier,
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ Cartesia voice speak failed: $e');
      _setState(CartesiaVoiceState.error);
      rethrow;
    } finally {
      if (_state != CartesiaVoiceState.error) {
        _setState(CartesiaVoiceState.idle);
      }
    }
  }

  /// Stop any in-progress speech playback.
  Future<void> stopSpeaking() async {
    await _cartesia.stopSpeaking();
    if (_state == CartesiaVoiceState.speaking) {
      _setState(CartesiaVoiceState.idle);
    }
  }

  /// Run one conversation turn: take a [transcript], generate a reply with the
  /// caller-supplied [responder] (the text LLM), then speak the reply.
  Future<String?> respondAndSpeak(
    String transcript,
    Future<String> Function(String transcript) responder, {
    String? voiceProfileKey,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    if (_disposed || transcript.trim().isEmpty) return null;
    String reply;
    try {
      _setState(CartesiaVoiceState.thinking);
      reply = await responder(transcript);
    } catch (e) {
      if (kDebugMode) print('⚠️ Cartesia voice responder failed: $e');
      _setState(CartesiaVoiceState.error);
      return null;
    }
    if (reply.trim().isEmpty) {
      _setState(CartesiaVoiceState.idle);
      return reply;
    }
    await speak(
      reply,
      voiceProfileKey: voiceProfileKey,
      varkPreferences: varkPreferences,
    );
    return reply;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _recorder.dispose();
    } catch (_) {}
    await _stateController.close();
    _instance = null;
  }
}
