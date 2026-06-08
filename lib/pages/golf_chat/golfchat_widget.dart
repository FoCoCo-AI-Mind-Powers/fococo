import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';

import '/adaptive_ui/adaptive_ui.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'golf_chat_message_body.dart';
import '/ai_integration/gemini_ai_client.dart';
import '/ai_integration/config/cartesia_mcp_config.dart';
import '/ai_integration/services/audio_session_service.dart';
import '/ai_integration/services/cartesia_api_service.dart';
import '/ai_integration/services/cartesia_speech_prompt.dart';
import '/ai_integration/services/cartesia_line_voice_service.dart';
import '/ai_integration/services/cartesia_voice_runtime.dart';
import '/ai_integration/services/voice_chat_database_service.dart';
import '/services/voice_live_activity_service.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/pages/golf_rounds/caddyplay_models.dart';
import '/services/first_use_disclosure_service.dart';
import '/services/ai_voice_preference_service.dart';
import '/services/units_preference_service.dart';

import 'golfchat_model.dart';

export 'golfchat_model.dart';

/// Breathing room between the tab bar (shell) and the composer — tab shell uses
/// [kFoCoCoBottomNavStripAndTabsHeight] + [MediaQuery.viewPadding.bottom].
/// Extra breathing room for the glass voice composer above the tab bar.
const double _kGolfChatVoiceComposerGapAboveNav = 28;
const Color _kGolfChatVoiceBlue = Color(0xFF5B8DEF);

class GolfChatWidget extends StatefulWidget {
  const GolfChatWidget({
    super.key,
    this.initialRoundId,
    this.initialCaddyPlaySnapshot,
    this.initialSessionId,
  });

  static const String routeName = 'golf_chat';
  static const String routePath = '/golf_chat';

  final String? initialRoundId;
  final Map<String, dynamic>? initialCaddyPlaySnapshot;
  final String? initialSessionId;

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
  // Charts/tables emitted by the model via function calling. Ephemeral — not
  // persisted, so reloaded history shows text only.
  final List<Map<String, dynamic>> visuals;

