import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart' show MediaItem;
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '../config/cartesia_config.dart';
import '../config/cartesia_mcp_config.dart';
import 'cartesia_pcm_audio.dart';
import 'cartesia_speech_prompt.dart';
import 'cartesia_streaming_tts.dart';
import 'cartesia_voice_runtime.dart';
import '/services/ai_voice_preference_service.dart';

/// Enhanced Cartesia API Service.
///
/// Synthesis (TTS) and transcription (STT) are proxied through the
/// `synthesizeSpeech` / `transcribeSpeech` Cloud Functions so the Cartesia
/// API key (Secret Manager `CARTESIA_API`) never ships in the client binary.
/// All the playback / VARK / background-audio behavior stays on-device.
class CartesiaAPIService {
  CartesiaAPIService._();

  static const Duration _synthesizeTimeout = Duration(seconds: 120);

  static CartesiaAPIService? _instance;
  static CartesiaAPIService get instance =>
      _instance ??= CartesiaAPIService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _isInitialized = false;
  bool _isSpeaking = false;
  // Single FoCoCo coach voice — calm, slower delivery. Override per-call by
  // passing `voiceId:` to `generateSpeech` / `speakText` if needed.
  String _currentVoiceId = kFoCoCoDefaultCartesiaVoiceId;

  // Stream controllers for state management
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  Duration _currentPosition = Duration.zero;
  Duration? _duration;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  String get currentVoiceId => _currentVoiceId;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Duration get currentPosition => _currentPosition;
  Duration? get duration => _duration;

  /// Initialize the Cartesia API service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // No client-side connection test — the API key lives server-side in the
      // synthesizeSpeech / transcribeSpeech Cloud Functions.

      // Configure audio player
      await _configureAudioPlayer();

      _isInitialized = true;

      unawaited(CartesiaConfig.verifyVoiceId());
      unawaited(CartesiaStreamingTts.instance.warmConnection());

