import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';

import '/adaptive_ui/adaptive_ui.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/ai_integration/gemini_ai_client.dart';
import '/ai_integration/config/cartesia_mcp_config.dart';
import '/ai_integration/config/gemini_live_config.dart';
import '/ai_integration/config/gemini_voice_config.dart';
import '/ai_integration/services/cartesia_api_service.dart';
import '/ai_integration/services/voice_chat_database_service.dart';
import '/ai_integration/widgets/navbar_widget.dart';

import 'golfchat_model.dart';

export 'golfchat_model.dart';

/// Space so the message list does not sit under the composer when it is pinned.
const double _kGolfChatComposerClearance = 140;

class GolfChatWidget extends StatefulWidget {
  const GolfChatWidget({
    super.key,
    this.initialRoundId,
    this.initialCaddyPlaySnapshot,
  });

  static const String routeName = 'golf_chat';
  static const String routePath = '/golf_chat';

  final String? initialRoundId;
  final Map<String, dynamic>? initialCaddyPlaySnapshot;

  @override
  State<GolfChatWidget> createState() => _GolfChatWidgetState();
}

class _ReplyPreview {
  final String id;
  final String text;
  final bool isUser;

  const _ReplyPreview({
    required this.id,
    required this.text,
    required this.isUser,
  });
}

class _GolfChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final _ReplyPreview? replyTo;

  const _GolfChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.replyTo,
  });

  _GolfChatMessage copyWith({_ReplyPreview? replyTo}) => _GolfChatMessage(
        id: id,
        text: text,
        isUser: isUser,
        time: time,
        replyTo: replyTo ?? this.replyTo,
      );
}

enum _VoiceModeState {
  idle,
  connecting,
  listening,
  processing,
  speaking,
  error
}

enum _AttachmentType { image, file }

class _ChatAttachment {
  final String id;
  final String path;
  final String name;
  final _AttachmentType type;
  final Uint8List? bytes;

  const _ChatAttachment({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    this.bytes,
  });
}