  const _GolfChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.replyTo,
    this.visuals = const [],
  });

  _GolfChatMessage copyWith({_ReplyPreview? replyTo}) => _GolfChatMessage(
        id: id,
        text: text,
        isUser: isUser,
        time: time,
        replyTo: replyTo ?? this.replyTo,
        visuals: visuals,
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
  GeminiAIClient? _aiClient;
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
  String _unitsAiContextLine = '';
  final List<_GolfChatMessage> _messages = <_GolfChatMessage>[];
  // Mutually exclusive sets — a message can be liked OR disliked, not both.
  final Set<String> _likedMessageIds = <String>{};
  final Set<String> _dislikedMessageIds = <String>{};
  _ReplyPreview? _replyPreview;

  void _toggleLike(_GolfChatMessage msg) {
    setState(() {
      if (_likedMessageIds.remove(msg.id)) return;
      _dislikedMessageIds.remove(msg.id);
      _likedMessageIds.add(msg.id);
    });
    if (_likedMessageIds.contains(msg.id)) {
      _showSnack('Thanks for the feedback');
    }
  }

  void _toggleDislike(_GolfChatMessage msg) {
    setState(() {
      if (_dislikedMessageIds.remove(msg.id)) return;
      _likedMessageIds.remove(msg.id);
      _dislikedMessageIds.add(msg.id);
    });
    if (_dislikedMessageIds.contains(msg.id)) {
      _showReportDialog(context, msg, FlutterFlowTheme.of(context));
    }
  }

  static const String _boundaryCopy =
      'Reflection only—not in-round coaching. AI helps you understand your game.';

  // Voice mode — Cartesia STT/TTS + `generateGolfChatResponse` (GEMINI_KEY_APP
  // secret on Cloud Functions). Does not use client-side Gemini Live.
  bool _isVoiceMode = false;
  _VoiceModeState _voiceState = _VoiceModeState.idle;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  bool _isHandlingVoiceTransportError = false;
  bool _isProcessingVoiceTurn = false;
  final BytesBuilder _voiceCaptureBuffer = BytesBuilder(copy: false);
  DateTime? _lastVoiceActivityAt;
  Timer? _voiceSilenceTimer;
  static const int _voiceSampleRate = 16000;
  static const int _voiceMinUtteranceBytes = _voiceSampleRate * 2 ~/ 2;
  static const Duration _voiceSilenceDuration = Duration(milliseconds: 1500);
  static const double _voiceActivityThreshold = 0.015;
  String _liveTranscription = '';
  final List<double> _audioLevels = List.filled(64, 0.0);
  final CartesiaLineVoiceService _lineVoice = CartesiaLineVoiceService.instance;
  StreamSubscription<CartesiaLineVoiceState>? _lineStateSub;
  bool _usingLineVoice = false;

  // Attachments
  final List<_ChatAttachment> _pendingAttachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _waveAnimationController;
  late AnimationController _gradientAnimationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _gradientAnimation;
  bool _hasBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GolfChatModel());
    _configureAudioPlayer();
    _initAnimations();
  }

  void _configureAudioPlayer() {
    // Reserved for bubble read-aloud; voice replies use CartesiaAPIService.
    _audioPlayerStateSubscription = _audioPlayer.playerStateStream.listen((_) {});
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
    final sessionChanged =
        oldWidget.initialSessionId != widget.initialSessionId;
    if (!roundChanged && !snapshotChanged && !sessionChanged) {
      return;
    }

    _hydrateRoundContextFromWidget();
    if (!_isLoading) {
      unawaited(_ensureSession());
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<GeminiAIClient> _ensureAiClient() async {
    _aiClient ??= GeminiAIClient();
    return _aiClient!;
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
    // Calm mentor delivery first — slower, smoother flow, matching the
    // requested coaching tone. Fall back to the central default if profiles
    // are missing for any reason.
    final profile = CartesiaMCPConfig.getVoiceProfile('mentor_calm') ??
        CartesiaMCPConfig.getVoiceProfile('coach_conversational') ??
        CartesiaMCPConfig.getVoiceProfile('coach_confident');
    final voiceId = profile?['voice_id']?.toString().trim();
    if (voiceId == null || voiceId.isEmpty) {
      return CartesiaMCPConfig.defaultVoiceId;
    }
    return voiceId;
  }

  Future<void> _initialize() async {
    try {
      await _db.initialize();
      _hydrateRoundContextFromWidget();
      _unitsAiContextLine = await UnitsPreferenceService.aiContextLine();
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
    final requestedSessionId = widget.initialSessionId?.trim();
    try {
      if (requestedSessionId != null && requestedSessionId.isNotEmpty) {
        session = await _db.getSessionById(requestedSessionId);
        if (session != null &&
            session.sessionMetadata['surface'] != 'golfchat') {
          session = null;
        }
      } else {
        session = await _db.getActiveSession();
        if (session != null &&
            session.sessionMetadata['surface'] != 'golfchat') {
          session = null;
        } else if (session != null &&
            requestedRoundId != null &&
            requestedRoundId.isNotEmpty &&
            session.sessionMetadata['roundId']?.toString() !=
                requestedRoundId) {
          session = null;
        }
      }
    } catch (_) {
      session = null;
    }

    try {
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
    } catch (e) {
      debugPrint('GolfChat session persistence unavailable: $e');
      // Fall back to an in-memory session so users can keep chatting.
      _sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
      _messages.clear();
      if (mounted) {
        _showSnack(
          'Chat history is unavailable right now. You can still continue chatting.',
        );
      }
      return;
    }

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
    _voiceSilenceTimer?.cancel();
    unawaited(_exitVoiceMode());
    _cartesiaTts.stopSpeaking();
    _audioPlayerStateSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _waveAnimationController.dispose();
    _gradientAnimationController.dispose();
    _lineStateSub?.cancel();
    unawaited(_lineVoice.disconnect());
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _enterVoiceMode() async {
    if (_isVoiceMode) {
      return;
    }

    if (!await AiVoicePreferenceService.isEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on AI Voice in Preferences to use voice mode.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!await _ensureMicrophonePermission()) {
      return;
    }

    await _stopTtsPlayback();
    await _cartesiaTts.stopSpeaking();

    final runtime = await CartesiaVoiceRuntime.load();
    if (runtime.hasLineAgent && mounted) {
      await _startLineVoiceMode();
      return;
    }

    await _startLegacyVoiceMode();
  }

  Future<void> _startLineVoiceMode() async {
    if (!mounted || _isVoiceMode) return;

    unawaited(VoiceLiveActivityService.instance.start());

    setState(() {
      _isVoiceMode = true;
      _usingLineVoice = true;
      _voiceState = _VoiceModeState.connecting;
      _liveTranscription = '';
      _audioLevels.fillRange(0, _audioLevels.length, 0.0);
    });

    _lineStateSub?.cancel();
    _lineStateSub = _lineVoice.stateStream.listen(_onLineVoiceState);

    try {
      await _lineVoice.connect(
        CartesiaLineVoiceSession(
          surface: 'golf_chat',
          systemPrompt: _golfChatLineSystemPrompt(),
          metadata: {
            if (_sessionId != null) 'session_id': _sessionId,
            if (_roundContextId != null) 'round_id': _roundContextId,
          },
        ),
      );
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.listening);
      }
      unawaited(VoiceLiveActivityService.instance.update(status: 'listening'));
    } catch (e) {
      debugPrint('Line voice mode start failed: $e');
      _lineStateSub?.cancel();
      _lineStateSub = null;
      await _lineVoice.disconnect();
      _usingLineVoice = false;
      unawaited(VoiceLiveActivityService.instance.stop());
      if (mounted) {
        setState(() {
          _isVoiceMode = false;
          _voiceState = _VoiceModeState.idle;
        });
        _showSnack('Live voice unavailable. Using standard voice mode.');
        await _startLegacyVoiceMode();
      }
    }
  }

  void _onLineVoiceState(CartesiaLineVoiceState state) {
    if (!mounted || !_usingLineVoice) return;
    final next = switch (state) {
      CartesiaLineVoiceState.connecting => _VoiceModeState.connecting,
      CartesiaLineVoiceState.listening => _VoiceModeState.listening,
      CartesiaLineVoiceState.speaking => _VoiceModeState.speaking,
      CartesiaLineVoiceState.processing => _VoiceModeState.processing,
      CartesiaLineVoiceState.error => _VoiceModeState.error,
      CartesiaLineVoiceState.idle => _VoiceModeState.idle,
    };
    if (_voiceState == next) return;
    setState(() => _voiceState = next);
    if (next == _VoiceModeState.listening ||
        next == _VoiceModeState.speaking) {
      unawaited(
        VoiceLiveActivityService.instance.update(
          status: next == _VoiceModeState.speaking ? 'speaking' : 'listening',
        ),
      );
    }
  }

  Future<void> _startLegacyVoiceMode() async {
    if (!mounted || _isVoiceMode) return;

    await AudioSessionService.activateVoiceChat();
    unawaited(VoiceLiveActivityService.instance.start());

    setState(() {
      _isVoiceMode = true;
      _voiceState = _VoiceModeState.connecting;
      _liveTranscription = '';
      _audioLevels.fillRange(0, _audioLevels.length, 0.0);
    });

    try {
      await _startVoiceCapture();
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.listening);
      }
      unawaited(VoiceLiveActivityService.instance.update(status: 'listening'));
    } catch (e) {
      debugPrint('Voice mode start failed: $e');
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.error);
        _showSnack(_describeVoiceError(e));
      }
    }
  }

  String _golfChatLineSystemPrompt() {
    final ctx = _reflectionContext();
    return 'You are FoCoCo GolfChat — calm golf mental reflection only. '
        'No swing mechanics. Short spoken replies. One idea per turn.\n\n'
        '${ctx.isNotEmpty ? "Player context:\n$ctx" : ""}';
  }

  Future<void> _startVoiceCapture() async {
    _voiceCaptureBuffer.clear();
    _lastVoiceActivityAt = null;
    _voiceSilenceTimer?.cancel();
    _voiceSilenceTimer = null;
    await _startAudioCapture();
  }

  Future<void> _exitVoiceMode() async {
    _voiceSilenceTimer?.cancel();
    _voiceSilenceTimer = null;
    _voiceCaptureBuffer.clear();
    _lastVoiceActivityAt = null;
    _isProcessingVoiceTurn = false;
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    if (_usingLineVoice) {
      _lineStateSub?.cancel();
      _lineStateSub = null;
      await _lineVoice.disconnect();
      _usingLineVoice = false;
    } else {
      try {
        await _audioRecorder.stop();
      } catch (_) {}
    }

    await _cartesiaTts.stopSpeaking();
    await AudioSessionService.deactivateVoiceChat();
    unawaited(VoiceLiveActivityService.instance.stop());

    if (mounted) {
      setState(() {
        _isVoiceMode = false;
        _voiceState = _VoiceModeState.idle;
        _liveTranscription = '';
        _audioLevels.fillRange(0, _audioLevels.length, 0.0);
      });
    }
  }

  /// Request the OS microphone prompt before any recording APIs are touched.
  /// Returns true when we have a usable permission. Handles permanently
  /// denied state by inviting the user to open Settings — required for both
  /// App Store and Play review compliance.
  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showSnack(
        'Microphone access is disabled. Open Settings to enable it for FoCoCo.',
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      );
      return false;
    }

    // Show our in-app purpose string before the OS prompt so the user
    // understands what they are about to grant. Apple/Google require this
    // for permission requests tied to coaching audio.
    final acknowledged = await FirstUseDisclosureService.instance
        .ensureAcknowledged(context, FoCoCoDisclosureTopic.microphone);
    if (!acknowledged) return false;

    final requested = await Permission.microphone.request();
    if (requested.isGranted || requested.isLimited) {
      return true;
    }

    _showSnack(
      requested.isPermanentlyDenied
          ? 'Microphone access is blocked. Enable it from Settings to talk with FoCoCo.'
          : 'Microphone permission is required for voice mode.',
      action: requested.isPermanentlyDenied
          ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
          : null,
    );
    return false;
  }

  Future<void> _startAudioCapture() async {
    if (!await _ensureMicrophonePermission()) {
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
      _onVoicePcmChunk(data);
    });
  }

  void _onVoicePcmChunk(Uint8List data) {
    if (!_isVoiceMode || data.isEmpty) {
      return;
    }

    if (_voiceState == _VoiceModeState.speaking &&
        _pcmRms(data) >= _voiceActivityThreshold) {
      unawaited(_cartesiaTts.stopSpeaking());
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.listening);
      }
    }

    if (_voiceState != _VoiceModeState.listening || _isProcessingVoiceTurn) {
      return;
    }

    _voiceCaptureBuffer.add(data);
    _updateAudioLevelsFromInput(data);

    if (_pcmRms(data) >= _voiceActivityThreshold) {
      _lastVoiceActivityAt = DateTime.now();
    }

    _voiceSilenceTimer?.cancel();
    _voiceSilenceTimer = Timer(_voiceSilenceDuration, () {
      if (_shouldFinalizeVoiceTurn()) {
        unawaited(_processVoiceTurn());
      }
    });
  }

  double _pcmRms(Uint8List pcm) {
    if (pcm.length < 2) return 0;
    var sum = 0.0;
    final sampleCount = pcm.length ~/ 2;
    for (var i = 0; i < sampleCount; i++) {
      final index = i * 2;
      final sample =
          (pcm[index] | (pcm[index + 1] << 8)).toSigned(16) / 32768.0;
      sum += sample * sample;
    }
    return math.sqrt(sum / sampleCount);
  }

  bool _shouldFinalizeVoiceTurn() {
    if (!_isVoiceMode ||
        _isProcessingVoiceTurn ||
        _voiceState != _VoiceModeState.listening) {
      return false;
    }
    if (_voiceCaptureBuffer.length < _voiceMinUtteranceBytes) {
      return false;
    }
    final lastActivity = _lastVoiceActivityAt;
    if (lastActivity == null) {
      return false;
    }
    return DateTime.now().difference(lastActivity) >= _voiceSilenceDuration;
  }

  Future<void> _processVoiceTurn() async {
    if (_isProcessingVoiceTurn || !_isVoiceMode) {
      return;
    }
    _isProcessingVoiceTurn = true;
    _voiceSilenceTimer?.cancel();

    final pcm = _voiceCaptureBuffer.toBytes();
    _voiceCaptureBuffer.clear();
    _lastVoiceActivityAt = null;

    if (pcm.length < _voiceMinUtteranceBytes) {
      _isProcessingVoiceTurn = false;
      return;
    }

    if (mounted) {
      setState(() => _voiceState = _VoiceModeState.processing);
    }
    unawaited(VoiceLiveActivityService.instance.update(status: 'processing'));

    try {
      final wav = _buildWavFile(pcm, sampleRate: _voiceSampleRate);
      final transcript = await _cartesiaTts.transcribeAudio(
        audioBytes: wav,
        fileName: 'golfchat-voice.wav',
        contentType: MediaType('audio', 'wav'),
        encoding: 'pcm_s16le',
        sampleRate: _voiceSampleRate,
        language: 'en',
      );

      final userText = transcript.text.trim();
      if (userText.isEmpty) {
        if (mounted) {
          setState(() => _voiceState = _VoiceModeState.listening);
        }
        unawaited(
            VoiceLiveActivityService.instance.update(status: 'listening'));
        return;
      }

      if (mounted) {
        setState(() => _liveTranscription = userText);
      }
      unawaited(VoiceLiveActivityService.instance.update(
        transcript: _truncateForActivity(userText),
        status: 'processing',
      ));

      final now = DateTime.now();
      final userMsg = _GolfChatMessage(
        id: now.microsecondsSinceEpoch.toString(),
        text: userText,
        isUser: true,
        time: now,
      );

      if (mounted) {
        setState(() {
          _messages.add(userMsg);
          _showBoundary = false;
        });
      } else {
        _messages.add(userMsg);
      }
      _scrollToBottom();
      await _persistMessage(userMsg, messageType: 'audio');

      final aiClient = await _ensureAiClient();
      final response = await aiClient.generateConversationResponse(
        userId: currentUserUid,
        conversationId:
            _sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userMessage: userText,
        conversationHistory: _messages
            .map((msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'content': msg.text,
                })
            .toList(growable: false),
        context: _reflectionContext(),
      );

      final aiMsg = _GolfChatMessage(
        id: '${now.microsecondsSinceEpoch + 1}',
        text: response.response,
        isUser: false,
        time: DateTime.now(),
        visuals: response.visuals,
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _liveTranscription = response.response;
        });
      } else {
        _messages.add(aiMsg);
        _liveTranscription = response.response;
      }
      _scrollToBottom();
      await _persistMessage(aiMsg, messageType: 'native_audio');

      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.speaking);
      }
      unawaited(VoiceLiveActivityService.instance.update(
        transcript: _truncateForActivity(response.response),
        status: 'speaking',
      ));

      await _cartesiaTts.speakTextWithContinuations(
        text: response.response,
        contentType: 'golf_reflection',
        speechProfile: CartesiaSpeechPrompt.golfReflection,
      );
    } catch (e) {
      debugPrint('GolfChat voice turn failed: $e');
      if (mounted) {
        setState(() => _voiceState = _VoiceModeState.error);
        _showSnack(_describeVoiceError(e));
      }
    } finally {
      _isProcessingVoiceTurn = false;
      if (mounted && _isVoiceMode && _voiceState != _VoiceModeState.error) {
        setState(() {
          _voiceState = _VoiceModeState.listening;
          _liveTranscription = '';
          _audioLevels.fillRange(0, _audioLevels.length, 0.0);
        });
        unawaited(
            VoiceLiveActivityService.instance.update(status: 'listening'));
      }
    }
  }

  Future<void> _handleVoiceSessionError(Object error) async {
    if (_isHandlingVoiceTransportError) {
      return;
    }

    _isHandlingVoiceTransportError = true;
    debugPrint('Voice session error: $error');

    try {
      await _audioStreamSubscription?.cancel();
    } catch (_) {}
    _audioStreamSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (_) {}

    await _cartesiaTts.stopSpeaking();
    await AudioSessionService.deactivateVoiceChat();
    unawaited(VoiceLiveActivityService.instance.stop());

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
    if (message.contains('GEMINI_KEY_APP') ||
        message.contains('Gemini key configuration')) {
      return 'GolfChat AI is not configured on the server. Confirm the '
          'GEMINI_KEY_APP secret in Google Secret Manager and redeploy '
          'Cloud Functions.';
    }
    if (message.contains('CARTESIA_API')) {
      return 'Voice transcription is not configured. Check the CARTESIA_API '
          'secret in Secret Manager.';
    }
    if (message.contains('reported as leaked')) {
      return 'The Gemini API key was flagged. Rotate GEMINI_KEY_APP in '
          'Secret Manager and redeploy functions.';
    }
    if (message.contains('failed-precondition')) {
      return 'Voice AI is temporarily unavailable. Try again in a moment.';
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

  /// Live Activities have a tight payload budget — keep the transcript short
  /// so the lock-screen + Dynamic Island update reliably.
  String _truncateForActivity(String text, {int max = 140}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '…${clean.substring(clean.length - max)}';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bootstrapIfVisible();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final hasKeyboard = keyboardHeight > 0;

    // Bottom-nav reserve is only used by the voice-mode overlay (which still
    // floats over the chat). The composer itself is now a normal Column row,
    // so it no longer needs manual bottom math — Scaffold.resizeToAvoidBottomInset
    // + SafeArea handles the keyboard and home indicator correctly.
    final voiceModeBottomReserve = hasKeyboard
        ? 0.0
        : (kFoCoCoBottomNavStripAndTabsHeight +
            MediaQuery.viewPaddingOf(context).bottom +
            _kGolfChatVoiceComposerGapAboveNav);

    final canPop = context.canPop();

    // Main content: progress → banners → conversation → composer.
    // The composer is the LAST row of the Column (not a Positioned overlay),
    // so the keyboard-aware Scaffold pushes it above the keyboard naturally
    // and the conversation never overlaps it.
    final mainColumn = Container(
          color: theme.primaryBackground,
          child: Column(
            children: [
              FoCoCoInlineScreenHeader(
                title: 'GolfChat',
                leading: canPop
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.primaryText,
                          size: 20,
                        ),
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                      )
                    : null,
                actions: [
                  IconButton(
                    icon: Icon(Icons.history_rounded, color: theme.primaryText),
                    tooltip: 'History',
                    onPressed: _showChatHistory,
                  ),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: theme.primaryText),
                    tooltip: 'New chat',
                    onPressed: () => unawaited(_startNewConversation()),
                  ),
                ],
                topInset: MediaQuery.viewPaddingOf(context).top,
              ),
              if (_isLoading && !_isVoiceMode) const LinearProgressIndicator(minHeight: 2),
              if (_showBoundary && !_isVoiceMode) _buildBoundary(theme),
              if (_hasRoundContext && !_isVoiceMode) _buildRoundContextBanner(theme),
              Expanded(
                child: _isVoiceMode
                    ? _buildVoiceModeOverlay(theme, voiceModeBottomReserve)
                    : _buildConversation(theme, extraBottomPadding: 0),
              ),
              if (!_isVoiceMode)
                SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: !hasKeyboard,
                  minimum: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildInput(theme),
                  ),
                ),
            ],
          ),
        );

    return FoCoCoAdaptiveScaffold(
      backgroundColor: theme.primaryBackground,
      hideAppBar: true,
      currentRoute: GolfChatWidget.routeName,
      onTap: (route) => context.goNamed(route),
      showBottomNav: false,
      enableVoiceButton: !_isVoiceMode,
      body: mainColumn,
    );
  }

  void _bootstrapIfVisible() {
    final isVisible =
        GoRouterState.of(context).uri.toString().contains(GolfChatWidget.routePath);
    if (!isVisible || _hasBootstrapped) {
      return;
    }

    _hasBootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initialize());
      unawaited(_initTts());
    });
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
                    primaryColor: _kGolfChatVoiceBlue,
                    secondaryColor: theme.secondary,
                    tertiaryColor: const Color(0xFF3D6FCC),
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
        line1 = 'Listening';
        line2 = 'You may start speaking';
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
        _PulsingVoiceGlyph(
          voiceState: _voiceState,
          color: _kGolfChatVoiceBlue,
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
        if (_liveTranscription.isNotEmpty && !_usingLineVoice) ...[
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
    if (!await AiVoicePreferenceService.isEnabled()) {
      return;
    }
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
        voiceProfileKey: 'mentor_calm',
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
        // AlertDialog wraps its actions in an OverflowBar that asks for
        // intrinsic widths. FoCoCoAdaptiveButton uses LayoutBuilder internally
        // (which can't return intrinsic dimensions), so plain TextButtons are
        // used here — same UX, no layout assertions.
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack('Thank you. Report submitted.');
            },
            child: Text(
              'Report',
              style: TextStyle(
                color: theme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    return Center(
      child: GestureDetector(
        onTap: _enterVoiceMode,
        child: const _PulsingVoiceGlyph(
          voiceState: _VoiceModeState.idle,
          color: _kGolfChatVoiceBlue,
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
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            14,
                            8,
                            14,
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
                            Carbon.phone_voice,
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
                              Carbon.phone_voice,
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
      return Material(
        color: theme.primaryBackground,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            border: Border(
              top: BorderSide(
                color: theme.alternate.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
          ),
          child: inner,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
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
      if (!mounted) return;
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
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
      if (mounted) _showSnack('Failed to capture image');
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
      if (!mounted) return;
      for (final image in images) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
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
      if (mounted) _showSnack('Failed to select images');
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
      if (!mounted) return;
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final bytes = await File(file.path!).readAsBytes();
            if (!mounted) return;
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
      if (mounted) _showSnack('Failed to select file');
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
    FocusScope.of(context).unfocus();
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

      final aiClient = await _ensureAiClient();
      final response = await aiClient.generateConversationResponse(
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
        visuals: response.visuals,
      );

      setState(() => _messages.add(aiMsg));
      _scrollToBottom();
      await _persistMessage(aiMsg);
    } catch (e) {
      _showSnack(_friendlySendError(e));
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
        '- Score to par: ${formatCaddyPlayScoreToParLabel(
              (snapshot!['scoreToPar'] as num?)?.toInt() ?? 0,
              approximate: snapshot['scoreToParIsApproximate'] == true,
            )}',
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

Formatting:
- Use **bold** for key insights and GolfChat-blue emphasis in prose.
- Use ### headings to separate sections in longer round reflections.
- For round stats, comparisons, or breakdowns, call render_table (preferred) instead of markdown pipe tables.
- Use render_chart when a trend or distribution is clearer visually.
- Keep short replies conversational; use structure only when reflecting on round data.

Constraints:
- Calm, clear, non-judgmental tone. No in-round or shot-by-shot coaching.
- No medical or therapeutic framing.
- Always complete every sentence — never stop mid-thought. When the user asks for depth, give a full answer.
- If deep analysis is needed, suggest exploring in the WebApp.

${roundContext.isEmpty ? '' : '\nCaddyPlay round context:\n$roundContext'}
${_unitsAiContextLine.isEmpty ? '' : '\n$_unitsAiContextLine'}
''';
  }

  Widget _buildVoiceConnectionBanner(FlutterFlowTheme theme) {
    final isError = _voiceState == _VoiceModeState.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: (isError ? theme.error : theme.secondary)
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                isError ? Icons.wifi_off_rounded : Icons.sync_rounded,
                size: 18,
                color: isError ? theme.error : theme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isError
                      ? 'Voice connection issue. Check network or tap mic to retry.'
                      : 'Connecting voice…',
                  style: theme.bodySmall.copyWith(color: theme.primaryText),
                ),
              ),
              if (isError)
                TextButton(
                  onPressed: _enterVoiceMode,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isGeminiUnavailableError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('reported as leaked') ||
        msg.contains('permission_denied') ||
        msg.contains('api_key_service_blocked') ||
        msg.contains('gemini is not available') ||
        msg.contains('403');
  }

  String _friendlySendError(Object error) {
    if (_isGeminiUnavailableError(error)) {
      return 'AI responses are temporarily unavailable. Rotate the Gemini key in '
          'Secret Manager / Cloud Functions and try again.';
    }
    return 'Failed to send message: $error';
  }

  Future<void> _persistMessage(
    _GolfChatMessage message, {
    String messageType = 'text',
  }) async {
    final sessionId = _sessionId;
    if (sessionId == null || currentUserUid.isEmpty) return;

    try {
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
    } catch (e) {
      // Persistence errors should not block chat generation.
      debugPrint('GolfChat message persistence failed: $e');
    }
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

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
        ),
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
  });

  final _GolfChatMessage message;
  final FlutterFlowTheme theme;
  final bool showTail;
  final bool isTtsSpeaking;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onReadAloud;

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
            constraints: BoxConstraints(
              maxWidth: isUser
                  ? 320
                  : MediaQuery.sizeOf(context).width - 56,
            ),
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
                  GolfChatMessageBody(
                    text: message.text,
                    visuals: message.visuals,
                    theme: theme,
                    textColor: textColor,
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
                          icon: Icons.replay_rounded,
                          iconColor: iconColor,
                          onTap: onReply,
                        ),
                        _BubbleActionIcon(
                          icon: Icons.copy_rounded,
                          iconColor: iconColor,
                          onTap: onCopy,
                        ),
                        _BubbleActionIcon(
                          icon: isTtsSpeaking
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          iconColor: iconColor,
                          onTap: onReadAloud,
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

class _PulsingVoiceGlyph extends StatefulWidget {
  const _PulsingVoiceGlyph({
    required this.color,
    required this.voiceState,
  });

  final Color color;
  final _VoiceModeState voiceState;

  @override
  State<_PulsingVoiceGlyph> createState() => _PulsingVoiceGlyphState();
}

class _PulsingVoiceGlyphState extends State<_PulsingVoiceGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _active =>
      widget.voiceState == _VoiceModeState.listening ||
      widget.voiceState == _VoiceModeState.speaking ||
      widget.voiceState == _VoiceModeState.processing;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = _active ? (_controller.value * 0.15) : 0.0;
        final scale = 1.0 + pulse;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: _active ? 0.08 : 0.04),
              border: Border.all(
                color: widget.color.withValues(alpha: _active ? 0.35 : 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _active ? 0.45 : 0.28),
                  blurRadius: _active ? 32 : 24,
                  spreadRadius: _active ? 6 : 4,
                ),
              ],
            ),
            child: Iconify(
              Carbon.phone_voice,
              size: 56,
              color: widget.color.withValues(alpha: _active ? 1 : 0.82),
            ),
          ),
        );
      },
    );
  }
}