      if (kDebugMode) {
        print('✅ Cartesia API Service initialized (TTS via Cloud Function)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Cartesia API: $e');
      }
      _errorController.add('Failed to initialize Cartesia API: $e');
      rethrow;
    }
  }

  /// Configure audio player with optimal settings
  Future<void> _configureAudioPlayer() async {
    await _audioPlayer.setLoopMode(LoopMode.off);

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _playerStateController.add(state);

      if (state.processingState == ProcessingState.completed) {
        _isSpeaking = false;
        _speakingController.add(false);
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _duration = duration;
    });
  }

  /// Generate speech using Cartesia TTS API
  /// Implements the official API as documented
  Future<List<int>> generateSpeech({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
    CartesiaSpeechProfile? speechProfile,
    String? contextId,
    bool continueGeneration = false,
    bool transcriptAlreadyPrepared = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final effectiveVoiceId = voiceId ?? _currentVoiceId;

      final profile = speechProfile ?? _speechProfileForContent(contentType);
      final prepared = transcriptAlreadyPrepared
          ? text.trim()
          : CartesiaSpeechPrompt.prepareForTts(
              _adaptTextForVARK(text, varkPreferences),
              profile: profile,
            );

      // Get voice settings based on content type
      final voiceSettings = _getVoiceSettings(contentType, varkPreferences);

      // Convert speed setting to numeric value
      final speedValue = _resolveSpeedValue(
        voiceSettings: voiceSettings,
        voiceProfileKey: voiceProfileKey,
        explicitSpeedMultiplier: speedMultiplier,
      );

      final runtime = await CartesiaVoiceRuntime.load();
      final generationConfig = CartesiaSpeechPrompt.generationConfig(profile);
      if (speedValue > 0) {
        generationConfig['speed'] =
            CartesiaSpeechPrompt.clampSpeed(speedValue);
      }

      // Low-latency path: WebSocket + generation_config (speed/emotion/pronunciation).
      if (contextId == null || contextId.isEmpty) {
        try {
          final pcm = await CartesiaStreamingTts.instance.synthesize(
            transcript: prepared,
            voiceId: effectiveVoiceId,
            generationConfig: generationConfig,
            pronunciationDictId: runtime.pronunciationDictId.isNotEmpty
                ? runtime.pronunciationDictId
                : null,
            language: CartesiaMCPConfig.defaultLanguage,
          );
          if (pcm.isNotEmpty) {
            final wav = pcm16MonoToWav(pcm);
            if (kDebugMode) {
              print(
                '✅ Generated ${wav.length} bytes of audio (streaming WebSocket)',
              );
            }
            return wav;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Cartesia streaming TTS failed, using callable fallback: $e');
          }
          if (e is StateError &&
              e.message.contains('already been listened')) {
            await CartesiaStreamingTts.instance.dispose();
          }
        }
      }

      // Callable fallback (continuations / offline websocket).
      final audioData = await _synthesizeViaCallable(
        transcript: prepared,
        voiceId: effectiveVoiceId,
        generationConfig: generationConfig,
        pronunciationDictId: runtime.pronunciationDictId.isNotEmpty
            ? runtime.pronunciationDictId
            : null,
        contextId: contextId,
        continueGeneration: continueGeneration,
      );

      if (kDebugMode) {
        print('✅ Generated ${audioData.length} bytes of audio (via function)');
      }

      return audioData;
    } on FirebaseFunctionsException catch (e) {
      final detail = (e.message ?? e.details?.toString() ?? '').trim();
      final message = detail.isNotEmpty
          ? 'synthesizeSpeech ${e.code}: $detail'
          : 'synthesizeSpeech ${e.code}';
      _errorController.add('Failed to generate speech: $message');
      if (kDebugMode) {
        print('❌ Error generating speech: $message');
      }
      throw Exception(message);
    } catch (e) {
      _errorController.add('Failed to generate speech: $e');
      if (kDebugMode) {
        print('❌ Error generating speech: $e');
      }
      rethrow;
    }
  }

  static const int _maxCallableTranscriptChars = 1200;

  Future<List<int>> _synthesizeViaCallable({
    required String transcript,
    required String voiceId,
    required Map<String, dynamic> generationConfig,
    String? pronunciationDictId,
    String? contextId,
    bool continueGeneration = false,
  }) async {
    final callable = _functions.httpsCallable(
      CartesiaConfig.synthesizeFunctionName,
      options: HttpsCallableOptions(timeout: _synthesizeTimeout),
    );

    Future<List<int>> invokeSegment(
      String segment, {
      required Map<String, dynamic> config,
      String? segmentContextId,
      bool segmentContinue = false,
    }) async {
      final payload = <String, dynamic>{
        'transcript': segment,
        'voice_id': voiceId,
        'language': CartesiaMCPConfig.defaultLanguage,
        'output_format': {
          'container': 'wav',
          'encoding': 'pcm_s16le',
          'sample_rate': 44100,
        },
        if (config.isNotEmpty) 'generation_config': config,
        if (pronunciationDictId != null && pronunciationDictId.isNotEmpty)
          'pronunciation_dict_id': pronunciationDictId,
        if (segmentContextId != null && segmentContextId.isNotEmpty) ...{
          'context_id': segmentContextId,
          'continue': segmentContinue,
        },
        'max_buffer_delay_ms': 0,
      };
      final result = await callable.call<Map<String, dynamic>>(payload);
      final data = Map<String, dynamic>.from(result.data as Map);
      final b64 = data['audio_base64'] as String?;
      if (b64 == null || b64.isEmpty) {
        throw Exception('synthesizeSpeech returned no audio');
      }
      return base64Decode(b64);
    }

    Future<List<int>> invokeWithRetry(String segment) async {
      try {
        return await invokeSegment(
          segment,
          config: generationConfig,
          segmentContextId: contextId,
          segmentContinue: continueGeneration,
        );
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'internal' && generationConfig.containsKey('emotion')) {
          final fallbackConfig = Map<String, dynamic>.from(generationConfig)
            ..remove('emotion');
          return invokeSegment(
            segment,
            config: fallbackConfig,
            segmentContextId: contextId,
            segmentContinue: continueGeneration,
          );
        }
        rethrow;
      }
    }

    if (transcript.length <= _maxCallableTranscriptChars) {
      return invokeWithRetry(transcript);
    }

    final segments = _splitTranscript(transcript, _maxCallableTranscriptChars);
    final pcm = BytesBuilder(copy: false);
    for (final segment in segments) {
      final wav = await invokeWithRetry(segment);
      if (wav.length > 44) {
        pcm.add(wav.sublist(44));
      }
    }
    return pcm16MonoToWav(
      Uint8List.fromList(pcm.toBytes()),
      sampleRate: 44100,
    );
  }

  List<String> _splitTranscript(String text, int maxChars) {
    if (text.length <= maxChars) {
      return [text];
    }

    final segments = <String>[];
    var rest = text.trim();
    while (rest.length > maxChars) {
      var splitAt = rest.lastIndexOf('. ', maxChars);
      if (splitAt < maxChars ~/ 2) {
        splitAt = rest.lastIndexOf(' ', maxChars);
      }
      if (splitAt <= 0) {
        splitAt = maxChars;
      }
      segments.add(rest.substring(0, splitAt).trim());
      rest = rest.substring(splitAt).trim();
    }
    if (rest.isNotEmpty) {
      segments.add(rest);
    }
    return segments;
  }

  /// Speak text using Cartesia TTS with VARK adaptations
  Future<void> speakText({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
    CartesiaSpeechProfile? speechProfile,
    VoidCallback? onComplete,
  }) async {
    if (!await AiVoicePreferenceService.isEnabled()) {
      onComplete?.call();
      return;
    }

    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      _speakingController.add(true);

      // Generate audio data
      final audioData = await generateSpeech(
        text: text,
        voiceId: voiceId,
        voiceProfileKey: voiceProfileKey,
        contentType: contentType,
        varkPreferences: varkPreferences,
        speedMultiplier: speedMultiplier,
        speechProfile: speechProfile,
      );

      // Play the generated audio
      await playAudioData(audioData, onComplete: onComplete);
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('Failed to speak text: $e');
      rethrow;
    }
  }

  /// Play audio data directly
  Future<void> playAudioData(
    List<int> audioData, {
    VoidCallback? onComplete,
  }) async {
    try {
      // Create a temporary audio source from bytes, tagged so playback can
      // continue in the background with lock-screen controls.
      final audioSource = _BytesAudioSource(audioData, tag: _makeMediaItem());

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();

      // Set up completion callback
      if (onComplete != null) {
        _audioPlayer.playerStateStream
            .where(
                (state) => state.processingState == ProcessingState.completed)
            .take(1)
            .listen((_) => onComplete());
      }

      if (kDebugMode) {
        print('🔊 Playing generated audio');
      }
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      throw Exception('Failed to play audio: $e');
    }
  }

  Future<void> speakTextAndWait({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
    CartesiaSpeechProfile? speechProfile,
    VoidCallback? onComplete,
    bool useContinuations = true,
  }) async {
    if (!await AiVoicePreferenceService.isEnabled()) {
      onComplete?.call();
      return;
    }

    if (useContinuations) {
      await speakTextWithContinuations(
        text: text,
        voiceId: voiceId,
        voiceProfileKey: voiceProfileKey,
        contentType: contentType,
        varkPreferences: varkPreferences,
        speedMultiplier: speedMultiplier,
        speechProfile: speechProfile,
        onComplete: onComplete,
      );
      return;
    }

    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      _speakingController.add(true);

      final audioData = await generateSpeech(
        text: text,
        voiceId: voiceId,
        voiceProfileKey: voiceProfileKey,
        contentType: contentType,
        varkPreferences: varkPreferences,
        speedMultiplier: speedMultiplier,
        speechProfile: speechProfile,
      );

      await playAudioDataAndWait(audioData, onComplete: onComplete);
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('Failed to speak text: $e');
      rethrow;
    }
  }

  /// Prefer one-shot streaming synthesis (instant TTFB). Continuations are only
  /// used when the callable fallback path is required.
  Future<void> speakTextWithContinuations({
    required String text,
    String? voiceId,
    String? voiceProfileKey,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
    double? speedMultiplier,
    CartesiaSpeechProfile? speechProfile,
    VoidCallback? onComplete,
  }) async {
    await speakTextAndWait(
      text: text,
      voiceId: voiceId,
      voiceProfileKey: voiceProfileKey,
      contentType: contentType,
      varkPreferences: varkPreferences,
      speedMultiplier: speedMultiplier,
      speechProfile: speechProfile,
      onComplete: onComplete,
      useContinuations: false,
    );
  }

  Future<void> playAudioDataAndWait(
    List<int> audioData, {
    VoidCallback? onComplete,
  }) async {
    try {
      final audioSource = _BytesAudioSource(audioData, tag: _makeMediaItem());
      await _audioPlayer.setAudioSource(audioSource);

      final completion = Completer<void>();
      late final StreamSubscription<PlayerState> stateSub;
      stateSub = _audioPlayer.playerStateStream.listen(
        (state) {
          if (state.processingState == ProcessingState.completed &&
              !completion.isCompleted) {
            completion.complete();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completion.isCompleted) {
            completion.completeError(error, stackTrace);
          }
        },
      );

      await _audioPlayer.play();
      if (!completion.isCompleted) {
        await completion.future;
      }
      await stateSub.cancel();
      onComplete?.call();
    } catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Stop current speech
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _speakingController.add(false);
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    if (_isSpeaking) {
      await _audioPlayer.pause();
    }
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    if (!_isSpeaking &&
        _audioPlayer.playerState.processingState == ProcessingState.ready) {
      await _audioPlayer.play();
      _isSpeaking = true;
      _speakingController.add(true);
    }
  }

  /// Set voice ID for subsequent requests
  void setVoiceId(String voiceId) {
    _currentVoiceId = voiceId;
    if (kDebugMode) {
      print('🎭 Voice ID set to: $voiceId');
    }
  }

  /// Title shown on the lock-screen / notification media controls while voice
  /// plays in the background. Callers (e.g. MindCoach) can set this so the
  /// background control surface reflects the current activity.
  String _playbackTitle = 'FoCoCo';

  void setPlaybackTitle(String title) {
    final trimmed = title.trim();
    _playbackTitle = trimmed.isEmpty ? 'FoCoCo' : trimmed;
  }

  /// Build the `MediaItem` tag that lets `just_audio_background` keep playback
  /// alive in the background and render lock-screen controls.
  MediaItem _makeMediaItem() => MediaItem(
        id: 'fococo-voice-${DateTime.now().microsecondsSinceEpoch}',
        title: _playbackTitle,
        artist: 'FoCoCo',
      );

  double _resolveSpeedValue({
    required Map<String, dynamic> voiceSettings,
    String? voiceProfileKey,
    double? explicitSpeedMultiplier,
  }) {
    if (explicitSpeedMultiplier != null && explicitSpeedMultiplier > 0) {
      return explicitSpeedMultiplier;
    }

    final profile = voiceProfileKey == null
        ? null
        : CartesiaMCPConfig.getVoiceProfile(voiceProfileKey);
    final profileSpeed = profile?['speed_multiplier'];
    if (profileSpeed is num && profileSpeed > 0) {
      return profileSpeed.toDouble();
    }

    switch (voiceSettings['speed']) {
      case 'slow':
        return CartesiaSpeechPrompt.clampSpeed(0.85);
      case 'fast':
        return CartesiaSpeechPrompt.clampSpeed(1.15);
      case 'normal':
      default:
        return CartesiaSpeechPrompt.clampSpeed(
          CartesiaMCPConfig.defaultSpeedMultiplier,
        );
    }
  }

  /// Adapt text based on VARK learning preferences
  String _adaptTextForVARK(
      String text, VarkPreferencesStruct? varkPreferences) {
    if (varkPreferences == null) return text;

    String adaptedText = text;

    // Visual learners - add visualization cues
    if (varkPreferences.visual) {
      adaptedText = adaptedText.replaceAllMapped(
        RegExp(r'\b(focus|concentrate|aim)\b', caseSensitive: false),
        (match) => 'visualize ${match.group(0)}',
      );
    }

    // Auditory learners - add listening cues
    if (varkPreferences.aural) {
      adaptedText = adaptedText.replaceAllMapped(
        RegExp(r'\b(breathe|rhythm|tempo)\b', caseSensitive: false),
        (match) => 'listen to your ${match.group(0)}',
      );
    }

    // Read/Write learners - add note-taking cues
    if (varkPreferences.readWrite) {
      if (text.length > 100) {
        adaptedText = 'Remember to note this down: $adaptedText';
      }
    }

    // Kinesthetic learners - add physical cues
    if (varkPreferences.kinesthetic) {
      adaptedText = adaptedText.replaceAllMapped(
        RegExp(r'\b(practice|drill|exercise)\b', caseSensitive: false),
        (match) => 'feel the ${match.group(0)}',
      );
    }

    return adaptedText;
  }

  /// Get voice settings based on content type and VARK preferences
  Map<String, dynamic> _getVoiceSettings(
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
  ) {
    Map<String, dynamic> settings = {};

    // Base settings for content type using string values like your curl command
    switch (contentType) {
      case 'coaching':
        settings['speed'] = 'normal';
        break;
      case 'meditation':
        settings['speed'] = 'slow';
        break;
      case 'motivation':
        settings['speed'] = 'fast';
        break;
      case 'instruction':
        settings['speed'] = 'normal';
        break;
      default:
        settings['speed'] = 'normal';
    }

    // VARK adaptations
    if (varkPreferences != null) {
      if (varkPreferences.visual) {
        settings['speed'] = 'normal'; // Normal speed for visualization
      }
      if (varkPreferences.aural) {
        settings['speed'] = 'slow'; // Slightly slower for listening
      }
      if (varkPreferences.readWrite) {
        settings['speed'] = 'slow'; // Slower for note-taking
      }
      if (varkPreferences.kinesthetic) {
        settings['speed'] = 'fast'; // Faster for action
      }
    }

    return settings;
  }

  CartesiaSpeechProfile _speechProfileForContent(String? contentType) {
    switch (contentType) {
      case 'golf_reflection':
        return CartesiaSpeechPrompt.golfReflection;
      case 'daily_insight':
        return CartesiaSpeechPrompt.dailyInsight;
      case 'meditation':
        return const CartesiaSpeechProfile(
          speedRatio: 0.75,
          emotion: 'peaceful',
          prependEmotionTag: true,
          prependSpeedTag: true,
        );
      default:
        return CartesiaSpeechPrompt.mentorCalm;
    }
  }

  /// Transcribe recorded audio with the Cartesia speech-to-text API.
  ///
  /// Cartesia is the single voice provider for every voice input in the app.
  /// This mirrors the web app's `/api/golfchat/voice/transcribe` route:
  /// `POST /stt` (multipart) with model `ink-whisper`.
  Future<CartesiaTranscript> transcribeAudio({
    required List<int> audioBytes,
    String fileName = 'voice-input.wav',
    MediaType? contentType,
    String? encoding,
    int? sampleRate,
    String? language,
  }) async {
    if (audioBytes.isEmpty) {
      return const CartesiaTranscript(text: '', words: []);
    }

    try {
      // Proxy through the Cloud Function — the STT key stays in Secret Manager.
      final mime = contentType ?? MediaType('audio', 'wav');
      final callable =
          _functions.httpsCallable(CartesiaConfig.transcribeFunctionName);
      final result = await callable.call<Map<String, dynamic>>({
        'audio_base64': base64Encode(audioBytes),
        'file_name': fileName,
        'mime_type': '${mime.type}/${mime.subtype}',
        if (encoding != null && encoding.isNotEmpty) 'encoding': encoding,
        if (sampleRate != null) 'sample_rate': sampleRate,
        if (language != null && language.isNotEmpty) 'language': language,
      });

      final decoded = Map<String, dynamic>.from(result.data as Map);
      final words = (decoded['words'] as List<dynamic>? ?? [])
          .map((w) => w.toString())
          .where((w) => w.isNotEmpty)
          .toList();

      return CartesiaTranscript(
        text: (decoded['text'] ?? '').toString().trim(),
        words: words,
        language: decoded['language']?.toString(),
        durationSeconds: (decoded['duration'] as num?)?.toDouble(),
      );
    } catch (e) {
      _errorController.add('Failed to transcribe audio: $e');
      if (kDebugMode) {
        print('❌ Error transcribing audio: $e');
      }
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _speakingController.close();
    _errorController.close();
    _playerStateController.close();
    _positionController.close();
    _audioPlayer.dispose();
  }
}

/// Result of a Cartesia speech-to-text transcription.
class CartesiaTranscript {
  const CartesiaTranscript({
    required this.text,
    required this.words,
    this.language,
    this.durationSeconds,
  });

  final String text;
  final List<String> words;
  final String? language;
  final double? durationSeconds;

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Custom audio source for playing bytes data
class _BytesAudioSource extends StreamAudioSource {
  final List<int> _audioData;

  _BytesAudioSource(this._audioData, {MediaItem? tag}) : super(tag: tag);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final rangeStart = start ?? 0;
    final rangeEnd = end ?? _audioData.length;

    return StreamAudioResponse(
      sourceLength: _audioData.length,
      contentLength: rangeEnd - rangeStart,
      offset: rangeStart,
      stream: Stream<List<int>>.multi((controller) {
        controller.add(
          Uint8List.fromList(_audioData.sublist(rangeStart, rangeEnd)),
        );
        controller.close();
      }),
      contentType: 'audio/wav',
    );
  }
}