class _GolfChatWidgetState extends State<GolfChatWidget>
    with TickerProviderStateMixin {
  late GolfChatModel _model;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final VoiceChatDatabaseService _db = VoiceChatDatabaseService();
  final GeminiAIClient _aiClient =
      GeminiAIClient(apiKey: GeminiLiveAPIConfig.apiKey);
  final CartesiaAPIService _cartesiaTts = CartesiaAPIService.instance;

  bool _isLoading = true;
  bool _isSending = false;
  bool _showBoundary = false;
  bool _ttsSpeaking = false;
  bool _ttsAvailable = false;
  String? _golfChatVoiceId;
  String? _roundContextId;
  Map<String, dynamic>? _roundContextSnapshot;

  String? _sessionId;
  final List<_GolfChatMessage> _messages = <_GolfChatMessage>[];
  _ReplyPreview? _replyPreview;

  static const String _boundaryCopy =
      'Reflection only—not in-round coaching. AI helps you understand your game.';

  // Voice mode state
  bool _isVoiceMode = false;
  _VoiceModeState _voiceState = _VoiceModeState.idle;
  LiveSession? _liveSession;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Future<void>? _liveReceiveTask;
  bool _keepReceivingLiveResponses = false;
  bool _isLiveReceiveLoopRunning = false;
  bool _isHandlingVoiceTransportError = false;
  bool _liveAudioPlaylistLoaded = false;
  int _liveAudioChunkCount = 0;
  bool _awaitingPlaybackDrain = false;
  String _liveTranscription = '';
  String _liveInputTranscript = '';
  String _liveOutputTranscript = '';
  final List<double> _audioLevels = List.filled(64, 0.0);

  // Attachments
  final List<_ChatAttachment> _pendingAttachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _waveAnimationController;
  late AnimationController _gradientAnimationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GolfChatModel());
    _configureAudioPlayer();
    _initialize();
    _initTts();
    _initAnimations();
  }

  void _configureAudioPlayer() {
    _audioPlayerStateSubscription = _audioPlayer.playerStateStream.listen(
      (state) {
        if (!_isVoiceMode) {
          return;
        }

        if (state.processingState == ProcessingState.completed) {
          unawaited(_resetLiveAudioPlayback());
          if (mounted && _awaitingPlaybackDrain) {
            setState(() {
              _voiceState = _VoiceModeState.listening;
              _audioLevels.fillRange(0, _audioLevels.length, 0.0);
            });
          }
          _awaitingPlaybackDrain = false;
        }
      },
    );
  }

  void _initAnimations() {
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveAnimationController, curve: Curves.linear),
    );

    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _gradientAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant GolfChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final roundChanged = oldWidget.initialRoundId != widget.initialRoundId;
    final snapshotChanged = !mapEquals(
      oldWidget.initialCaddyPlaySnapshot,
      widget.initialCaddyPlaySnapshot,
    );
    if (!roundChanged && !snapshotChanged) {
      return;
    }

    _hydrateRoundContextFromWidget();
    if (!_isLoading) {
      unawaited(_ensureSession());
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initTts() async {
    try {
      await _cartesiaTts.initialize();
      _golfChatVoiceId = _resolveGolfChatVoiceId();
      if (_golfChatVoiceId != null) {
        _cartesiaTts.setVoiceId(_golfChatVoiceId!);
      }
      if (mounted) {
        setState(() => _ttsAvailable = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _ttsAvailable = false);
      }
    }
  }

  String? _resolveGolfChatVoiceId() {
    final profile = CartesiaMCPConfig.getVoiceProfile('coach_conversational') ??
        CartesiaMCPConfig.getVoiceProfile('coach_confident');
    if (profile == null) {
      return null;
    }
    final voiceId = profile['voice_id']?.toString().trim();
    if (voiceId == null || voiceId.isEmpty) {
      return null;
    }
    return voiceId;
  }

  Future<void> _initialize() async {
    try {
      await _db.initialize();
      _hydrateRoundContextFromWidget();
      await _loadBoundaryFlag();
      await _ensureSession();
    } catch (e) {
      if (mounted) {
        _showSnack('GolfChat setup failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBoundaryFlag() async {
    if (currentUserUid.isEmpty) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance.doc('user/$currentUserUid').get();
      final data = userDoc.data();
      final uxFlags = data?['uxFlags'] as Map<String, dynamic>?;
      final shown = uxFlags?['golfChatBoundaryShownAt'];

      if (shown == null) {
        _showBoundary = true;
        await FirebaseFirestore.instance.doc('user/$currentUserUid').set({
          'uxFlags': {
            'golfChatBoundaryShownAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Non-blocking: if boundary write fails, still let user chat.
      _showBoundary = true;
    }
  }

  Future<void> _ensureSession() async {
    if (currentUserUid.isEmpty) return;

    VoiceChatSession? session;
    final requestedRoundId = _roundContextId?.trim();
    try {
      session = await _db.getActiveSession();
      if (session != null && session.sessionMetadata['surface'] != 'golfchat') {
        session = null;
      } else if (session != null &&
          requestedRoundId != null &&
          requestedRoundId.isNotEmpty &&
          session.sessionMetadata['roundId']?.toString() != requestedRoundId) {
        session = null;
      }
    } catch (_) {
      session = null;
    }

    if (session == null) {
      session = await _db.startSession(
        title: 'GolfChat Reflection',
        metadata: <String, dynamic>{
          'surface': 'golfchat',
          'tone': 'calm_reflection',
          if (requestedRoundId != null && requestedRoundId.isNotEmpty)
            'roundId': requestedRoundId,
          if (_roundContextSnapshot != null)
            'caddyplaySnapshot': _roundContextSnapshot,
        },
      );
    } else {
      _hydrateRoundContextFromSession(session);
    }

    _sessionId = session.id;

    try {
      final savedMessages =
          await _db.getSessionMessages(sessionId: session.id, limit: 200);
      _messages
        ..clear()
        ..addAll(savedMessages.map((msg) => _GolfChatMessage(
              id: msg.id,
              text: msg.content,
              isUser: msg.isUser == true,
              time: msg.timestamp,
            )));
    } catch (_) {
      // If loading history fails, keep this session empty.
    }

    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _hydrateRoundContextFromWidget() {
    final roundId = widget.initialRoundId?.trim();
    _roundContextId = (roundId == null || roundId.isEmpty) ? null : roundId;
    final snapshot = widget.initialCaddyPlaySnapshot;
    _roundContextSnapshot =
        snapshot == null ? null : Map<String, dynamic>.from(snapshot);
  }

  void _hydrateRoundContextFromSession(VoiceChatSession session) {
    final metadata = session.sessionMetadata;
    final roundId = metadata['roundId']?.toString().trim();
    if ((roundId ?? '').isNotEmpty) {
      _roundContextId = roundId;
    }
    final snapshot = metadata['caddyplaySnapshot'];
    if (snapshot is Map) {
      _roundContextSnapshot = Map<String, dynamic>.from(snapshot);
    }
  }

  @override
  void dispose() {
    unawaited(_exitVoiceMode());
    _cartesiaTts.stopSpeaking();
    _audioPlayerStateSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _waveAnimationController.dispose();
    _gradientAnimationController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _enterVoiceMode() async {
    if (_isVoiceMode) {
      return;
    }

    await _stopTtsPlayback();
    await _resetLiveAudioPlayback();

    setState(() {
      _isVoiceMode = true;
      _voiceState = _VoiceModeState.connecting;
      _liveTranscription = '';
      _liveInputTranscript = '';
      _liveOutputTranscript = '';
      _audioLevels.fillRange(0, _audioLevels.length, 0.0);
    });

    try {
      final liveModel = FirebaseAI.googleAI(
        app: await getGoogleAIFirebaseApp(),
      ).liveGenerativeModel(
        model: GeminiVoiceConfig.nativeAudioDialogModel,
        liveGenerationConfig: LiveGenerationConfig(
          responseModalities: [ResponseModalities.audio],
          speechConfig: SpeechConfig(
            voiceName: GeminiVoiceConfig.geminiLiveVoiceName,
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
        ),
        systemInstruction:
            Content.system(GeminiVoiceConfig.voiceCoachingSystemPrompt),
      );

      _liveSession = await liveModel.connect();
      _keepReceivingLiveResponses = true;
      _liveReceiveTask = _processLiveResponses();

      await _startAudioCapture();
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.listening);
      }
    } catch (e) {
      debugPrint('Voice mode connection failed: $e');
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.error);
        _showSnack(_describeVoiceError(e));
      }
    }
  }

  Future<void> _processLiveResponses() async {
    final session = _liveSession;
    if (session == null || _isLiveReceiveLoopRunning) {
      return;
    }

    _isLiveReceiveLoopRunning = true;
    try {
      while (_keepReceivingLiveResponses && identical(session, _liveSession)) {
        await for (final response in session.receive()) {
          await _handleLiveResponse(response);
          if (!_keepReceivingLiveResponses ||
              !identical(session, _liveSession)) {
            break;
          }
        }

        if (!_keepReceivingLiveResponses || !identical(session, _liveSession)) {
          break;
        }

        await Future<void>.delayed(const Duration(milliseconds: 32));
      }
    } catch (error) {
      if (_keepReceivingLiveResponses) {
        await _handleVoiceSessionError(error);
      }
    } finally {
      _isLiveReceiveLoopRunning = false;
    }
  }

  Future<void> _handleLiveResponse(LiveServerResponse response) async {
    final message = response.message;

    if (message is GoingAwayNotice) {
      debugPrint(
          'Voice session going away soon. Time left: ${message.timeLeft}');
      return;
    }

    if (message is! LiveServerContent) {
      return;
    }

    _handleTranscriptionChunk(
      message.inputTranscription,
      isUser: true,
    );
    _handleTranscriptionChunk(
      message.outputTranscription,
      isUser: false,
    );

    final modelTurn = message.modelTurn;
    if (modelTurn != null) {
      for (final part in modelTurn.parts) {
        if (part is TextPart) {
          _handleOutputTextChunk(part.text);
        } else if (part is InlineDataPart && part.mimeType.contains('audio')) {
          if (mounted) {
            setState(() => _voiceState = _VoiceModeState.speaking);
          }
          _updateAudioLevels(part.bytes);
          await _playPcmAudio(part.bytes);
        }
      }
    }

    if (message.interrupted == true) {
      await _resetLiveAudioPlayback();
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.listening);
      }
      _awaitingPlaybackDrain = false;
    }

    if (message.turnComplete == true) {
      await _commitLiveVoiceTurn();
      final shouldWaitForPlayback = _liveAudioChunkCount > 0 &&
          _audioPlayer.processingState != ProcessingState.completed;
      _awaitingPlaybackDrain = shouldWaitForPlayback;
      if (!shouldWaitForPlayback && mounted) {
        setState(() => _voiceState = _VoiceModeState.listening);
      }
    }
  }

  Future<void> _sendAudioChunk(Uint8List audioData) async {
    final session = _liveSession;
    if (session == null ||
        !_keepReceivingLiveResponses ||
        _voiceState == _VoiceModeState.error) {
      return;
    }

    try {
      await session.sendAudioRealtime(InlineDataPart('audio/pcm', audioData));
    } catch (e) {
      await _handleVoiceSessionError(e);
    }
  }

  Future<void> _exitVoiceMode() async {
    _keepReceivingLiveResponses = false;
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (_) {}
    await _resetLiveAudioPlayback();
    try {
      await _liveSession?.close();
    } catch (_) {}
    _liveSession = null;
    try {
      await _liveReceiveTask;
    } catch (_) {}
    _liveReceiveTask = null;
    _awaitingPlaybackDrain = false;

    if (mounted) {
      setState(() {
        _isVoiceMode = false;
        _voiceState = _VoiceModeState.idle;
        _liveTranscription = '';
        _liveInputTranscript = '';
        _liveOutputTranscript = '';
        _audioLevels.fillRange(0, _audioLevels.length, 0.0);
      });
    }
  }

  Future<void> _startAudioCapture() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnack('Microphone permission required for voice mode.');
      await _exitVoiceMode();
      return;
    }

    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    _audioStreamSubscription = stream.listen((data) {
      unawaited(_sendAudioChunk(data));
      _updateAudioLevelsFromInput(data);
    });
  }

  Future<void> _handleVoiceSessionError(Object error) async {
    if (_isHandlingVoiceTransportError) {
      return;
    }

    _isHandlingVoiceTransportError = true;
    _keepReceivingLiveResponses = false;
    debugPrint('Voice session error: $error');

    try {
      await _audioStreamSubscription?.cancel();
    } catch (_) {}
    _audioStreamSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (_) {}

    await _resetLiveAudioPlayback();

    try {
      await _liveSession?.close();
    } catch (_) {}
    _liveSession = null;

    if (mounted) {
      setState(() => _voiceState = _VoiceModeState.error);
      _showSnack(_describeVoiceError(error));
    } else {
      debugPrint('GolfChat voice error: ${_describeVoiceError(error)}');
    }

    _isHandlingVoiceTransportError = false;
  }

  String _describeVoiceError(Object error) {
    final message = error.toString();
    if (message.contains('reported as leaked')) {
      return 'Voice API key was revoked as leaked. Rotate the Firebase/Google AI key or run with --dart-define=GEMINI_API_KEY=NEW_KEY.';
    }
    if (message.contains('WebSocket Closed')) {
      return 'Voice connection closed unexpectedly.';
    }
    return 'Voice connection error';
  }

  void _updateAudioLevels(Uint8List audioData) {
    if (audioData.isEmpty) return;

    final samples = audioData.length ~/ 2;
    final step = math.max(1, samples ~/ _audioLevels.length);

    for (int i = 0; i < _audioLevels.length && i * step < samples; i++) {
      final index = i * step * 2;
      if (index + 1 < audioData.length) {
        final sample =
            (audioData[index] | (audioData[index + 1] << 8)).toSigned(16);
        _audioLevels[i] = (sample.abs() / 32768.0).clamp(0.0, 1.0);
      }
    }
    if (mounted) setState(() {});
  }

  void _updateAudioLevelsFromInput(Uint8List audioData) {
    if (_voiceState != _VoiceModeState.listening) return;
    _updateAudioLevels(audioData);
  }

  Future<void> _playPcmAudio(Uint8List pcmData) async {
    try {
      final wavData = _buildWavFile(pcmData, sampleRate: 24000);
      final audioChunk = _BytesAudioSource(wavData);

      if (!_liveAudioPlaylistLoaded) {
        await _audioPlayer.setAudioSources(
          <AudioSource>[audioChunk],
          preload: true,
        );
        _liveAudioPlaylistLoaded = true;
        _liveAudioChunkCount = 1;
      } else {
        await _audioPlayer.addAudioSource(audioChunk);
        _liveAudioChunkCount += 1;
      }

      if (!_audioPlayer.playing) {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void _handleTranscriptionChunk(
    Transcription? transcription, {
    required bool isUser,
  }) {
    final text = transcription?.text;
    if (text == null || text.isEmpty) {
      return;
    }

    final current = isUser ? _liveInputTranscript : _liveOutputTranscript;
    final updated = '$current$text';

    if (!mounted) {
      if (isUser) {
        _liveInputTranscript = updated;
      } else {
        _liveOutputTranscript = updated;
      }
      _liveTranscription = _normalizedTranscript(
        _liveOutputTranscript.isNotEmpty
            ? _liveOutputTranscript
            : _liveInputTranscript,
      );
      return;
    }

    setState(() {
      if (isUser) {
        _liveInputTranscript = updated;
      } else {
        _liveOutputTranscript = updated;
      }

      _liveTranscription = _normalizedTranscript(
        _liveOutputTranscript.isNotEmpty
            ? _liveOutputTranscript
            : _liveInputTranscript,
      );

      if (isUser &&
          transcription?.finished == true &&
          _liveOutputTranscript.isEmpty) {
        _voiceState = _VoiceModeState.processing;
      }
    });
  }

  void _handleOutputTextChunk(String text) {
    if (text.isEmpty) {
      return;
    }

    final updated = '$_liveOutputTranscript$text';
    if (mounted) {
      setState(() {
        _liveOutputTranscript = updated;
        _liveTranscription = _normalizedTranscript(_liveOutputTranscript);
      });
    } else {
      _liveOutputTranscript = updated;
      _liveTranscription = _normalizedTranscript(_liveOutputTranscript);
    }
  }

  String _normalizedTranscript(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _commitLiveVoiceTurn() async {
    final userTranscript = _normalizedTranscript(_liveInputTranscript);
    final modelTranscript = _normalizedTranscript(_liveOutputTranscript);

    _liveInputTranscript = '';
    _liveOutputTranscript = '';

    if (mounted) {
      setState(() {
        _liveTranscription = modelTranscript;
      });
    } else {
      _liveTranscription = modelTranscript;
    }

    if (userTranscript.isEmpty && modelTranscript.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final newMessages = <_GolfChatMessage>[];

    if (userTranscript.isNotEmpty) {
      newMessages.add(
        _GolfChatMessage(
          id: now.microsecondsSinceEpoch.toString(),
          text: userTranscript,
          isUser: true,
          time: now,
        ),
      );
    }

    if (modelTranscript.isNotEmpty) {
      newMessages.add(
        _GolfChatMessage(
          id: '${now.microsecondsSinceEpoch + 1}',
          text: modelTranscript,
          isUser: false,
          time: now,
        ),
      );
    }

    if (newMessages.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _messages.addAll(newMessages);
        _showBoundary = false;
      });
    } else {
      _messages.addAll(newMessages);
      _showBoundary = false;
    }

    _scrollToBottom();

    for (final message in newMessages) {
      await _persistMessage(
        message,
        messageType: message.isUser ? 'audio' : 'native_audio',
      );
    }
  }

  Future<void> _resetLiveAudioPlayback() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      if (_liveAudioPlaylistLoaded) {
        await _audioPlayer.setAudioSources(
          const <AudioSource>[],
          preload: false,
        );
      }
    } catch (_) {}

    _liveAudioPlaylistLoaded = false;
    _liveAudioChunkCount = 0;
  }

  Uint8List _buildWavFile(Uint8List pcmData, {int sampleRate = 24000}) {
    final byteData = ByteData(44 + pcmData.length);
    byteData.setUint32(0, 0x52494646, Endian.big);
    byteData.setUint32(4, 36 + pcmData.length, Endian.little);
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
    byteData.setUint32(40, pcmData.length, Endian.little);
    final wavBytes = byteData.buffer.asUint8List();
    wavBytes.setRange(44, 44 + pcmData.length, pcmData);
    return wavBytes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final hasKeyboard = keyboardHeight > 0;
    final bottomNavReserve = hasKeyboard
        ? 0.0
        : (kFoCoCoBottomNavStripAndTabsHeight + viewPadding.bottom);

    return StreamBuilder<UserRecord>(
      stream: currentUserUid.isNotEmpty
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/$currentUserUid'))
          : null,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return FoCoCoAdaptiveScaffold(
          backgroundColor: theme.primaryBackground,
          title: 'GolfChat',
          currentRoute: GolfChatWidget.routeName,
          onTap: (route) => context.goNamed(route),
          showBottomNav: false,
          drawer: user != null
              ? FoCoCoDrawer(
                  currentUser: user,
                  currentRoute: GolfChatWidget.routeName,
                  onNavigate: (route) => context.goNamed(route),
                )
              : null,
          leading: user == null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: FoCoCoAdaptiveIconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed('mind_coach');
                        }
                      },
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconColor: theme.primaryText,
                      style: AdaptiveButtonStyle.plain,
                      size: AdaptiveButtonSize.small,
                    ),
                  ),
                )
              : null,
          enableVoiceButton: !_isVoiceMode,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                color: theme.primaryBackground,
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Text(
                          'Reflect • Understand your game • Reset',
                          style: theme.bodySmall
                              .copyWith(color: theme.secondaryText),
                        ),
                      ),
                    ),
                    if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                    if (_showBoundary) _buildBoundary(theme),
                    if (_hasRoundContext) _buildRoundContextBanner(theme),
                    Expanded(
                      child: _buildConversation(
                        theme,
                        extraBottomPadding:
                            hasKeyboard ? 0 : _kGolfChatComposerClearance,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isVoiceMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: hasKeyboard ? 0.0 : bottomNavReserve,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildInput(theme),
                  ),
                ),
              if (_isVoiceMode)
                Positioned.fill(
                  child: _buildVoiceModeOverlay(theme, bottomNavReserve),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceModeOverlay(
    FlutterFlowTheme theme,
    double bottomNavReserve,
  ) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPad = bottomNavReserve + keyboardInset;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveAnimation, _gradientAnimation]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF000000)),
              const CustomPaint(
                painter: _StarfieldPainter(),
                size: Size.infinite,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: CustomPaint(
                  painter: _VoiceBottomWavePainter(
                    audioLevels: _audioLevels,
                    wavePhase: _waveAnimation.value,
                    gradientProgress: _gradientAnimation.value,
                    primaryColor: theme.primary,
                    secondaryColor: theme.secondary,
                    tertiaryColor: theme.tertiary,
                    isActive: _voiceState == _VoiceModeState.listening ||
                        _voiceState == _VoiceModeState.speaking ||
                        _voiceState == _VoiceModeState.processing,
                    voiceState: _voiceState,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: _buildVoiceModeCenterHint(theme),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  child: _buildInput(theme, voiceGlass: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceModeCenterHint(FlutterFlowTheme theme) {
    final String line1;
    final String? line2;
    switch (_voiceState) {
      case _VoiceModeState.connecting:
        line1 = 'Connecting';
        line2 = 'Setting up voice…';
        break;
      case _VoiceModeState.listening:
        line1 = 'You may start speaking';
        line2 = null;
        break;
      case _VoiceModeState.processing:
        line1 = 'Processing';
        line2 = null;
        break;
      case _VoiceModeState.speaking:
        line1 = 'Coaching';
        line2 = null;
        break;
      case _VoiceModeState.error:
        line1 = 'Connection issue';
        line2 = 'Check network or try again';
        break;
      case _VoiceModeState.idle:
        line1 = '';
        line2 = null;
    }

    if (line1.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoiceMicGlyph(
          theme: theme,
          voiceState: _voiceState,
          wavePhase: _waveAnimation.value,
          gradientT: _gradientAnimation.value,
        ),
        const SizedBox(height: 20),
        Text(
          line1,
          textAlign: TextAlign.center,
          style: theme.titleMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        if (line2 != null) ...[
          const SizedBox(height: 8),
          Text(
            line2,
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
        if (_liveTranscription.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            _liveTranscription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBoundary(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: theme.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _boundaryCopy,
                  style: theme.bodySmall.copyWith(
                    color: theme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasRoundContext =>
      (_roundContextId?.isNotEmpty ?? false) || _roundContextSnapshot != null;

  Widget _buildRoundContextBanner(FlutterFlowTheme theme) {
    final courseName = _roundContextSnapshot?['courseName']?.toString().trim();
    final evaluation =
        _roundContextSnapshot?['evaluationPhrase']?.toString().trim();
    final moments = _roundContextSnapshot?['totalMoments'];
    final roundLabel = switch (moments) {
      int value => '$value moments captured',
      num value => '${value.toInt()} moments captured',
      _ => null,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.tertiary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flag_circle_outlined,
            color: theme.tertiary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName?.isNotEmpty == true
                      ? 'Round context loaded: $courseName'
                      : 'Round context loaded',
                  style: theme.bodySmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (roundLabel != null ||
                    (evaluation?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (roundLabel != null) roundLabel,
                      if (evaluation?.isNotEmpty ?? false) evaluation!,
                    ].join(' • '),
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(
    FlutterFlowTheme theme, {
    double extraBottomPadding = 0,
  }) {
    if (_messages.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: extraBottomPadding),
        child: _buildEmptyState(theme),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + extraBottomPadding),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final showTail = index == _messages.length - 1 ||
            (index < _messages.length - 1 &&
                _messages[index + 1].isUser != msg.isUser);
        final isUser = msg.isUser == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: _GlassChatBubble(
              message: msg,
              theme: theme,
              showTail: showTail,
              isTtsSpeaking: _ttsSpeaking && msg.id == _lastTtsMessageId,
              onReply: () => _setReplyPreview(msg),
              onCopy: () {
                Clipboard.setData(ClipboardData(text: msg.text));
                _showSnack('Copied to clipboard');
              },
              onReadAloud: () {
                if (_ttsSpeaking && _lastTtsMessageId == msg.id) {
                  _stopTtsPlayback();
                } else {
                  _speakMessage(msg);
                }
              },
              onShare: () => _shareMessage(msg.text),
              onReport: () => _showReportDialog(context, msg, theme),
              onMore: () => _showBubbleContextMenu(context, msg, theme),
            )
                .animate(
                    delay: Duration(milliseconds: 30 * index.clamp(0, 5)),
                    autoPlay: true)
                .fadeIn(duration: 220.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1, 1),
                  duration: 240.ms,
                  curve: Curves.easeOutBack,
                )
                .slide(
                  begin:
                      isUser ? const Offset(0.15, 0) : const Offset(-0.15, 0),
                  end: Offset.zero,
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        );
      },
    );
  }

  String? _lastTtsMessageId;

  void _showBubbleContextMenu(
      BuildContext context, _GolfChatMessage msg, FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryBackground.withValues(alpha: 0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: theme.alternate.withValues(alpha: 0.15),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ContextMenuItem(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: msg.text));
                      _showSnack('Copied to clipboard');
                    },
                  ),
                  _ContextMenuItem(
                    icon: _ttsSpeaking && _lastTtsMessageId == msg.id
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded,
                    label: _ttsSpeaking && _lastTtsMessageId == msg.id
                        ? 'Stop'
                        : 'Read aloud',
                    onTap: () {
                      Navigator.pop(context);
                      if (_ttsSpeaking && _lastTtsMessageId == msg.id) {
                        _stopTtsPlayback();
                      } else {
                        _speakMessage(msg);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setReplyPreview(_GolfChatMessage msg) {
    setState(() {
      _replyPreview = _ReplyPreview(
        id: msg.id,
        text:
            msg.text.length > 80 ? '${msg.text.substring(0, 80)}...' : msg.text,
        isUser: msg.isUser,
      );
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _clearReplyPreview() {
    setState(() => _replyPreview = null);
  }

  Future<void> _stopTtsPlayback() async {
    try {
      await _cartesiaTts.stopSpeaking();
    } catch (_) {
      // Ignore stop errors.
    }
    if (mounted) {
      setState(() {
        _ttsSpeaking = false;
        _lastTtsMessageId = null;
      });
    }
  }

  Future<void> _speakMessage(_GolfChatMessage msg) async {
    if (!_ttsAvailable) {
      _showSnack('Voice playback unavailable right now.');
      return;
    }

    try {
      setState(() {
        _ttsSpeaking = true;
        _lastTtsMessageId = msg.id;
      });
      await _cartesiaTts.speakText(
        text: msg.text,
        voiceId: _golfChatVoiceId,
        contentType: 'conversation',
      );
      if (mounted) {
        setState(() {
          _ttsSpeaking = false;
          _lastTtsMessageId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ttsSpeaking = false;
          _lastTtsMessageId = null;
        });
        _showSnack('Could not read aloud: $e');
      }
    }
  }

  Future<void> _shareMessage(String text) async {
    try {
      await Share.share(
        text,
        subject: 'GolfChat reflection',
        sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
      );
    } catch (e) {
      if (mounted) _showSnack('Share failed: $e');
    }
  }

  void _showReportDialog(
      BuildContext context, _GolfChatMessage msg, FlutterFlowTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.primaryBackground,
        title: Text('Report message', style: theme.titleMedium),
        content: Text(
          'This will flag the message for review. Do you want to continue?',
          style: theme.bodyMedium,
        ),
        actions: [
          FoCoCoAdaptiveButton(
            onPressed: () => Navigator.pop(context),
            label: 'Cancel',
            style: AdaptiveButtonStyle.plain,
            textColor: theme.secondaryText,
          ),
          FoCoCoAdaptiveButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack('Thank you. Report submitted.');
            },
            label: 'Report',
            style: AdaptiveButtonStyle.filled,
            color: theme.error,
            textColor: theme.primaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    final openers = const <String>[
      'What happened? What would you do differently?',
      'Where did your decisions or mindset shift?',
      'What felt clear—or unclear—about your game today?',
    ];

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Iconify(
                Carbon.chat,
                size: 44,
                color: theme.secondaryText.withValues(alpha: 0.72),
              ),
              const SizedBox(height: 14),
              Text(
                'Understand your game.',
                style: theme.titleMedium.copyWith(color: theme.primaryText),
              ),
              const SizedBox(height: 6),
              Text(
                'You reflect and explain. AI analyzes patterns, asks follow-ups, and connects mindset to outcomes.',
                textAlign: TextAlign.center,
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 14),
              ...openers.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildQuickActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(FlutterFlowTheme theme) {
    return Column(
      children: [
        _buildQuickActionCard(
          theme: theme,
          carbonIconSvg: Carbon.flag_filled,
          title: 'Log a Round',
          subtitle: 'Capture your round data for better AI insights',
          onTap: () => context.pushNamed('caddy_play'),
          color: theme.tertiary,
        ),
        const SizedBox(height: 10),
        _buildQuickActionCard(
          theme: theme,
          carbonIconSvg: Carbon.cognitive,
          title: 'Recommended Sessions',
          subtitle: 'MindCoach sessions based on your reflection',
          onTap: () => context.pushNamed('mind_coach'),
          color: theme.secondary,
        ),
        const SizedBox(height: 10),
        _buildQuickActionCard(
          theme: theme,
          carbonIconSvg: Carbon.recently_viewed,
          title: 'Chat History',
          subtitle: 'View past conversations and insights',
          onTap: _showChatHistory,
          color: theme.primary,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required FlutterFlowTheme theme,
    required String carbonIconSvg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Iconify(
                    carbonIconSvg,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.bodyMedium.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Iconify(
                  Carbon.chevron_right,
                  color: theme.secondaryText.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.alternate.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Chat History',
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.alternate.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Iconify(
                          Carbon.close,
                          color: theme.secondaryText,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No conversation history yet',
                          style: theme.bodyMedium.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? theme.conversationUser
                                      .withValues(alpha: 0.1)
                                  : theme.alternate.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.isUser ? 'You' : 'AI',
                                      style: theme.labelSmall.copyWith(
                                        color: msg.isUser
                                            ? theme.conversationUser
                                            : theme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeago.format(msg.time),
                                      style: theme.labelSmall.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  msg.text,
                                  style: theme.bodySmall.copyWith(
                                    color: theme.primaryText,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FoCoCoAdaptiveButtonIcon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startNewConversation();
                      },
                      label: 'Start New Conversation',
                      icon: Icons.add_rounded,
                      style: AdaptiveButtonStyle.filled,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _messages.clear();
      _sessionId = null;
    });
    await _ensureSession();
    _showSnack('New conversation started');
  }

  Widget _buildInput(FlutterFlowTheme theme, {bool voiceGlass = false}) {
    final fieldFill = voiceGlass
        ? Colors.white.withValues(alpha: 0.06)
        : theme.alternate.withValues(alpha: 0.12);
    final hintColor = voiceGlass
        ? Colors.white.withValues(alpha: 0.45)
        : theme.secondaryText.withValues(alpha: 0.7);
    final iconColor =
        voiceGlass ? Colors.white.withValues(alpha: 0.65) : theme.secondaryText;
    final textColor = voiceGlass ? Colors.white : theme.primaryText;

    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyPreview != null) ...[
          _buildReplyPreviewBar(theme),
          const SizedBox(height: 8),
        ],
        if (_pendingAttachments.isNotEmpty) ...[
          _buildAttachmentPreview(theme),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(voiceGlass ? 28 : 24),
                  border: voiceGlass
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _showAttachmentDialog(theme),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14, bottom: 12),
                        child: Iconify(
                          Carbon.add,
                          size: 24,
                          color: iconColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: theme.bodyMedium.copyWith(color: textColor),
                        cursorColor: voiceGlass ? Colors.white : theme.primary,
                        decoration: InputDecoration(
                          hintText: voiceGlass
                              ? 'How can FoCoCo help?'
                              : 'Reflect, ask, or share...',
                          hintStyle:
                              theme.bodyMedium.copyWith(color: hintColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    if (!voiceGlass)
                      GestureDetector(
                        onTap: _enterVoiceMode,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 14, bottom: 12, left: 4),
                          child: Iconify(
                            Carbon.microphone,
                            size: 24,
                            color: iconColor,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 6, bottom: 10, left: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List<Widget>.generate(
                              5,
                              (i) => Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Iconify(
                              Carbon.microphone,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (voiceGlass) ...[
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: theme.secondary.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    child: Center(
                      child: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Iconify(
                              Carbon.send_filled,
                              size: 22,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _exitVoiceMode,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: theme.secondary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    child: Center(
                      child: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.primaryText,
                                ),
                              ),
                            )
                          : Iconify(
                              Carbon.send_filled,
                              size: 22,
                              color: theme.primaryText,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    if (!voiceGlass) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border(
            top: BorderSide(
              color: theme.alternate.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: inner,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              child: inner,
            ),
          ),
        ),
      ),
    );
  }

  void _showAttachmentDialog(FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AttachmentBottomSheet(
        theme: theme,
        onImageFromCamera: _pickImageFromCamera,
        onImageFromGallery: _pickImageFromGallery,
        onFilePick: _pickFile,
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    Navigator.pop(context);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pendingAttachments.add(_ChatAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: image.path,
            name: image.name,
            type: _AttachmentType.image,
            bytes: bytes,
          ));
        });
      }
    } catch (e) {
      _showSnack('Failed to capture image');
    }
  }

  Future<void> _pickImageFromGallery() async {
    Navigator.pop(context);
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      for (final image in images) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pendingAttachments.add(_ChatAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: image.path,
            name: image.name,
            type: _AttachmentType.image,
            bytes: bytes,
          ));
        });
      }
    } catch (e) {
      _showSnack('Failed to select images');
    }
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx', 'xls'],
      );
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final bytes = await File(file.path!).readAsBytes();
            setState(() {
              _pendingAttachments.add(_ChatAttachment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                path: file.path!,
                name: file.name,
                type: _AttachmentType.file,
                bytes: bytes,
              ));
            });
          }
        }
      }
    } catch (e) {
      _showSnack('Failed to select file');
    }
  }

  void _removeAttachment(String id) {
    setState(() {
      _pendingAttachments.removeWhere((a) => a.id == id);
    });
  }

  Widget _buildAttachmentPreview(FlutterFlowTheme theme) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = _pendingAttachments[index];
          return _AttachmentPreviewItem(
            attachment: attachment,
            theme: theme,
            onRemove: () => _removeAttachment(attachment.id),
          );
        },
      ),
    );
  }

  Widget _buildReplyPreviewBar(FlutterFlowTheme theme) {
    final preview = _replyPreview!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.alternate.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color:
                    preview.isUser ? theme.conversationUser : theme.secondary,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preview.isUser ? 'You' : 'AI',
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      preview.text,
                      style: theme.bodySmall.copyWith(
                        color: theme.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: FoCoCoAdaptiveIconButton(
                    onPressed: _clearReplyPreview,
                    icon: Icons.close_rounded,
                    iconColor: theme.secondaryText,
                    style: AdaptiveButtonStyle.bordered,
                    size: AdaptiveButtonSize.small,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final replyTo = _replyPreview != null
        ? _ReplyPreview(
            id: _replyPreview!.id,
            text: _replyPreview!.text,
            isUser: _replyPreview!.isUser,
          )
        : null;
    _clearReplyPreview();

    final userMsg = _GolfChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      time: DateTime.now(),
      replyTo: replyTo,
    );

    setState(() {
      _messages.add(userMsg);
      _showBoundary = false;
    });

    _scrollToBottom();

    try {
      await _persistMessage(userMsg);

      final response = await _aiClient.generateConversationResponse(
        userId: currentUserUid,
        conversationId:
            _sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userMessage: text,
        conversationHistory: _messages
            .map((msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'content': msg.text,
                })
            .toList(growable: false),
        context: _reflectionContext(),
      );

      final aiMsg = _GolfChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: response.response,
        isUser: false,
        time: DateTime.now(),
      );

      setState(() => _messages.add(aiMsg));
      _scrollToBottom();
      await _persistMessage(aiMsg);
    } catch (e) {
      _showSnack('Failed to send message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _reflectionContext() {
    final roundId = _roundContextId?.trim();
    final snapshot = _roundContextSnapshot;
    final roundContext = <String>[
      if (roundId != null && roundId.isNotEmpty) '- Round ID: $roundId',
      if ((snapshot?['courseName']?.toString().trim().isNotEmpty ?? false))
        '- Course: ${snapshot!['courseName']}',
      if ((snapshot?['date']?.toString().trim().isNotEmpty ?? false))
        '- Round date: ${snapshot!['date']}',
      if ((snapshot?['roundType']?.toString().trim().isNotEmpty ?? false))
        '- Round type: ${snapshot!['roundType']}',
      if (snapshot?['scoreToPar'] != null)
        '- Score to par: ${snapshot!['scoreToPar']}',
      if (snapshot?['holesPlayed'] != null)
        '- Holes played: ${snapshot!['holesPlayed']}',
      if (snapshot?['totalMoments'] != null)
        '- Total moments: ${snapshot!['totalMoments']}',
      if ((snapshot?['momentumShift']?.toString().trim().isNotEmpty ?? false))
        '- Momentum shift: ${snapshot!['momentumShift']}',
      if ((snapshot?['mindsetSummary']?.toString().trim().isNotEmpty ?? false))
        '- Mindset summary: ${snapshot!['mindsetSummary']}',
      if ((snapshot?['completionInsight']?.toString().trim().isNotEmpty ??
          false))
        '- Completion insight: ${snapshot!['completionInsight']}',
    ].join('\n');

    return '''
GolfChat: AI helps the user understand their game.

Your role (AI):
- Analyze what the user shares: reflect back patterns and decision trends.
- Connect mindset to outcomes (e.g. how their thinking showed up in results).
- Ask smart, short follow-ups that deepen clarity—one or two questions at a time.
- Surface decision trends over time when you have enough context.
- Build clarity over time; avoid one-off advice.

User role: They reflect, ask questions, and explain what happened. Meet them there.

Formatting (Markdown):
- Use **bold** for key insights, patterns, or important phrases.
- Use *italic* for reflective questions or emphasis.
- Use bullet lists (- item) to break down observations.
- Use tables (| col | col |) when comparing stats, patterns, or round data.
- Use ### headings to separate sections in longer responses.
- Keep formatting clean and purposeful—don't over-format short replies.

Constraints:
- Calm, clear, non-judgmental tone. No in-round or shot-by-shot coaching.
- No medical or therapeutic framing.
- If deep analysis is needed, suggest exploring in the WebApp.

${roundContext.isEmpty ? '' : '\nCaddyPlay round context:\n$roundContext'}
''';
  }

  Future<void> _persistMessage(
    _GolfChatMessage message, {
    String messageType = 'text',
  }) async {
    final sessionId = _sessionId;
    if (sessionId == null || currentUserUid.isEmpty) return;

    await _db.saveMessage(
      VoiceChatMessage(
        id: message.id,
        userId: currentUserUid,
        sessionId: sessionId,
        content: message.text,
        isUser: message.isUser,
        timestamp: message.time,
        messageType: messageType,
        isSystem: false,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      debugPrint('GolfChat snack: $message');
    }
  }
}

class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this._bytes);

  final Uint8List _bytes;

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

class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListTile(
      leading: Icon(icon, size: 22, color: theme.primaryText),
      title: Text(label,
          style: theme.bodyMedium.copyWith(color: theme.primaryText)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _GlassChatBubble extends StatelessWidget {
  const _GlassChatBubble({
    required this.message,
    required this.theme,
    this.showTail = true,
    this.isTtsSpeaking = false,
    required this.onReply,
    required this.onCopy,
    required this.onReadAloud,
    required this.onShare,
    required this.onReport,
    required this.onMore,
  });

  final _GolfChatMessage message;
  final FlutterFlowTheme theme;
  final bool showTail;
  final bool isTtsSpeaking;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onReadAloud;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser == true;
    final bubbleColor = isUser
        ? theme.conversationUser.withValues(alpha: 0.92)
        : theme.conversationBackground.withValues(alpha: 0.92);
    final textColor = isUser ? Colors.white : theme.primaryText;
    final iconColor = textColor.withValues(alpha: 0.85);
    final borderColor = isUser
        ? theme.conversationUser.withValues(alpha: 0.35)
        : theme.alternate.withValues(alpha: 0.2);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : (showTail ? 4 : 18)),
          bottomRight: Radius.circular(isUser ? (showTail ? 4 : 18) : 18),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : (showTail ? 4 : 18)),
                bottomRight: Radius.circular(isUser ? (showTail ? 4 : 18) : 18),
              ),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.replyTo != null)
                  _ReplyQuote(
                    preview: message.replyTo!,
                    theme: theme,
                    isUserBubble: isUser,
                  ),
                if (isUser)
                  Text(
                    message.text,
                    style: theme.bodyMedium.copyWith(
                      color: textColor,
                      height: 1.35,
                    ),
                  )
                else
                  MarkdownBody(
                    data: message.text,
                    shrinkWrap: true,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.bodyMedium.copyWith(
                        color: textColor,
                        height: 1.35,
                      ),
                      h1: theme.titleLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      h2: theme.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      h3: theme.titleSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      strong: theme.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      em: theme.bodyMedium.copyWith(
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: theme.bodyMedium.copyWith(color: textColor),
                      tableHead: theme.bodySmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      tableBody: theme.bodySmall.copyWith(color: textColor),
                      tableBorder: TableBorder.all(
                        color: textColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      tableHeadAlign: TextAlign.left,
                      tableCellsPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      code: theme.bodySmall.copyWith(
                        color: textColor,
                        backgroundColor: textColor.withValues(alpha: 0.08),
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockSpacing: 8,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        timeago.format(message.time, locale: 'en_short'),
                        style: theme.labelSmall.copyWith(
                          color: textColor.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BubbleActionIcon(
                          icon: Icons.thumb_up_outlined,
                          iconColor: iconColor,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Thanks for feedback'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: theme.primaryBackground,
                              ),
                            );
                          },
                        ),
                        _BubbleActionIcon(
                          icon: Icons.thumb_down_outlined,
                          iconColor: iconColor,
                          onTap: onReport,
                        ),
                        _BubbleActionIcon(
                          icon: Icons.replay_rounded,
                          iconColor: iconColor,
                          onTap: onReply,
                        ),
                        _BubbleActionIcon(
                          icon: Icons.share_outlined,
                          iconColor: iconColor,
                          onTap: onShare,
                        ),
                        _BubbleActionIcon(
                          icon: Icons.more_horiz_rounded,
                          iconColor: iconColor,
                          onTap: onMore,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleActionIcon extends StatelessWidget {
  const _BubbleActionIcon({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.preview,
    required this.theme,
    required this.isUserBubble,
  });

  final _ReplyPreview preview;
  final FlutterFlowTheme theme;
  final bool isUserBubble;

  @override
  Widget build(BuildContext context) {
    final accentColor = preview.isUser
        ? (isUserBubble ? Colors.white : theme.conversationUser)
        : (isUserBubble ? theme.conversationBackground : theme.secondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isUserBubble ? Colors.white : theme.primaryText)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preview.isUser ? 'You' : 'AI',
              style: theme.labelSmall.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              preview.text,
              style: theme.bodySmall.copyWith(
                color: (isUserBubble ? Colors.white : theme.primaryText)
                    .withValues(alpha: 0.9),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sparse starfield for voice mode (deterministic layout).
class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  static const int _count = 96;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final rnd = math.Random(0x4f63436f);
    for (var i = 0; i < _count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.72;
      final base = 0.15 + rnd.nextDouble() * 0.55;
      paint.color = Colors.white.withValues(alpha: base.clamp(0.08, 0.85));
      final r = 0.6 + rnd.nextDouble() * 1.1;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom-edge gradient glow with waves driven by mic / model PCM levels.
class _VoiceBottomWavePainter extends CustomPainter {
  _VoiceBottomWavePainter({
    required this.audioLevels,
    required this.wavePhase,
    required this.gradientProgress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.isActive,
    required this.voiceState,
  });

  final List<double> audioLevels;
  final double wavePhase;
  final double gradientProgress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final bool isActive;
  final _VoiceModeState voiceState;

  double _levelAt(double normalizedX) {
    if (audioLevels.isEmpty) return 0;
    final i = (normalizedX * (audioLevels.length - 1))
        .floor()
        .clamp(0, audioLevels.length - 1);
    return audioLevels[i];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = gradientProgress;
    final c0 = Color.lerp(
      primaryColor,
      secondaryColor,
      t,
    )!
        .withValues(alpha: 0.95);
    final c1 = Color.lerp(
      secondaryColor,
      tertiaryColor,
      t,
    )!
        .withValues(alpha: 0.85);
    final c2 = Color.lerp(
      tertiaryColor,
      primaryColor,
      t,
    )!
        .withValues(alpha: 0.65);

    final baseAmp = switch (voiceState) {
      _VoiceModeState.speaking => 38.0,
      _VoiceModeState.listening => 34.0,
      _VoiceModeState.processing => 22.0,
      _ => 14.0,
    };
    final activeBoost = isActive ? 1.35 : 0.85;

    for (var layer = 0; layer < 3; layer++) {
      final phaseOff = layer * math.pi * 0.45;
      final ampMul = 1.0 - layer * 0.22;
      final path = Path();
      const waves = 2.8;
      var first = true;
      var lastY = 0.0;
      for (var x = 0.0; x <= size.width; x += 1.5) {
        final nx = x / math.max(size.width, 1);
        final lvl = _levelAt(nx);
        final wobble = math.sin(
          wavePhase + phaseOff + nx * waves * math.pi * 2,
        );
        final y = size.height * (0.12 + layer * 0.05) +
            wobble * baseAmp * ampMul * activeBoost * (1.0 + lvl * 2.2) +
            lvl * 28 * ampMul;
        lastY = y;
        if (first) {
          path.moveTo(0, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      path
        ..lineTo(size.width, lastY)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            c2.withValues(alpha: 0.12 + layer * 0.06),
            c1.withValues(alpha: 0.38 + layer * 0.08),
            c0.withValues(alpha: 0.55 + layer * 0.06),
          ],
          stops: const [0.0, 0.35, 0.72, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }

    final gloss = Paint()
      ..blendMode = BlendMode.plus
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          primaryColor.withValues(alpha: 0.0),
          secondaryColor.withValues(alpha: 0.22),
          tertiaryColor.withValues(alpha: 0.18),
          primaryColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.38, 0.62, 1.0],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.75),
      gloss,
    );
  }

  @override
  bool shouldRepaint(covariant _VoiceBottomWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.gradientProgress != gradientProgress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.voiceState != voiceState ||
        !_levelsEqual(oldDelegate.audioLevels, audioLevels);
  }

  bool _levelsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.015) return false;
    }
    return true;
  }
}

class _VoiceMicGlyph extends StatelessWidget {
  const _VoiceMicGlyph({
    required this.theme,
    required this.voiceState,
    required this.wavePhase,
    required this.gradientT,
  });

  final FlutterFlowTheme theme;
  final _VoiceModeState voiceState;
  final double wavePhase;
  final double gradientT;

  @override
  Widget build(BuildContext context) {
    final active = voiceState == _VoiceModeState.listening ||
        voiceState == _VoiceModeState.speaking;
    final h = 28.0;
    return SizedBox(
      height: h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(5, (i) {
          final base =
              active ? 0.35 + 0.65 * math.sin(wavePhase + i * 0.9) : 0.2;
          final bh = (h * (0.25 + base * 0.75)).clamp(4.0, h);
          final c = Color.lerp(
            theme.primary,
            theme.secondary,
            (i / 4 + gradientT) % 1.0,
          )!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 4,
              height: bh,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: active ? 0.85 : 0.35),
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AttachmentBottomSheet extends StatelessWidget {
  const _AttachmentBottomSheet({
    required this.theme,
    required this.onImageFromCamera,
    required this.onImageFromGallery,
    required this.onFilePick,
  });

  final FlutterFlowTheme theme;
  final VoidCallback onImageFromCamera;
  final VoidCallback onImageFromGallery;
  final VoidCallback onFilePick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.alternate.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Add to conversation',
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    theme: theme,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: theme.primary,
                    onTap: onImageFromCamera,
                  ),
                  _AttachmentOption(
                    theme: theme,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: theme.secondary,
                    onTap: onImageFromGallery,
                  ),
                  _AttachmentOption(
                    theme: theme,
                    icon: Icons.insert_drive_file_rounded,
                    label: 'File',
                    color: theme.tertiary,
                    onTap: onFilePick,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.theme,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final FlutterFlowTheme theme;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.labelMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreviewItem extends StatelessWidget {
  const _AttachmentPreviewItem({
    required this.attachment,
    required this.theme,
    required this.onRemove,
  });

  final _ChatAttachment attachment;
  final FlutterFlowTheme theme;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.alternate.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.alternate.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: attachment.type == _AttachmentType.image
              ? (attachment.bytes != null
                  ? Image.memory(
                      attachment.bytes!,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(attachment.path),
                      fit: BoxFit.cover,
                    ))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getFileIcon(attachment.name),
                      size: 28,
                      color: theme.secondaryText,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        attachment.name,
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText,
                          fontSize: 9,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: theme.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
